rho_http_client <- function(
  headers = list(),
  timeout_ms = 30000L,
  tls = nanonext::tls_config(),
  stream_buffer_size = 65536L,
  max_error_body_bytes = 1048576L
) {
  RhoHttpClient(
    headers = headers,
    timeout_ms = as.integer(timeout_ms),
    tls = tls,
    stream_buffer_size = as.integer(stream_buffer_size),
    max_error_body_bytes = as.integer(max_error_body_bytes)
  )
}

rho_http_request <- function(
  method,
  url,
  headers = list(),
  body = NULL,
  timeout_ms = 30000L,
  response_headers = character(),
  convert = TRUE
) {
  RhoHttpRequest(
    method = toupper(method),
    url = url,
    headers = headers,
    body = body,
    timeout_ms = as.integer(timeout_ms),
    response_headers = response_headers,
    convert = isTRUE(convert)
  )
}

rho_http_send <- S7::new_generic(
  "rho_http_send",
  c("client", "request"),
  function(client, request, ...) S7::S7_dispatch()
)

S7::method(rho_http_send, list(RhoHttpClient, RhoHttpRequest)) <- function(client, request, ...) {
  headers <- c(
    rho_normalize_http_headers(client@headers),
    rho_normalize_http_headers(request@headers)
  )
  bh <- rho_encode_http_body(request@body, headers)
  data <- bh$data
  headers <- bh$headers
  aio <- nanonext::ncurl_aio(
    url = request@url,
    convert = request@convert,
    method = request@method,
    headers = headers,
    data = data,
    response = request@response_headers,
    timeout = request@timeout_ms %||% client@timeout_ms,
    tls = client@tls
  )
  task <- rho.async::rho_wrap_aio(aio, collect = function(handle) {
    nanonext::call_aio_(handle)
    list(status = handle$status, headers = handle$headers, data = handle$data)
  })
  rho.async::rho_then(task, function(res) {
    RhoHttpResponse(
      status = as.integer(res$status %||% NA_integer_),
      headers = res$headers %||% list(),
      data = res$data,
      url = request@url
    )
  })
}

rho_http_open_stream <- S7::new_generic(
  "rho_http_open_stream",
  c("client", "request"),
  function(client, request, ...) S7::S7_dispatch()
)

S7::method(rho_http_open_stream, list(RhoHttpClient, RhoHttpRequest)) <- function(
  client,
  request,
  ...
) {
  headers <- c(
    rho_normalize_http_headers(client@headers),
    rho_normalize_http_headers(request@headers)
  )
  encoded <- rho_encode_http_body(request@body, headers)
  timeout_ms <- request@timeout_ms %||% client@timeout_ms
  aio <- nanonext::ncurl_stream_aio(
    url = request@url,
    method = request@method,
    headers = encoded$headers,
    data = encoded$data,
    timeout = timeout_ms,
    tls = client@tls,
    buffer = client@stream_buffer_size
  )
  opening <- rho.async::rho_wrap_aio(aio)
  stream <- rho.async::rho_then(opening, function(result) {
    head <- RhoHttpResponseHead(
      status = as.integer(result$status),
      headers = result$headers %||% list(),
      url = request@url
    )
    state <- new.env(parent = emptyenv())
    state$connection <- result$stream
    state$head <- head
    state$timeout_ms <- timeout_ms
    state$complete <- FALSE
    state$closed <- FALSE
    state$created_at <- Sys.time()
    RhoHttpBodyStream(state = state)
  })
  rho.async::rho_catch(stream, function(error) {
    RhoHttpTransportError(
      message = sprintf("HTTP stream could not be opened: %s", conditionMessage(error)),
      url = request@url,
      parent = error
    )
  })
}
