# Overall data
test_that("happy path", {
  gps <- get_gps_data()
  expect_no_error(
    validate_gps_data(gps)
  )
})
test_that("missing latitude col", {
  gps <- get_gps_data()
  gps <- gps %>% dplyr::select(-c("latitude"))
  expect_error(
    validate_gps_data(gps)
  )
})
test_that("missing longitude col", {
  gps <- get_gps_data()
  gps <- gps %>% dplyr::select(-c("longitude"))
  expect_error(
    validate_gps_data(gps)
  )
})
test_that("missing speed col", {
  gps <- get_gps_data()
  gps <- gps %>% dplyr::select(-c("speed"))
  expect_error(
    validate_gps_data(gps)
  )
})
test_that("missing time col", {
  gps <- get_gps_data()
  gps <- gps %>% dplyr::select(-c("time"))
  expect_error(
    validate_gps_data(gps)
  )
})
test_that("extra cols", {
  gps <- get_gps_data()
  gps <- gps %>% dplyr::mutate(extra_col = c(1:nrow(gps)))
  expect_error(
    validate_gps_data(gps)
  )
})

# time col
test_that("time wrong format", {
  gps <- get_gps_data()
  gps <- gps %>% dplyr::mutate(time = as.numeric(time))
  expect_error(
    validate_gps_data(gps)
  )
})
test_that("time has NAs", {
  gps <- get_gps_data()
  gps$time[1] <- NA
  expect_error(
    validate_gps_data(gps)
  )
})
test_that("time wrong timezone", {
  gps <- get_gps_data()
  gps <- gps %>% dplyr::mutate(time = lubridate::with_tz(time, tzone = "PDT"))
  expect_error(
    validate_gps_data(gps)
  )
})

# latitude col
test_that("latitude counts wrong format", {
  gps <- get_gps_data()
  gps <- gps %>% dplyr::mutate(latitude = as.character(latitude))
  expect_error(
    validate_gps_data(gps)
  )
})
test_that("latitude has NAs", {
  gps <- get_gps_data()
  gps$latitude[1] <- NA
  expect_error(
    validate_gps_data(gps)
  )
})
test_that("latitude has values out of range", {
  gps <- get_gps_data()
  gps$latitude[1] <- -200
  expect_error(
    validate_gps_data(gps)
  )
})

# longitude col
test_that("longitude counts wrong format", {
  gps <- get_gps_data()
  gps <- gps %>% dplyr::mutate(longitude = as.character(longitude))
  expect_error(
    validate_gps_data(gps)
  )
})
test_that("longitude has NAs", {
  gps <- get_gps_data()
  gps$longitude[1] <- NA
  expect_error(
    validate_gps_data(gps)
  )
})
test_that("longitude has values out of range", {
  gps <- get_gps_data()
  gps$longitude[1] <- -200
  expect_error(
    validate_gps_data(gps)
  )
})

# speed col
test_that("speed counts wrong format", {
  gps <- get_gps_data()
  gps <- gps %>% dplyr::mutate(speed = as.character(speed))
  expect_error(
    validate_gps_data(gps)
  )
})

test_that("speed has NAs", {
  gps <- get_gps_data()
  gps$speed[1] <- NA
  expect_error(
    validate_gps_data(gps)
  )
})

# epoch start time assignment
test_that("assigned epoch time is the closest epoch time", {
  gps_data <- get_gps_data_30()
  # gps data with 5 second increments and we are using 30 second epochs
    gps_new <- assign_epoch_start_time(gps_data, epoch_length)
  # the difference in the date time before and after this function should be precisely 1/2 the epoch length
    expect_true(
      all(
        abs(as.numeric(gps_data$time)-as.numeric(gps_new$time)) <= 15
        )
      )
})

# test smaller gps windows
test_that("gps data are processed to have unique epoch times", {
  gps_data <- get_gps_data()
  tinytest::expect_identical(
    length(gps_data$time), length(unique(gps_data$time))
                   )

})




