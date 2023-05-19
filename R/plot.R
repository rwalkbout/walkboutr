generate_bout_plot <- function(walk_bouts, ..., collated_arguments = NULL){
  # collated_arguments <- collate_arguments(..., collated_arguments=collated_arguments)
  leading_minutes = 8
  trailing_minutes = 12
  gps_target_size = 0.25
  dwellbout_radii_quantile <- .95
  max_dwellbout_radii_ft <- 66
  active_counts_per_epoch_min <- 500
  min_gps_obs_within_bout <- 5
  min_gps_coverage_ratio <- 0.2
  local_time_zone <- "US/Pacific"

  bouts <- process_accelerometry_counts_into_bouts(accelerometry_counts)
  gps_epochs <- process_gps_data_into_gps_epochs(gps_data)
  walk_bouts <- bouts %>%
    dplyr::left_join(gps_epochs, by = "time") %>%
    dplyr::arrange(time) %>%
    dplyr::mutate(bout = ifelse(bout==0,NA,bout))

  # if there are no bouts, just return the data
  if(sum(is.na(walk_bouts$bout)) == nrow(walk_bouts)){
    return(walk_bouts)
  } else{
    bout_radii <- generate_bout_radius(walk_bouts,dwellbout_radii_quantile) # returns df: bout, bout_radius (numer)
    gps_completeness <- evaluate_gps_completeness(walk_bouts,min_gps_obs_within_bout,min_gps_coverage_ratio) # returns df: bout, complete_gps (T/F), median_speed

  all_bouts <- walk_bouts %>%
    dplyr::left_join(gps_completeness, by = c("bout")) %>%
    dplyr::left_join(bout_radii, by = c("bout")) %>%
    dplyr::filter(!is.na(bout)) %>%
    dplyr::select(c("latitude", "longitude", "bout_radius", "complete_gps", "bout","time", "activity_counts"))

  for(b in all_bouts$bout){
    df <- all_bouts %>%
      dplyr::filter(bout == b) %>%
      dplyr::select(-c("bout"))
    bout_radius <- max(df$bout_radius)
    if(max_dwellbout_radii_ft > bout_radius){
      plot_dat_b <- data.frame(x0 = 1:(max_dwellbout_radii_ft*2.2), y0 = 1:(max_dwellbout_radii_ft*2.2)) %>% dplyr::mutate(alpha = 0.2)} else{
        plot_dat_b <- data.frame(x0 = 1:(bout_radius*2.2), y0 = 1:(bout_radius*2.2)) %>% dplyr::mutate(alpha = 0.2)
      }
    colors <- list(threshold = "skyblue4", data_radius = "palegreen4")
    # circle plotting code
    p <- ggplot2::ggplot() +
      ggplot2::coord_fixed() +
      ggplot2::theme_void()
    thresh_circle <- ggforce::geom_circle(data = plot_dat_b, aes(x0=0, y0=0, r = max_dwellbout_radii_ft),
                                          color = colors$threshold, fill = colors$threshold, show.legend = TRUE)
    bout_circle <-  ggforce::geom_circle(aes(x0=0, y0=0, r = bout_radius),
                                         color = colors$data_radius, fill = colors$data_radius, show.legend = TRUE, data = plot_dat_b)
    if(any(is.na(df$complete_gps))){
      if(max_dwellbout_radii_ft>bout_radius) {
        circles <- p +
          thresh_circle +
          bout_circle
        title <- paste0("Dwell Bout (radius = ", bout_radius %>% round(2), " feet)")
        title_color <- colors$threshold } else{
          circles <- p +
            bout_circle +
            thresh_circle
          title <- paste0("Non-Dwell Bout (radius = ", bout_radius %>% round(2), " feet)")
          title_color <- colors$data_radius
        }
    } else{
      circles <- p + thresh_circle
      title <- paste0("Incomplete GPS Coverage")
      title_color <- colors$threshold
    }
    ## ACCELEROMETRY PLOT
    min_n <- min(as.numeric(df$time))
    start <- lubridate::with_tz(min_n, tz = local_time_zone)- lubridate::minutes(leading_minutes)
    max_n <- max(as.numeric(df$time))
    end <- lubridate::with_tz(max_n, tz = local_time_zone) + lubridate::minutes(trailing_minutes)

    df <- df %>%
      dplyr::mutate(active = ifelse(activity_counts > active_counts_per_epoch_min, "high", "low")) %>%
      dplyr::mutate(time = lubridate::ymd_hms(time)) %>%
      dplyr::filter(time > start) %>%
      dplyr::filter(time < end)
    xmax <- end
    xmin <- start + (1 - gps_target_size)*(end - start)
    y_low <- 0
    y_high <- max(walk_bouts$activity_counts)*1.2
    ymax <- y_high
    ymin <- (1 - gps_target_size) * y_high
    plot <- ggplot(walk_bouts, aes(x = time, y = activity_counts)) +
      geom_point() +
      geom_hline(yintercept=active_counts_per_epoch_min, linetype="dashed", color = "darksalmon") +
      xlim(as.POSIXct(start), as.POSIXct(end)) +
      ylim(y_low, y_high) +
      geom_text(aes(end, active_counts_per_epoch_min, label = "Active", size = 12)) +
      geom_line() +
      ggtitle(paste(title)) +
      labs(x = "Time",
           y = "Accelerometer Counts") +
      theme_bw() +
      annotation_custom(ggplotGrob(circles), xmin = xmin, xmax = end, ymin = ymin, ymax = ymax)
  }
  return(plot)

} }
