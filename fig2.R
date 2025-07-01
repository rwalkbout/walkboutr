## Paper figure 2
## Accelerometer counts by time with a highlighted period of interest

library(tidyverse)

counts <- data.frame(activity_counts = c(0, 50, 70, 200, 70, 300, 600, 510, 700, 750, 700, 800, 775, 675,
                                                       800, 600, 400, 550, 450, 790, 650, 550, 400, 200, 50, 50, 0, 0))
time <- seq(lubridate::ymd_hms("2023-04-07 08:00:30"), length.out = nrow(counts), by = "30 sec")
accelerometry_counts <- cbind(counts, time)
min <- accelerometry_counts$time[7]
max <- accelerometry_counts$time[22]
ggplot2::ggplot(accelerometry_counts, ggplot2::aes(x=time, y=activity_counts)) +
          ggplot2::annotate('rect', xmin=min, xmax=max, ymin=0, ymax=800, alpha=.6, fill = "gray") +
          ggplot2::geom_point() +
          ggplot2::geom_line() +
          ggplot2::geom_hline(yintercept=500, linetype="dashed", color = "#0084A4", linewidth = 2) +
          ggplot2::labs(x = "Time",
                        y = "Accelerometer Counts",
                        title = "Accelerometer Counts by Time") +
          ggplot2::theme_bw() +
          ggplot2::theme(plot.title = ggplot2::element_text(hjust=0.5))