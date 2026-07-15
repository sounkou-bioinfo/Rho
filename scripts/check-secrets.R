#!/usr/bin/env Rscript

gitleaks <- Sys.which("gitleaks")
if (!nzchar(gitleaks)) {
  stop(
    "gitleaks is required; install the pinned version from docs/releasing.md",
    call. = FALSE
  )
}

scans <- list(
  c("git", "--no-banner", "--no-color", "--redact", "--exit-code", "1", "."),
  c("dir", "--no-banner", "--no-color", "--redact", "--exit-code", "1", ".")
)
for (arguments in scans) {
  status <- system2(gitleaks, arguments)
  if (!identical(status, 0L)) {
    quit(status = status)
  }
}
