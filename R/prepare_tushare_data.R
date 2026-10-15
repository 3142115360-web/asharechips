# Offline preparation only. This function never requests or stores credentials.
prepare_tushare_data <- function(daily, daily_basic, adj_factor = NULL,
                                ts_code = NULL, as_of = NULL) {
  .chip_frame(daily, c("ts_code", "trade_date", "high", "low", "close", "vol", "amount"), "daily")
  .chip_frame(daily_basic, c("ts_code", "trade_date", "turnover_rate"), "daily_basic")
  if (!is.null(adj_factor)) .chip_frame(adj_factor, c("ts_code", "trade_date", "adj_factor"), "adj_factor")
  if (!is.null(ts_code)) {
    .chip_stock(ts_code)
    if (length(ts_code) != 1L) .chip_error("`ts_code` must be one stock code.")
  }
  if (!is.null(as_of)) {
    if (length(as_of) != 1L) .chip_error("`as_of` must be one date.")
    as_of <- .chip_dates(as_of, "as_of")
  }
  normalize <- function(table, name) {
    table$ts_code <- .chip_stock(table$ts_code, single = FALSE)
    table$trade_date <- .chip_dates(table$trade_date, paste0(name, "$trade_date"))
    if (!is.null(ts_code)) table <- table[table$ts_code == ts_code, , drop = FALSE]
    if (!is.null(as_of)) table <- table[table$trade_date <= as_of, , drop = FALSE]
    if (!nrow(table)) .chip_error("No matching rows remain in `", name, "`.")
    .chip_stock(table$ts_code)
    if (anyDuplicated(table[c("ts_code", "trade_date")])) {
      .chip_error("`", name, "` contains duplicate stock/date keys.")
    }
    table
  }
  daily <- normalize(daily, "daily")
  daily_basic <- normalize(daily_basic, "daily_basic")
  join_rows <- function(table, name) {
    if (!identical(unique(daily$ts_code), unique(table$ts_code))) {
      .chip_error("`", name, "` refers to a different stock.")
    }
    indices <- match(daily$trade_date, table$trade_date)
    if (anyNA(indices)) {
      .chip_error("`", name, "` has no matching row for ", sum(is.na(indices)),
                  " daily date(s); rows are never silently dropped.")
    }
    indices
  }
  selected <- c("ts_code", "trade_date", "high", "low", "close", "vol", "amount")
  # Preserve useful optional daily columns while reserving the authoritative
  # turnover, share-count and adjustment fields for the matching source table.
  optional <- setdiff(names(daily), c(selected, "turnover_rate", "float_share", "adj_factor"))
  result <- daily[c(selected, optional)]
  basic_indices <- join_rows(daily_basic, "daily_basic")
  result$turnover_rate <- .chip_number(daily_basic$turnover_rate[basic_indices], "turnover_rate")
  if ("float_share" %in% names(daily_basic)) {
    result$float_share <- .chip_number(daily_basic$float_share[basic_indices], "float_share")
  }
  if (!is.null(adj_factor)) {
    adj_factor <- normalize(adj_factor, "adj_factor")
    result$adj_factor <- .chip_number(adj_factor$adj_factor[join_rows(adj_factor, "adj_factor")], "adj_factor")
    if (any(result$adj_factor <= 0)) .chip_error("Adjustment factors must be positive.")
  }
  result <- result[order(result$trade_date), , drop = FALSE]
  rownames(result) <- NULL
  result
}
