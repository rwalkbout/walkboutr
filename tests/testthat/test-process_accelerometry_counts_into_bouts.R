test_that("assign activity levels", {
  acc <- build_accelerometry_data()
  acc <- assign_activity_levels(acc, 10)
  expect_equal(acc$activity[1], ACTIVITY_LEVELS$inactive)
  expect_equal(acc$activity[2:11], rep(ACTIVITY_LEVELS$low_active, 10))
  expect_equal(acc$activity[12:nrow(acc)], rep(ACTIVITY_LEVELS$active, (nrow(acc)-11)))
})


