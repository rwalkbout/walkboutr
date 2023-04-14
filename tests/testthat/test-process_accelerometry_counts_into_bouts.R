test_that("test smallest bout", {
  accelerometry_counts <- get_smallest_bout()
  labels <- accelerometry_counts %>%
    dplyr::select(c("bout", "non_wearing","complete_day"))
  accelerometry_counts <- accelerometry_counts %>%
    dplyr::select(-c("bout", "non_wearing","complete_day"))
  acc <- process_accelerometry_counts_into_bouts(accelerometry_counts)
  expect_identical(
  acc$bout, expected = labels$bout
  )
})

test_that("test smallest bout with smallest inactive time", {
  accelerometry_counts <- get_smallest_bout_with_largest_inactive_period()
  labels <- accelerometry_counts %>%
    dplyr::select(c("bout", "non_wearing","complete_day"))
  accelerometry_counts <- accelerometry_counts %>%
    dplyr::select(-c("bout", "non_wearing","complete_day"))
  acc <- process_accelerometry_counts_into_bouts(accelerometry_counts)
  expect_identical(
    acc$bout, expected = labels$bout
  )
})

test_that("test smallest bout with smallest non wearing period", {
  accelerometry_counts <- get_smallest_bout_with_smallest_non_wearing_period()
  labels <- accelerometry_counts %>%
    dplyr::select(c("bout", "non_wearing","complete_day"))
  accelerometry_counts <- accelerometry_counts %>%
    dplyr::select(-c("bout", "non_wearing","complete_day"))
  acc <- process_accelerometry_counts_into_bouts(accelerometry_counts)
  expect_identical(
    acc$bout, expected = labels$bout
  )
})
