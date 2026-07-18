#' Worker-owned httr2 implementation of the Rho HTTP contract
#'
#' `rho_httr2_http_client()` constructs an `HttpClient` whose httr2 connection
#' lives in a compute worker. The worker sends a typed response head, raw body
#' chunks, completion, or an error value over a private localhost NNG socket.
#' The calling process receives those values through `RhoTask` and `RhoStream`
#' without parsing HTTP or waiting for httr2's synchronous response-head open.
#'
#' Complete requests also execute through the selected compute backend. Closing
#' a body stream or client closes its NNG socket and cancels the owning compute
#' task. The default compute backend is mirai; callers may supply another
#' `RhoComputeBackend` that preserves the same call specification semantics.
#' [rho.http::rho_http_open_execution()] returns `RhoHttpWorkerOpen` for this
#' client because connection setup and receipt of the response head occur in
#' that selected worker.
#'
#' @name rho_http_httr2
#' @aliases RhoHttr2HttpClient RhoHttr2HttpBodyStream
#' @aliases rho_httr2_http_client
#' @export RhoHttr2HttpClient
#' @export RhoHttr2HttpBodyStream
#' @export rho_httr2_http_client
#' @importFrom rho.http RhoHttpResponseHead rho_http_client_close
#' @importFrom rho.http rho_http_open_execution rho_http_open_stream rho_http_send
#' @importFrom rho.async rho_stream_close rho_stream_next
NULL
