
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

## Basic Usage

#### Simulated sample data

This is an example of simulated data that could be processed by
walkboutr. The GPS data contain the required columns: time, latitude,
longitude, speed. The accelerometry data contain the required columns:
time, accerometry counts. These data have no extra columns, do not
contain NAs, and don’t have negative speeds or accelerometry counts. All
times are also in date-time format.

``` r
library(walkboutr)
# generate sample gps data:
gps_data <- generate_walking_in_seattle_gps_data() 
# generate sample accelerometry data:
accelerometry_counts <- make_full_day_bout_without_metadata() 
```

GPS data:
<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;">
time
</th>
<th style="text-align:right;">
latitude
</th>
<th style="text-align:right;">
longitude
</th>
<th style="text-align:right;">
speed
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
2012-04-07 00:00:30
</td>
<td style="text-align:right;">
47.60620
</td>
<td style="text-align:right;">
122.3321
</td>
<td style="text-align:right;">
0.9675562
</td>
</tr>
<tr>
<td style="text-align:left;">
2012-04-07 00:01:00
</td>
<td style="text-align:right;">
47.61064
</td>
<td style="text-align:right;">
122.3365
</td>
<td style="text-align:right;">
0.9223307
</td>
</tr>
<tr>
<td style="text-align:left;">
2012-04-07 00:01:30
</td>
<td style="text-align:right;">
47.61407
</td>
<td style="text-align:right;">
122.3400
</td>
<td style="text-align:right;">
0.5313921
</td>
</tr>
<tr>
<td style="text-align:left;">
2012-04-07 00:02:00
</td>
<td style="text-align:right;">
47.61670
</td>
<td style="text-align:right;">
122.3426
</td>
<td style="text-align:right;">
0.7581466
</td>
</tr>
<tr>
<td style="text-align:left;">
2012-04-07 00:02:30
</td>
<td style="text-align:right;">
47.61954
</td>
<td style="text-align:right;">
122.3454
</td>
<td style="text-align:right;">
0.8348447
</td>
</tr>
<tr>
<td style="text-align:left;">
2012-04-07 00:03:00
</td>
<td style="text-align:right;">
47.62278
</td>
<td style="text-align:right;">
122.3487
</td>
<td style="text-align:right;">
0.6335497
</td>
</tr>
</tbody>
</table>
Accelerometry data:
<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:right;">
activity_counts
</th>
<th style="text-align:left;">
time
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
0
</td>
<td style="text-align:left;">
2012-04-07 00:00:30
</td>
</tr>
<tr>
<td style="text-align:right;">
0
</td>
<td style="text-align:left;">
2012-04-07 00:01:00
</td>
</tr>
<tr>
<td style="text-align:right;">
0
</td>
<td style="text-align:left;">
2012-04-07 00:01:30
</td>
</tr>
<tr>
<td style="text-align:right;">
0
</td>
<td style="text-align:left;">
2012-04-07 00:02:00
</td>
</tr>
<tr>
<td style="text-align:right;">
500
</td>
<td style="text-align:left;">
2012-04-07 00:02:30
</td>
</tr>
<tr>
<td style="text-align:right;">
500
</td>
<td style="text-align:left;">
2012-04-07 00:03:00
</td>
</tr>
</tbody>
</table>
<p>
<p>

Now that we have sample data, we can look at how the walkboutr package
works. There are two top level functions that will allow us to generate
either (1) a dataset with bouts and bout categories with all of our
original data included, or (2) a summary dataset that is completely
de-identified and shareable for research purposes.

#### Walk bout dataset including original data

``` r
walk_bouts <- identify_walk_bouts_in_gps_and_accelerometry_data(gps_data,accelerometry_counts)
```

<table class="table table table" style="margin-left: auto; margin-right: auto; font-size: 12px; margin-left: auto; margin-right: auto; margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:right;">
bout
</th>
<th style="text-align:left;">
bout_category
</th>
<th style="text-align:left;">
time
</th>
<th style="text-align:right;">
latitude
</th>
<th style="text-align:right;">
longitude
</th>
<th style="text-align:right;">
speed
</th>
<th style="text-align:right;">
activity_counts
</th>
<th style="text-align:left;">
inactive
</th>
<th style="text-align:left;">
non_wearing
</th>
<th style="text-align:right;">
n_epochs_date
</th>
<th style="text-align:left;">
complete_day
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
non_walk_slow
</td>
<td style="text-align:left;">
2012-04-07 00:03:30
</td>
<td style="text-align:right;">
47.62588
</td>
<td style="text-align:right;">
122.3518
</td>
<td style="text-align:right;">
0.9995464
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:left;">
FALSE
</td>
<td style="text-align:left;">
FALSE
</td>
<td style="text-align:right;">
8616
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
non_walk_slow
</td>
<td style="text-align:left;">
2012-04-07 00:02:30
</td>
<td style="text-align:right;">
47.61954
</td>
<td style="text-align:right;">
122.3454
</td>
<td style="text-align:right;">
0.8348447
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:left;">
FALSE
</td>
<td style="text-align:left;">
FALSE
</td>
<td style="text-align:right;">
8616
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
non_walk_slow
</td>
<td style="text-align:left;">
2012-04-07 00:03:00
</td>
<td style="text-align:right;">
47.62278
</td>
<td style="text-align:right;">
122.3487
</td>
<td style="text-align:right;">
0.6335497
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:left;">
FALSE
</td>
<td style="text-align:left;">
FALSE
</td>
<td style="text-align:right;">
8616
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
non_walk_slow
</td>
<td style="text-align:left;">
2012-04-07 00:05:30
</td>
<td style="text-align:right;">
47.64387
</td>
<td style="text-align:right;">
122.3698
</td>
<td style="text-align:right;">
0.9944386
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:left;">
FALSE
</td>
<td style="text-align:left;">
FALSE
</td>
<td style="text-align:right;">
8616
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
non_walk_slow
</td>
<td style="text-align:left;">
2012-04-07 00:06:00
</td>
<td style="text-align:right;">
47.64848
</td>
<td style="text-align:right;">
122.3744
</td>
<td style="text-align:right;">
1.2970529
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:left;">
FALSE
</td>
<td style="text-align:left;">
FALSE
</td>
<td style="text-align:right;">
8616
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
non_walk_slow
</td>
<td style="text-align:left;">
2012-04-07 00:06:30
</td>
<td style="text-align:right;">
47.65482
</td>
<td style="text-align:right;">
122.3807
</td>
<td style="text-align:right;">
1.0669589
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:left;">
FALSE
</td>
<td style="text-align:left;">
FALSE
</td>
<td style="text-align:right;">
8616
</td>
<td style="text-align:left;">
TRUE
</td>
</tr>
</tbody>
</table>

#### Summarized walk bout dataset

This dataset is a set of labelled bouts that are categorized
(`bout_category`) and contains information on bout specific median speed
(`median_speed`), the start time of the bout (`bout_start`), the
duration of the bout (in minutes for computational ease, `duration`),
and a flag for whether the bout came from a dataset with a complete day
worth of data (`complete_day`).

``` r
summary <- summarize_walk_bouts(walk_bouts)
```

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:right;">
bout
</th>
<th style="text-align:right;">
median_speed
</th>
<th style="text-align:left;">
complete_day
</th>
<th style="text-align:left;">
bout_start
</th>
<th style="text-align:right;">
duration
</th>
<th style="text-align:left;">
bout_category
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0.9895184
</td>
<td style="text-align:left;">
TRUE
</td>
<td style="text-align:left;">
2012-04-07 00:02:30
</td>
<td style="text-align:right;">
4304.5
</td>
<td style="text-align:left;">
non_walk_slow
</td>
</tr>
</tbody>
</table>

In this example, we have 1 bout(s), and each bout has a label. Bout 1
occurred on 2012.04.07 and has a complete day worth of data
(`complete_day` = TRUE) and a start time of 00:02:30. This bout lasted
4304.5 minutes, or 71.7416667 hours. The bout is a non walk bout because
the participant was moving too slowly for this walk to be considered
walking.

For more information on bout categories and how these are assigned,
please see the vignette titled XXX.
