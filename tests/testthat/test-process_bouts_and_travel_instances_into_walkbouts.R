test_that("gps outliers are being applied correctly", {
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
  actual <- outlier_gps_points(data)

  # Assert that the resulting dataframe has the expected number of rows
  tinytest::expect_equal(nrow(actual), nrow(expected))
  # Assert that the resulting dataframe has the expected latitude values
  # tinytest::expect_identical(actual$latitude, expected$latitude)
  # Assert that the resulting dataframe has the expected longitude values
  # tinytest::expect_identical(actual$longitude, expected$longitude)

})

test_that("bout radii df has bout labels and radii", {
  walk_bouts <- get_walk_bouts()
  bout_radii <- generate_bout_radius(walk_bouts)
  expect_identical(names(bout_radii), c("bout", "bout_radius"))
})


