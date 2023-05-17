#' Generate a dataset with date-time, speed, and latitude and longitude of someone moving through space on a walk in Seattle
#'
#' @param start_lat The starting latitude of the walk.
#' @param start_lon The starting longitude of the walk.
#' @param start_time The start time of a series of data
#' @param time_interval The time interval between points in seconds.
#' @param n_epochs The number of epochs in the series
#'
#' @returns A data frame with four columns: "timestamp", "lat", "lon", and "speed".
#'
#' @export
generate_gps_data <- function(start_lat, start_long, start_time, n_epochs = 110, time_interval = 30.0, seed = 1234) {

  # set the initial location and speed
  current_lat <- start_lat
  current_long <- start_long
  current_speed <- runif(1, 0.5, 1.5)  # km/h

  # set random number generator seed for reproducibility
  set.seed(seed)

  # generate a series of locations and speeds
  directions <- runif(n_epochs, 0, 2 * pi)
  dts <- runif(n_epochs, 25, 35)

  # create a time vector
  times <- seq.POSIXt(as.POSIXct(start_time), length.out = n_epochs + 1, by = time_interval)

  # create a data frame with columns [time, latitude, longitude, speed]
  df <- data.frame(time = lubridate::ymd_hms(times,tz="UTC"),
               latitude = numeric(n_epochs + 1),
               longitude = numeric(n_epochs + 1),
               speed = numeric(n_epochs + 1))

  # generate latitudes, longitudes, and speeds using a loop
  df$latitude[1] <- start_lat
  df$longitude[1] <- start_long
  df$speed[1] <- current_speed

  for (i in seq_along(directions)) {
    df[i+1, c("latitude", "longitude")] <- next_lat_long(df[i, "latitude"], df[i, "longitude"], df[i, "speed"], directions[i], dts[i])
    df$speed[i+1] <- runif(1, 0.5, 1.5)
  }

  return(df)
}



#' Calculate next latitude and longitude based on current location, speed, direction, and time elapsed.
#'
#' Given a current location (latitude and longitude), speed, direction (in radians), and time elapsed (in seconds),
#' this function calculates the next latitude and longitude. The calculations are based on the assumption of a constant
#' speed and direction during the elapsed time.
#'
#' @param latitude The current latitude in decimal degrees.
#' @param longitude The current longitude in decimal degrees.
#' @param speed The speed in kilometers per hour.
#' @param direction The direction of movement in radians from due north (0 radians).
#' @param dt The elapsed time in seconds.
#'
#' @return A numeric vector of length 2 containing the next latitude and longitude in decimal degrees.
next_lat_long <- function(latitude, longitude, speed, direction, dt) {

  # convert the direction from radians to degrees
  direction_degrees <- direction * 180 / pi

  # convert the speed from km/h to m/s
  speed_mps <- speed / 3.6

  # calculate the distance traveled in meters
  distance_m <- speed_mps * dt

  # calculate the bearing in degrees from due north
  bearing_degrees <- (90 - direction_degrees) %% 360

  # convert the current latitude and longitude to radians
  lat1 <- latitude * pi / 180
  lon1 <- longitude * pi / 180

  # calculate the next latitude and longitude in radians
  lat2 <- lat1 + (distance_m / 6378137) * (180 / pi)
  lon2 <- lon1 + (distance_m / 6378137) * (180 / pi) / cos(lat1 * pi/180)

  # convert the next latitude and longitude to decimal degrees
  lat2_degrees <- lat2 * 180 / pi
  lon2_degrees <- lon2 * 180 / pi

  return(c(lat2_degrees, lon2_degrees))
}




#' Generate GPS data for a walking activity in Seattle, WA
#'
#' This function generates a data frame containing GPS data for a walking activity in Seattle, WA on April 7th, 2012. It calls the function generate_gps_data to create a series of GPS locations and speeds. The resulting data frame has columns for time, latitude, longitude, and speed.
#'
#' @return A data frame with columns [time, latitude, longitude, speed]
#' @export
generate_walking_in_seattle_gps_data <- function(){
  # Generating a sample dataset of walking in Seattle, WA, USA on April 7th, 2012
  start_lat <- 47.6062
  start_long <- 122.3321
  start_time <- '2012-04-07 00:00:30'
  gps_data <- generate_gps_data(start_lat = start_lat, start_long = start_long, start_time = start_time)
}



#' Generate accelerometry datasets
#'
#' This function generates a list of activity epochs with specified minimum active counts per epoch, minimum bout length,
#' maximum number of consecutive inactive epochs in a bout, minimum non-wearing length, and minimum complete day length.
#'
#' @param active_counts_per_epoch_min Minimum active counts per epoch (default: 500)
#' @param minimum_bout_length Minimum length of a bout in epochs (default: 10)
#' @param maximum_number_consec_inactive_epochs_in_bout Maximum number of consecutive inactive epochs in a bout (default: 3)
#' @param min_non_wearing_length Minimum length of non-wearing period in epochs (default: 40)
#' @param min_complete_day Minimum length of a complete day in epochs (default: 8602)
#' @param activity_epoch A list containing activity counts, bout, non-wearing, and complete day information
#' @param length Length of the active period
#' @param is_bout Logical indicating if the active period is a bout
#' @param non_wearing Logical indicating if the active period is a non-wearing period
#' @param complete_day Logical indicating if the active period is a complete day
#'
#' @return A list of activity epochs
make_active_period <- function(length = 1, is_bout = TRUE, non_wearing = FALSE, complete_day = FALSE) {
  active_counts_per_epoch_min <- 500
  minimum_bout_length <- 10
  maximum_number_consec_inactive_epochs_in_bout <- 3
  min_non_wearing_length <- 20 * 2 # Assuming 30 second epochs
  min_complete_day <- 8602 # 8hrs per 24 hrs
  activity_epoch <- list(activity_counts = integer(), bout = integer(), non_wearing = logical(), complete_day = logical())

  # General purpose activity sequence builders
  activity_epoch <- data.frame()
  active_period <- data.frame(activity_counts = rep(active_counts_per_epoch_min, length),
         bout = as.integer(is_bout),
         non_wearing = as.logical(non_wearing),
         complete_day = as.logical(complete_day))
  return(active_period)
}



#' Create an inactive period
#'
#' This function creates an inactive period with a given length.
#'
#' @param length The length of the inactive period.
#' @param is_bout Logical value indicating whether this period is part of a bout of inactivity.
#' @param non_wearing Logical value indicating whether this period is due to non-wearing of the accelerometer.
#' @param complete_day Logical value indicating whether this period occurs during a complete day of wearing the accelerometer.
#'
#' @return A data frame with columns activity_counts, bout, non_wearing, and complete_day, where activity_counts is set to 0 for the entire length, and bout, non_wearing, and complete_day are set according to the input values.
#'
make_inactive_period <- function(length = 1, is_bout = FALSE, non_wearing = FALSE, complete_day = FALSE) {
  inactive_period <- data.frame(activity_counts = rep(0, length),
         bout = as.integer(is_bout),
         non_wearing = as.logical(non_wearing),
         complete_day = as.logical(complete_day))
  return(inactive_period)
}


#' Add date and format to activity counts
#'
#' This function takes a data frame of activity counts and adds a column of time stamps in POSIXct format.
#' The time stamps start at "2012-04-07 00:00:30" and increase by 30 seconds for each row of the data frame.
#'
#' @param counts a data frame containing activity counts
#' @return a data frame with time stamps added in POSIXct format
add_date_and_format <- function(counts) {
  time <- seq(lubridate::ymd_hms("2012-04-07 00:00:30"), length.out = nrow(counts), by = "30 sec")
  df <- cbind(counts, time)
  return(df)
  }



#' Create the smallest bout window
#'
#' This function creates an active period of minimum length defined by the parameter \code{minimum_bout_length}.
#'
#' @return A data.frame with columns [activity_counts, bout, non_wearing, complete_day] representing the smallest bout window.
#' @examples
make_smallest_bout_window <- function(minimum_bout_length = 10) {
  return(make_active_period(minimum_bout_length))
}


#' Create a non-bout window
#'
#' This function creates a non-bout window, which is a period of inactivity that is not long enough to be considered as an inactive bout.
#'
#' @return a data frame with columns "activity_counts", "bout", "non_wearing", "complete_day"
#' @examples
#' make_non_bout_window()
#'
#' @export
make_non_bout_window <- function(maximum_number_consec_inactive_epochs_in_bout = 3) {
  return(make_inactive_period(maximum_number_consec_inactive_epochs_in_bout + 1))
}


#' Create smallest non-wearing window
#'
#' Create an inactive period that represents the smallest non-wearing window.
#' This function uses the \code{make_inactive_period()} function to create the non-wearing window.
#'
#' @return An inactive period data frame that represents the smallest non-wearing window.
#' @examples
#' make_smallest_nonwearing_window()
#' @export
make_smallest_nonwearing_window <- function(min_non_wearing_length = 20*2) {
  return(make_inactive_period(min_non_wearing_length, non_wearing = TRUE))
}


#' Generate an activity sequence for a complete day with minimal activity
#'
#' This function generates an activity sequence for a complete day with a minimal activity count.
#'
#' @return An activity sequence data frame with minimum activity counts for a complete day.
#'
#' @examples
#' make_smallest_complete_day_activity()
#'
#' @export
make_smallest_complete_day_activity <- function(min_complete_day = 8602) {
  return(make_active_period(min_complete_day, non_wearing = FALSE, complete_day = TRUE))
}


#' Make the smallest bout dataset
#'
#' Generates a dataset representing the smallest bout, consisting of a sequence of inactive periods followed by the smallest active period.
#'
#' @return A data frame containing the activity counts and bout information for the smallest bout.
#' @examples
#' make_smallest_bout()
#' @export
make_smallest_bout <- function() {
  counts <- dplyr::bind_rows(
    make_non_bout_window(),
    make_smallest_bout_window(),
    make_non_bout_window()
  )
  return(add_date_and_format(counts))
}



#' Create the smallest bout window without metadata
#'
#' This function creates the smallest bout window without the metadata columns. It calls the \code{\link{make_smallest_bout}} function and then removes the columns "non_wearing", "complete_day", and "bout" using \code{dplyr::select}.
#'
#' @return A data frame containing the smallest bout window without metadata.
#'
#' @examples
#' make_smallest_bout_without_metadata()
#' @export
make_smallest_bout_without_metadata <- function() {
  return(make_smallest_bout() %>%
           dplyr::select(-c("non_wearing", "complete_day", "bout")))
}


#' Generate a sequence of accelerometer counts representing the smallest bout with the largest inactive period
#'
#' This function generates a sequence of accelerometer counts representing the smallest bout with the largest inactive period.
#' The length of the inactive period is determined by the value of `maximum_number_consec_inactive_epochs_in_bout` variable.
#'
#' @return A data frame with columns `activity_counts` and `time`, representing the accelerometer counts and the corresponding time stamps.
#'
#' @examples
#' make_smallest_bout_with_largest_inactive_period()
#' @export
make_smallest_bout_with_largest_inactive_period <- function(maximum_number_consec_inactive_epochs_in_bout = 3) {
  nbw <- make_non_bout_window()
  inactive_period <- make_inactive_period(maximum_number_consec_inactive_epochs_in_bout, is_bout = TRUE)
  sbw <- make_smallest_bout_window()
  halfway <- nrow(sbw)/2

  counts <- dplyr::bind_rows(
    nbw,
    sbw[1:halfway, ],
    inactive_period,
    sbw[(halfway+1):nrow(sbw), ],
    nbw
  )
  return(add_date_and_format(counts))
}


#' Generate the smallest bout with the smallest non-wearing period dataset
#'
#' This function creates a dataset consisting of the smallest bout and the smallest non-wearing period. The bout length, non-wearing period length, and epoch length are defined in the global variables: minimum_bout_length, maximum_number_consec_inactive_epochs_in_bout, and min_non_wearing_length, respectively.
#'
#' @return A data frame with columns for activity counts and date-time stamps.
#'
#' @examples
#' make_smallest_bout_with_smallest_non_wearing_period()
#' @export
make_smallest_bout_with_smallest_non_wearing_period <- function() {
  counts <- dplyr::bind_rows(
    make_non_bout_window(),
    make_smallest_bout_window(),
    make_smallest_nonwearing_window()
  )
  return(add_date_and_format(counts))
}


#' Create activity counts for a full day bout
#'
#' This function creates a data frame with activity counts for a full day bout. A full day bout is defined as an uninterrupted period of activity with a length of at least \code{min_complete_day}. The function calls the \code{make_non_bout_window()}, \code{make_smallest_bout_window()}, and \code{make_smallest_complete_day_activity()} functions to generate the activity counts for the non-bout window, smallest bout window, and smallest complete day activity, respectively.
#'
#' @return A data frame with activity counts for a full day bout
#' @export
make_full_day_bout <- function() {
  counts <- dplyr::bind_rows(
    make_non_bout_window(),
    make_smallest_bout_window(),
    make_smallest_complete_day_activity()
  )
  counts <- add_date_and_format(counts)
  counts <- counts %>%
    dplyr::mutate(complete_day = TRUE)
  return(counts)
}


#' Create activity counts for a full day bout without metadata
#'
#' This function creates a data frame with activity counts for a full day bout. A full day bout is defined as an uninterrupted period of activity with a length of at least \code{min_complete_day}. The function calls the \code{make_non_bout_window()}, \code{make_smallest_bout_window()}, and \code{make_smallest_complete_day_activity()} functions to generate the activity counts for the non-bout window, smallest bout window, and smallest complete day activity, respectively.
#'
#' @return A data frame with activity counts for a full day bout without metadata
#' @export
make_full_day_bout_without_metadata <- function() {
  counts <- dplyr::bind_rows(
    make_non_bout_window(),
    make_smallest_bout_window(),
    make_smallest_complete_day_activity()
  )
  counts <- add_date_and_format(counts)
  counts <- counts %>%
    dplyr::mutate(complete_day = TRUE) %>%
    dplyr::select(-c("complete_day", "non_wearing", "bout"))
  return(counts)
}


#' Create a data frame of walking bouts with GPS data
#'
#' This function combines accelerometer and GPS data to create a data frame of walking bouts.
#' It generates a full day of activity with bouts of minimum and non-bout periods, and GPS data for walking in Seattle.
#' The accelerometer data is processed into bouts using the \code{\link{process_accelerometry_counts_into_bouts}} function.
#' The GPS data is processed into epochs using the \code{\link{process_gps_data_into_gps_epochs}} function.
#'
#' @return A data frame of walking bouts with GPS data
#' @examples
#' make_full_walk_bout_df()
#' @export
make_full_walk_bout_df <- function() {
  accelerometry_counts <- make_full_day_bout() %>%
    dplyr::select(-c("bout","non_wearing","complete_day"))
  gps_data <- generate_walking_in_seattle_gps_data()
  bouts <- process_accelerometry_counts_into_bouts(accelerometry_counts)
  gps_epochs <- process_gps_data_into_gps_epochs(gps_data)

  walk_bouts <- gps_epochs %>%
    merge(bouts, by = "time", all=TRUE) %>%
    dplyr::arrange(time) %>%
    dplyr::mutate(bout = ifelse(bout==0,NA,bout)) # replace 0s with NAs since they arent bouts

}
