\name{chip_mean_cost}
\alias{chip_mean_cost}
\title{Calculate a Share-Weighted Mean Cost}
\usage{chip_mean_cost(price, shares)}
\arguments{
  \item{price}{Non-empty vector of positive, finite prices. Numeric text and
  factors containing numeric text are also accepted.}
  \item{shares}{Equally sized vector of non-negative, finite share counts
  or weights with a finite positive sum.}
}
\description{
Calculate the weighted mean of prices without R's vector recycling.
Prices and share counts must correspond in the same order.
}
\value{A numeric scalar equal to the sum of prices multiplied by normalized
share counts. Prices retain the input monetary units.}
\examples{
chip_mean_cost(c(10, 11, 12), c(50, 20, 30)) # 10.8
chip_mean_cost(c(10, 11, 12), c(0.5, 0.2, 0.3))
}
