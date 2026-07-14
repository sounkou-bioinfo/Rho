#' Asynchronous HTTP and server-sent event contracts
#'
#' `RhoHttpRequest` is a typed request value. [rho_http_send()] returns a task
#' resolving to `RhoHttpResponse`; [rho_http_open_stream()] resolves to a
#' `RhoHttpBodyStream` after the response head arrives. `RhoSseDecoder`
#' preserves protocol state across arbitrary byte chunks. [rho_sse_connect()]
#' exposes decoded `RhoSseEvent` values through the common Rho stream protocol.
#'
#' TLS configuration is an explicit property of `RhoHttpClient` and is created
#' in memory by `nanonext::tls_config()`; this package does not search the host
#' filesystem for certificate bundles.
#'
#' @name rho_http_contracts
#' @aliases RhoHttpClient RhoHttpRequest RhoHttpResponse RhoHttpResponseHead
#' @aliases RhoHttpBodyStream RhoSseEvent RhoSseDecoder RhoSseStream
#' @aliases RhoHttpError RhoHttpTransportError RhoHttpStatusError
#' @aliases rho_http_client rho_http_request rho_http_send rho_http_open_stream
#' @aliases rho_sse_connect
#' @aliases rho_sse_decoder rho_sse_decode rho_sse_parse
#' @export RhoHttpClient
#' @export RhoHttpRequest
#' @export RhoHttpResponse
#' @export RhoHttpResponseHead
#' @export RhoHttpBodyStream
#' @export RhoSseEvent
#' @export RhoSseDecoder
#' @export RhoSseStream
#' @export RhoHttpError
#' @export RhoHttpTransportError
#' @export RhoHttpStatusError
#' @export rho_http_client
#' @export rho_http_request
#' @export rho_http_send
#' @export rho_http_open_stream
#' @export rho_sse_connect
#' @export rho_sse_decoder
#' @export rho_sse_decode
#' @export rho_sse_parse
#' @importFrom rho.async rho_stream_close rho_stream_next
NULL
