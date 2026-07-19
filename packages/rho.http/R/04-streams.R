rho_nanonext_http_close <- function(stream) {
  if (!isTRUE(stream@state$closed)) {
    close(stream@state$connection)
    stream@state$closed <- TRUE
  }
  invisible(TRUE)
}

S7::method(rho_stream_next, RhoNanonextHttpBodyStream) <- function(
  stream,
  timeout = NULL,
  ...
) {
  if (isTRUE(stream@state$closed)) {
    return(rho.async::rho_task(rho.async::rho_stream_end()))
  }
  if (isTRUE(stream@state$complete)) {
    rho_nanonext_http_close(stream)
    return(rho.async::rho_task(rho.async::rho_stream_end()))
  }

  timeout_ms <- if (is.null(timeout)) stream@state$timeout_ms else as.integer(timeout)
  aio <- nanonext::ncurl_stream_recv(stream@state$connection, timeout = timeout_ms)
  receiving <- rho.async::rho_wrap_aio(aio)
  next_item <- rho.async::rho_then(receiving, function(result) {
    stream@state$complete <- isTRUE(result$complete)
    if (!length(result$data) && stream@state$complete) {
      rho_nanonext_http_close(stream)
      return(rho.async::rho_stream_end())
    }
    rho.async::rho_stream_value(result$data)
  })
  handled <- rho.async::rho_catch(next_item, function(error) {
    rho_nanonext_http_close(stream)
    rho.async::rho_stream_value(RhoHttpTransportError(
      message = sprintf("HTTP stream receive failed: %s", conditionMessage(error)),
      url = stream@head@url,
      parent = error
    ))
  })
  rho.async::rho_task_from_promise(
    rho.async::rho_as_promise(handled),
    cancel = function(reason) {
      rho.async::rho_cancel(handled, reason)
      rho_nanonext_http_close(stream)
    },
    label = "http-stream-receive"
  )
}

S7::method(rho_stream_close, RhoNanonextHttpBodyStream) <- function(stream, ...) {
  rho_nanonext_http_close(stream)
}

rho_sse_buffer_next <- function(stream) {
  if (!length(stream@state$buffer)) {
    return(NULL)
  }
  event <- stream@state$buffer[[1L]]
  stream@state$buffer <- stream@state$buffer[-1L]
  rho.async::rho_task(rho.async::rho_stream_value(event))
}

rho_sse_stream_next <- function(stream, timeout) {
  buffered <- rho_sse_buffer_next(stream)
  if (!is.null(buffered)) {
    return(buffered)
  }
  if (isTRUE(stream@state$closed)) {
    return(rho.async::rho_task(rho.async::rho_stream_end()))
  }

  rho.async::rho_then(
    rho.async::rho_stream_next(stream@state$source, timeout = timeout),
    function(item) {
      if (S7::S7_inherits(item, rho.async::RhoAsyncError)) {
        stream@state$closed <- TRUE
        return(item)
      }
      if (S7::S7_inherits(item, rho.async::RhoStreamEnd)) {
        rho_sse_decode(stream@state$decoder, final = TRUE)
        stream@state$closed <- TRUE
        return(rho.async::rho_stream_end())
      }
      if (!S7::S7_inherits(item, rho.async::RhoStreamValue)) {
        rho.async::rho_signal_contract_violation(
          "An SSE source stream must yield a RhoStreamValue or RhoStreamEnd"
        )
      }
      if (S7::S7_inherits(item@value, RhoHttpError)) {
        stream@state$closed <- TRUE
        return(item)
      }
      stream@state$buffer <- rho_sse_decode(
        stream@state$decoder,
        item@value
      )
      rho_sse_stream_next(stream, timeout)
    }
  )
}

S7::method(rho_stream_next, RhoSseStream) <- function(
  stream,
  timeout = NULL,
  ...
) {
  rho_sse_stream_next(stream, timeout)
}

S7::method(rho_stream_close, RhoSseStream) <- function(stream, ...) {
  if (!isTRUE(stream@state$closed)) {
    rho.async::rho_stream_close(stream@state$source)
    rho_sse_decode(stream@state$decoder, final = TRUE)
    stream@state$closed <- TRUE
  }
  invisible(TRUE)
}
