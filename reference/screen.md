# Visually screen orthoimages via a web app

Used to screen images for quality, this web app allows users to view and
score each image, marking images to send back for repair, and entering
comments. The flights database is built the first time each site is
visited in the app. Results are saved in the flights database for each
site, and are used by `flights_report`. Image scores are used to help
select the image to use when there are duplicated portable names.
Minimum scores may be included in search names. Rejected images are
never used in fitting.

## Usage

``` r
screen()
```

## Details

`screen` builds the flights database for each site when you select it
from the `site` dropdown. An alternative to running `screen` is to call
`build_fights_db` for each site whenever new images are added. Scores
may be added to a sites database (`flights/flights_<site>.txt`) by hand
if necessary.

When an image file is updated (presumably from downloading a repaired
image), the old image is replaced in the database with the new one, thus
the score, repair flag, and comments will be reset. This sets you up for
assessing repaired images.

`screen` displays the selected image with a red outline indicating the
site footprint. It includes the following controls:

- **Site** select the site. All sites listed in pars/sites.txt are
  included. The full site name will be displayed, along with the number
  of scored images, the total number of images, and the percent that
  have been scored.

- **Revisit images**. Normally, images that have been scored or flagged
  for repair are hidden. Turn this switch on to revisit all images.
  (After scoring or flagging an image, it won't be hidden until changing
  sites or toggling this switch.)

- **Image filter** enter a regular expression to filter images on either
  the file name or portable name (see `README` for a description of
  names). When the filter is in effect, only the selected images will be
  displayed. Usually, typing a distinct portion of the name will
  suffice, but you can go crazy with regular expressions if you want.

- **Navigation buttons** Jump to the first, previous, next, or last
  image for this site. It takes a couple of seconds to render
  high-resolution images.

- **Image info** displays the image file name, the portable name, the
  number of bands, and key components of the image (type, sensor,
  season, year, and tide stage).

- **Image Score** allows you to score each image for quality. Categories
  are unscored, poor, fair, good, very good, and excellent. Scoring
  should take into account the amount of missing data, image quality,
  and artifacts such as cloud stripes and water reflections.

- **Flag for repair** marks images for repair (for instance, stripes are
  usually due to cloud cover on interleaved transects; image processing
  software can sometimes remove these). Images flagged for repair will
  be hidden unless **Revisit images** is selected.

- **Comments**

- **Show zooms** shows a 5x and 20x zoom of the center of the image for
  up-close quality inspection. It takes a moment.

- **Always show zooms** turn this on to always show zoomed insets.

- **Exit** saves the flights database for the current site and exits
  (flights databases are also saved when switching sites).
