#' Process bouts and GPS epochs into walk bouts
#'
#' This function processes bouts and GPS epochs into walk bouts. It uses a set of parameters and constants to determine whether an epoch is active or inactive, the minimum number of epochs for a period of activity to be considered as a potential bout, the local time zone of the data, and other relevant information. It takes in two data frames, "bouts" and "gps_epochs", and returns a processed data frame, "walk_bouts", with added columns "bout", "bout_radius", "bout_category", "complete_days", "non_wearing", and "speed".#'
#' @param bouts a data frame containing bout information
#' @param ... additional arguments to be passed on to other functions
#' @param collated_arguments a list of arguments collated from other functions
#'
#' @return a processed data frame, "walk_bouts", with added columns "bout", "bout_radius", "bout_category", "complete_days", "non_wearing", and "speed"#'
#'
#' @details The function first collates the arguments passed to it with the collate_arguments() function. It then merges "gps_epochs" and "bouts" data frames by "time" column, and orders the resulting data frame by "time". Then, it generates the "bout_radius" using the generate_bout_radius() function, which calculates the radius of a bounding circle that would be considered a dwell bout. Next, the function evaluates the completeness of GPS data using the evaluate_gps_completeness() function, which determines the number of GPS observations within a bout and the ratio of data points with versus without GPS data. Finally, the function generates the "bout_category" using the generate_bout_category() function, which determines whether a bout is a walk bout or a dwell bout, and calculates the complete days, non-wearing periods, and speed.
#' The function categorizes bouts into the following categories:
#'   - dwell bout
#'   - non-walk too vigorous
#'   - non-walk too slow
#'   - non-walk too fast
#'   - unknown lack of gps
#'
#' NOTE: If there are multiple GPS points associated with a given epoch interval,
#' we use the latest possible GPS data point within that epoch. As such,
#' median walking speed is calculated for only the latest available GPS data point in each epoch.
#'
#' NOTE: The median speed is calculated using only the GPS data points that remain after
#' GPS data processing. All GPS data points that are outliered for the calculation of a bout
#' radius, are, however, included in the assessment of GPS completeness as they are outliers
#' but are still present GPS data points.
#'
#' NOTE: Outliered data points are excluded from the radius calculation but are included in
#' subsequent functions that assess GPS completeness. They are also returned from
#' these functions with the original data and all new variables.
#'
#' @export
process_bouts_and_gps_epochs_into_walkbouts <- function(bouts, ..., collated_arguments = NULL){
  collated_arguments <- collate_arguments(..., collated_arguments = collated_arguments)
  print('processing bouts and gps_epochs')

  walk_bouts <- gps_epochs %>%
    merge(bouts, by = "time", all=TRUE) %>%
    dplyr::arrange(time) %>%
    dplyr::mutate(bout = ifelse(bout==0,NA,bout))

  # if there are no bouts, just return the data
  if(sum(is.na(walk_bouts$bout)) == nrow(walk_bouts)){
    return(walk_bouts)
  } else{

  bout_radii <- generate_bout_radius(walk_bouts,
                                     collated_arguments$dwellbout_radii_quantile) # returns df: bout, bout_radius (numer)
  gps_completeness <- evaluate_gps_completeness(walk_bouts,
                                                collated_arguments$min_gps_obs_within_bout,
                                                colalted_arguments$min_gps_coverage_ratio) # returns df: bout, complete_gps (T/F), median_speed
  walk_bouts <- generate_bout_category(walk_bouts, bout_radii, gps_completeness,
                                       collated_arguments$max_dwellbout_radii_ft,
                                       collated_arguments$max_walking_cpe,
                                       collated_arguments$min_walking_speed_km_h,
                                       collated_arguments$max_walking_speed_km_h) # returns df: bout, bout_category, complete_days, non_wearing, speed

  return(walk_bouts) }
}

#' Outlier GPS data points
#' This function identifies outlier GPS points for the bout radius calculation from a given set of latitude and longitude coordinates.
#'
#' @param lat_long A data frame containing the latitude and longitude coordinates for the GPS points.
#' @param dwellbout_radii_quantile The threshold for outliering GPS data points - any data points above the specified percentile are outliered.
#'
#' @return A data frame containing the latitude and longitude coordinates for the non-outlier GPS points.
#'
#' @examples
#' # Create a sample data frame of GPS coordinates
#' lat_long <- data.frame(
#'   latitude = c(39.7456, 39.7446, 39.7445, 39.7458, 39.7445),
#'   longitude = c(-104.9952, -104.9953, -104.9949, -104.9949, -104.9953)
#' )
#'
#' # Call the outlier_gps_points() function with the sample data frame
#' outlier_gps_points(lat_long, 0.95)
outlier_gps_points <- function(lat_long, dwellbout_radii_quantile){
  # outlier gps points that are above the 95% percentile of summed distances
  distance_sum <- sp::SpatialPoints(coords = cbind(long = lat_long$longitude, lat = lat_long$latitude)) %>%
    sp::spDists(., longlat = TRUE) %>%
    colSums()
  points_to_keep <- distance_sum < quantile(distance_sum, dwellbout_radii_quantile)[[1]][1]
  lat_long <- cbind(lat_long, points_to_keep) %>% dplyr::filter(points_to_keep==TRUE)
  return(lat_long)
}


#' Generate Bounding Circle Radius for Walking Bouts
#'
#' This function generates a bounding circle radius for each walking bout identified in the input data. The bounding circle is defined as the smallest circle that fully contains all GPS locations observed during a walking bout.
#'
#' @param walk_bouts A data frame containing GPS locations for each walking bout, with columns "longitude", "latitude", and "bout" (a unique identifier for each bout)
#' @param dwellbout_radii_quantile A quantile (between 0 and 1) used to filter outlying GPS data points before generating the bounding circle. GPS points with a distance from the center greater than the radius of the circle that contains (1 - dwellbout_radii_quantile) of the GPS points are considered outliers and are excluded.
#'
#' @return A data frame containing the bout identifier and the radius of the bounding circle for each walking bout.
generate_bout_radius <- function(walk_bouts, dwellbout_radii_quantile){
  bout_radii <- data.frame(bout = integer(), bout_radius=numeric())
  bout_labels <- walk_bouts %>%
    tidyr::drop_na(bout) %>%
    dplyr::select(bout) %>%
    unique() # drop rows with NA bout label
  for(bout_label in bout_labels){
  # pull long/lat and remove outliers
    lat_long <- walk_bouts %>%
      dplyr::filter(bout==bout_label) %>%
      tidyr::drop_na()
    lat_long <- outlier_gps_points(lat_long, dwellbout_radii_quantile)
    lat_long <- lat_long %>%
      dplyr::distinct(longitude, latitude, .keep_all = TRUE)

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


#' Evaluate GPS completeness for each walking bout
#'
#' This function evaluates the completeness of GPS data for each walking bout. For each bout, it checks if the number of valid GPS records (with speed, latitude, and longitude data) is greater than a specified threshold, and if the ratio of valid GPS records to total records is greater than a specified minimum. If both of these conditions are met, the function considers the GPS data for the bout to be complete. The function also calculates the median speed for each bout.
#'
#' @param walk_bouts A data frame containing information about walking bouts, including GPS data.
#' @param min_gps_obs_within_bout The minimum number of GPS observations required for a bout to be considered to have complete GPS data.
#' @param min_gps_coverage_ratio The minimum ratio of GPS observations with valid data to total GPS observations for a bout to be considered to have complete GPS data.
#'
#' @return A data frame containing information about the GPS completeness and median speed for each bout.
evaluate_gps_completeness <- function(walk_bouts, min_gps_obs_within_bout, min_gps_coverage_ratio){
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
    # can take out this ifelse since its all T/F
    dplyr::select(c("bout", "complete_gps", "median_speed"))

  return(gps_completeness)
}


#' Generate bout categories
#'
#' Given accelerometer bout data, this function generates bout categories, which includes dwell bouts, non-walk bouts that are either too slow, too fast, or too vigorous, and bouts with an unknown lack of GPS data.
#'
#' @param walk_bouts a data frame that contains bout information for walking bouts.
#' @param bout_radii a data frame that contains bout radii information.
#' @param gps_completeness a data frame that contains GPS data completeness information.
#' @param max_dwellbout_radii_ft a numeric scalar that specifies the maximum radius, in feet, of a bounding circle that would be considered a dwell bout.
#' @param max_walking_cpe a numeric scalar that specifies the maximum activity counts per epoch value before the accelerometer is considered to be picking up on an activity other than walking.
#' @param min_walking_speed_km_h a numeric scalar that specifies the minimum speed considered walking.
#' @param max_walking_speed_km_h a numeric scalar that specifies the maximum speed considered walking.
#'
#' @return a data frame with the following columns: bout, dwell_bout (T/F), non_walk_too_vigorous (T/F), non_walk_slow (T/F), non_walk_fast (T/F), non_walk_incomplete_gps (T/F)
#'
#' @details The function uses the bout information for walking bouts, bout radii information, and GPS data completeness information to generate the bout categories.
#'
#' The function first generates dwell bouts by joining the bout radii information and GPS data completeness information on the bout column, and then filters out the rows that have bout values that are missing using the filter function. Then, it calculates the dwell bout values as TRUE if the complete_gps column is TRUE and the bout_radius column is less than max_dwellbout_radii_ft. The resulting data frame only contains the bout and dwell_bout columns.
#' The function then joins the resulting data frame with the walking bout data frame using the bout column. Then, for the non-walk bouts, the function calculates whether they are too vigorous, too slow, or too fast. For the non-walk bouts that are too vigorous, the function calculates the mean activity_counts for each bout, and then sets the non_walk_too_vigorous value as TRUE if the mean activity_counts value is greater than max_walking_cpe. For the non-walk bouts that are too slow or too fast, the function calculates the median speed for each bout, and then sets the non_walk_slow or non_walk_fast value as TRUE if the median speed value is less than min_walking_speed_km_h or greater than max_walking_speed_km_h, respectively. Finally, the function generates a non_walk_incomplete_gps value as TRUE if the complete_gps value is FALSE for the bout.
#' The resulting data frame contains the following columns: bout, dwell_bout (T/F), non_walk_too_vigorous (T/F), non_walk_slow (T/F), non_walk_fast (T/F), non_walk_incomplete_gps (T/F).
generate_bout_category <- function(walk_bouts, bout_radii, gps_completeness,
                                   max_dwellbout_radii_ft, max_walking_cpe, min_walking_speed_km_h, max_walking_speed_km_h){
  # bout categories:
    # dwell bout
    # nonwalk too vigorous,
    # nonwalk too slow,
    # nonwalk too fast,
    # unknown lack of gps

  dwell_bouts <- bout_radii %>%
    dplyr::filter(!(is.na(bout))) %>%
    dplyr::left_join(gps_completeness, by = "bout") %>%
    dplyr::mutate(dwell_bout = ifelse(("complete_gps"==TRUE & ("bout_radius" < max_dwellbout_radii_ft)), TRUE, FALSE)) %>%
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

  nonwalk_incomplete_gps <- gps_completeness %>%
    dplyr::mutate(non_walk_incomplete_gps = !complete_gps) %>%
    dplyr::select(c("bout", "non_walk_incomplete_gps"))

  cols <- c("dwell_bout", "non_walk_incomplete_gps", "non_walk_fast", "non_walk_slow", "non_walk_too_vigorous",
            "complete_day", "non_wearing", "inactive")
  categorized_bouts <- plyr::join_all(list(
    walk_bouts_dwell, nonwalk_cpe, nonwalk_slow, nonwalk_fast, nonwalk_incomplete_gps),
      by = c("bout"), type = "left") %>%
      dplyr::mutate_at(cols, ~tidyr::replace_na(.,FALSE))

  cols <- c("dwell_bout", "non_walk_incomplete_gps", "non_walk_fast", "non_walk_slow", "non_walk_too_vigorous")
  if(any(rowSums(categorized_bouts %>% dplyr::select(all_of(cols))) > 1)){
    stop(paste0("Error: some bouts have been classified as 2 different categories."))
  }

  categorized_bouts <- categorized_bouts %>%
    tidyr::pivot_longer(., cols = cols, names_to="bout_category") %>%
    dplyr::filter(value) %>%
    dplyr::select(-c("inactive","value")) %>%
    unique(.)

  return(categorized_bouts)
}
