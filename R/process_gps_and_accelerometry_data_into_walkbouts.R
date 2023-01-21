process_gps_and_accelerometry_data_into_walkbouts <- function(gps_data, accelerometry_data){
  bouts <- process_accelerometry_counts_into_bouts(accelerometry_data)
  travel_instances <- process_gps_data_into_travel_instances(gps_data)
  walk_bouts <- process_bouts_and_travel_instances_into_walkbouts(bouts, travel_instances)
  return(list(bouts=bouts, travel_instances=travel_instances, walk_bouts=walk_bouts))
}
