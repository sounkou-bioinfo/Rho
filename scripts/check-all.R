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

build_root <- tempfile("rho-check-")
dir.create(build_root)
on.exit(unlink(build_root, recursive = TRUE, force = TRUE), add = TRUE)
source_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
previous_directory <- setwd(build_root)
on.exit(setwd(previous_directory), add = TRUE)

for (pkg in order) {
  source <- file.path(source_root, pkg)
  description <- file.path(source, "DESCRIPTION")
  if (!file.exists(description)) {
    next
  }
  fields <- read.dcf(description, fields = c("Package", "Version"))
  package <- fields[[1L, "Package"]]
  version <- fields[[1L, "Version"]]

  message("== R CMD build ", pkg, " ==")
  status <- system2(
    file.path(R.home("bin"), "R"),
    c("CMD", "build", "--no-manual", shQuote(source))
  )
  if (!identical(status, 0L)) {
    quit(status = status)
  }

  tarball <- file.path(build_root, sprintf("%s_%s.tar.gz", package, version))
  if (!file.exists(tarball)) {
    stop(sprintf("R CMD build did not create %s", tarball), call. = FALSE)
  }

  message("== R CMD check ", basename(tarball), " ==")
  status <- system2(
    file.path(R.home("bin"), "R"),
    c("CMD", "check", "--no-manual", shQuote(tarball))
  )
  if (!identical(status, 0L)) {
    quit(status = status)
  }

  check_log <- file.path(build_root, paste0(package, ".Rcheck"), "00check.log")
  status_line <- grep("^Status:", readLines(check_log, warn = FALSE), value = TRUE)
  if (!identical(status_line, "Status: OK")) {
    message("Package check was not clean: ", paste(status_line, collapse = ", "))
    quit(status = 1L)
  }
}
