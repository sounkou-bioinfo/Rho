#!/usr/bin/env Rscript
order <- c(
  "packages/rho.async",
  "packages/rho.http",
  "packages/rho.ai",
  "packages/rho.agent",
  "packages/rho.ext",
  "packages/rho.compute",
  "packages/rho.http.httr2",
  "packages/rho.graphics",
  "packages/rho.coding",
  "packages/rho.bio",
  "packages/rho.duckdb",
  "packages/rho.bio.agent",
  "packages/rho.testkit"
)
if (!requireNamespace("tinytest", quietly = TRUE)) {
  stop("tinytest is required", call. = FALSE)
}
for (pkg in order) {
  if (!file.exists(file.path(pkg, "DESCRIPTION"))) {
    next
  }
  name <- read.dcf(file.path(pkg, "DESCRIPTION"), fields = "Package")[[1]]
  message("== testing ", name, " ==")
  if (!requireNamespace(name, quietly = TRUE)) {
    stop(sprintf("Package `%s` is not installed", name), call. = FALSE)
  }
  results <- tinytest::test_package(name)
  if (!tinytest::all_pass(results)) quit(status = 1L)
}
