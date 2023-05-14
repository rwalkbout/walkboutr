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
generate_gps_data <- function(start_lat, start_long, start_time, n_epochs = 100, time_interval = 30.0) {

  # set the initial location and speed
  current_lat <- start_lat
  current_long <- start_long
  current_speed <- runif(1, 0.5, 1.5)  # km/h

  # set random number generator seed for reproducibility
  set.seed(1234)

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

#' Gets the next lat/long coordinate
#'
#' @param speed The speed of the person in meters per second.
#' @param direction The initial direction of the person's movement in degrees.
#'

# define the next_lat_long function to calculate the next latitude and longitude given the current position, speed, direction, and time step.
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


#' Generate accelerometry datasets
#
# active_counts_per_epoch_min <- 500
# minimum_bout_length <- 10
# maximum_number_consec_inactive_epochs_in_bout <- 3
# min_non_wearing_length <- 20 * 2 # Assuming 30 second epochs
# min_complete_day <- 8602 # 8hrs per 24 hrs
# activity_epoch <- list(activity_counts = integer(), bout = integer(), non_wearing = logical(), complete_day = logical())
#
# # General purpose activity sequence builders
# make_active_period <- function(length = 1, is_bout = TRUE, non_wearing = FALSE, complete_day = FALSE) {
#   active_period <- tibble(activity_counts = rep(active_counts_per_epoch_min, length),
#          bout = as.integer(is_bout),
#          non_wearing = as.logical(non_wearing),
#          complete_day = as.logical(complete_day))
#   return(active_period)
# }
# make_inactive_period <- function(length = 1, is_bout = FALSE, non_wearing = FALSE, complete_day = FALSE) {
#   inactive_period <- tibble(activity_counts = rep(0, length),
#          bout = as.integer(is_bout),
#          non_wearing = as.logical(non_wearing),
#          complete_day = as.logical(complete_day))
#   return(inactive_period)
# }
# add_date_and_format <- function(counts_and_labels) {
#   dates <- seq(ymd_hms("2012-04-07 00:00:00"), length.out = length(counts_and_labels), by = "30 sec")
#   df <- tibble(activity_counts = sapply(counts_and_labels, [[, 1),
#                bout = sapply(counts_and_labels, [[, 2),
#                non_wearing = sapply(counts_and_labels, [[, 3),
#                complete_day = sapply(counts_and_labels, [[, 4),
#                time = dates))
#   return(df)
#   }
#
# # Higher level helpers
# make_smallest_bout_window <- function() {
#   make_active_period(minimum_bout_length)
# }
#
# make_non_bout_window <- function() {
#   make_inactive_period(maximum_number_consec_inactive_epochs_in_bout + 1)
# }
#
# make_smallest_nonwearing_window <- function() {
#   make_inactive_period(min_non_wearing_length, non_wearing = TRUE)
# }
#
# make_smallest_complete_day_activity <- function() {
#   make_active_period(min_complete_day, non_wearing = FALSE, complete_day = TRUE)
# }
#
# # Test set makers
# make_smallest_bout <- function() {
#   counts <- bind_rows(
#     make_non_bout_window(),
#     make_smallest_bout_window(),
#     make_non_bout_window()
#   )
#   add_date_and_format(counts)
# }
#
# make_smallest_bout_with_largest_inactive_period <- function() {
#   nbw <- make_non_bout_window()
#   inactive_period <- make_inactive_period(maximum_number_consec_inactive_epochs_in_bout, is_bout = TRUE)
#   sbw <- make_smallest_bout_window()
#   halfway <- length(sbw$activity_counts) // 2
#
#   counts <- bind_rows(
#     nbw,
#     sbw[1:halfway, ],
#     inactive_period,
#     sbw[(halfway+1):length(sbw$activity_counts), ],
#     nbw
#   )
#   add_date_and_format(counts)
# }
#
# make_smallest_bout_with_smallest_non_wearing_period <- function() {
#   counts <- bind_rows(
#     make_non_bout_window(),
#     make_smallest_bout_window(),
#     make_smallest_nonwearing_window()
#   )
#   add_date_and_format(counts)
# }
#
# make_full_day_bout <- function() {
#   counts <- bind_rows(
#     make_non_bout_window(),
#     make_smallest
