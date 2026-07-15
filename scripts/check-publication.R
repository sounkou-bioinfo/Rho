#!/usr/bin/env Rscript

version <- trimws(readLines("VERSION", warn = FALSE, encoding = "UTF-8"))
version <- version[nzchar(version)]
if (length(version) != 1L) {
  stop("VERSION must contain exactly one non-empty line", call. = FALSE)
}

lifecycle_badge <- "https://img.shields.io/badge/lifecycle-experimental-orange.svg"
package_dirs <- list.dirs("packages", recursive = FALSE, full.names = TRUE)
package_dirs <- package_dirs[file.exists(file.path(package_dirs, "DESCRIPTION"))]
errors <- character()

record_error <- function(message) {
  errors <<- c(errors, message)
}

check_file <- function(path, description) {
  if (!file.exists(path)) {
    record_error(sprintf("missing %s: %s", description, path))
    return(FALSE)
  }
  TRUE
}

check_readme <- function(path) {
  if (!check_file(path, "README")) {
    return(invisible(NULL))
  }
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (!any(grepl(lifecycle_badge, lines, fixed = TRUE))) {
    record_error(sprintf("%s has no experimental lifecycle badge", path))
  }
  relative_readme_links <- grep(
    "\\]\\(\\.\\./(?:\\.\\./)?[^)]*README[.]md\\)",
    lines,
    perl = TRUE,
    value = TRUE
  )
  if (length(relative_readme_links)) {
    record_error(sprintf(
      "%s contains a relative README link that pkgdown rewrites incorrectly",
      path
    ))
  }
  invisible(NULL)
}

check_news <- function(path, heading) {
  if (!check_file(path, "NEWS")) {
    return(invisible(NULL))
  }
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (!length(lines) || !identical(lines[[1L]], heading)) {
    record_error(sprintf("%s must begin with `%s`", path, heading))
  }
  invisible(NULL)
}

check_news("NEWS.md", sprintf("# Rho %s", version))
check_readme("README.Rmd")
check_readme("README.md")

tracked_readme_cache <- system2(
  "git",
  c("ls-files", "--", "README_cache"),
  stdout = TRUE,
  stderr = FALSE
)
if (length(tracked_readme_cache)) {
  record_error(sprintf(
    "README cache files must not be tracked: %s",
    paste(tracked_readme_cache, collapse = ", ")
  ))
}

for (package_dir in package_dirs) {
  package <- read.dcf(
    file.path(package_dir, "DESCRIPTION"),
    fields = "Package"
  )[[1L]]
  check_news(
    file.path(package_dir, "NEWS.md"),
    sprintf("# %s %s", package, version)
  )
  check_readme(file.path(package_dir, "README.Rmd"))
  check_readme(file.path(package_dir, "README.md"))
}

if (length(errors)) {
  message("Publication metadata contract failed:")
  message(paste0("- ", errors, collapse = "\n"))
  quit(status = 1L)
}

message(sprintf(
  "Publication metadata contract passed: root and %d packages",
  length(package_dirs)
))
