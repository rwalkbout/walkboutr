test_that("test smallest bout", {
  collated_arguments <- collate_arguments()
  accelerometry_counts <- make_smallest_bout()
  labels <- accelerometry_counts %>%
    dplyr::select(c("bout", "non_wearing","complete_day"))
  acc <- accelerometry_counts %>%
    dplyr::select(-c("bout", "non_wearing","complete_day"))
  acc <- process_accelerometry_counts_into_bouts(acc, collated_arguments$epoch_length)
  tinytest::expect_identical(
  acc$bout, labels$bout
  )
})

test_that("test smallest bout with smallest inactive time", {
  collated_arguments <- collate_arguments()
  accelerometry_counts <- make_smallest_bout_with_largest_inactive_period()
  labels <- accelerometry_counts %>%
    dplyr::select(c("bout", "non_wearing","complete_day"))
  acc <- accelerometry_counts %>%
    dplyr::select(-c("bout", "non_wearing","complete_day"))
  acc <- process_accelerometry_counts_into_bouts(acc, collated_arguments$epoch_length)
  tinytest::expect_identical(
    acc$bout, labels$bout
  )
})

test_that("test smallest bout with smallest non wearing period", {
  collated_arguments <- collate_arguments()
  accelerometry_counts <- make_smallest_bout_with_smallest_non_wearing_period()
  labels <- accelerometry_counts %>%
    dplyr::select(c("bout", "non_wearing","complete_day"))
  acc <- accelerometry_counts %>%
    dplyr::select(-c("bout", "non_wearing","complete_day"))
  acc <- process_accelerometry_counts_into_bouts(acc, collated_arguments$epoch_length)
  tinytest::expect_identical(
    acc$bout, labels$bout
  )
})

test_that("test non_wearing period identification", {
  collated_arguments <- collate_arguments()
  accelerometry_counts <- make_smallest_bout_with_smallest_non_wearing_period()
  acc <- accelerometry_counts %>%
    dplyr::select(-c("non_wearing"))
  acc <- identify_non_wearing_periods(acc, collated_arguments$non_wearing_min_threshold_epochs)
  tinytest::expect_identical(acc$non_wearing, accelerometry_counts$non_wearing)
})

test_that("test non_wearing period identification", {
  collated_arguments <- collate_arguments()
  accelerometry_counts <- make_full_day_bout()
  acc <- identify_complete_days(accelerometry_counts %>% dplyr::select(-c("complete_day")),
                                collated_arguments$min_wearing_hours_per_day, collated_arguments$epoch_length, collated_arguments$local_time_zone)
  expect_identical(acc$complete_day, expected = accelerometry_counts$complete_day)
})
