# Plot size & count degradation experiments — retrospective and decision

**Project:** MassMarsh UAS / `marshmap` U-Net
**Site:** NOR (single site), 4 primary classes (101 water + 102/103/104 vegetation)
**Date:** 2026-07-16
**Companion code:** `R/degrade.R`, `R/do_degrade*.R` (size); `R/degrade_count.R`,
`R/do_degrade_count.R` (count). Design spec: `inst/dev/pixel_degradation_experiment.md`.

---

## TL;DR

Two experiments asked whether U-Net accuracy could tell us how **big** field plots
should be and how **many** we need. Neither could, by construction — both degrade a
single fixed site's existing labels, which is the wrong instrument for a question
about independent field sampling. The plot **size** was ultimately chosen on
field-practical grounds; the plot **count** target was held.

- **Plot size:** **0.71 m radius** (1.42 m diameter), chosen on practical grounds,
  not on model results (see [Decision](#decision)).
- **Plot count:** **1000–1500 plots across all classes (~100+/class), held.** The
  analysis gave no defensible reason to relax it, and every bias in it points toward
  *under*-stating the true requirement.

---

## 1. The question

For training a vegetation-map U-Net, how large should field plots be, and how many
independent plots do we need? The hope was that degrading an existing labeled dataset
would reveal a size floor and a count plateau.

Two axes, tested separately to avoid confounding:

1. **Size** — labeled *area per location*, holding count and placement fixed.
2. **Count** — number of independent labeled *locations*, holding size fixed.

---

## 2. Experiment 1 — plot size (radius)

**Design.** Hold plot count and centers fixed; carve each training transect down to
radius-`r` disks around synthetic plot centers on the transect centerlines. Leave
validation and test labels at **full extent**, so the evaluation target is identical
across radii and any accuracy difference is attributable to training-pixel density
alone. Radii 0.10–1.25 m + a full-transect anchor (`r = ∞`); 3 spatial folds
(test/val = (1,2),(3,4),(5,6)); 8 seeds; class weights pinned to the full-transect
frequency so the loss objective doesn't drift with radius.

**Result.** CCR is **flat (~0.80–0.83) across the entire range *and* at the
full-transect anchor** — even a 0.10 m radius disk (~a handful of labeled pixels per
plot) matches training on the uncarved transect. Class 101 (water) ~0.99 everywhere;
102/103/104 noisy with no radius trend.

**Why this can't set a size floor.** The flatness is largely a **design artifact**:

- Shrinking a disk shrinks the **labels**, not the **imagery** the network sees. A
  256 px (~20 m) patch enters training as long as it contains ≥1 labeled pixel, and
  the fixed plot centers blanket the marsh — so training *patches* barely change
  (≈1.3× from smallest to full) while labeled *pixels* change ~240×.
- Plots within a transect are **spatially correlated** (2.5 m spacing), so extra
  labeled pixels are largely redundant. The independent unit is the transect, not the
  pixel or the plot.
- The ImageNet-pretrained ResNet-34 encoder means a few labels suffice to calibrate
  the head on top of pretrained features.

So the size experiment mostly taught us *why this class of experiment misleads* — a
valuable negative result, but not a size floor.

---

## 3. Experiment 2 — plot count (transects)

**Design.** Fix radius at 0.5 m; vary the **number of training transects** drawn from
the pool: 4, 8, 16, 32, 64, and all (~121) + anchor. The draw is a **random,
unstratified subset pooled across all classes** (nested within a seed), so at low
counts whole classes can be absent from the training set. 3 folds; 8 seeds; pinned
weights.

> **Units — important.** The x-axis is the **total number of training transects
> across all classes**, not plots and not per-class. A transect is one digitized
> ground-truth polygon (single class). "Plots" here are synthetic points along those
> transects (the `n_plots` column), a within-transect byproduct — *not* the axis. The
> axis tops out at ~121 transects.

**Result.** Class 101 (water; ~half the pixels, spectrally distinct) **plateaus by
~50 transects**. Classes 102/103/104 are **still rising at the maximum (~121)** — no
plateau reached.

**Why this can't set a count target.** Same core problem plus scale mismatch:

- **Single site (NOR)** → zero between-marsh variance, which is exactly the variance a
  multi-site deployment faces. A model still improving on within-NOR diversity will
  need *more* to generalize across marshes, not less.
- **Transects ≠ independent plots.** Within-transect correlation means the transect
  axis already overstates the information each step adds; and there's no clean
  conversion from "N of our existing transects" to "N field plots to collect."
- **4-class categorical recall ≠ the real target.** The deployment goal is %cover in
  10% bins across 7 species + bare — finer and harder, needing *more* data per class.
  Categorical recall is a floor at best and measures the wrong task.

---

## 4. Shared limitations

Both experiments **degrade a fixed dataset from one site**. They measure the marginal
value of *more of the same kind of data within one marsh* — not the number of
*independent* plots for a multi-site %cover campaign. Every bias runs the same
direction: **toward under-stating the true requirement.** That's why a flat/rising
curve here is *not* license to collect less.

---

## <a name="decision"></a>5. Decision

**Plot size: 0.71 m radius (1.42 m diameter).** Chosen on **field-practical grounds**,
not on the model experiments (which couldn't discriminate size anyway):

- **Circumscribes the standard 1 m² square quadrat** (radius = 1/√2 ≈ 0.707 m spans
  the square's 1.41 m diagonal) — commensurable with the established protocol.
- **RTK point without disturbing the plot** — small enough that you needn't step
  *into* the footprint (later photographed by the drone) to take the survey point.
- **Portable** — the hoop is not too awkward to carry between plots.

For what little it's worth, the size experiment showed no categorical-accuracy penalty
even well below this radius, so nothing contraindicates it — but the justification is
practical and %cover-protocol-driven.

**Plot count: 1000–1500 plots across all classes (~100+/class), held.** The count
experiment showed the hard vegetation classes were still improving at the maximum
available transects, and its biases all point toward under-stating need. Nothing here
justifies relaxing the target.

---

## 6. What would actually answer the question (future work)

The count/size question needs a fundamentally different design than degrading one
site's labels:

- **Between-site holdout** — hold out *whole marshes*, not bypoly blocks within NOR,
  to expose the between-site variance the deployment faces.
- **%cover regression target** — score the actual task (continuous %cover per species)
  rather than 4-class categorical recall.

Neither is possible with current data (single site, categorical primary classes).
Until then, the field target stands on protocol and practicality, not on these models.
