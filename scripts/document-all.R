#!/usr/bin/env Rscript
if (!requireNamespace("roxygen2", quietly = TRUE)) {
  stop("roxygen2 is required", call. = FALSE)
}
pkg_dirs <- c(
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
for (pkg in pkg_dirs) {
  if (file.exists(file.path(pkg, "DESCRIPTION"))) {
    roxygen2::roxygenise(pkg, load_code = roxygen2::load_installed)
  }
}
