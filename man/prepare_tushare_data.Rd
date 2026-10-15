\name{prepare_tushare_data}
\alias{prepare_tushare_data}
\title{Prepare Matching Tushare Tables without Network Access}
\usage{
prepare_tushare_data(daily, daily_basic, adj_factor = NULL,
                    ts_code = NULL, as_of = NULL)
}
\arguments{
  \item{daily}{Unadjusted daily prices, supplied as a non-empty data frame with
  \code{ts_code}, \code{trade_date}, \code{high}, \code{low}, \code{close},
  \code{vol} (lots of 100 shares), and \code{amount} (thousand CNY).}
  \item{daily_basic}{Non-empty data frame with \code{ts_code},
  \code{trade_date}, \code{turnover_rate} (percentage points) and optionally
  \code{float_share} (ten thousand shares).}
  \item{adj_factor}{Optional factor table with three columns:
  \code{ts_code} for stock codes; \code{trade_date} for dates;
  and \code{adj_factor} for positive factors.}
  \item{ts_code}{Optional single stock code to select from all tables. Without
  it, each table must refer to one and the same stock.}
  \item{as_of}{Optional cutoff date. Accepts a \code{Date}, \code{YYYYMMDD}
  number or text, or \code{YYYY-MM-DD} text. Rows after it are excluded. The
  cutoff need not be a trading date; the last remaining daily row determines
  the price basis used by the estimator.}
}
\description{
Validate and join locally supplied daily price, turnover and optional factor
tables with complete one-to-one stock/date matches. Dates are normalized and
sorted. No API requests, token storage or file writes are performed.
}
\details{
Duplicate selected stock/date keys, different stocks or a missing turnover
or factor row for any retained daily date are errors. Extra dates in the
indicator or factor table are ignored. Daily prices remain authoritative;
for example, \code{daily_basic$close} does not replace \code{daily$close}.
Columns from \code{daily} are preserved except reserved indicator/factor
columns, which are supplied by their authoritative tables. Arithmetic and
price-range validation is performed by the estimator.
}
\value{
A data frame ready for \code{estimate_chip_distribution()}, with daily price
columns, matched \code{turnover_rate}, optional \code{float_share} and optional
\code{adj_factor}. If factors are included, explicitly specify
\code{adjustment_col = "adj_factor"} in the estimator.
}
\seealso{\code{\link{estimate_chip_distribution}}}
\examples{
daily <- data.frame(
  ts_code = rep("000001.SZ", 2), trade_date = c("20260105", "20260102"),
  high = c(11, 10), low = c(11, 10), close = c(11, 10),
  vol = c(100, 100), amount = c(110, 100)
)
basic <- data.frame(
  ts_code = rep("000001.SZ", 2), trade_date = c("20260102", "20260105"),
  turnover_rate = c(0, 20)
)
input <- prepare_tushare_data(daily, basic)
estimate_chip_distribution(input)
}
