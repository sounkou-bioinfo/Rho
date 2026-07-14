rho_abort <- function(..., call. = FALSE) stop(sprintf(...), call. = call.)
rho_non_empty_string <- S7::new_property(S7::class_character, validator = function(value) {
  if (length(value) != 1L || is.na(value) || !nzchar(value)) "must be one non-empty string"
})
