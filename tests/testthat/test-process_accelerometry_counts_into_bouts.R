test_that("test smallest bout", {
  accelerometry_counts <- get_smallest_bout()
  labels <- accelerometry_counts %>%
    dplyr::select(c("bout", "non_wearing","complete_day"))
  acc <- accelerometry_counts %>%
    dplyr::select(-c("bout", "non_wearing","complete_day"))
  acc <- process_accelerometry_counts_into_bouts(acc)
  tinytest::expect_identical(
  acc$bout, labels$bout
  )
})

test_that("test smallest bout with smallest inactive time", {
  accelerometry_counts <- get_smallest_bout_with_largest_inactive_period()
  labels <- accelerometry_counts %>%
    dplyr::select(c("bout", "non_wearing","complete_day"))
  acc <- accelerometry_counts %>%
    dplyr::select(-c("bout", "non_wearing","complete_day"))
  acc <- process_accelerometry_counts_into_bouts(acc)
  tinytest::expect_identical(
    acc$bout, labels$bout
  )
})

test_that("test smallest bout with smallest non wearing period", {
  accelerometry_counts <- get_smallest_bout_with_smallest_non_wearing_period()
  labels <- accelerometry_counts %>%
    dplyr::select(c("bout", "non_wearing","complete_day"))
  acc <- accelerometry_counts %>%
    dplyr::select(-c("bout", "non_wearing","complete_day"))
  acc <- process_accelerometry_counts_into_bouts(acc)
  tinytest::expect_identical(
    acc$bout, labels$bout
  )
})

test_that("test non_wearing period identification", {
  accelerometry_counts <- get_smallest_bout_with_smallest_non_wearing_period()
  acc <- accelerometry_counts %>%
    dplyr::select(-c("non_wearing"))
  acc <- identify_non_wearing_periods(acc)
  tinytest::expect_identical(acc$non_wearing, accelerometry_counts$non_wearing)
})

test_that("test non_wearing period identification", {
  accelerometry_counts <- get_full_day_bout()
  acc <- identify_complete_days(accelerometry_counts %>% dplyr::select(-c("complete_day")))
  expect_identical(acc$complete_day, expected = accelerometry_counts$complete_day)
})
