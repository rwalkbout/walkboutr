#' Global parameters and constants
#'
#' This function returns a list of parameters used in the analysis.
#'
#'List of Parameters
#' @param epoch_length The duration of an epoch in seconds.
#' @param active_counts_per_epoch_min Minimum accelerometer counts for an epoch to be considered active (vs. inactive).
#' @param minimum_bout_length Minimum number of epochs for a period of activity to be considered as a potential bout.
#' @param local_time_zone Local time zone of the data - data come in and are returned in UTC, but local time zone is used to compute complete_days.
#' @param maximum_number_consec_inactive_epochs_in_bout Number of consecutive epochs that can be labeled as inactive during a bout without ending the bout.
#'
#' List of Constants
#' @param non_wearing_min_threshold_epochs Number of consecutive epochs with activity counts of 0 that constitute a non_wearing period.
#' @param min_wearing_hours_per_day Minimum number of hours in a day an individual must wear an accelerometer for the day to be considered complete.
#' @param min_gps_obs_within_bout Minimum number of GPS observations within a bout for that bout to be considered to have complete GPS data.
#' @param min_gps_coverage_ratio Minimum ratio of data points with versus without GPS data for the bout to be considered to have complete GPS data.
#' @param dwellbout_radii_quantile Threshold for outliering GPS data points - any data points above the 95th percentile are outliered.
#' @param max_dwellbout_radii_ft Maximum radius, in feet, of a bounding circle that would be considered a dwell bout (rather than a potential walk bout).
#' @param min_dwellbout_obs Minimum number of observations to consider something a potential dwell bout.
#' @param max_walking_cpe Maxiumum CPE value before the accelerometer is considered to be picking up on an activity other than walking.
#' @param min_walking_speed_km_h Minimum speed considered walking.
#' @param max_walking_speed_km_h Maximum speed considered walking.
#'
#' Collate Arguments
#'
#' This function collates user-provided arguments with pre-defined parameters and constants.
#'
#' @param ... named arguments passed by the user
#' @param collated_arguments NULL or previously collated arguments
#'
#' @example
#' collate_arguments(epoch_length = 60)
#'
#' @return A list of all arguments, including both pre-defined parameters and constants and any user-provided arguments.#'
#'
#' @export

parameters <-
  list(
    epoch_length = 30, # epoch length is the duration of an epoch in seconds
    active_counts_per_epoch_min = 500, # minimum accelerometer counts for an epoch to be considered active (vs. inactive)
    minimum_bout_length = 10, # minimum number of epochs for a period of activity to be considered as a potential bout
    local_time_zone = "PDT", # local time zone of the data - data come in and are returned in UTC, but local time zone is used to compute complete_days
    maximum_number_consec_inactive_epochs_in_bout = 3 # number of consecutive epochs that can be labeled as inactive during a bout without ending the bout
  )

constants <-
  list(
    non_wearing_min_threshold_epochs = 40, # number of consecutive epochs with activity counts of 0 that constitute a non_wearing period
    min_wearing_hours_per_day = 8, # minimum number of hours in a day an individual must wear an accelerometer for the day to be considered complete
    min_gps_obs_within_bout = 5, # minimum number of GPS observations within a bout for that bout to be considered to have complete GPS data
    min_gps_coverage_ratio = 0.2, # minimum ratio of data points with versus without GPS data for the bout to be considered to have complete GPS data
    dwellbout_radii_quantile = 0.95, # threshold for outliering GPS data points - any data points above the 95th percentile are outliered
    max_dwellbout_radii_ft = 66, # maximum radius, in feet, of a bounding circle that would be consdiered a dwell bout (rather than a potential walk bout)
    min_dwellbout_obs = 10, # minimum number of observations to consider something a potential dwell bout
    max_walking_cpe = 2863, # maxiumum cpe value before the accelerometer is considered to be picking up on an activity other than walking
    min_walking_speed_km_h = 2, # minimum speed considered walking
    max_walking_speed_km_h = 6 # maximum speed considered walking
  )

collate_arguments <- function(..., collated_arguments = NULL){
  user_arguments <- list(...)
  if (!is.null(collated_arguments) & length(user_arguments) > 0){
    stop(paste0("Error: "))
  }
  arguments <- c(parameters, constants)
  for(n in names(user_arguments)){
    if(!(n %in% names(parameters))){
      stop(paste("Error: unknown parameter ", n, ". Accepted parameter names are: ", toString(names(parameters)), sep = ", "))
    }
    arguments[n] <- user_arguments[n]
  }
  return(arguments)
}
