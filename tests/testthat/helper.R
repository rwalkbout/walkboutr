get_accelerometry_data <- function(){
  start <- as.POSIXct('2012-04-07',tz="UTC")
  end <- as.POSIXct('2012-04-08',tz="UTC")
  step <- 30 # by default, the seq function will treat this as seconds
  time <- seq(start, end, by=step)
  # activity_counts <- (0:(length(time)-1))
  activity_counts <- runif(length(time), 0, 3000)
  accelerometry_counts <- data.frame(time = time, activity_counts = activity_counts)
  return(accelerometry_counts)
}

get_smallest_bout <- function(){
  path <- testthat::test_path("fixtures/smallest_bout.csv")
  readr::read_csv(path, show_col_types = FALSE)
}

get_smallest_bout_with_largest_inactive_period <- function(){
  path <- testthat::test_path("fixtures/smallest_bout_with_largest_inactive_period.csv")
  readr::read_csv(path, show_col_types = FALSE)
}

get_smallest_bout_with_smallest_non_wearing_period <- function(){
  path <- testthat::test_path("fixtures/smallest_bout_with_smallest_non_wearing_period.csv")
  readr::read_csv(path, show_col_types = FALSE)
}

get_full_day_bout <- function(){
  path <- testthat::test_path("fixtures/smallest_full_day_bout.csv")
  readr::read_csv(path, show_col_types = FALSE)
}

get_gps_data <- function(){
  path <- testthat::test_path("fixtures/gps_data.csv")
  readr::read_csv(path, show_col_types = FALSE)
}

