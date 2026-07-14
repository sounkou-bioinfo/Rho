#!/usr/bin/env Rscript

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("Package 'rmarkdown' is required", call. = FALSE)
}

package_order <- c(
  "rho.async",
  "rho.http",
  "rho.ai",
  "rho.agent",
  "rho.ext",
  "rho.compute",
  "rho.graphics",
  "rho.coding",
  "rho.bio",
  "rho.duckdb",
  "rho.bio.agent",
  "rho.testkit"
)

readmes <- c(file.path("packages", package_order, "README.Rmd"), "README.Rmd")

for (readme in readmes) {
  if (!file.exists(readme)) {
    stop(sprintf("README source does not exist: %s", readme), call. = FALSE)
  }
  message("== rendering ", readme, " ==")
  rmarkdown::render(
    input = readme,
    output_format = "github_document",
    quiet = TRUE,
    envir = new.env(parent = globalenv())
  )
  markdown <- sub("\\.Rmd$", ".md", readme)
  lines <- readLines(markdown, warn = FALSE, encoding = "UTF-8")
  writeLines(sub("[ \\t]+$", "", lines), markdown, useBytes = TRUE)
  html <- sub("\\.Rmd$", ".html", readme)
  if (file.exists(html)) {
    unlink(html)
  }
}
