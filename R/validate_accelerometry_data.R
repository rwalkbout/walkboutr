#' Validate accelerometry input data
#'
#' The input schema for the accelerometry data is `time` and `activity_counts`.
#' - `time` should be a column in date-time format, in the UTC time zone, with no null values.
#' - `activity_counts` should be a positive numeric column with no null values.
#'
#' This function checks the schema of the accelerometry input data
#' and raises an error if any schema constraints are violated.
#'
#' @param accelerometry_counts Raw accelerometry data with the expected schema.
#'
#' @export
#'
#'
validate_accelerometry_data <- function(accelerometry_counts){

  # Validate Schema
    diff <- setdiff(names(accelerometry_counts), c("time", "activity_counts"))
    missing <- setdiff(c("time", "activity_counts"), names(accelerometry_counts))
    if(length(missing)>0){
      stop(paste0("Error: data provided are missing `", missing, "` columns."))
    }
    if(length(diff)>0){
      diff <- paste0(diff, collapse = ', ')
      stop(paste0("Error: data provided have the following extra columns: ", diff))
    }

  # Validate time variable
    if(!lubridate::is.timepoint(accelerometry_counts$time)){
      stop(paste0("Error: time is not provided in date-time format. class of time variable should be: `POSIXct` `POSIXt`"))
    }
    if(any(is.na(accelerometry_counts$time))){
      stop(paste0("Error: activity counts contain NAs"))
    }
    if(!(lubridate::tz(accelerometry_counts$time) == "UTC")){
      stop(paste0("Error: time zone provided is not UTC."))
    }

  # Validate activity_counts variable
    if(!(class(accelerometry_counts$activity_counts) %in% c("integer", "numeric"))){
      stop(paste0("Error: activity counts are not class integer or numeric."))
    }
    if(any(is.na(accelerometry_counts$activity_counts))){
      stop(paste0("Error: activity counts contain NAs"))
    }
    if(!all(accelerometry_counts$activity_counts > 0)){
      stop(paste0("Error: negative activity counts in data."))
    }
}
