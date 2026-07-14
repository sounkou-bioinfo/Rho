rho_abort <- function(..., call. = FALSE) stop(sprintf(...), call. = call.)

rho_normalize_http_headers <- function(headers) {
  if (is.null(headers) || !length(headers)) {
    return(NULL)
  }
  if (is.list(headers)) {
    headers <- unlist(headers, use.names = TRUE)
  }
  if (!is.character(headers) || is.null(names(headers)) || any(!nzchar(names(headers)))) {
    rho_abort("HTTP headers must be a named character vector or named list")
  }
  headers
}

rho_encode_http_body <- function(body, headers) {
  if (is.null(body)) {
    return(list(data = NULL, headers = headers))
  }
  if (is.raw(body) || is.character(body)) {
    return(list(data = body, headers = headers))
  }
  if (is.list(body)) {
    if (!any(tolower(names(headers %||% character())) == "content-type")) {
      headers <- c(headers %||% character(), `Content-Type` = "application/json")
    }
    return(list(
      data = yyjsonr::write_json_str(body, auto_unbox = TRUE, null = "null"),
      headers = headers
    ))
  }
  rho_abort("HTTP body must be NULL, raw, character, or list")
}
