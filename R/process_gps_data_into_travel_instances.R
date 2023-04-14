#' Convert GPS data into travel instances
#'
#' The input schema for the accelerometry data is `time` and `activity_counts`.
#' - `time` should be a column in date-time format, in the UTC time zone, with no null values.
#' - `latitude` should be a numeric, non-null latitude coordinate between -90 and 90
#' - `longitude` should be a numeric, non-null longitude coordinate between -180 and 180
#' - `speed` should be a numeric, non-null value in kilometers per hour
#'
#' @param gps_data GPS data
#'
#' @return A data frame of GPS data, unidentified.
#' @export
#'
process_gps_data_into_travel_instances <- function(gps_data) {
  print('processing gps data into travel instances')
  validate_gps_data(gps_data)

  # TODO:
  #  - write tests for gps data validation
  #  - Write the processing code in the middle
  #  - Need to account for the fact that sometimes gps data will have smaller time increments than acc data


  # TODO: Question - can we validate that it is in km/h?

}

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
    stop(paste0("Error: activity counts contain NAs"))
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
  if(any(gps_data$speed > 2000)){
    message("Warning: speed column contains implausibly large values")
  }

}

assign_epoch_start_time <- function(gps_date_time, epoch_length){
  # select the closest 30 second increment to assign epoch start time
  gps_data <- gps_data %>%
    mutate(time = as.numeric(time)) %>%
    mutate(dx_n = (-1*time)%%epoch_length) %>%
    mutate(dx_p = time%%epoch_length) %>%
    mutate(time = ifelse(dx_n<dx_p, time+dx_n, time-dx_p)) %>%
    mutate(time = as_datetime(time, tz="UTC")) %>%
    select(-c(dx_n, dx_p))
}


