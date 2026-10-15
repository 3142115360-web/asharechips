## Submission

This is the first CRAN submission of asharechips, version 0.2.0.
The package estimates holding-cost distributions for Chinese equities using
explicit turnover-replacement and price-allocation assumptions. It prepares
locally supplied Tushare tables and returns reproducible cost summaries and
per-day diagnostics. All examples, tests and the vignette use synthetic data.
The package performs no network requests and requires no API credentials.

## Executed test environments

* macOS Sequoia 15.6, Apple silicon, R 4.6.1 (2026-06-24): complete
  `R CMD check --as-cran`, including incoming, PDF and HTML checks.
* macOS Sequoia 15.6, Apple silicon, R 4.5.1: regression tests and installation
  of the final source archive with a working example.
* Official Win-builder, Windows Server 2022 x64, R-release 4.6.1
  (2026-06-24 ucrt): complete checks, including tests, vignette rebuild and
  PDF/HTML manuals, on 2026-10-14.
* Official Win-builder, Windows Server 2022 x64, R-devel
  (2026-10-13 r90668 ucrt): complete checks, including tests, vignette rebuild
  and PDF/HTML manuals, on 2026-10-14.

## R CMD check results

All three complete checks: 0 errors | 0 warnings | 1 note

The only note is the expected CRAN incoming message:

    Maintainer: 'ZHAORUIHONG <3142115360@qq.com>'
    New submission

There are no reverse dependencies because this is a new package.

## External check evidence

Both Win-builder results were read in full and saved locally. They identify
asharechips 0.2.0 and the supplied maintainer and report only the new-submission
note. No package changes were necessary after those checks.

* R-release: https://win-builder.r-project.org/U8TyO5hnpJna/00check.log
* R-devel: https://win-builder.r-project.org/mL4KTsG18QF8/00check.log

The service retains these links for approximately 72 hours. The checked source
archive is unchanged (SHA256):

    0c99dd5e8d53539dbe4d7da99eeee6c92bb6b92b2a4c5354bb11bc26836735d9

Linux checks have not been run; no unexecuted platform checks are claimed.
This file is excluded from the source archive by .Rbuildignore.
