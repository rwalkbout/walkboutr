#' Generate Bout Plot
#'
#' This function generates a plot of accelerometry counts and GPS radius for a specific bout.
#'
#' @param accelerometry_counts A data frame or tibble containing accelerometry counts.
#' @param gps_data A data frame or tibble containing GPS data.
#' @param bout_number The number of the bout to be plotted.
#' @param leading_minutes number of minutes before a bout starts that we want to plot
#' @param trailing_minutes number of minutes after a bout ends that we want to plot
#' @param gps_target_size proportional size of circle plot
#' @param ... Additional arguments to be passed to the function
#' @param collated_arguments A list of collated arguments
#'
#' @return A ggplot object representing the bout plot.
#'
#' @export
generate_bout_plot <- function(accelerometry_counts,gps_data,bout_number, leading_minutes = 8,
                               trailing_minutes = 12, gps_target_size = 0.25,
                               ..., collated_arguments = NULL){
  time <- bout <- activity_counts <- NULL
  b <- bout_number
  collated_arguments <- collate_arguments(..., collated_arguments=collated_arguments)

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
    bout_radii <- generate_bout_radius(walk_bouts,collated_arguments$dwellbout_radii_quantile) # returns df: bout, bout_radius (numer)
    gps_completeness <- evaluate_gps_completeness(walk_bouts,collated_arguments$min_gps_obs_within_bout,collated_arguments$min_gps_coverage_ratio) # returns df: bout, complete_gps (T/F), median_speed

  all_bouts <- walk_bouts %>%
    dplyr::left_join(gps_completeness, by = c("bout")) %>%
    dplyr::left_join(bout_radii, by = c("bout")) %>%
    dplyr::filter(!is.na(bout)) %>%
    dplyr::select(c("latitude", "longitude", "bout_radius", "complete_gps", "bout","time", "activity_counts"))

    df <- all_bouts %>%
      dplyr::filter(bout == b) %>%
      dplyr::select(-c("bout"))

    bout_radius <- max(df$bout_radius)
    # proportionally scale down the values to make plotting faster
      bout_thresh_ratio <- collated_arguments$max_dwellbout_radii_ft/bout_radius
      plot_bout_radius <- .1*bout_radius
      plot_max_dwellbout_radii_ft <- bout_thresh_ratio*plot_bout_radius

    if(collated_arguments$max_dwellbout_radii_ft > bout_radius){
      plot_dat_b <- data.frame(x0 = 1:(plot_max_dwellbout_radii_ft*2.2), y0 = 1:(plot_max_dwellbout_radii_ft*2.2)) %>% dplyr::mutate(alpha = 0.2)} else{
        plot_dat_b <- data.frame(x0 = 1:(plot_bout_radius*2.2), y0 = 1:(plot_bout_radius*2.2)) %>% dplyr::mutate(alpha = 0.2)
      }
    colors <- list(threshold = "skyblue4", data_radius = "palegreen4")
    # circle plotting code
    p <- ggplot2::ggplot() +
      ggplot2::coord_fixed() +
      ggplot2::theme_void()
    thresh_circle <- ggforce::geom_circle(data = plot_dat_b, ggplot2::aes(x0=0, y0=0, r = plot_max_dwellbout_radii_ft),
                                          color = colors$threshold, fill = colors$threshold, show.legend = TRUE)
    bout_circle <-  ggforce::geom_circle(data = plot_dat_b, ggplot2::aes(x0=0, y0=0, r = plot_bout_radius),
                                         color = colors$data_radius, fill = colors$data_radius, show.legend = TRUE)
    if(!(any(is.na(df$complete_gps)))){
      if(plot_max_dwellbout_radii_ft>plot_bout_radius) {
        circles <- p +
          thresh_circle +
          bout_circle
        title <- paste0("Dwell Bout (radius = ", plot_bout_radius %>% round(2), " feet)")
        title_color <- colors$threshold } else{
          circles <- p +
            bout_circle +
            thresh_circle
          title <- paste0("Non-Dwell Bout (radius = ", plot_bout_radius %>% round(2), " feet)")
          title_color <- colors$data_radius
        }
    } else{
      circles <- p + thresh_circle
      title <- paste0("Incomplete GPS Coverage")
      title_color <- colors$threshold
    }
    ## ACCELEROMETRY PLOT
    min_n <- min(as.numeric(df$time))
    start <- lubridate::with_tz(min_n, tz = collated_arguments$local_time_zone)- lubridate::minutes(leading_minutes)
    max_n <- max(as.numeric(df$time))
    end <- lubridate::with_tz(max_n, tz = collated_arguments$local_time_zone) + lubridate::minutes(trailing_minutes)

    df <- df %>%
      dplyr::mutate(active = ifelse(activity_counts > collated_arguments$active_counts_per_epoch_min, "high", "low")) %>%
      dplyr::mutate(time = lubridate::ymd_hms(time)) %>%
      dplyr::filter(time > start) %>%
      dplyr::filter(time < end)
    xmax <- end
    xmin <- start + (1 - gps_target_size)*(end - start)
    y_low <- 0
    y_high <- max(walk_bouts$activity_counts)*1.2
    ymax <- y_high
    ymin <- (1 - gps_target_size) * y_high
    plot <- ggplot2::ggplot(walk_bouts, ggplot2::aes(x = time, y = activity_counts)) +
      ggplot2::geom_point() +
      ggplot2::geom_hline(yintercept=collated_arguments$active_counts_per_epoch_min, linetype="dashed", color = "darksalmon") +
      ggplot2::xlim(as.POSIXct(start), as.POSIXct(end)) +
      ggplot2::ylim(y_low, y_high) +
      ggplot2::geom_text(ggplot2::aes(end, collated_arguments$active_counts_per_epoch_min, label = "Active", size = 12)) +
      ggplot2::geom_line() +
      ggplot2::ggtitle(paste(title)) +
      ggplot2::labs(x = "Time",
           y = "Accelerometer Counts") +
      ggplot2::theme_bw() +
      ggplot2::theme(legend.position = "none") +
      ggplot2::annotation_custom(ggplot2::ggplotGrob(circles), xmin = xmin, xmax = end, ymin = ymin, ymax = ymax)
  }
  return(plot)

}
