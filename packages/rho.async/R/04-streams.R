rho_stream_value <- function(value) RhoStreamValue(value = value)
rho_stream_end <- function() RhoStreamEnd()

rho_list_stream <- function(values) {
  RhoListStream(
    state = rho_new_state(
      values = values,
      index = 0L,
      closed = FALSE,
      created_at = Sys.time()
    )
  )
}

rho_stream_from_task <- function(task) {
  RhoTaskStream(
    state = rho_new_state(
      task = rho_as_task(task),
      source = NULL,
      closed = FALSE,
      created_at = Sys.time()
    )
  )
}

S7::method(rho_stream_next, RhoListStream) <- function(stream, timeout = NULL, ...) {
  if (isTRUE(stream@state$closed)) {
    return(rho_task(rho_stream_end()))
  }
  stream@state$index <- stream@state$index + 1L
  if (stream@state$index > length(stream@state$values)) {
    stream@state$closed <- TRUE
    return(rho_task(rho_stream_end()))
  }
  rho_task(rho_stream_value(stream@state$values[[stream@state$index]]))
}

S7::method(rho_stream_close, RhoStream) <- function(stream, ...) {
  stream@state$closed <- TRUE
  invisible(TRUE)
}

S7::method(rho_stream_collect, RhoStream) <- function(stream, limit = Inf, timeout = NULL, ...) {
  values <- list()
  while (length(values) < limit) {
    item <- rho_await(rho_stream_next(stream), timeout = timeout)
    if (S7::S7_inherits(item, RhoStreamEnd)) {
      break
    }
    values[[length(values) + 1L]] <- item@value
  }
  values
}

S7::method(rho_stream_map, RhoStream) <- function(stream, f, ...) {
  if (!is.function(f)) {
    rho_abort("`f` must be a function")
  }
  RhoMappedStream(
    state = rho_new_state(
      source = stream,
      f = f,
      closed = FALSE,
      created_at = Sys.time()
    )
  )
}

S7::method(rho_stream_flat_map, RhoStream) <- function(stream, f, ...) {
  if (!is.function(f)) {
    rho_abort("`f` must be a function")
  }
  RhoFlatMappedStream(
    state = rho_new_state(
      source = stream,
      f = f,
      buffer = list(),
      closed = FALSE,
      created_at = Sys.time()
    )
  )
}

S7::method(rho_stream_next, RhoMappedStream) <- function(stream, timeout = NULL, ...) {
  rho_then(rho_stream_next(stream@state$source), function(item) {
    if (S7::S7_inherits(item, RhoStreamEnd)) {
      stream@state$closed <- TRUE
      return(item)
    }
    rho_stream_value(stream@state$f(item@value))
  })
}

rho_flat_mapped_stream_next <- function(stream) {
  if (length(stream@state$buffer)) {
    value <- stream@state$buffer[[1L]]
    stream@state$buffer <- stream@state$buffer[-1L]
    return(rho_task(rho_stream_value(value)))
  }

  rho_then(rho_stream_next(stream@state$source), function(item) {
    if (S7::S7_inherits(item, RhoStreamEnd)) {
      stream@state$closed <- TRUE
      return(item)
    }
    values <- stream@state$f(item@value)
    if (is.null(values)) {
      values <- list()
    }
    if (!is.list(values)) {
      rho_abort("A flat-map function must return a list or NULL")
    }
    stream@state$buffer <- values
    rho_flat_mapped_stream_next(stream)
  })
}

S7::method(rho_stream_next, RhoFlatMappedStream) <- function(stream, timeout = NULL, ...) {
  rho_flat_mapped_stream_next(stream)
}

S7::method(rho_stream_next, RhoTaskStream) <- function(stream, timeout = NULL, ...) {
  if (is.null(stream@state$source)) {
    return(rho_then(stream@state$task, function(source) {
      if (!rho_is_stream(source)) {
        rho_abort("A task-backed stream must resolve to a RhoStream")
      }
      stream@state$source <- source
      rho_stream_next(source)
    }))
  }
  rho_then(rho_stream_next(stream@state$source), function(item) {
    if (S7::S7_inherits(item, RhoStreamEnd)) {
      stream@state$closed <- TRUE
    }
    item
  })
}

S7::method(rho_stream_close, RhoTaskStream) <- function(stream, ...) {
  if (is.null(stream@state$source)) {
    rho_cancel(stream@state$task, reason = "stream closed")
  } else {
    rho_stream_close(stream@state$source)
  }
  stream@state$closed <- TRUE
  invisible(TRUE)
}
