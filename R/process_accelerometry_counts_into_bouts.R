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
process_accelerometry_counts_into_bouts <- function(accelerometry_counts) {
  print('processing accelerometry counts')
  validate_accelerometry_data(accelerometry_counts)

  # TODO:
  #  - Write the processing code in the middle
}

