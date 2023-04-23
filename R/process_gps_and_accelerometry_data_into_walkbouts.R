#' Convert accelerometry and GPS data into walk bouts
#'
#' @param gps_data GPS data
#' @param accelerometry_data Accelerometry data
#'
#' @return A data frame of walk bouts
#' @export
#'
process_gps_and_accelerometry_data_into_walkbouts <- function(gps_data, accelerometry_data){
  bouts <- process_accelerometry_counts_into_bouts(accelerometry_counts)
  gps_epochs <- process_gps_data_into_gps_epochs(gps_data)
  walk_bouts <- process_bouts_and_gps_epochs_into_walkbouts(bouts, gps_epochs)
  return(list(bouts=bouts, gps_epochs=gps_epochs, walk_bouts=walk_bouts))
}
