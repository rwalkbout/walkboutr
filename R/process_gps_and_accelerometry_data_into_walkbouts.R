#' Convert accelerometry and GPS data into walk bouts
#'
#' @param gps_data GPS data
#' @param accelerometry_data Accelerometry data
#'
#' @return A data frame of walk bouts
#' @export
#'
process_gps_and_accelerometry_data_into_walkbouts <- function(gps_data, accelerometry_data){
  bouts <- process_accelerometry_counts_into_bouts(accelerometry_counts, active_counts_per_epoch_min, epoch_length)
  gps_epochs <- process_gps_data_into_gps_epochs(gps_data)
  walk_bouts <- process_bouts_and_gps_epochs_into_walkbouts(bouts, gps_epochs)
  return(walkbouts)
}

summarize_walkbouts <- function(walk_bouts){

  summary_walk_bouts <- walk_bouts %>%
    dplyr::group_by(bout) %>%
    dplyr::filter(!is.na(bout))
    dplyr::summarise(
      median_speed = median(speed),
              complete_day = any(complete_day),
              non_wearing = any(non_wearing),
              bout_start = lubridate::as_datetime(
                min(as.numeric(time)), tz = "UTC")
              )
  return(summary_walk_bouts)
}

