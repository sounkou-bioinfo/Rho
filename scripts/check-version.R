#!/usr/bin/env Rscript

version_lines <- trimws(readLines("VERSION", warn = FALSE))
version_lines <- version_lines[nzchar(version_lines)]
if (length(version_lines) != 1L) {
  stop("VERSION must contain exactly one non-empty line", call. = FALSE)
}
release_version <- version_lines[[1L]]
release_package_version <- tryCatch(
  package_version(release_version),
  error = function(error) {
    stop("VERSION is not a valid R package version", call. = FALSE)
  }
)

package_dirs <- list.dirs("packages", recursive = FALSE, full.names = TRUE)
package_dirs <- package_dirs[file.exists(file.path(package_dirs, "DESCRIPTION"))]
descriptions <- lapply(package_dirs, function(package_dir) {
  read.dcf(file.path(package_dir, "DESCRIPTION"), all = TRUE)
})
package_names <- vapply(
  descriptions,
  function(description) description[[1L, "Package"]],
  character(1)
)

errors <- character()
record_error <- function(message) {
  errors <<- c(errors, message)
}

dependency_fields <- c("Depends", "Imports", "LinkingTo", "Suggests", "Enhances")
for (index in seq_along(package_dirs)) {
  package_dir <- package_dirs[[index]]
  description <- descriptions[[index]]
  package <- description[[1L, "Package"]]
  version <- description[[1L, "Version"]]

  if (!identical(package, basename(package_dir))) {
    record_error(sprintf(
      "%s declares Package: %s",
      package_dir,
      package
    ))
  }
  if (!identical(version, release_version)) {
    record_error(sprintf(
      "%s has version %s; expected %s",
      package,
      version,
      release_version
    ))
  }

  depends <- description[[1L, "Depends"]]
  if (!grepl("R \\(>= 4\\.4\\.0\\)", depends)) {
    record_error(sprintf("%s does not require R >= 4.4.0", package))
  }

  present_fields <- intersect(dependency_fields, colnames(description))
  dependency_text <- paste(description[1L, present_fields], collapse = ",")
  dependency_specs <- trimws(strsplit(dependency_text, ",", fixed = TRUE)[[1L]])
  dependency_specs <- dependency_specs[nzchar(dependency_specs)]
  dependency_names <- sub("[[:space:]]*\\(.*$", "", dependency_specs)
  internal_dependencies <- intersect(package_names, dependency_names)

  test_files <- list.files(
    file.path(package_dir, "inst", "tinytest", "rmd"),
    pattern = "[.]Rmd$",
    full.names = TRUE
  )
  test_lines <- unlist(
    lapply(test_files, readLines, warn = FALSE, encoding = "UTF-8"),
    use.names = FALSE
  )
  loaded_internal_dependencies <- package_names[vapply(
    package_names,
    function(dependency) {
      any(grepl(
        sprintf("library(%s)", dependency),
        test_lines,
        fixed = TRUE
      ))
    },
    logical(1)
  )]
  undeclared_test_dependencies <- setdiff(
    loaded_internal_dependencies,
    c(package, internal_dependencies)
  )
  for (dependency in undeclared_test_dependencies) {
    record_error(sprintf(
      "%s tests load undeclared internal dependency %s",
      package,
      dependency
    ))
  }

  for (dependency in internal_dependencies) {
    specification <- dependency_specs[dependency_names == dependency]
    required <- sprintf("%s (>= %s)", dependency, release_version)
    if (length(specification) != 1L || !identical(specification, required)) {
      record_error(sprintf(
        "%s must depend on %s as `%s`",
        package,
        dependency,
        required
      ))
    }
  }

  remotes <- if ("Remotes" %in% colnames(description)) {
    trimws(strsplit(description[[1L, "Remotes"]], ",", fixed = TRUE)[[1L]])
  } else {
    character()
  }
  expected_remotes <- sprintf(
    "RGenomicsETL/Rho/packages/%s",
    internal_dependencies
  )
  for (remote in setdiff(expected_remotes, remotes)) {
    record_error(sprintf(
      "%s must declare monorepo remote `%s`",
      package,
      remote
    ))
  }
}

if (length(errors)) {
  message("Monorepo version contract failed:")
  message(paste0("- ", errors, collapse = "\n"))
  quit(status = 1L)
}

message(sprintf(
  "Version contract passed: %d packages at %s",
  length(package_dirs),
  release_version
))
