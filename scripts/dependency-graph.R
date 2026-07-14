#!/usr/bin/env Rscript
pkg_dirs <- if (dir.exists("packages")) {
  list.dirs("packages", full.names = TRUE, recursive = FALSE)
} else {
  character()
}
for (pkg in pkg_dirs) {
  desc <- file.path(pkg, "DESCRIPTION")
  if (!file.exists(desc)) {
    next
  }
  d <- read.dcf(desc)
  fields <- intersect(c("Imports", "Depends", "Suggests"), colnames(d))
  cat(d[[1, "Package"]], "\n")
  for (f in fields) {
    cat("  ", f, ": ", gsub("\\s+", " ", d[[1, f]]), "\n", sep = "")
  }
}
