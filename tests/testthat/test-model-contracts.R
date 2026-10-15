model_contract_data <- function(
    dates = c("20260102", "20260105"),
    prices = c(10, 12),
    turnover = c(0, 50),
    volume = c(100, 100),
    amount = prices * volume / 10
) {
  data.frame(
    ts_code = rep("000001.SZ", length(dates)),
    trade_date = dates,
    high = prices,
    low = prices,
    close = prices,
    vol = volume,
    amount = amount,
    turnover_rate = turnover,
    stringsAsFactors = FALSE
  )
}

weight_at <- function(result, price) {
  result$distribution$weight[match(price, result$distribution$price)]
}

test_that("the exponential recurrence has the documented analytic weights", {
  daily <- model_contract_data(turnover = c(0, 100))
  result <- estimate_chip_distribution(daily)

  retained <- exp(-1)
  expect_equal(weight_at(result, 10), retained, tolerance = 1e-12)
  expect_equal(weight_at(result, 12), -expm1(-1), tolerance = 1e-12)
  expect_equal(result$summary$average_cost, 10 * retained + 12 * -expm1(-1),
               tolerance = 1e-12)
  expect_equal(result$summary$history_coverage, -expm1(-1), tolerance = 1e-12)
  expect_equal(result$diagnostics$applied_replacement_fraction, c(0, -expm1(-1)),
               tolerance = 1e-12)
})

test_that("dates must be valid calendar dates in an unambiguous supported form", {
  bad_calendar <- model_contract_data()
  bad_calendar$trade_date[[1L]] <- "20260230"
  expect_error(estimate_chip_distribution(bad_calendar), "invalid calendar date")

  ambiguous_shape <- model_contract_data()
  ambiguous_shape$trade_date[[1L]] <- "2026-1-02"
  expect_error(estimate_chip_distribution(ambiguous_shape), "valid YYYYMMDD")
})

test_that("Tushare VWAP units and adjustment factors give the final-date basis", {
  daily <- model_contract_data(
    prices = c(10, 20),
    turnover = c(0, 50),
    amount = c(100, 200)
  )
  daily$adj_factor <- c(1, 2)

  result <- estimate_chip_distribution(
    daily,
    adjustment_col = "adj_factor",
    turnover_transform = "linear"
  )

  expect_equal(result$diagnostics$raw_transaction_price, c(10, 20))
  expect_equal(result$diagnostics$transaction_price, c(5, 20))
  expect_equal(result$summary$last_close, 20)
  expect_equal(weight_at(result, 5), 0.5, tolerance = 1e-12)
  expect_equal(weight_at(result, 20), 0.5, tolerance = 1e-12)
  expect_equal(result$summary$average_cost, 12.5, tolerance = 1e-12)

  bad_units <- model_contract_data(prices = c(9.5, 9.5), turnover = c(0, 0),
                                   amount = c(200, 95))
  bad_units$high <- c(10, 10)
  bad_units$low <- c(9, 9)
  expect_error(estimate_chip_distribution(bad_units), "outside the daily low-high range")
})

test_that("a supplied initial distribution is already on the final-date basis and updates on day one", {
  daily <- model_contract_data(prices = c(10, 20), turnover = c(50, 0))
  daily$adj_factor <- c(1, 2)
  initial <- data.frame(price = 7, weight = 1)

  result <- estimate_chip_distribution(
    daily,
    price_method = "close",
    adjustment_col = "adj_factor",
    initial_distribution = initial
  )

  retained <- exp(-0.5)
  expect_equal(weight_at(result, 7), retained, tolerance = 1e-12)
  expect_equal(weight_at(result, 5), -expm1(-0.5), tolerance = 1e-12)
  expect_equal(result$diagnostics$transaction_price[[1L]], 5)
  expect_equal(result$diagnostics$applied_replacement_fraction[[1L]], -expm1(-0.5),
               tolerance = 1e-12)
  expect_false(result$diagnostics$initialized_here[[1L]])
  expect_equal(result$summary$initialization_weight, retained, tolerance = 1e-12)
})

test_that("uniform placement uses cell-overlap mass, including partial edge cells", {
  daily <- data.frame(
    trade_date = "20260102",
    high = 11.2,
    low = 10.2,
    close = 10.7,
    turnover_rate = 0
  )
  result <- estimate_chip_distribution(daily, price_method = "uniform", price_step = 1)

  expect_equal(result$distribution$price, c(10, 11))
  expect_equal(result$distribution$weight, c(0.3, 0.7), tolerance = 1e-12)
  expect_equal(sum(result$distribution$weight), 1, tolerance = 1e-12)
})

test_that("zero-turnover rows may have zero volume and amount and do not alter chips", {
  daily <- model_contract_data(turnover = c(0, 0), volume = c(100, 0), amount = c(100, 0))
  result <- estimate_chip_distribution(daily)

  expect_equal(result$distribution$price, 10)
  expect_equal(result$distribution$weight, 1)
  expect_true(is.na(result$diagnostics$raw_transaction_price[[2L]]))
  expect_equal(result$summary$average_cost, 10)
})

test_that("profit is strictly below the last close and equality is reported separately", {
  daily <- model_contract_data(turnover = c(0, 50))
  result <- estimate_chip_distribution(daily, turnover_transform = "linear")

  expect_equal(result$summary$profit_ratio, 0.5, tolerance = 1e-12)
  expect_equal(result$summary$breakeven_ratio, 0.5, tolerance = 1e-12)
  expect_equal(result$summary$loss_ratio, 0, tolerance = 1e-12)
  expect_equal(result$summary$profit_ratio + result$summary$breakeven_ratio +
                 result$summary$loss_ratio, 1, tolerance = 1e-12)
})

test_that("Tushare-shaped tables are matched completely without silent row loss", {
  daily <- model_contract_data(
    dates = c("20260105", "20260102"),
    prices = c(12, 10),
    turnover = c(999, 999)
  )
  daily$float_share <- c(999, 999)
  daily$adj_factor <- c(999, 999)
  basic <- data.frame(
    ts_code = c("000001.SZ", "000001.SZ"),
    trade_date = c("20260102", "20260105"),
    turnover_rate = c(1, 2),
    float_share = c(100, 100)
  )
  factors <- data.frame(
    ts_code = c("000001.SZ", "000001.SZ"),
    trade_date = c("20260102", "20260105"),
    adj_factor = c(1, 2)
  )

  prepared <- prepare_tushare_data(daily, basic, factors)
  expect_equal(prepared$trade_date, c("20260102", "20260105"))
  expect_equal(prepared$turnover_rate, c(1, 2))
  expect_equal(prepared$float_share, c(100, 100))
  expect_equal(prepared$adj_factor, c(1, 2))
  expect_equal(nrow(prepared), nrow(daily))

  expect_error(
    prepare_tushare_data(daily, basic[-1L, , drop = FALSE], factors),
    "no matching row"
  )
  other_stock <- basic
  other_stock$ts_code <- "000002.SZ"
  expect_error(prepare_tushare_data(daily, other_stock), "different stock")
  expect_error(prepare_tushare_data(daily, basic, as_of = "2026-13-01"),
               "invalid calendar date")
})

test_that("plot accepts a caller-supplied x-axis label", {
  result <- estimate_chip_distribution(model_contract_data())
  file <- tempfile(fileext = ".pdf")
  grDevices::pdf(file)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_silent(plot(result, xlab = "Custom estimated share (%)"))
})

test_that("chip_mean_cost validates weights and returns a weighted cost", {
  expect_equal(chip_mean_cost(c(10, 20), c(1, 3)), 17.5)
  expect_error(chip_mean_cost(c(10, 20), 1), "equal lengths")
  expect_error(chip_mean_cost(c(10, 20), c(0, 0)), "finite positive sum")
  expect_error(chip_mean_cost(c(10, 20), c(1, -1)), "non-negative")
  expect_error(chip_mean_cost(c("ten", "20"), c(1, 1)), "finite numeric")
})

test_that("result methods expose the documented public data", {
  result <- estimate_chip_distribution(model_contract_data())
  expect_equal(summary(result), result$summary)
  expect_equal(as.data.frame(result), result$distribution)
  expect_output(print(result), "<chip_distribution>", fixed = TRUE)
  expect_output(print(result), "Estimated profitable chips", fixed = TRUE)
})

test_that("Date, numeric date, and factor-like numeric inputs are accepted", {
  dated <- model_contract_data()
  dated$trade_date <- as.Date(c("2026-01-02", "2026-01-05"))
  dated$turnover_rate <- factor(c("0", "50"))
  dated$adj_factor <- factor(c("1", "2"))
  result <- estimate_chip_distribution(dated, adjustment_col = "adj_factor",
                                       turnover_transform = "linear")
  expect_equal(result$summary$start_date, "20260102")
  expect_equal(result$summary$end_date, "20260105")
  expect_equal(result$diagnostics$transaction_price, c(5, 12))

  numeric_dates <- model_contract_data()
  numeric_dates$trade_date <- c(20260102, 20260105)
  expect_equal(estimate_chip_distribution(numeric_dates)$summary$end_date, "20260105")
})

test_that("public input validation rejects missing columns and invalid numeric data", {
  daily <- model_contract_data()
  expect_error(
    estimate_chip_distribution(daily[, setdiff(names(daily), "close")]),
    "missing required columns"
  )
  expect_error(estimate_chip_distribution(daily, high_col = "close"), "distinct columns")
  expect_error(estimate_chip_distribution(daily, date_col = ""), "non-empty column name")

  bad_rate <- daily
  bad_rate$turnover_rate <- c("zero", "1")
  expect_error(estimate_chip_distribution(bad_rate), "finite numeric")
  bad_amount <- daily
  bad_amount$amount[[2L]] <- -1
  expect_error(estimate_chip_distribution(bad_amount), "cannot be negative")
})

test_that("circulating-capital changes are flagged and cutoff dates filter offline tables", {
  daily <- model_contract_data()
  daily$float_share <- c(100, 120)
  expect_warning(
    result <- estimate_chip_distribution(daily),
    "Circulating shares changed"
  )
  expect_equal(result$diagnostics$capital_changed, c(FALSE, TRUE))

  raw_daily <- model_contract_data()
  basic <- raw_daily[c("ts_code", "trade_date", "turnover_rate")]
  prepared <- prepare_tushare_data(
    raw_daily,
    basic,
    as_of = as.Date("2026-01-03")
  )
  expect_equal(prepared$trade_date, "20260102")
  expect_equal(nrow(prepared), 1L)
})
