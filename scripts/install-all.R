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
for (pkg in order) {
  if (file.exists(file.path(pkg, "DESCRIPTION"))) {
    message("== installing ", pkg, " ==")
    status <- system2(file.path(R.home("bin"), "R"), c("CMD", "INSTALL", shQuote(pkg)))
    if (!identical(status, 0L)) quit(status = status)
  }
}
