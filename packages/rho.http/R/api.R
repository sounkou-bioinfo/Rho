#' Asynchronous HTTP and server-sent event contracts
#'
#' `RhoHttpRequest` is a typed request value. [rho_http_send()] returns a task
#' resolving to `RhoHttpResponse`. [rho_sse_connect()] exposes decoded
#' `RhoSseEvent` values through the common Rho stream protocol.
#'
#' TLS configuration is an explicit property of `RhoHttpClient` and is created
#' in memory by `nanonext::tls_config()`; this package does not search the host
#' filesystem for certificate bundles.
#'
#' @name rho_http_contracts
#' @aliases RhoHttpClient RhoHttpRequest RhoHttpResponse RhoSseEvent
#' @aliases rho_http_client rho_http_request rho_http_send rho_sse_connect
#' @aliases rho_sse_parse
#' @export RhoHttpClient
#' @export RhoHttpRequest
#' @export RhoHttpResponse
#' @export RhoSseEvent
#' @export rho_http_client
#' @export rho_http_request
#' @export rho_http_send
#' @export rho_sse_connect
#' @export rho_sse_parse
NULL
