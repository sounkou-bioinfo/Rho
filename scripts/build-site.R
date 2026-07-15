#!/usr/bin/env Rscript

if (!requireNamespace("pkgdown", quietly = TRUE)) {
  stop("Package 'pkgdown' is required", call. = FALSE)
}

package_dirs <- list.dirs("packages", recursive = FALSE, full.names = TRUE)
package_dirs <- package_dirs[file.exists(file.path(package_dirs, "DESCRIPTION"))]

dir.create("_site", recursive = TRUE, showWarnings = FALSE)
invisible(file.create(file.path("_site", ".nojekyll")))
site_root <- normalizePath("_site", mustWork = TRUE)

for (package_dir in package_dirs) {
  package_name <- read.dcf(file.path(package_dir, "DESCRIPTION"), fields = "Package")[[1L]]
  destination <- file.path(site_root, package_name)
  message("== pkgdown ", package_name, " ==")
  pkgdown::build_site(
    pkg = package_dir,
    new_process = FALSE,
    install = FALSE,
    preview = FALSE,
    override = list(destination = destination)
  )
}
