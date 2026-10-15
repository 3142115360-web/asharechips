test_that("Tushare-shaped data produces a normalized, sorted distribution", {
  daily <- data.frame(
    ts_code = rep("000001.SZ", 3),
    trade_date = c("20260106", "20260102", "20260105"),
    high = c(12, 10, 11),
    low = c(12, 10, 11),
    close = c(12, 10, 11),
    vol = c(100, 100, 100),
    amount = c(120, 100, 110),
    turnover_rate = c(30, 0, 20)
  )

  result <- estimate_chip_distribution(daily)
  expected_average <-
    10 * exp(-0.5) +
    11 * (1 - exp(-0.2)) * exp(-0.3) +
    12 * (1 - exp(-0.3))

  expect_s3_class(result, "chip_distribution")
  expect_equal(sum(result$distribution$weight), 1, tolerance = 1e-12)
  expect_equal(result$summary$ts_code, "000001.SZ")
  expect_equal(result$summary$start_date, "20260102")
  expect_equal(result$summary$end_date, "20260106")
  expect_equal(result$summary$average_cost, expected_average, tolerance = 1e-12)
  expect_equal(result$summary$history_coverage, 1 - exp(-0.5), tolerance = 1e-12)
  expect_false(any(result$diagnostics$vwap_outside_range))
})

test_that("linear turnover rejects rates over 100", {
  daily <- data.frame(
    trade_date = c("20260102", "20260105"),
    high = c(10, 11),
    low = c(10, 11),
    close = c(10, 11),
    turnover_rate = c(0, 150)
  )

  expect_error(
    estimate_chip_distribution(
      daily,
      price_method = "typical",
      turnover_transform = "linear"
    ),
    "exceeds 100%"
  )
})

test_that("a mixed stock-code data frame is rejected", {
  daily <- data.frame(
    ts_code = c("000001.SZ", "000002.SZ"),
    trade_date = c("20260102", "20260105"),
    high = c(10, 11),
    low = c(10, 11),
    close = c(10, 11),
    turnover_rate = c(0, 20)
  )

  expect_error(
    estimate_chip_distribution(daily, price_method = "typical"),
    "exactly one stock"
  )
})
