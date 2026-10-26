# asharechips

`asharechips` estimates daily holding-cost distributions for mainland Chinese
A-share equities. It provides offline preparation of Tushare tables, explicit
turnover-replacement models, optional price adjustment and initial distributions,
cost statistics, graphics and per-day diagnostics. The estimates describe a
model of circulating shares; they do not identify actual investors.

The package needs only base R and the recommended `graphics` package at runtime.
No token, network access or external data is needed for its examples or tests.

中文入门说明：[筹码分布模型与使用方法](inst/README.zh-CN.md)。

## Installation

Install the development version from GitHub:

```r
install.packages("remotes")  # Needed only for installation from GitHub
remotes::install_github("3142115360-web/asharechips", build_vignettes = TRUE)
library(asharechips)
```

Alternatively, install a locally built source archive:

```r
install.packages("asharechips_0.2.1.tar.gz", repos = NULL, type = "source")
library(asharechips)
```

## A reproducible example

```r
# Synthetic prices and turnover; this is not a real stock history.
daily <- data.frame(
  trade_date = c("20260106", "20260102", "20260105"),
  high = c(12, 10, 11), low = c(12, 10, 11), close = c(12, 10, 11),
  vol = c(100, 100, 100), amount = c(120, 100, 110),
  turnover_rate = c(30, 0, 20)
)
chips <- estimate_chip_distribution(daily)
summary(chips)
as.data.frame(chips)
plot(chips, main = "Synthetic cost distribution")
chip_mean_cost(c(10, 11, 12), c(50, 20, 30))
```

## Preparing Tushare data

Download `daily`, `daily_basic` and optionally `adj_factor` through your own
Tushare account. Supply those tables locally:

```r
input <- prepare_tushare_data(daily, daily_basic, adj_factor,
                             ts_code = "000001.SZ", as_of = "20260930")
chips <- estimate_chip_distribution(input, adjustment_col = "adj_factor")
```

This code assumes that the three tables have already been downloaded. All
retained daily dates must have matching indicators and factors. No daily rows
are silently lost. When passing factors, use original unadjusted daily prices.

| Input | Required units or meaning |
|---|---|
| `high`, `low`, `close` | CNY per share |
| `vol` | Lots of 100 shares |
| `amount` | Thousand CNY |
| `turnover_rate` | Percentage points: `5` means five percent |
| `adj_factor` | Positive factor, normalized to the last observed date |
| `float_share` | Optional circulating share count, in ten thousand shares |

The default transaction price is `amount * 10 / vol`, following the
[official daily-data units](https://tushare.pro/document/2?doc_id=27).
The turnover denominator follows
[Tushare's daily indicator definition](https://tushare.pro/document/2?doc_id=32).

## The model

At each update, the distribution is the sum of retained previous weight and
new transaction weight. With reported turnover `r` in percentage points:

```text
retention = exp(-r / 100)             # default
new distribution = retention * old distribution
                 + (1 - retention) * today's price distribution
```

The exponential choice is a homogeneous random-replacement assumption. The
linear choice retains `1 - r / 100` and requires `r <= 100`. New weight can be
placed at VWAP, a typical price, close, or uniformly across the low-high range.
Grid spacing, transaction-price method and history length change the result.

The default initializes all shares from the first row, then updates from row
two. A supplied `initial_distribution` must be on the final date's price basis
and is updated starting with row one. `initialization_weight` reports how much
of that initial model survives, while `history_coverage` reports its replacement.

Profitable weight is strictly below the final close. Equal-price weight is
reported separately as `breakeven_ratio`. Cost quantiles are discrete left-inverse
quantiles. Tied peaks use the lowest price. These definitions are documented in
`?estimate_chip_distribution`, along with every output field.

## Limits

Daily data cannot reveal which holdings were sold, intraday transaction-price
distributions, investor identities or the costs of newly unlocked or issued
shares. Changes to `float_share` trigger a warning; they are not automatically
modelled. Dividend adjustment provides a comparable price basis rather than
literal cash acquisition costs. Transaction fees and taxes are excluded.
The estimates are descriptive and do not predict future returns.

## Documentation and development

```r
vignette("introduction", package = "asharechips")
```

Chinese guidance is installed as `system.file("README.zh-CN.md", package =
"asharechips")`. Help files in `man/` are maintained directly rather than
generated from roxygen comments. To reproduce checks:

```text
R CMD build asharechips
R CMD check --as-cran asharechips_0.2.1.tar.gz
```

The repository includes a Windows, macOS, Linux and R-devel check workflow.
Results appear under the repository's Actions tab after each push.

The workflow's presence alone does not mean that every check has passed; inspect
the individual jobs and their logs before relying on a release candidate.

## License

MIT, copyright Ruihong Zhao. See [inst/LICENSE.txt](inst/LICENSE.txt) for the full text.
The R package license metadata is in `LICENSE`; the full license is also
installed as `LICENSE.txt`.
