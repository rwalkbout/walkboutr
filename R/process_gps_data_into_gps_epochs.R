#' Convert GPS data into GPS epochs
#'
#' The input schema for the accelerometry data is `time`, `latitude`, `longitude`, and `speed`.
#' - `time` should be a column in date-time format, in the UTC time zone, with no null values.
#' - `latitude` should be a numeric, non-null latitude coordinate between -90 and 90
#' - `longitude` should be a numeric, non-null longitude coordinate between -180 and 180
#' - `speed` should be a numeric, non-null value in kilometers per hour
#'
#' This function processes GPS data into GPS epochs, with each epoch having a duration specified by \code{epoch_length}.
#'
#' @param gps_data A data frame containing GPS data. Must have columns "Latitude", "Longitude"
#' @param ... Additional arguments to be passed to the function.
#' @param collated_arguments A named list of arguments, used to avoid naming conflicts when calling this function as part of a pipeline. Optional.
#'
#' @returns A data frame with columns latitude, longitude, time, and speed, where time is now the nearest epoch start time
#'
#' @export
process_gps_data_into_gps_epochs <- function(gps_data, ..., collated_arguments = NULL) {
  collated_arguments <- collate_arguments(..., collated_arguments = collated_arguments)
  validate_gps_data(gps_data)
  gps_epochs <- assign_epoch_start_time(gps_data,
                                        collated_arguments$epoch_length)
  return(gps_epochs)
}


#' Validate GPS data
#'
#' This function validates GPS data for required variables, correct variable class, and correct data range.
#'
#' @param gps_data A data frame containing GPS data with the following variables: time, latitude, longitude, and speed.
#'
#' @returns This function does not return anything. It throws an error if the GPS data fails any of the validation checks.
#'
#' @export
validate_gps_data <- function(gps_data){

# Validation schema
  diff <- setdiff(names(gps_data), c("time", "latitude", "longitude", "speed"))
  missing <- setdiff(c("time", "latitude", "longitude", "speed"), names(gps_data))
  if(length(missing)>0){
    stop(paste0("Error: data provided are missing `", missing, "` columns."))
  }
  if(length(diff)>0){
    diff <- paste0(diff, collapse = ', ')
    stop(paste0("Error: data provided have the following extra columns: ", diff))
  }

# Validate time variable
  if(!lubridate::is.timepoint(gps_data$time)){
    stop(paste0("Error: time is not provided in date-time format. class of time variable should be: `POSIXct` `POSIXt`"))
  }
  if(any(is.na(gps_data$time))){
    stop(paste0("Error: time data contain NAs"))
  }
  if(!(lubridate::tz(gps_data$time) == "UTC")){
    stop(paste0("Error: time zone provided is not UTC."))
  }

# Validate latitude/longitude variable
  if(!(class(gps_data$latitude) %in% c("numeric"))){
    stop(paste0("Error: latitude column is not class integer or numeric."))
  }
  if(any(is.na(gps_data$latitude))){
    stop(paste0("Error: latitude column contains NAs"))
  }
  if(any(gps_data$latitude < -90 | gps_data$latitude > 90)){
    stop(paste0("Error: latitude column contains invalid latitude coordinates"))
  }
  if(!(class(gps_data$longitude) %in% c("integer", "numeric"))){
    stop(paste0("Error: longitude column is not class integer or numeric."))
  }
  if(any(is.na(gps_data$longitude))){
    stop(paste0("Error: longitude column contains NAs"))
  }
  if(any(gps_data$longitude < -180 | gps_data$longitude > 180)){
    stop(paste0("Error: longitude column contains invalid longitude coordinates"))
  }

# Validate speed variable
  if(!(class(gps_data$speed) %in% c("numeric"))){
    stop(paste0("Error: speed column is not class integer or numeric."))
  }
  if(any(is.na(gps_data$speed))){
    stop(paste0("Error: speed column contains NAs"))
  }
  if(any(gps_data$speed<0)){
    stop(paste0("Error: speed column contains negative values"))
  }
  if(any(gps_data$speed > 2000)){
    message("Warning: speed column contains implausibly large values")
  }

}



#' Assign Epoch Start Time
#'
#' @param gps_data A data frame with GPS data including a column of timestamps and columns for latitude and longitude
#' @param epoch_length The duration of an epoch in seconds
#' @details Selects the closest 30 second increment to assign epoch start time and takes the GPS coordinates associated with the latest time if there are multiple GPS data points in a given 30 second increment. This function returns a data frame of GPS data with a column of epoch times.
#'
#' @returns A data frame of GPS data with an additional column indicating epoch start time
#'
#' @export
assign_epoch_start_time <- function(gps_data, epoch_length){
  time <- epoch_time <- dx_p <- NULL
  # select the closest 30 second increment to assign epoch start time
  # if there are multiple gps data points in a given 30 second increment,
    # takes the gps coordinates associated with the latest time
  gps_epochs <- gps_data %>%
    dplyr::mutate(epoch_time = as.numeric(time)) %>%
    dplyr::mutate(dx_p = epoch_time%%epoch_length) %>%
    dplyr::mutate(epoch_time = epoch_time-dx_p) %>%
    dplyr::group_by(epoch_time) %>%
    dplyr::filter(as.numeric(time) == max(as.numeric(time))) %>%
    dplyr::mutate(time = lubridate::as_datetime(epoch_time, tz="UTC")) %>%
    dplyr:: ungroup() %>%
    dplyr::select(-c(dx_p, epoch_time))
  return(gps_epochs)
}


