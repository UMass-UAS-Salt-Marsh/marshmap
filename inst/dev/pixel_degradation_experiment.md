# Pixel-degradation experiment: how much does plot size matter?

**Project:** MassMarsh UAS / marshmap U-Net
**Purpose of this doc:** design spec + integration notes for implementing the
experiment on Unity. Companion code: `degrade.R`.

---

## 1. Question

For a **fixed set of independent labeled locations**, how much does reducing the
number of labeled pixels *per location* cost U-Net accuracy? In field terms:
does a 0.5 m plot lose anything a 1.0 m plot captures, holding plot count and
placement constant?

If accuracy is flat from ~1.25 m down to ~0.5 m, plot size doesn't matter on the
pixel axis and we choose hoop size purely on throughput, placeability in
patch-forming subclasses, and ease of percent-cover estimation — i.e. go small.
If accuracy falls below some radius `r*`, that's the minimum plot radius and we
don't go smaller.

This tests **sampling area (footprint) at fixed 8 cm resolution**. The separate
resolution axis (finer pixels via flying lower or pan-sharpening) is *not* tested
here — deferred to keep the two from confounding each other.

---

## 2. Core design principle

Vary **only the training labels**. Carve training-fold polygons down to radius-`r`
disks around fixed plot centers; leave the held-out **validation and test labels
at full extent**. The evaluation target is then identical across every radius, so
any difference in accuracy is attributable to training-pixel density per plot and
nothing else.

```
                 TRAIN folds            VAL fold        TEST fold
label extent:    carved to radius r     full            full
used for:        loss                   epoch selection  final metrics only
```

---

## 3. What varies vs. what is held fixed

| Held FIXED across all cells | VARIES |
|---|---|
| Plot centers + count (phase 1) | Training disk radius `r` |
| Fold assignment (spatial split) | Random seed (network init + data order) |
| Backbone (ResNet34), patch size, augmentation | |
| LR schedule, optimizer, max-epochs, early-stop rule | |
| Evaluation target (full-extent val/test labels) | |

Notes:
- **Recompute class weights per `r`** from the carved labels (that's what you'd do
  in practice at that radius) and **log the weights** so a large effect can be
  checked against a weight shift in a follow-up.
- Keep augmentation identical across cells so it isn't a hidden multiplier.

---

## 4. Sweep grid & compute

- **Radii (m):** 0.40, 0.50, 0.65, 0.80, 1.00, 1.25
  (≈ 5.0, 6.25, 8.1, 10.0, 12.5, 15.6 px at 8 cm → ≈ 79, 123, 207, 314, 491, 767
  px/plot). Low anchor probes the breakpoint below 0.5 m; high anchor shows
  whether the curve is still climbing past 1 m.
- **Seeds:** 3 to start (results are noisy; report mean ± sd).
- **Model:** `primary` (4-class water/low/transitional/high) first. Optionally the
  water model as a second check. **Skip 3-4-5** — too close to chance to read.
- **Spatial split (phase 1):** one fixed three-way holdout (one test fold, one val
  fold, rest train). This gives the tightest paired comparison across `r` on the
  *same* test region. Multi-fold is a phase-2 refinement.
- **Grid size:** 6 radii × 3 seeds = 18 training runs on the primary model. A
  single slurmcollie array; an afternoon on Gypsum.

---

## 5. Evaluation protocol

- Three-way **spatial** split: train / val / test, folds separated as usual
  (>~20 m). Carving applies to **train only**.
- **Select epoch / early-stop on the val fold**, never the test fold
  (test-set epoch selection == using it as a validation set).
- **Report on the test fold at full extent:** overall CCR, Kappa, and per-class
  recall / IoU. Per-class is the important read — a rare or spectrally
  heterogeneous class may need more pixels/plot than a uniform common one, and the
  overall number will hide that.

---

## 6. Label semantics (the easy thing to get wrong)

When carving a training polygon to disks:

- disk pixels → the modeling class code
- **poly-interior pixels outside every disk → `ignore_index`** (excluded from
  loss). NOT background/99.
- genuine background (99) and other kept context → **left at full extent**, layered
  back under the carved target labels.

Rationale: in the real point-plot design, unsampled marsh is *unknown*, not
*background*. Class 99 is positively identified (upland / non-marsh) from PI.
Sending unsampled target-class marsh to 99 would train the model that
marsh-that-looks-like-class-X is background. `carve_plot_labels()` in `degrade.R`
implements this: target extent → ignore, disks stamped over it, context covered
back underneath.

---

## 7. Outputs & analysis

Each cell returns one tidy row → experiment/fits DB:
`radius_m, radius_px, px_per_plot, n_plots, seed, model, test_fold, ccr, kappa,
recall_<class>...`

`summarize_degrade()` aggregates over seeds and prints a compact table + a base-R
line plot of CCR (and per-class recall) vs radius.

**Decision rule:**
- Curves flat 1.25 → 0.5 m → plot size is not the constraint; pick hoop on
  throughput + placeability + cover-estimation → smallest workable (0.5–0.8 m).
- Meaningful drop below some `r*` → set minimum radius at `r*`.
- Watch for **class-specific** breakpoints, not just the overall curve.

---

## 8. Integration points for Claude Code (TODOs)

I don't have exact signatures for these — wire against the repo:

1. `slurmcollie::slurm()` call convention (partition = gypsum, gpu, mem, walltime;
   `reps`/`moreargs`) — match `do_map` / `do_layer` usage.
2. `the$parsdir` path resolution for the experiment YAML.
3. `train_unet(...)` hook — the existing prep+train entry point (reticulate/Python).
   Must accept a training-label raster override, val_fold, test_fold, seed, and
   return `list(ccr=, kappa=, recall_by_class=)`.
4. Fits/experiment-DB row insertion at the end of `do_degrade()` (as in `do_layer`).
5. Confirm CRS is projected in metres (buffer widths + spacing are in map units).
6. Verify `terra::intersect()` point-in-polygon behaviour on the actual label
   vector, and that `field = 'class'` matches the class-code column name.

Inputs the YAML should provide: `labels_vect` (polygon labels w/ class + fold),
`label_template` (8 cm grid), `target_labels` + `context_labels` rasters,
`all_folds`, `spacing_m`, `pixel_m`, `ignore_index`, `scratch`.

---

## 9. Phase-2 extensions (not now)

- **Resolution axis:** repeat at upsampled 4 cm with native bands + a pan channel
  (the deferred pan-sharpen comparison) to separate "area" from "crispness".
- **Joint surface:** cross radius × plots-per-class to map the full
  plots-vs-pixels tradeoff, not just the radius slice.
- **Center-placement seed:** vary synthetic-plot placement as a second seed to
  bound placement sensitivity.
- **Multi-fold** spatial CV once the effect size is known.
- **Density vs. footprint:** a random-thinning variant (drop pixels within a fixed
  extent) answers "do labels need to be dense?" — different question from plot size.
