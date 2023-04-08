#' Convert accelerometry counts into bouts of physical activity
#'
#' The input schema for the accelerometry data is `time` and `activity_counts`.
#' - `time` should be a column in date-time format, in the UTC time zone, with no null values.
#' - `activity_counts` should be a positive numeric column with no null values.
#'
#' @param accelerometry_counts Raw accelerometry data with the expected schema.
#'
#' @return A data frame of bouts.
#' @export
#'
#'
process_accelerometry_counts_into_bouts <- function(accelerometry_counts, active_counts_per_epoch_min) {
  print('processing accelerometry counts')
  validate_accelerometry_data(accelerometry_counts)

  accelerometry_counts <- assign_activity_levels(accelerometry_counts, active_counts_per_epoch_min)

  # TODO:
  #  - Write the processing code in the middle
}

assign_activity_levels <- function(accelerometry_counts, active_counts_per_epoch_min){
  accelerometry_counts <- accelerometry_counts %>%
    dplyr::mutate(activity = ACTIVITY_LEVELS$low_active) %>%
    dplyr::mutate(activity = ifelse(activity_counts == 0, ACTIVITY_LEVELS$inactive, activity)) %>%
    dplyr::mutate(activity = ifelse(activity_counts > active_counts_per_epoch_min, ACTIVITY_LEVELS$active, activity))
  return(accelerometry_counts)
}
