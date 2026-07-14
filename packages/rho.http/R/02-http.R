rho_http_client <- function(headers = list(), timeout_ms = 30000L, tls = nanonext::tls_config()) {
  RhoHttpClient(headers = headers, timeout_ms = as.integer(timeout_ms), tls = tls)
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
