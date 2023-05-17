# library(hexSticker)
#
# # Define the colors to use in the sticker
# time <- as.POSIXct(c("2012-04-07 00:00:30", "2012-04-07 00:01:00", "2012-04-07 00:01:30", "2012-04-07 00:02:00", "2012-04-07 00:02:30", "2012-04-07 00:03:00", "2012-04-07 00:03:30", "2012-04-07 00:04:00", "2012-04-07 00:04:30", "2012-04-07 00:05:00", "2012-04-07 00:05:30", "2012-04-07 00:06:00", "2012-04-07 00:06:30", "2012-04-07 00:07:00", "2012-04-07 00:07:30", "2012-04-07 00:08:00", "2012-04-07 00:08:30", "2012-04-07 00:09:00"), tz="UTC")
# counts <- c(0, 25, 100, 500, 700, 800, 700, 700, 600, 650, 600, 800, 500, 600, 650, 500, 25, 25)
# df <- data.frame(times, counts)
# primary_color <- "#4e79a7"
#
# # Use ggplot to create the plot of time versus count data
# p <- ggplot2::ggplot(df, aes(x = times, y = counts)) +
#   ggplot2::geom_line(color = primary_color) +
#   ggplot2::theme_bw() +
#   ggplot2::theme(panel.background = element_rect(fill = 'transparent')) +
#   theme(axis.text.x=element_blank(), #remove x axis labels
#         axis.ticks.x=element_blank(), #remove x axis ticks
#         axis.text.y=element_blank(),  #remove y axis labels
#         axis.ticks.y=element_blank()  #remove y axis ticks
#   ) +
#   ggplot2::ylim(0, max(counts) + 50) +
#   labs(x = "time", y = "activity count")
#
# # Use the `hexSticker` function to create the logo
# logo <-
# sticker <- hexSticker::sticker(p,
#   package = " walkboutr ",
#   p_size=16, s_x=1, s_y=.75, s_width=1.1, s_height=.8
# )
