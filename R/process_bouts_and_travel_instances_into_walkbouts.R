#' Convert bouts and travel instances into walk bouts
#'
#' @param bouts Accelerometry bouts
#' @param gps_epochs GPS epochs
#'
#' @return A data frame of walk bouts and summary statistics.
#' @export
#'


# TODO
  # make this work by subject and concat subjects and design df to return
  # clean up functions, write docs
  # kangs schema stuff
  # what do we want to return?

process_bouts_and_travel_instances_into_walkbouts <- function(bouts, gps_epochs){
  print('processing bouts and gps_epochs')

  walk_bouts <- gps_epochs %>%
    merge(bouts, by = "time", all=TRUE) %>%
    dplyr::arrange(time) %>%
    dplyr::mutate(bout = ifelse(bout==0,NA,bout)) # replace 0s with NAs since they arent bouts

  if(is.na(all(walk_bouts$bout))){
    return(walk_bouts)

  } else{
  speed_df <- walk_bouts %>%
    dplyr::group_by(bout) %>%
    dplyr::summarise(median_speed = stats::median(speed))

  bout_radii <- generate_bout_radius(walk_bouts) # returns df: bout, bout_radius (numer)
  gps_completeness <- evaluate_gps_completeness(walk_bouts) # returns df: bout, complete_gps (T/F), speed
  categorized_bouts <- generate_bout_category(walk_bouts, bout_radii, gps_completeness) # returns df: bout, bout_category (string)

  categorized_bouts <- categorized_bouts %>%
    dplyr::left_join(speed_df, by = c("bout")) # returns df: bout, bout_category, complete_days, median_speed
  return(walk_bouts) }
}




outlier_gps_points <- function(lat_long){
  # outlier gps points that are above the 95% percentile of summed distances
  distance_sum <- sp::SpatialPoints(coords = cbind(long = lat_long$longitude, lat = lat_long$latitude)) %>%
    sp::spDists(., longlat = TRUE) %>%
    colSums()
  points_to_keep <- distance_sum < quantile(distance_sum, dwellbout_radii_quantile)[[1]][1]
  lat_long <- cbind(lat_long, points_to_keep) %>% dplyr::filter(points_to_keep==TRUE)
  return(lat_long)
}

generate_bout_radius <- function(walk_bouts){
  bout_radii <- data.frame(bout = integer(), bout_radius=numeric())
  bout_labels <- walk_bouts %>%
    tidyr::drop_na(bout) %>%
    dplyr::select(bout) %>%
    unique() # drop rows with NA bout label
  for(bout_label in bout_labels){
  # pull long/lat and remove outliers
    lat_long <- walk_bouts %>%
      dplyr::filter(bout==bout_label) %>%
      tidyr::drop_na() %>%
      dplyr::distinct(longitude, latitude, .keep_all = TRUE)
    lat_long <- outlier_gps_points(lat_long)

    if(nrow(lat_long > 1)){
      # derive radius of bounding circle
      circle <- lat_long %>%
        dplyr::select(longitude, latitude) %>%
        as.matrix() %>% # - convert x and y columns to two-column matrix with n rows
        sf::st_multipoint() %>% # generate (x, y) coordinates
        lwgeom::st_minimum_bounding_circle()
      circle_area <- geosphere::areaPolygon(x=circle[[1]])
      circle_radius <- sqrt(circle_area/pi) %>% measurements::conv_unit(., from = 'm', to = 'ft')
    } else {
      circle_radius <- NA
    }
    bout_radii <- rbind(bout_radii, data.frame(bout = bout_label, bout_radius = circle_radius))
  }
  return(bout_radii)
}


evaluate_gps_completeness <- function(walk_bouts){
  # determine if we have sufficient gps coverage for each bout
  gps_completeness <- walk_bouts %>%
    dplyr::group_by(bout) %>%
    dplyr::summarise(
      n_valid_gps_records = sum(!is.na(speed) & !is.na(latitude) & !is.na(longitude)), # speed and GPS units
      gps_coverage_ratio = ifelse(sum(!is.na(bout))!=0, n_valid_gps_records/sum(!is.na(bout)), NA),
      sufficient_gps_records = n_valid_gps_records>min_gps_obs_within_bout,
      sufficient_gps_coverage = gps_coverage_ratio>min_gps_coverage_ratio,
      median_speed = stats::median(!is.na(speed))) %>%
    dplyr::mutate(complete_gps = ifelse((sufficient_gps_coverage==FALSE & sufficient_gps_records == FALSE), FALSE, TRUE)) %>%
    dplyr::select(c("bout", "complete_gps", "median_speed"))

  return(gps_completeness)
}


generate_bout_category <- function(walk_bouts, bout_radii, gps_completeness){
  # bout categories:
    # dwell bout
    # nonwalk too vigorous,
    # nonwalk too slow,
    # nonwalk too fast,
    # unknown lack of gps

  dwell_bouts <- bout_radii %>%
    dplyr::filter(!(is.na(bout))) %>%
    dplyr::left_join(gps_completeness, by = "bout") %>%
    dplyr::mutate(dwell_bout = ifelse(("complete_gps"==TRUE & ("bout_radius"<max_dwellbout_radii_ft)), TRUE, FALSE)) %>%
    dplyr::select(c("bout", "dwell_bout")) # cols: bout, dwell_bout (T/F)

  walk_bouts_dwell <- walk_bouts %>%
    dplyr::left_join(dwell_bouts, by = c("bout")) %>%
    dplyr::filter(!is.na(bout))

  nonwalk_cpe <- walk_bouts_dwell %>%
    dplyr::filter(dwell_bout == FALSE) %>%
    dplyr::group_by(bout) %>%
    dplyr::summarize(mean_cpe = mean(activity_counts)) %>%
    dplyr::mutate(non_walk_too_vigorous = mean_cpe > max_walking_cpe) %>%
    dplyr::select(c("bout", "non_walk_too_vigorous")) # cols: bout, non_walk_too_vigorous(T/F)

  nonwalk_slow <- walk_bouts_dwell %>%
    dplyr::filter(dwell_bout == FALSE) %>%
    dplyr::group_by(bout) %>%
    dplyr::summarize(median_speed = stats::median(speed)) %>%
    dplyr::mutate(non_walk_slow = median_speed < min_walking_speed_km_h) %>%
    dplyr::select(c("bout", "non_walk_slow")) # cols: bout, non_walk_slow(T/F)

  nonwalk_fast <- walk_bouts_dwell %>%
    dplyr::filter(dwell_bout == FALSE) %>%
    dplyr::group_by(bout) %>%
    dplyr::summarise(median_speed = stats::median(speed)) %>%
    dplyr::mutate(non_walk_fast = median_speed > max_walking_speed_km_h) %>%
    dplyr::select(c("bout", "non_walk_fast")) # cols: bout, non_walk_fast(T/F)

  nonwalk_gps <- gps_completeness %>%
    dplyr::mutate(non_walk_gps = !complete_gps) %>%
    dplyr::select(c("bout", "non_walk_gps"))

  cols <- c("dwell_bout", "non_walk_gps", "non_walk_fast", "non_walk_slow", "non_walk_too_vigorous",
            "complete_day", "non_wearing", "inactive")
  categorized_bouts <- plyr::join_all(list(
    walk_bouts_dwell, nonwalk_cpe, nonwalk_slow, nonwalk_fast, nonwalk_gps),
      by = c("bout"), type = "left") %>%
      dplyr::mutate_at(cols, ~tidyr::replace_na(.,FALSE))

  cols <- c("dwell_bout", "non_walk_gps", "non_walk_fast", "non_walk_slow", "non_walk_too_vigorous")
  if(any(rowSums(categorized_bouts %>% dplyr::select(all_of(cols))) > 1)){
    stop(paste0("Error: some bouts have been classified as 2 different categories."))
  }

  categorized_bouts <- categorized_bouts %>%
    tidyr::pivot_longer(., cols = cols, names_to="bout_category") %>%
    dplyr::filter(value) %>%
    dplyr::select(-c("inactive","value", "speed")) %>%
    unique(.)

  return(categorized_bouts)
}

