# The turnover model is an explicit modelling assumption, not a reconstruction
# of actual investor positions. See the help page for the complete recurrence.
estimate_chip_distribution <- function(
    data,
    date_col = "trade_date",
    high_col = "high",
    low_col = "low",
    close_col = "close",
    turnover_col = "turnover_rate",
    volume_col = "vol",
    amount_col = "amount",
    adjustment_col = NULL,
    price_step = 0.01,
    price_method = c("vwap", "typical", "close", "uniform"),
    turnover_transform = c("exponential", "linear"),
    initial_distribution = NULL
) {
  price_method <- match.arg(price_method)
  turnover_transform <- match.arg(turnover_transform)
  columns <- list(date_col = date_col, high_col = high_col, low_col = low_col,
                  close_col = close_col, turnover_col = turnover_col,
                  volume_col = volume_col, amount_col = amount_col,
                  adjustment_col = adjustment_col)
  for (name in names(columns)) {
    .chip_column(columns[[name]], name, optional = name == "adjustment_col")
  }
  required <- c(date_col, high_col, low_col, close_col, turnover_col)
  if (price_method == "vwap") required <- c(required, volume_col, amount_col)
  if (!is.null(adjustment_col)) required <- c(required, adjustment_col)
  if (anyDuplicated(required)) {
    .chip_error("Required input columns must refer to distinct columns.")
  }
  .chip_frame(data, required)
  .chip_scalar(price_step, "price_step", positive = TRUE)
  code <- if ("ts_code" %in% names(data)) unique(.chip_stock(data$ts_code)) else NA_character_
  dates <- .chip_dates(data[[date_col]], date_col)
  if (anyDuplicated(dates)) .chip_error("`", date_col, "` must contain unique trading dates.")
  ordering <- order(dates)
  data <- data[ordering, , drop = FALSE]
  dates <- dates[ordering]
  n <- nrow(data)
  low <- .chip_number(data[[low_col]], low_col)
  high <- .chip_number(data[[high_col]], high_col)
  close <- .chip_number(data[[close_col]], close_col)
  rate <- .chip_number(data[[turnover_col]], turnover_col)
  if (any(low <= 0 | high <= 0 | close <= 0)) {
    .chip_error("High, low, and close prices must be positive.")
  }
  if (any(high < low)) .chip_error("Every daily high must be greater than or equal to its low.")
  tolerance <- 1e-6 * pmax(1, high)
  if (any(close < low - tolerance | close > high + tolerance)) {
    .chip_error("Every close must lie between its daily low and high.")
  }
  if (any(rate < 0)) .chip_error("`", turnover_col, "` cannot contain negative values.")
  if (turnover_transform == "linear" && any(rate > 100)) {
    .chip_error("`", turnover_col, "` exceeds 100%. Use the exponential model instead.")
  }

  # Retention is computed directly: 1 - (1 - exp(-r)) loses tiny survivals.
  retention <- if (turnover_transform == "exponential") exp(-rate / 100) else 1 - rate / 100
  replacement <- if (turnover_transform == "exponential") -expm1(-rate / 100) else rate / 100
  raw_transaction <- if (price_method == "close") close else low / 3 + high / 3 + close / 3
  vwap_rounding_adjusted <- rep(FALSE, n)
  if (price_method == "vwap") {
    volume <- .chip_number(data[[volume_col]], volume_col)
    amount <- .chip_number(data[[amount_col]], amount_col)
    if (any(volume < 0 | amount < 0)) .chip_error("Volume and amount cannot be negative.")
    needed <- replacement > 0
    if (is.null(initial_distribution)) needed[1L] <- TRUE
    valid <- volume > 0 & amount > 0
    if (any(!valid & needed)) {
      .chip_error("Positive volume and amount are required whenever VWAP is needed.")
    }
    if (any((volume == 0) != (amount == 0))) {
      .chip_error("Volume and amount must be zero together on non-trading rows.")
    }
    raw_transaction <- rep(NA_real_, n)
    raw_transaction[valid] <- (amount[valid] / volume[valid]) * 10
    if (any(!is.finite(raw_transaction[valid]))) .chip_error("Computed VWAP is not finite.")
    outside <- valid & (raw_transaction < low - tolerance | raw_transaction > high + tolerance)
    if (any(outside)) {
      .chip_error("Calculated VWAP is outside the daily low-high range on ",
                  sum(outside), " row(s); check volume/amount units and joined data.")
    }
    vwap_rounding_adjusted <- valid & (raw_transaction < low | raw_transaction > high)
    raw_transaction[valid] <- pmin(high[valid], pmax(low[valid], raw_transaction[valid]))
  }

  factor_ratio <- rep(1, n)
  if (!is.null(adjustment_col)) {
    factor <- .chip_number(data[[adjustment_col]], adjustment_col)
    if (any(factor <= 0)) .chip_error("Adjustment factors must be positive.")
    factor_ratio <- factor / factor[n]
    if (any(!is.finite(factor_ratio) | factor_ratio <= 0)) {
      .chip_error("Adjustment-factor ratios exceed the supported numeric range.")
    }
  }
  low <- low * factor_ratio
  high <- high * factor_ratio
  close <- close * factor_ratio
  transaction <- raw_transaction * factor_ratio
  if (any(!is.finite(c(low, high, close))) || any(c(low, high, close) <= 0) ||
      any(!is.finite(transaction[!is.na(transaction)]))) {
    .chip_error("Adjusted prices exceed the supported numeric range.")
  }

  initial <- NULL
  if (!is.null(initial_distribution)) {
    .chip_frame(initial_distribution, c("price", "weight"), "initial_distribution")
    initial <- list(price = .chip_number(initial_distribution$price, "initial_distribution$price"),
                    weight = .chip_number(initial_distribution$weight, "initial_distribution$weight"))
    if (any(initial$price <= 0) || any(initial$weight < 0) ||
        !is.finite(sum(initial$weight)) || sum(initial$weight) <= 0) {
      .chip_error("Initial prices must be positive and weights non-negative with a finite positive sum.")
    }
    initial$weight <- initial$weight / sum(initial$weight)
  }
  min_price <- min(c(low, if (!is.null(initial)) initial$price))
  max_price <- max(c(high, if (!is.null(initial)) initial$price))
  if (price_step <= .Machine$double.eps * max_price * 4) {
    .chip_error("`price_step` is too small for the magnitude of the input prices.")
  }
  origin <- floor(min_price / price_step) * price_step
  if (origin <= 0) origin <- min_price
  size <- ceiling((max_price - origin) / price_step) + 1
  if (!is.finite(size) || size > 1000000) {
    .chip_error("The grid would exceed 1,000,000 bins; increase `price_step`.")
  }
  grid <- origin + (seq_len(as.integer(size)) - 1) * price_step
  if (any(!is.finite(grid)) || any(diff(grid) <= 0)) {
    .chip_error("The requested price grid is not numerically representable.")
  }
  point_index <- function(price) pmax(1L, pmin(length(grid), as.integer(round((price - origin) / price_step)) + 1L))
  weights <- numeric(length(grid))
  deposit <- function(day, mass) {
    if (price_method == "uniform" && high[day] > low[day]) {
      first <- max(1L, as.integer(floor((low[day] - origin) / price_step - 0.5)) + 1L)
      last <- min(length(grid), as.integer(ceiling((high[day] - origin) / price_step + 0.5)) + 1L)
      indices <- seq.int(first, last)
      overlaps <- pmax(0, pmin(high[day], grid[indices] + price_step / 2) -
                           pmax(low[day], grid[indices] - price_step / 2))
      total <- sum(overlaps)
      if (!is.finite(total) || total <= 0) .chip_error("Cannot represent the daily uniform distribution.")
      weights[indices] <<- weights[indices] + mass * overlaps / total
    } else {
      index <- point_index(transaction[day])
      weights[index] <<- weights[index] + mass
    }
  }
  initialized <- rep(FALSE, n)
  applied <- replacement
  if (is.null(initial)) {
    deposit(1L, 1)
    initialized[1L] <- TRUE
    applied[1L] <- 0
    first_update <- 2L
  } else {
    indices <- point_index(initial$price)
    for (i in seq_along(indices)) weights[indices[i]] <- weights[indices[i]] + initial$weight[i]
    first_update <- 1L
  }
  if (first_update <= n) {
    for (day in seq.int(first_update, n)) {
      weights <- weights * retention[day]
      if (replacement[day] > 0) deposit(day, replacement[day])
    }
  }
  weights <- weights / sum(weights)
  kept <- weights > 0
  distribution <- data.frame(price = grid[kept], weight = weights[kept], percent = weights[kept] * 100)
  interval <- .chip_quantiles(distribution$price, distribution$weight, c(0.05, 0.5, 0.95))
  last_close <- close[n]
  # Treat only floating-point equality as break-even; coarse price bins still
  # imply an approximation that is explained in the documentation.
  equal <- abs(distribution$price - last_close) <=
    8 * .Machine$double.eps * pmax(1, abs(distribution$price), abs(last_close))
  profit <- sum(distribution$weight[distribution$price < last_close & !equal])
  breakeven <- sum(distribution$weight[equal])
  loss <- sum(distribution$weight[distribution$price > last_close & !equal])
  peak <- which.max(distribution$weight)
  update_days <- seq_len(n) >= first_update
  initial_weight <- prod(retention[update_days])
  capital_changed <- rep(FALSE, n)
  if ("float_share" %in% names(data)) {
    floating <- .chip_number(data$float_share, "float_share")
    if (any(floating <= 0)) .chip_error("`float_share` must be positive.")
    if (n > 1L) capital_changed[-1L] <- abs(diff(floating)) / floating[-n] > 1e-6
    if (any(capital_changed)) {
      warning("Circulating shares changed; issuance, unlocks and repurchases are not modelled.", call. = FALSE)
    }
  }
  result_summary <- data.frame(
    ts_code = code, start_date = dates[1L], end_date = dates[n], observations = n,
    last_close = last_close, average_cost = sum(distribution$price * distribution$weight),
    median_cost = interval[2L], peak_price = distribution$price[peak],
    peak_percent = distribution$percent[peak], profit_ratio = profit,
    profit_percent = profit * 100, breakeven_ratio = breakeven, loss_ratio = loss,
    cost_low_90 = interval[1L], cost_high_90 = interval[3L],
    concentration_90 = ((interval[3L] - interval[1L]) / interval[3L]) /
      (1 + interval[1L] / interval[3L]),
    cumulative_turnover_percent = sum(rate[update_days]), history_coverage = 1 - initial_weight,
    initialization_weight = initial_weight, row.names = NULL
  )
  diagnostics <- data.frame(
    trade_date = dates, turnover_rate = rate, replacement_fraction = replacement,
    applied_replacement_fraction = applied, retention = retention,
    transaction_price = transaction, raw_transaction_price = raw_transaction,
    adjustment_ratio = factor_ratio, vwap_outside_range = rep(FALSE, n),
    vwap_rounding_adjusted = vwap_rounding_adjusted,
    initialized_here = initialized, capital_changed = capital_changed
  )
  structure(list(distribution = distribution, summary = result_summary,
                 diagnostics = diagnostics,
                 settings = c(columns, list(price_step = price_step, price_method = price_method,
                   turnover_transform = turnover_transform,
                   initialization = if (is.null(initial)) "first_day" else "supplied",
                   price_basis = "last_trading_day", grid_origin = origin))),
            class = "chip_distribution")
}
