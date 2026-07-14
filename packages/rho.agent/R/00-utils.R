rho_abort <- function(..., call. = FALSE) stop(sprintf(...), call. = call.)
rho_new_state <- function(...) {
  e <- new.env(parent = emptyenv())
  vals <- list(...)
  for (nm in names(vals)) {
    assign(nm, vals[[nm]], e)
  }
  e
}
