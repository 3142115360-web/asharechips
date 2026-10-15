.chip_error <- function(...) stop(..., call. = FALSE)

.chip_column <- function(x, argument, optional = FALSE) {
  if (optional && is.null(x)) return(invisible(NULL))
  if (!is.character(x) || length(x) != 1L || is.na(x) ||
      !nzchar(trimws(x))) {
    .chip_error("`", argument, "` must be one non-empty column name.")
  }
  invisible(x)
}

.chip_frame <- function(data, required, argument = "data") {
  if (!is.data.frame(data) || nrow(data) == 0L) {
    .chip_error("`", argument, "` must be a non-empty data frame.")
  }
  if (is.null(names(data)) || anyNA(names(data)) ||
      any(!nzchar(names(data))) || anyDuplicated(names(data))) {
    .chip_error("`", argument, "` must have unique, non-empty column names.")
  }
  missing <- setdiff(required, names(data))
  if (length(missing)) {
    .chip_error("`", argument, "` is missing required columns: ",
                paste(missing, collapse = ", "), ".")
  }
  invisible(data)
}

.chip_number <- function(x, name) {
  if (is.factor(x)) x <- as.character(x)
  if ((!is.numeric(x) && !is.character(x)) || is.object(x) ||
      !is.null(dim(x))) {
    .chip_error("`", name, "` must be a numeric vector or numeric text.")
  }
  result <- suppressWarnings(as.numeric(x))
  if (anyNA(result) || any(!is.finite(result))) {
    .chip_error("`", name, "` must contain only finite numeric values.")
  }
  result
}

.chip_scalar <- function(x, name, positive = FALSE) {
  if (!is.numeric(x) || is.object(x) || length(x) != 1L ||
      is.na(x) || !is.finite(x) || (positive && x <= 0)) {
    .chip_error("`", name, "` must be one ",
                if (positive) "positive, " else "", "finite number.")
  }
  x
}

.chip_dates <- function(x, name = "trade_date") {
  if (inherits(x, "Date")) {
    text <- format(x, "%Y%m%d")
  } else {
    if (is.factor(x)) x <- as.character(x)
    if ((!is.character(x) && !is.numeric(x)) || is.object(x) ||
        !is.null(dim(x))) {
      .chip_error("`", name, "` must contain Date, YYYYMMDD, or YYYY-MM-DD values.")
    }
    text <- as.character(x)
    valid_shape <- !is.na(text) &
      (grepl("^[0-9]{8}$", text) | grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", text))
    if (any(!valid_shape)) {
      .chip_error("`", name, "` must contain valid YYYYMMDD or YYYY-MM-DD dates.")
    }
    text <- gsub("-", "", text, fixed = TRUE)
  }
  parsed <- suppressWarnings(as.Date(text, format = "%Y%m%d"))
  if (anyNA(parsed) || any(format(parsed, "%Y%m%d") != text)) {
    .chip_error("`", name, "` contains an invalid calendar date.")
  }
  text
}

.chip_stock <- function(x, name = "ts_code", single = TRUE) {
  if (is.factor(x)) x <- as.character(x)
  if (!is.character(x) || anyNA(x) || any(!nzchar(trimws(x)))) {
    .chip_error("`", name, "` must contain non-empty stock codes.")
  }
  if (single && length(unique(x)) != 1L) {
    .chip_error("`", name, "` must identify exactly one stock.")
  }
  x
}

.chip_quantiles <- function(price, weight, probabilities) {
  cumulative <- cumsum(weight / sum(weight))
  cumulative[length(cumulative)] <- 1
  vapply(probabilities, function(p) price[which(cumulative >= p)[1L]], numeric(1))
}
