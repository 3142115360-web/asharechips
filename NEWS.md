# asharechips 0.2.1

* Fix the README license link so that its target is present in the built source
  package.
* Cite the published turnover-based cost-distribution recurrence and distinguish
  it from the package-specific retention and price-allocation choices.

# asharechips 0.2.0

* Validate calendar dates, column mappings, numeric input, stock selection,
  turnover units, adjustment factors and grid resource limits.
* Reject material VWAP inconsistencies instead of clipping their cost prices;
  record minor rounding adjustments explicitly.
* Separate profitable, break-even and loss shares. All returned positive
  weights are preserved. Uniform allocation uses price-cell overlap.
* Add an optional initial distribution, report surviving initial weight,
  flag circulating-share changes and clarify first-day initialization.
* Add offline `prepare_tushare_data()` and `chip_mean_cost()`.
* Add summary and data-frame methods, customizable plots, complete English
  reference pages, a worked vignette, Chinese guidance and regression tests.
* Replace provisional author metadata with the maintainer's supplied details.

# asharechips 0.1.0

* Initial local prototype of a daily turnover-replacement estimator.
