test_that("happy path", {
  acc <- build_accelerometry_data()
  expect_no_error(
    validate_accelerometry_data(acc)
  )
})

test_that("missing time col", {
  acc <- build_accelerometry_data()
  acc <- acc %>% dplyr::select(-c("time"))
  expect_error(
    validate_accelerometry_data(acc)
  )
})

test_that("extra cols", {
  acc <- build_accelerometry_data()
  acc <- acc %>% dplyr::mutate(extra_col = c(1:nrow(acc)))
  expect_error(
    validate_accelerometry_data(acc)
  )
})

test_that("time wrong format", {
  acc <- build_accelerometry_data()
  acc <- acc %>% dplyr::mutate(time = as.numeric(time))
  expect_error(
    validate_accelerometry_data(acc)
  )
})

test_that("time has NAs", {
  acc <- build_accelerometry_data()
  acc$time[1] <- NA
  expect_error(
    validate_accelerometry_data(acc)
  )
})

test_that("time wrong timezone", {
  acc <- build_accelerometry_data()
  acc <- acc %>% dplyr::mutate(time = lubridate::with_tz(time, tzone = "PDT"))
  expect_error(
    validate_accelerometry_data(acc)
  )
})

test_that("activity counts wrong format", {
  acc <- build_accelerometry_data()
  acc <- acc %>% dplyr::mutate(activity_counts = as.character(activity_counts))
  expect_error(
    validate_accelerometry_data(acc)
  )
})

test_that("activity counts has NAs", {
  acc <- build_accelerometry_data()
  acc$activity_counts[1] <- NA
  expect_error(
    validate_accelerometry_data(acc)
  )
})

test_that("activity counts has negative values", {
  acc <- build_accelerometry_data()
  acc$activity_counts[1] <- -5
  expect_error(
    validate_accelerometry_data(acc)
  )
})
