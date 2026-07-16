#' Asynchronous HTTP and server-sent event contracts
#'
#' `RhoHttpRequest` is a typed request value. `HttpClient` requires
#' [rho_http_send()] and [rho_http_open_stream()]. The latter resolves to a
#' `RhoHttpBodyStream` after the response head arrives. `RhoSseDecoder`
#' preserves protocol state across arbitrary byte chunks. [rho_sse_connect()]
#' is the default composition over any `RhoHttpClient` implementation and
#' exposes decoded `RhoSseEvent` values through the common Rho stream protocol.
#'
#' `rho_http_client()` constructs the built-in `RhoNanonextHttpClient`. Its TLS
#' configuration is created in memory by `nanonext::tls_config()`; this package
#' does not search the host filesystem for certificate bundles. Another client
#' subclasses `RhoHttpClient`, implements `HttpClient`, and returns its own
#' `RhoHttpBodyStream` subclass with stream-next and close methods. Providers and
#' SSE decoding do not depend on its connection handle.
#'
#' @name rho_http_contracts
#' @aliases HttpClient RhoHttpClient RhoNanonextHttpClient
#' @aliases RhoHttpRequest RhoHttpPayload RhoHttpResponse RhoHttpResponseHead
#' @aliases RhoHttpBodyStream RhoNanonextHttpBodyStream
#' @aliases RhoSseEvent RhoSseDecoder RhoSseStream
#' @aliases RhoHttpError RhoHttpTransportError RhoHttpStatusError
#' @aliases rho_http_client rho_http_request rho_http_payload rho_http_send
#' @aliases rho_http_open_stream rho_http_client_close
#' @aliases rho_sse_connect
#' @aliases rho_sse_decoder rho_sse_decode rho_sse_parse
#' @export RhoHttpClient
#' @export RhoNanonextHttpClient
#' @export RhoHttpRequest
#' @export RhoHttpPayload
#' @export RhoHttpResponse
#' @export RhoHttpResponseHead
#' @export RhoHttpBodyStream
#' @export RhoNanonextHttpBodyStream
#' @export HttpClient
#' @export RhoSseEvent
#' @export RhoSseDecoder
#' @export RhoSseStream
#' @export RhoHttpError
#' @export RhoHttpTransportError
#' @export RhoHttpStatusError
#' @export rho_http_client
#' @export rho_http_request
#' @export rho_http_payload
#' @export rho_http_send
#' @export rho_http_open_stream
#' @export rho_http_client_close
#' @export rho_sse_connect
#' @export rho_sse_decoder
#' @export rho_sse_decode
#' @export rho_sse_parse
#' @importFrom rho.async rho_stream_close rho_stream_next
#' @importFrom s7contract interface_requirement new_interface
NULL
