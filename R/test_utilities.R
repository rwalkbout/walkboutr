build_accelerometry_data <- function(){
  start <- as.POSIXct('2012-04-07',tz="UTC")
  end <- as.POSIXct('2012-04-08',tz="UTC")
  step <- 30 # by default, the seq function will treat this as seconds
  time <- seq(start, end, by=step)
  activity_counts <- (0:(length(time)-1))
  accelerometry_counts <- data.frame(time = time, activity_counts = activity_counts)
  return(accelerometry_counts)
}

