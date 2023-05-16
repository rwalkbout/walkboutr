
<!-- README.md is generated from README.Rmd. Please edit that file -->

# walkboutr

<!-- badges: start -->
<!-- badges: end -->

The goal of walkboutr is to process GPS and accelerometry data into
walking bouts. walkboutr will either return the original dataset along
with bout labels and categories, or a summarized, de-identified dataset
that can be shared for collaboration.

## Installation

You can install the development version of walkboutr from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("rwalkbout/walkboutr")
```

## Example

This is an example of simulated data that could be processed by
walkboutr. The GPS data contain the required columns: time, latitude,
longitude, speed. The accelerometry data contain the required columns:
time, accerometry counts. These data have no extra columns, do not
contain NAs, and don’t have negative speeds or accelerometry counts. All
times are also in date-time format.

``` r
library(walkboutr)
gps_data <- generate_walking_in_seattle_gps_data() # this will generate sample GPS data
accelerometry_counts <- make_full_day_bout_without_metadata() # this will generate sample accelerometry data 

(head(gps_data))
#>                  time latitude longitude     speed
#> 1 2012-04-07 00:00:30 47.60620  122.3321 0.8223424
#> 2 2012-04-07 00:01:00 47.60998  122.3359 0.9223307
#> 3 2012-04-07 00:01:30 47.61341  122.3393 0.5313921
#> 4 2012-04-07 00:02:00 47.61603  122.3419 0.7581466
#> 5 2012-04-07 00:02:30 47.61887  122.3448 0.8348447
#> 6 2012-04-07 00:03:00 47.62212  122.3480 0.6335497
(head(accelerometry_counts))
#>   activity_counts                time
#> 1               0 2012-04-07 00:00:30
#> 2               0 2012-04-07 00:01:00
#> 3               0 2012-04-07 00:01:30
#> 4               0 2012-04-07 00:02:00
#> 5             500 2012-04-07 00:02:30
#> 6             500 2012-04-07 00:03:00
```

Now that we have sample data, we can look at how the walkboutr package
works. There are two top level functions that will allow us to generate
either (1) a dataset with bouts and bout categories with all of our
original data included, or (2) a summary dataset that is completely
de-identified and shareable for research purposes.

#### Walk bout dataset including original data

``` r
# walk_bouts <- identify_walk_bouts_in_gps_and_accelerometry_data(gps_data,accelerometry_counts)
# (head(walk_bouts))
```

#### Summarized walk bout dataset

This dataset is a set of labelled bouts that are categorized
(`bout_category`) and contains information on bout specific median speed
(`median_speed`), the start time of the bout (`bout_start`), the
duration of the bout (in minutes for computational ease, `duration`),
and a flag for whether the bout came from a dataset with a complete day
worth of data (`complete_day`).

``` r
# summary <- summarize_walk_bouts(walk_bouts)
# (head(summary))
```

You’ll still need to render `README.Rmd` regularly, to keep `README.md`
up-to-date. `devtools::build_readme()` is handy for this. You could also
use GitHub Actions to re-render `README.Rmd` every time you push. An
example workflow can be found here:
<https://github.com/r-lib/actions/tree/v1/examples>.

You can also embed plots, for example:

<img src="man/figures/README-pressure-1.png" width="100%" />

In that case, don’t forget to commit and push the resulting figure
files, so they display on GitHub and CRAN.
