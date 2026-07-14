rho_thinking_levels <- c("off", "minimal", "low", "medium", "high", "xhigh", "max")

rho_thinking_level_entry <- function(model, level) {
  mapping <- model@capabilities@thinking_level_map
  position <- match(level, names(mapping))
  if (is.na(position)) {
    return(list(present = FALSE, value = NULL))
  }
  list(present = TRUE, value = mapping[[position]])
}

S7::method(rho_supported_thinking_levels, Model) <- function(model, ...) {
  if (!model@capabilities@reasoning) {
    return("off")
  }
  Filter(
    function(level) {
      entry <- rho_thinking_level_entry(model, level)
      if (entry$present && is.null(entry$value)) {
        return(FALSE)
      }
      if (level %in% c("xhigh", "max")) {
        return(entry$present)
      }
      TRUE
    },
    rho_thinking_levels
  )
}

S7::method(rho_clamp_thinking_level, Model) <- function(model, level, ...) {
  if (!level %in% rho_thinking_levels) {
    rho_abort("Unknown thinking level: %s", level)
  }
  available <- rho_supported_thinking_levels(model)
  if (level %in% available) {
    return(level)
  }
  requested <- match(level, rho_thinking_levels)
  higher <- if (requested < length(rho_thinking_levels)) {
    rho_thinking_levels[seq.int(requested + 1L, length(rho_thinking_levels))]
  } else {
    character()
  }
  supported_higher <- intersect(higher, available)
  if (length(supported_higher)) {
    return(supported_higher[[1L]])
  }
  lower <- if (requested > 1L) rev(rho_thinking_levels[seq_len(requested - 1L)]) else character()
  supported_lower <- intersect(lower, available)
  if (length(supported_lower)) {
    return(supported_lower[[1L]])
  }
  if (length(available)) available[[1L]] else "off"
}

S7::method(rho_map_thinking_level, Model) <- function(model, level, ...) {
  clamped <- rho_clamp_thinking_level(model, level)
  entry <- rho_thinking_level_entry(model, clamped)
  if (entry$present) entry$value else clamped
}

S7::method(rho_model_supports_input, Model) <- function(model, input, ...) {
  input %in% model@capabilities@input
}

S7::method(rho_model_supports_transport, Model) <- function(model, transport, ...) {
  transport %in% model@capabilities@transports
}
