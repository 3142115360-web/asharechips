## Submission

This is a resubmission of asharechips, version 0.2.1.

## Changes in response to CRAN review

* Fixed the invalid `LICENSE.md` file URI in `README.md`. The README now links
  to `inst/LICENSE.txt`, which is present in the built source package.
* Added the published method reference requested by the reviewer to the
  `Description` field: Liu and Wang (2018)
  <doi:10.1016/j.physa.2017.11.154>.
* Clarified that the cited recurrence supports the linear turnover update,
  while exponential retention and price allocation are package-specific
  modelling choices.
* The author and maintainer remain represented as `Ruihong Zhao`, with separate
  given and family names. The maintainer does not currently supply an ORCID.

## Executed test environment

* macOS Sequoia 15.6, Apple silicon, R 4.6.1 (2026-06-24): complete
  `R CMD check --as-cran`, including incoming, tests, vignette rebuild,
  PDF manual and HTML manual checks.

## R CMD check results

0 errors | 0 warnings | 1 note

The only note is the expected CRAN incoming message:

    Maintainer: 'Ruihong Zhao <3142115360@qq.com>'
    New submission

There are no reverse dependencies because this is a new package. All examples,
tests and the vignette use synthetic data; the package performs no network
requests and requires no API credentials.

This file is excluded from the source archive by `.Rbuildignore`.
