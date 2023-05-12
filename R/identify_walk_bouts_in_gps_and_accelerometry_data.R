#' Convert accelerometry and GPS data into walk bouts
#'
#' @param gps_data GPS data
#' @param accelerometry_data Accelerometry data
#'
#' @return A data frame of walk bouts
#' @export
#'

identify_walk_bouts_in_gps_and_accelerometry_data <- function(gps_data, accelerometry_counts, ..., collated_arguments = NULL){
  collated_arguments <- collate_arguments(..., collated_arguments=collated_arguments)

  bouts <- process_accelerometry_counts_into_bouts(accelerometry_counts, collated_arguments=collated_arguments)
  gps_epochs <- process_gps_data_into_gps_epochs(gps_data, collated_arguments=collated_arguments)
  walk_bouts <- process_bouts_and_gps_epochs_into_walkbouts(bouts, collated_arguments=collated_arguments)
  return(walk_bouts)
}

summarize_walk_bouts <- function(walk_bouts){

  summary_walk_bouts <- walk_bouts %>%
    dplyr::group_by(bout) %>%
    dplyr::filter(!is.na(bout)) %>%
    dplyr::summarise(
              median_speed = median(speed),
              complete_day = any(complete_day),
              non_wearing = any(non_wearing),
              bout_start = lubridate::as_datetime(
                min(as.numeric(time)), tz = "UTC"),
              duration =
                max(as.numeric(time) + epoch_length) -
                min(as.numeric(time))
                )
  return(summary_walk_bouts)
}

