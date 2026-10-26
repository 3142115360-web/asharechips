\name{estimate_chip_distribution}
\alias{estimate_chip_distribution}
\title{Estimate a Holding-Cost Distribution from Daily Market Data}
\usage{
estimate_chip_distribution(
  data, date_col = "trade_date", high_col = "high", low_col = "low",
  close_col = "close", turnover_col = "turnover_rate", volume_col = "vol",
  amount_col = "amount", adjustment_col = NULL, price_step = 0.01,
  price_method = c("vwap", "typical", "close", "uniform"),
  turnover_transform = c("exponential", "linear"),
  initial_distribution = NULL
)
}
\arguments{
  \item{data}{A non-empty data frame containing one row per observed day and one
  stock. A \code{ts_code} column, if present, must identify a single stock.
  Missing trading days are not imputed.}
  \item{date_col}{Date column name. Accepts \code{Date} objects, eight-digit
  \code{YYYYMMDD} numbers or text, or \code{YYYY-MM-DD} text. Dates must be valid
  and unique; they are normalized to \code{YYYYMMDD} and sorted.}
  \item{high_col, low_col, close_col}{Column names for positive finite daily
  high, low and closing prices in CNY per share. High must be at least low and
  close must lie in that range. Use unadjusted prices when supplying factors.}
  \item{turnover_col}{Column name for non-negative daily turnover in percentage
  points: \code{5} means five percent. Tushare's \code{turnover_rate} uses
  unrestricted circulating shares; \code{turnover_rate_f} uses a different
  denominator and should not be mixed with it.}
  \item{volume_col, amount_col}{Volume and amount column names, required for
  VWAP. Units are lots of 100 shares and thousand CNY, respectively, as in
  Tushare daily data. Zero values are permitted together only on rows on which no
  transaction price is needed. Negative values are rejected.}
  \item{adjustment_col}{Optional column name for strictly positive adjustment
  factors. Historical prices are multiplied by that day's factor divided by
  the last observed day's factor. Without factors, prices must already share
  a consistent basis.}
  \item{price_step}{Positive price-grid spacing in CNY. Smaller spacing increases
  resolution and computational work. Grids above one million bins are rejected.
  The spacing must exceed the numerical resolution of the input prices.}
  \item{price_method}{Placement of newly traded weight: \code{"vwap"} uses
  \code{amount * 10 / vol}; \code{"typical"} uses the mean of high, low and
  close; \code{"close"} uses close; \code{"uniform"} distributes weight
  across the high-low interval using overlap with each grid cell.}
  \item{turnover_transform}{\code{"exponential"} retains \eqn{\exp(-r/100)}
  of previous weight, allowing turnover above 100 percent. \code{"linear"}
  retains \eqn{1-r/100} and requires turnover at most 100 percent.}
  \item{initial_distribution}{Optional non-empty data frame with positive
  \code{price} and non-negative \code{weight} columns. Weights are normalized
  and must have a finite positive sum. Prices must already use the last
  observed day's price basis. The distribution describes holdings immediately
  before the first row; that row's turnover is therefore applied.}
}
\description{
Estimate the cost distribution of circulating shares using an explicitly
specified daily turnover-replacement model. Returns auditable weights,
descriptive cost statistics and a per-day diagnostic record.
}
\details{
Let \eqn{w_{t-1}} be the previous grid distribution, \eqn{g_t} the normalized
distribution assigned to newly traded shares and \eqn{s_t} the retention
fraction. The recurrence is
\deqn{w_t = s_t w_{t-1} + (1-s_t) g_t.}
The exponential transformation assumes homogeneous random replacement; the
linear alternative assumes a fraction of existing shares changes hands once.
Neither transformation identifies actual sellers or individual accounts.

If \code{initial_distribution} is \code{NULL}, all initial weight is placed
using the first day's price rule. Its turnover is not used as a replacement
step. If an initial distribution is supplied, every row is a replacement step.
\code{history_coverage} describes the amount of initial weight replaced by
those steps, not coverage of actual shareholder records.

Point prices are rounded to the nearest grid centre using R's ties-to-even
rounding. Centres are spaced by \code{price_step}; the first centre is the
largest non-negative grid multiple not exceeding the minimum input price,
except that a zero centre is replaced by the minimum positive input price.
Uniform allocation uses overlap with cells extending half a step either side
of each centre. A zero-width high-low interval is allocated to one centre.
No arbitrary small-weight threshold is used; only zero numerical weights are
omitted. Very old weights may underflow in long histories.

VWAP values beyond the high-low range by more than
\code{1e-6 * max(1, high)} in original price units are rejected. Smaller
rounding discrepancies are clamped to the range and flagged. The optional
\code{float_share} column must be positive; a consecutive relative change
above \code{1e-6} produces a warning and a diagnostic flag. Issuances, unlocks,
repurchases, fees and taxes are not modelled. Dividend factors provide a
comparable price basis rather than literal historical cash acquisition costs.

Runtime is approximately proportional to the product of the number of days
and grid bins. Memory usage is proportional to bins plus input rows.
}
\value{
A \code{chip_distribution} object, a list with four components:
\describe{
  \item{distribution}{Data frame with positive grid \code{price}, normalized
  \code{weight} (sum one, subject to numerical precision), and
  \code{percent = 100 * weight}.}
  \item{summary}{One-row data frame, with these groups of fields:
  \itemize{
    \item Stock identifier: \code{ts_code}.
    \item Date interval: \code{start_date} and \code{end_date}.
    \item Input count: \code{observations}. Final price: \code{last_close}.
    \item Weighted mean: \code{average_cost}. Weighted median: \code{median_cost}.
    \item Peak cost: \code{peak_price}. Peak share: \code{peak_percent}.
    Tied peaks use the lowest price.
    \item Profitable share: \code{profit_ratio} and \code{profit_percent};
    only costs strictly below the last close are included.
    \item Equal-price share: \code{breakeven_ratio}. Higher-cost share:
    \code{loss_ratio}. Equality allows only numerical rounding error.
    The profit, break-even and loss ratios sum to one.
    \item Central interval: \code{cost_low_90} and \code{cost_high_90}, the
    discrete 5th and 95th weighted quantiles.
    \item Range width: \code{concentration_90}, the interval's width divided
    by the sum of its endpoints. Smaller values mean narrower cost ranges,
    not higher ownership concentration.
    \item Turnover sum: \code{cumulative_turnover_percent}, over applied rows.
    \item Surviving prior: \code{initialization_weight}, the product of
    retention fractions over applied update rows.
    \item Replaced prior: \code{history_coverage}, one minus surviving prior.
  }}
  \item{diagnostics}{One row per sorted date with the following fields:
  \itemize{
    \item Date: \code{trade_date}. Turnover: \code{turnover_rate}.
    \item Proposed replacement: \code{replacement_fraction}.
    \item Used replacement: \code{applied_replacement_fraction}; zero for
    an initialized first row.
    \item Old-weight retention: \code{retention}.
    \item Final-basis price: \code{transaction_price}.
    \item Original-basis price: \code{raw_transaction_price}.
    \item Factor normalization: \code{adjustment_ratio}.
    \item Minor VWAP corrections: \code{vwap_rounding_adjusted}.
    \item Initialization flag: \code{initialized_here}.
    \item Share-count change flag: \code{capital_changed}.
  }
  \code{vwap_outside_range} is retained for backwards
  compatibility and is always false because material violations are errors.
  Uniform allocation's transaction price is a representative typical price,
  not the allocation itself.}
  \item{settings}{Column mappings, grid spacing and origin, price and turnover
  methods, initialization rule and \code{price_basis = "last_trading_day"}.}
}
The estimates depend on modelling assumptions, observed history and grid
spacing. They do not establish investor identity or future returns.
}
\references{
Liu, H. and Wang, L. (2018). ``The price momentum of stock in
distribution.'' \emph{Physica A: Statistical Mechanics and its Applications},
492, 2336--2344. \doi{10.1016/j.physa.2017.11.154}.

Tushare daily prices and units:
\url{https://tushare.pro/document/2?doc_id=27}.
Turnover definitions: \url{https://tushare.pro/document/2?doc_id=32}.
Adjustment factors: \url{https://tushare.pro/document/2?doc_id=28}.
}
\seealso{\code{\link{prepare_tushare_data}}, \code{\link{chip_mean_cost}},
\code{\link{plot.chip_distribution}}}
\examples{
# Entirely synthetic data; no network access or API token is required.
daily <- data.frame(
  trade_date = c("20260106", "20260102", "20260105"),
  high = c(12, 10, 11), low = c(12, 10, 11), close = c(12, 10, 11),
  vol = c(100, 100, 100), amount = c(120, 100, 110),
  turnover_rate = c(30, 0, 20)
)
chips <- estimate_chip_distribution(daily)
summary(chips)
as.data.frame(chips)

initial <- data.frame(price = c(8, 12), weight = c(0.5, 0.5))
estimate_chip_distribution(daily, initial_distribution = initial)
}
\keyword{models}
