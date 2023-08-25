#' Process Accelerometry Counts into Bouts
#'
#' This function processes accelerometry counts into bouts of activity and
#' returns those bouts as well as flags for whether the individual was wearing
#' their device and if the wearing day can be considered complete
#'
#' The input schema for the accelerometry data is `time` and `activity_counts`.
#' - `time` should be a column in date-time format, in the UTC time zone, with no null values.
#' - `activity_counts` should be a positive numeric column with no null values.
#'
#' @param accelerometry_counts A data frame with two columns: time and activity counts (CPE, counts per epoch)
#' @param ... Additional arguments to be passed to the function.
#' @param collated_arguments An optional list of previously collated arguments.
#'
#' @return A list of processed data frames containing identified walk bouts, non-wearing periods,
#' and complete days, based on the provided accelerometry counts and processing parameters.
#'
#' @details This function processes accelerometry counts into bouts of activity.
#' The function first validates the input data in the first step.
#' In the second step, the function identifies bouts of activity based on a
#' specified minimum number of active counts per epoch, a maximum number of
#' consecutive inactive epochs allowed within a bout, and a minimum bout length.
#' In the third step, the function identifies non-wearing periods based on a
#' specified threshold of consecutive epochs with 0 activity counts.
#' In the fourth step, the function identifies complete days of wearing the
#' accelerometer based on a specified minimum number of hours of wearing and
#' the epoch length. The returned list includes information about each complete
#' day, including the start and end times of each day, the duration of the day
#' in seconds, the number of epochs, the total number of cpm for the day, and
#' the bouts of activity within the day.
#'
#' @export
process_accelerometry_counts_into_bouts <- function(accelerometry_counts, ..., collated_arguments = NULL) {
  collated_arguments <- collate_arguments(..., collated_arguments = collated_arguments)
  # Step 1: validate data
  validate_accelerometry_data(accelerometry_counts)
  # Step 2: Identify bouts
  accelerometry_counts <- identify_bouts(accelerometry_counts,
                                         collated_arguments$maximum_number_consec_inactive_epochs_in_bout,
                                         collated_arguments$active_counts_per_epoch_min,
                                         collated_arguments$minimum_bout_length)
  # Step 3: Identify nonwearing periods
  accelerometry_counts <- identify_non_wearing_periods(accelerometry_counts,
                                                       collated_arguments$non_wearing_min_threshold_epochs)
  # Step 4: Identify complete days
  bouts <- identify_complete_days(accelerometry_counts,
                                  collated_arguments$min_wearing_hours_per_day,
                                  collated_arguments$epoch_length,
                                  collated_arguments$local_time_zone)
  return(bouts)
}



#' Run Length Encoding:
#'
#' A function that runs a normal run length encoding and adds some extra variables for use in calculations.
#'
#' @param x a vector to run the function on
#'
#' @returns a data.frame with columns for lengths, values, end, and begin
run_length_encode <- function(x){
  # running a normal run length encoding and adding some extra variables for use in calculations
  rle_df <- with(rle(as.numeric(x)),
                 data.frame(dplyr::tibble(
                   "lengths"  = lengths,
                   "values" = values,
                   "end" = cumsum(lengths),
                   "begin" = (end-lengths)+1)))
  return(rle_df)
}



#' Identify Bouts:
#'
#' @param accelerometry_counts A data frame containing accelerometry counts and times
#' @param maximum_number_consec_inactive_epochs_in_bout Maximum number of consecutive inactive epochs in a bout without ending the bout
#' @param active_counts_per_epoch_min Minimum accelerometer counts for an epoch to be considered active (vs. inactive)
#' @param minimum_bout_length Minimum number of epochs for a period of activity to be considered as a potential bout
#'
#' @returns A data frame with the same columns as the input data frame \code{accelerometry_counts},
#' but with a new column named \code{bout} that indicates whether each epoch is part of a bout
#' (in which case it gets a bout number assigned) or not (0)
#'
#' @details This function partitions the accelerometry data into bouts of activity and non-bouts by
#' first identifying all epochs that are definitely not part of bouts. Then, it uses run length encoding to
#' partition the data into potential bouts and non-bouts, and labels each potential bout as a bout or non-bout
#' based on whether it meets the criteria for bout length and the number of consecutive inactive epochs allowed.
#' Finally, the function adds a new column to the input data frame \code{accelerometry_counts} named \code{bout}
#' that indicates whether each epoch is part of a bout (1) or not (0).
identify_bouts <- function(accelerometry_counts, maximum_number_consec_inactive_epochs_in_bout, active_counts_per_epoch_min, minimum_bout_length){

  activity_counts <- inactive <- values <- maybe_bout <- bout <- time <- . <- NULL
  n_epochs_date <- non_wearing <- total_wearing_epochs_whole_day <- NULL
  # Identify all epochs that are definitely not part of bouts
    # if we have 4 or more epochs where the activity level is below our activity threshold
    # then the epoch at the left most edge of that window is definitely not part of a bout
    # we can identify these periods by making a boolean col that identifies all low activity periods
    # and then doing a rolling sum of that activity col with a window size of 4 to find a rolling sum
    # and labeling all epochs where that rolling sum is 4 as non-bout.
  non_bout_window <- maximum_number_consec_inactive_epochs_in_bout + 1
  accelerometry_counts <- accelerometry_counts %>%
    dplyr::mutate(bout = 0,
           inactive = activity_counts < active_counts_per_epoch_min,
           non_bout = data.table::frollsum(inactive, non_bout_window, fill = non_bout_window) == non_bout_window)
  # Use that identification to partition dataset into non bouts and maybe bouts using a run length encoding
  non_bout_rle <- run_length_encode(accelerometry_counts$non_bout) %>%
    dplyr::mutate(maybe_bout = 1-values)

  # Every sequence of epochs labeled maybe_bout will have a number of inactive periods at the end of the series equal to the
  # maximum number of consecutive inactive epochs in a bout.
  # So, we find all potential bouts by filtering to anything labeled maybe_bout with enough epochs to
  # meet our minimum bout length and account for trailing inactive periods.
  potential_bout_length <- minimum_bout_length + maximum_number_consec_inactive_epochs_in_bout
  potential_bouts <- non_bout_rle %>%
    dplyr::filter((lengths >= potential_bout_length) & (maybe_bout == 1))

  # Remove inactive and non_bout cols
  accelerometry_counts <- accelerometry_counts %>%
    dplyr::select(-c("inactive", "non_bout"))

  # If there are no potential bouts, return accelerometry_counts and all bout labels are NA
  if(nrow(potential_bouts) == 0){
    return(accelerometry_counts) }

  # Otherwise, label bouts
  num_bouts <- 0
  for (i in 1:nrow(potential_bouts)){
    row <- dplyr::slice(potential_bouts, i)
    start_ind <- row$begin
    end_ind <- row$end-maximum_number_consec_inactive_epochs_in_bout
    active_epochs <- accelerometry_counts %>%
      dplyr::slice(start_ind:end_ind) %>%
      dplyr::filter(activity_counts >= active_counts_per_epoch_min) %>%
      nrow()
    is_bout <- active_epochs >= minimum_bout_length
    if (is_bout){
      num_bouts <- num_bouts + 1
      accelerometry_counts <- accelerometry_counts %>%
        dplyr::mutate(bout = ifelse(dplyr::row_number() %in% (start_ind:end_ind), num_bouts, bout))
      }
    }
  return(accelerometry_counts)
}



#' Identify non-wearing periods:
#' This function identifies non-wearing periods in accelerometry data based on a
#' threshold of consecutive epochs with activity counts of 0.
#'
#' @param accelerometry_counts a data frame containing columns for time
#' (in POSIXct format) and activity_counts
#' @param non_wearing_min_threshold_epochs an integer value indicating the
#' minimum number of consecutive epochs with 0 activity counts that constitute a non-wearing period
#'
#' @returns a data frame with the same columns as the input data frame \code{accelerometry_counts},
#' but with a new column named \code{non_wearing} that indicates whether the
#' individual was wearing their accelerometer during a given period.
#'
#' @details
#' Identify periods where the accelerometer is not being worn based on the activity counts and a minimum threshold value.
identify_non_wearing_periods <- function(accelerometry_counts, non_wearing_min_threshold_epochs){
  activity_counts <- values <- NULL
  accelerometry_counts <- accelerometry_counts %>%
    dplyr::mutate(inactive = (activity_counts == 0),
           non_wearing = F)
  inactive_rle <- run_length_encode(accelerometry_counts$inactive)

  non_wearing <- inactive_rle %>%
    dplyr::filter(values == 1 & lengths >= non_wearing_min_threshold_epochs)

  if(nrow(non_wearing) == 0){
    return(accelerometry_counts) }

  for(i in 1:nrow(non_wearing)){
    row <- dplyr::slice(non_wearing, i)
    start_ind <- row$begin
    end_ind <- row$end
    accelerometry_counts <- accelerometry_counts %>%
      dplyr::mutate(non_wearing = dplyr::row_number() %in% (start_ind:end_ind))
  }
  return(accelerometry_counts)
}



#' Identify complete wearing days
#' This function identifies complete days based on accelerometry data by
#' calculating the total number of epochs worn per day and comparing it to the
#' minimum number of wearing epochs per day required to consider a day complete.
#'
#' @param accelerometry_counts A data frame containing accelerometry counts and non-wearing epochs.
#' @param min_wearing_hours_per_day Minimum number of hours of wearing time required for a day to be considered complete.
#' @param epoch_length The duration of an epoch in seconds.
#' @param local_time_zone The local time zone of the data. The data come in and are returned in UTC, but the local time zone is used to compute complete_days.
#'
#' @returns A data frame containing accelerometer counts, non-wearing epochs, and a binary variable indicating if the day is complete or not.
identify_complete_days <- function(accelerometry_counts, min_wearing_hours_per_day, epoch_length, local_time_zone){
  time <- . <- n_epochs_date <- non_wearing <- total_wearing_epochs_whole_day <- NULL
  min_wearing_epochs_per_day <- (min_wearing_hours_per_day*60*60)/epoch_length
  # max_non_wearing_per_day <- 24-min_wearing_hours_per_day
  complete_days_df <- accelerometry_counts %>%
    dplyr::mutate(date = lubridate::as_date(time, tz = local_time_zone)) %>%
    dplyr::group_by(date) %>%
    dplyr::summarise(n_epochs_date = nrow(.),
                     total_wearing_epochs_whole_day = n_epochs_date - sum(non_wearing)) %>%
    dplyr::mutate(complete_day = total_wearing_epochs_whole_day >= min_wearing_epochs_per_day) %>%
    # dplyr::mutate(complete_day = total_non_wearing_epochs_whole_day <= max_non_wearing_per_day) %>%
    # dplyr::select(-c(total_non_wearing_epochs_whole_day))
    dplyr::select(-c(total_wearing_epochs_whole_day))
  accelerometry_counts <- accelerometry_counts %>%
    dplyr::mutate(date = lubridate::as_date(time, tz = local_time_zone)) %>%
    dplyr::left_join(complete_days_df, by = c("date")) %>%
    dplyr::select(-c("date"))
  return(accelerometry_counts)
}


