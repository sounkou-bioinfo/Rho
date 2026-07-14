# Rmd-driven tinytest

Edit `inst/tinytest/rmd/*.Rmd` only. Generate test files with:

```bash
Rscript scripts/purl-tests.R
```

CI uses:

```bash
make check-purled-tests
make check-format
make check
```

Generated `inst/tinytest/test-*.R` files are committed to make `tinytest::test_package()` ordinary and transparent.

`make check` installs packages in dependency order, builds source tarballs in a
temporary directory, and requires exactly `Status: OK` from every package check.
Roxygen2 documentation is regenerated with `make rd`; the committed `NAMESPACE`
and `man/` files are generated artifacts.
