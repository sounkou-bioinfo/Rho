#!/usr/bin/env Rscript

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("Package 'rmarkdown' is required", call. = FALSE)
}

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) > 1L) {
  stop("Expected at most one credential-file path", call. = FALSE)
}
if (length(arguments) == 1L) {
  credential_path <- arguments[[1L]]
  if (!nzchar(credential_path) || !file.exists(credential_path)) {
    stop("The supplied credential file does not exist", call. = FALSE)
  }
  options(
    rho.openai_codex_credential = normalizePath(
      credential_path,
      winslash = "/",
      mustWork = TRUE
    ),
    rho.codex_readme_rebuild = TRUE
  )
}

package_order <- c(
  "rho.async",
  "rho.http",
  "rho.ai",
  "rho.agent",
  "rho.ext",
  "rho.compute",
  "rho.http.httr2",
  "rho.graphics",
  "rho.coding",
  "rho.bio",
  "rho.duckdb",
  "rho.bio.agent",
  "rho.testkit"
)

readmes <- file.path("packages", package_order, "README.Rmd")
if (length(arguments) == 1L) {
  readmes <- c("README.Rmd", readmes)
} else {
  message("== root README requires make rdm-codex CREDENTIAL=/path/to/auth.json ==")
}

for (readme in readmes) {
  if (!file.exists(readme)) {
    stop(sprintf("README source does not exist: %s", readme), call. = FALSE)
  }
  message("== rendering ", readme, " ==")
  rmarkdown::render(
    input = readme,
    output_format = "github_document",
    quiet = TRUE,
    envir = new.env(parent = globalenv()),
    intermediates_dir = tempdir()
  )
  markdown <- sub("\\.Rmd$", ".md", readme)
  lines <- readLines(markdown, warn = FALSE, encoding = "UTF-8")
  writeLines(sub("[[:blank:]]+$", "", lines), markdown, useBytes = TRUE)
  html <- sub("\\.Rmd$", ".html", readme)
  if (file.exists(html)) {
    unlink(html)
  }
}
