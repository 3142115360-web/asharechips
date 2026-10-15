\name{chip_distribution}
\alias{print.chip_distribution}
\alias{plot.chip_distribution}
\alias{summary.chip_distribution}
\alias{as.data.frame.chip_distribution}
\title{Inspect and Plot a Chip Distribution}
\usage{
\method{print}{chip_distribution}(x, ...)
\method{summary}{chip_distribution}(object, ...)
\method{as.data.frame}{chip_distribution}(x, row.names = NULL, optional = FALSE, ...)
\method{plot}{chip_distribution}(x, ..., col = "#4C78A8", close_col = "#D62728")
}
\arguments{
  \item{x, object}{A \code{chip_distribution} object returned by
  \code{estimate_chip_distribution()}.}
  \item{...}{For \code{plot}, named arguments forwarded to
  \code{graphics::plot}; defaults such as \code{xlab}, \code{ylim} and
  \code{main} can be overridden. \code{x} and \code{y} cannot be overridden.
  For \code{as.data.frame}, arguments forwarded to the data-frame method.
  Otherwise ignored.}
  \item{row.names, optional}{Passed to \code{as.data.frame}.}
  \item{col}{Colour for horizontal chip segments.}
  \item{close_col}{Colour for the final closing-price reference line.}
}
\description{
Print a brief model summary, extract statistics or weights, or plot estimated
cost on the vertical axis against estimated chip share on the horizontal axis.
}
\value{
\code{summary} returns the one-row summary data frame;
\code{as.data.frame} returns the distribution data frame.
\code{print} and \code{plot} return \code{x} invisibly.
\code{plot} draws on the current graphics device without opening an external
viewer or saving files.
}
\seealso{\code{\link{estimate_chip_distribution}}}
\examples{
daily <- data.frame(
  trade_date = c("20260102", "20260105"),
  high = c(10, 11), low = c(10, 11), close = c(10, 11),
  vol = c(100, 100), amount = c(100, 110), turnover_rate = c(0, 20)
)
chips <- estimate_chip_distribution(daily)
print(chips)
summary(chips)
as.data.frame(chips)
plot(chips, main = "Synthetic example", xlab = "Share (\%)")
}
