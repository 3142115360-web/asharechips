print.chip_distribution <- function(x, ...) {
  s <- x$summary
  cat("<chip_distribution>\n")
  if (!is.na(s$ts_code)) cat("  Stock: ", s$ts_code, "\n", sep = "")
  cat("  Period: ", s$start_date, " to ", s$end_date, " (", s$observations, " rows)\n", sep = "")
  cat("  Average cost: ", format(round(s$average_cost, 4), trim = TRUE), " CNY\n", sep = "")
  cat("  Last close: ", format(round(s$last_close, 4), trim = TRUE), " CNY\n", sep = "")
  cat("  Estimated profitable chips: ", format(round(s$profit_percent, 2), trim = TRUE), "%\n", sep = "")
  cat("  Initialization weight remaining: ", format(round(s$initialization_weight * 100, 2), trim = TRUE), "%\n", sep = "")
  invisible(x)
}

summary.chip_distribution <- function(object, ...) object$summary

as.data.frame.chip_distribution <- function(x, row.names = NULL, optional = FALSE, ...) {
  as.data.frame(x$distribution, row.names = row.names, optional = optional, ...)
}

plot.chip_distribution <- function(x, ..., col = "#4C78A8", close_col = "#D62728") {
  distribution <- x$distribution
  s <- x$summary
  args <- list(...)
  if (length(args) && (is.null(names(args)) || anyNA(names(args)) || any(!nzchar(names(args))))) {
    .chip_error("Additional plot arguments must be named.")
  }
  if (anyDuplicated(names(args)) || any(c("x", "y") %in% names(args))) {
    .chip_error("Plot arguments must be unique; `x` and `y` are set by the method.")
  }
  y_range <- range(c(distribution$price, s$last_close))
  if (diff(y_range) == 0) y_range <- y_range + c(-1, 1) * max(x$settings$price_step, y_range[1L] * 0.01)
  defaults <- list(x = distribution$percent, y = distribution$price, type = "n",
                   xlim = c(0, max(distribution$percent) * 1.05), ylim = y_range,
                   xlab = "Estimated chip share (%)", ylab = "Estimated cost (CNY)")
  defaults[names(args)] <- args
  do.call(graphics::plot, defaults)
  graphics::segments(0, distribution$price, distribution$percent, distribution$price, col = col, lwd = 2)
  graphics::abline(h = s$last_close, col = close_col, lty = 2)
  graphics::legend("topright", legend = paste0("Last close: ", format(round(s$last_close, 2), nsmall = 2)),
                   lty = 2, col = close_col, bty = "n")
  invisible(x)
}
