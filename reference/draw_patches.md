# Draw training patches for visual QC

Reads numpy patch files and writes RGB TIFFs with class labels overlaid
in color. Used to verify that the entire pipeline from shapefile through
patch extraction through numpy export produces correct, aligned data.

## Usage

``` r
draw_patches(
  data_dir,
  site,
  dataset = "train",
  n = 5,
  patchno = NULL,
  rgb_channels = c(3, 2, 1),
  class_colors = NULL,
  output_dir = NULL,
  overlay_alpha = 0.5
)
```

## Arguments

- data_dir:

  Directory containing numpy files (e.g., .../set1)

- site:

  Site name (e.g., 'NOR')

- dataset:

  Which dataset to draw from: 'train', 'validate', or 'test'

- n:

  Number of patches to draw (default 5). Ignored if patchno is
  specified.

- patchno:

  Optional integer vector of specific patch indices to draw

- rgb_channels:

  Which channels to use for RGB display (default c(3, 2, 1) for Red,
  Green, Blue assuming MicaSense band order: Blue, Green, Red, RedEdge,
  NIR)

- class_colors:

  Named list mapping remapped class values to hex colors

- output_dir:

  Directory to write TIFFs (default: data_dir)

- overlay_alpha:

  Transparency for class overlay, 0-1 (default 0.5)

## Value

Invisible vector of output file paths
