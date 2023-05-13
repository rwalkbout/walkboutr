#' Categorizes accelerometer bouts as walking or non-walking based on various criteria.
#'
#' This function takes in a set of accelerometer bouts and categorizes them as either
#' walking or non-walking based on several criteria, such as the average counts per epoch,
#' median walking speed, and the presence or absence of GPS data. The function returns a
#' data frame with information about each bout, including whether it was a dwell bout or
#' non-walking bout, whether GPS data was complete or not, and whether the bout was too slow or too fast.
#'
#' @param walk_bouts A data frame containing accelerometry data for each bout.
#' @param bout_radii A data frame containing information about each bout's radius.
#' @param gps_completeness A data frame containing information about each bout's GPS completeness.
#' @param max_dwellbout_radii_ft A numeric value specifying the maximum radius, in feet, for a bout to be considered a dwell bout.
#' @param max_walking_cpe A numeric value specifying the maximum counts per epoch for a bout to be considered a walking bout.
#' @param min_walking_speed_km_h A numeric value specifying the minimum walking speed (in km/h) for a bout to be considered a walking bout.
#' @param max_walking_speed_km_h A numeric value specifying the maximum walking speed (in km/h) for a bout to be considered a walking bout.
#'
#' NOTE: If there are multiple GPS points associated with a given epoch interval,
#' we use the latest possible GPS data point within that epoch. As such,
#' median walking speed is calculated for only the latest available GPS data point in each epoch.
#' Additionally, the median speed is calculated using only the GPS data points that remain after
#' GPS data processing. All GPS data points that are outliered for the calculation of a bout
#' radius, are, however, included in the assessment of GPS completeness as they are outliers
#' but are still present GPS data points.
#'
#' @return A data frame containing information about each bout and its corresponding bout category.
#'
#' @details The function categorizes bouts into the following categories:
#'   - dwell bout
#'   - non-walk too vigorous
#'   - non-walk too slow
#'   - non-walk too fast
#'   - unknown lack of gps
#'
#' This is done by first taking in a data frame containing walking bout data and
#' calculates the radius of a bounding circle around each bout.
#' The function first removes any data points that are considered outliers
#' based on a given quantile threshold (95%).
#'
#' It then uses the remaining data points to calculate the radius of the bounding
#' circle. The function returns a data frame containing the bout label and the
#' calculated radius for each bout.
#'
#' Outliered data points are excluded from the radius calculation but are included in
#' subsequent functions that assess GPS completeness. They are also returned from
#' these functions with the original data and all new variables.
#'
#' This function then evaluates whether the GPS data for each bout has sufficient
#' coverage and data points to be considered complete.
#'
#' @return A data frame with categorized bouts.
#'
#' @examples
#' # Generate example data
#' walk_bouts <- data.frame(
#'   bout = c(1, 2, 3, 4, 5),
#'   activity_counts = c(500, 1000, 2000, 3000, 4000),
#'   speed = c(4, 5, 6, 7, 8)
#' )
#'
#' bout_radii <- data.frame(
#'   bout = c(1, 2, 3, 4, 5),
#'   bout_radius = c(10, 20, 30, 40, 50)
#' )
#'
#' gps_completeness <- data.frame(
#'   bout = c(1, 2, 3, 4, 5),
#'   complete_gps = c(TRUE, TRUE, FALSE, FALSE, TRUE)
#' )
#'
#' # Categorize bouts
#' categorized_bouts <- generate_bout_category(walk_bouts, bout_radii, gps_completeness, 50, 2500, 3, 6)
#'
#' @export
#'

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


outlier_gps_points <- function(lat_long, dwellbout_radii_quantile){
  # outlier gps points that are above the 95% percentile of summed distances
  distance_sum <- sp::SpatialPoints(coords = cbind(long = lat_long$longitude, lat = lat_long$latitude)) %>%
    sp::spDists(., longlat = TRUE) %>%
    colSums()
  points_to_keep <- distance_sum < quantile(distance_sum, dwellbout_radii_quantile)[[1]][1]
  lat_long <- cbind(lat_long, points_to_keep) %>% dplyr::filter(points_to_keep==TRUE)
  return(lat_long)
}

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
