rho_nanonext_websocket_close <- function(socket) {
  if (!isTRUE(socket@state$closed)) {
    close(socket@state$connection)
    socket@state$closed <- TRUE
  }
  invisible(TRUE)
}

rho_nanonext_websocket_error <- function(socket, error, operation) {
  RhoWebSocketTransportError(
    message = sprintf("WebSocket %s failed: %s", operation, conditionMessage(error)),
    url = socket@url,
    parent = error
  )
}

S7::method(rho_stream_next, RhoNanonextWebSocket) <- function(
  stream,
  timeout = NULL,
  ...
) {
  if (isTRUE(stream@state$closed)) {
    return(rho.async::rho_task(rho.async::rho_stream_end()))
  }
  timeout_ms <- if (is.null(timeout)) stream@state$timeout_ms else as.integer(timeout)
  mode <- if (isTRUE(stream@state$textframes)) "character" else "raw"
  receiving <- rho.async::rho_wrap_aio(nanonext::recv_aio(
    stream@state$connection,
    mode = mode,
    timeout = timeout_ms
  ))
  item <- rho.async::rho_then(
    receiving,
    function(value) rho.async::rho_stream_value(value)
  )
  handled <- rho.async::rho_catch(item, function(error) {
    rho_nanonext_websocket_close(stream)
    rho.async::rho_stream_value(rho_nanonext_websocket_error(
      stream,
      error,
      "receive"
    ))
  })
  rho.async::rho_task_from_promise(
    rho.async::rho_as_promise(handled),
    cancel = function(reason) {
      rho.async::rho_cancel(handled, reason)
      rho_nanonext_websocket_close(stream)
    },
    label = "websocket-receive"
  )
}

S7::method(rho_duplex_send, RhoNanonextWebSocket) <- function(
  duplex,
  value,
  timeout = NULL,
  ...
) {
  if (isTRUE(duplex@state$closed)) {
    return(rho.async::rho_task(RhoWebSocketTransportError(
      message = "WebSocket is closed",
      url = duplex@url,
      parent = NULL
    )))
  }
  timeout_ms <- if (is.null(timeout)) duplex@state$timeout_ms else as.integer(timeout)
  sending <- rho.async::rho_wrap_aio(
    nanonext::send_aio(
      duplex@state$connection,
      value,
      mode = "raw",
      timeout = timeout_ms
    ),
    collect = function(handle) {
      nanonext::call_aio_(handle)
      handle$result
    }
  )
  sent <- rho.async::rho_then(sending, function(result) {
    if (!identical(result, 0L)) {
      return(RhoWebSocketTransportError(
        message = sprintf("WebSocket send returned status %s", result),
        url = duplex@url,
        parent = NULL
      ))
    }
    NULL
  })
  handled <- rho.async::rho_catch(sent, function(error) {
    rho_nanonext_websocket_close(duplex)
    rho_nanonext_websocket_error(duplex, error, "send")
  })
  rho.async::rho_task_from_promise(
    rho.async::rho_as_promise(handled),
    cancel = function(reason) {
      rho.async::rho_cancel(handled, reason)
      rho_nanonext_websocket_close(duplex)
    },
    label = "websocket-send"
  )
}

S7::method(rho_stream_close, RhoNanonextWebSocket) <- function(
  stream,
  ...
) {
  rho_nanonext_websocket_close(stream)
}
