# test outlier function
test_that("gps outliers are being applied correctly", {
  collated_arguments <- collate_arguments()
  data <- data.frame(
    latitude = rep(37.7749, 100),
    longitude = c(seq(-122.4193, -122.4190, by = 0.0001),
                  seq(-122.4190, -122.4187, by = 0.0001),
                  seq(-122.4187, -122.4184, by = 0.0001),
                  seq(-122.4184, -122.4181, by = 0.0001),
                  seq(-122.4181, -122.4178, by = 0.0001))
  )

  # Define the expected results
  expected <- data[-96:-100,]
  actual <- outlier_gps_points(data, collated_arguments$dwellbout_radii_quantile)

  # Assert that the resulting dataframe has the expected number of rows
  tinytest::expect_equal(nrow(actual), nrow(expected))

})

# test generate_bout_radius
test_that("bout radii df has bout labels and radii", {
  collated_arguments <- collate_arguments()
  walk_bouts <- make_full_walk_bout_df()
  bout_radii <- generate_bout_radius(walk_bouts, collated_arguments$dwellbout_radii_quantile)
  expect_identical(names(bout_radii), c("bout", "bout_radius"))
})

# TODO: Test that generate_bout_radius function

# test evaluate_gps_completeness
test_that("evaluate_gps_completeness returns expected output", {
  collated_arguments <- collate_arguments()
  # Define input data
  walk_bouts <- data.frame(
    bout = c(1, 1, 1, 1, 1, 2, 2, 2, 2, 2),
    speed = c(NA, 2, NA, 3, NA, 1, 2, 3, 3, 4),
    latitude = c(NA, 41, NA, 40, 39, 40, 40, 43, 41, 42),
    longitude = c(NA, -73, NA, -71, NA, -71, -73, -74, -74, -75)
  )
  # Define expected output
  expected_output <- data.frame(
    bout = c(1, 2),
    complete_gps = c(FALSE, TRUE),
    median_speed = c(2,3)
  )
  # Call the function to get actual output
  actual_output <- evaluate_gps_completeness(walk_bouts,
                                             collated_arguments$min_gps_obs_within_bout, collated_arguments$min_gps_coverage_ratio)
  # Test that the actual output matches the expected output
  tinytest::expect_identical(actual_output, expected_output)
})

# test generate_bout_category
walk_bouts <- data.frame(bout = 1:10,
                         activity_counts = rnorm(10),
                         speed = rnorm(10))
bout_radii <- data.frame(bout = 1:10,
                         max_dwellbout_radii_ft = rnorm(10))
gps_completeness <- data.frame(bout = 1:10,
                               complete_gps = sample(c(TRUE, FALSE), 10, replace = TRUE),
                               median_speed = rnorm(10))
test_that("generate_bout_category correctly categorizes bouts", {
  collated_arguments <- collate_arguments()
  walk_bouts <- make_full_walk_bout_df()
  bout_radii <- generate_bout_radius(walk_bouts, collated_arguments$dwellbout_radii_quantile)
  gps_completeness <- evaluate_gps_completeness(walk_bouts,
                                                collated_arguments$min_gps_obs_within_bout, collated_arguments$min_gps_coverage_ratio)
  categorized_bouts <- generate_bout_category(walk_bouts, bout_radii, gps_completeness,
                                              collated_arguments$max_dwellbout_radii_ft,
                                              collated_arguments$max_walking_cpe,
                                              collated_arguments$min_walking_speed_km_h,
                                              collated_arguments$max_walking_speed_km_h)
  tinytest::expect_true("bout" %in% colnames(categorized_bouts))
  tinytest::expect_true("bout_category" %in% colnames(categorized_bouts))
  num_bout_categories <- categorized_bouts %>%
    dplyr::group_by(bout) %>%
    dplyr::summarize(num_categories = length(unique(bout_category)))
  expect_equal(num_bout_categories$num_categories, 1)
})

test_that("generate_bout_category results in a df with no NA bout labels", {
  collated_arguments <- collate_arguments()
  walk_bouts <- make_full_walk_bout_df()
  bout_radii <- generate_bout_radius(walk_bouts, collated_arguments$dwellbout_radii_quantile)
  gps_completeness <- evaluate_gps_completeness(walk_bouts,
                                                collated_arguments$min_gps_obs_within_bout, collated_arguments$min_gps_coverage_ratio)
  categorized_bouts <- generate_bout_category(walk_bouts, bout_radii, gps_completeness,
                                              collated_arguments$max_dwellbout_radii_ft,
                                              collated_arguments$max_walking_cpe,
                                              collated_arguments$min_walking_speed_km_h,
                                              collated_arguments$max_walking_speed_km_h)
  test <- categorized_bouts %>%
    dplyr::filter(is.na("bout"))
  na_bout_labels <- nrow(test)
  tinytest::expect_identical(0, na_bout_labels)
})














