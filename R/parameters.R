#' Global parameters and constants
#'
#'

# TODO: make sure errors print in one line.
  # read about documentation and cran requirements
  # write documentation for parameters and constants
  # write a prompt for gpt that says these are the params and constants in my library. and then pass in one function at a time and ask for roxygen documentation
    # in prompt tell it that if it needs information about the other functions, have it tell me that it needs the function definition instead of documenting.
    # give it params and constants and ask it to convert in line comments to docstrings using roxygen
  # make vignettes
  # maybe gpt will tell me how to publish to cran

parameters <-
  list(
    # epoch length is the duration of an epoch in seconds
    epoch_length = 30,
    active_counts_per_epoch_min = 500,
    minimum_bout_length = 10,
    local_time_zone = "PDT",
    maximum_number_consec_inactive_epochs_in_bout = 3
  )

constants <-
  list(
    non_wearing_min_threshold_epochs = 40,
    min_wearing_hours_per_day = 8,
    min_gps_obs_within_bout = 5,
    min_gps_coverage_ratio = 0.2,
    dwellbout_radii_quantile = 0.95,
    max_dwellbout_radii_ft = 66,
    min_dwellbout_obs = 10,
    max_walking_cpe = 2863,
    min_walking_speed_km_h = 2,
    max_walking_speed_km_h = 6
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
