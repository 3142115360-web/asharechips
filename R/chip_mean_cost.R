chip_mean_cost <- function(price, shares) {
  price <- .chip_number(price, "price")
  shares <- .chip_number(shares, "shares")
  if (!length(price) || length(price) != length(shares)) {
    .chip_error("`price` and `shares` must be non-empty and have equal lengths.")
  }
  if (any(price <= 0) || any(shares < 0) ||
      !is.finite(sum(shares)) || sum(shares) <= 0) {
    .chip_error("Prices must be positive and shares non-negative with a finite positive sum.")
  }
  sum(price * (shares / sum(shares)))
}
