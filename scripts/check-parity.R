#!/usr/bin/env Rscript

ledger <- "docs/pi-parity.md"
lines <- readLines(ledger, warn = FALSE, encoding = "UTF-8")
table_lines <- lines[grepl("^\\|", lines)]

rows <- lapply(table_lines, function(line) {
  cells <- strsplit(sub("\\|$", "", sub("^\\|", "", line)), "\\|", fixed = FALSE)[[1L]]
  trimws(cells)
})
rows <- Filter(
  function(cells) {
    length(cells) >= 3L &&
      !identical(cells[[1L]], "Area") &&
      !identical(cells[[1L]], "Adapter") &&
      !all(grepl("^-+$", cells))
  },
  rows
)

blockers <- vapply(
  Filter(
    function(cells) {
      !identical(tolower(cells[[length(cells)]]), "verified")
    },
    rows
  ),
  function(cells) {
    sprintf(
      "%s — %s [%s]",
      cells[[1L]],
      cells[[2L]],
      cells[[length(cells)]]
    )
  },
  character(1)
)

if (length(blockers)) {
  message("Pi parity and live-provider gates are incomplete:")
  message(paste0("- ", blockers, collapse = "\n"))
  quit(status = 1L)
}

message(sprintf("Parity contract passed: %d verified rows", length(rows)))
