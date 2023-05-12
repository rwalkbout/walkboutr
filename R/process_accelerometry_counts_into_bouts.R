#' Convert accelerometry counts into bouts of physical activity
#'
#' The input schema for the accelerometry data is `time` and `activity_counts`.
#' - `time` should be a column in date-time format, in the UTC time zone, with no null values.
#' - `activity_counts` should be a positive numeric column with no null values.
#'
#' @param accelerometry_counts Raw accelerometry data with the expected schema.
#'
#' @return A data frame of bouts.
#' @export
#'
#'

process_accelerometry_counts_into_bouts <- function(accelerometry_counts, ..., collated_arguments = NULL) {
  collated_arguments <- collate_arguments(..., collated_arguments = collated_arguments)
  print('processing accelerometry counts')
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

identify_bouts <- function(accelerometry_counts, maximum_number_consec_inactive_epochs_in_bout, active_counts_per_epoch_min, minimum_bout_length){

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

identify_non_wearing_periods <- function(accelerometry_counts, non_wearing_min_threshold_epochs){
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

identify_complete_days <- function(accelerometry_counts, min_wearing_hours_per_day, epoch_length, local_time_zone){
  min_wearing_epochs_per_day <- min_wearing_hours_per_day/epoch_length
  # max_non_wearing_per_day <- 24-min_wearing_hours_per_day
  complete_days_df <- accelerometry_counts %>%
    dplyr::mutate(date = lubridate::as_date(time, tz = local_time_zone)) %>%
    dplyr::group_by(date) %>%
    dplyr::summarise(total_wearing_epochs_whole_day = min_wearing_epochs_per_day - sum(non_wearing)) %>%
    # dplyr::summarise(total_non_wearing_epochs_whole_day = sum(non_wearing)) %>%
    dplyr::mutate(complete_day = total_wearing_epochs_whole_day >= min_wearing_epochs_per_day) %>%
    # dplyr::mutate(complete_day = total_non_wearing_epochs_whole_day <= max_non_wearing_per_day) %>%
    # dplyr::select(-c(total_non_wearing_epochs_whole_day))
    dplyr::select(-c(total_wearing_epochs_whole_day))
  accelerometry_counts <- accelerometry_counts %>%
    dplyr::mutate(date = lubridate::as_date(time)) %>%
    dplyr::left_join(complete_days_df, by = c("date")) %>%
    dplyr::select(-c("date"))
  return(accelerometry_counts)
}


