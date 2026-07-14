rho_abort <- function(..., call. = FALSE) {
  stop(sprintf(...), call. = call.)
}

rho_new_state <- function(parent = emptyenv(), ...) {
  e <- new.env(parent = parent)
  vals <- list(...)
  for (nm in names(vals)) {
    assign(nm, vals[[nm]], envir = e)
  }
  e
}

rho_is_task <- function(x) {
  isTRUE(tryCatch(S7::S7_inherits(x, RhoTask), error = function(e) FALSE))
}

rho_is_stream <- function(x) {
  isTRUE(tryCatch(S7::S7_inherits(x, RhoStream), error = function(e) FALSE))
}
