rho_non_empty_string <- S7::new_property(
  S7::class_character,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || !nzchar(value)) "must be one non-empty string"
  }
)

rho_positive_integer <- S7::new_property(
  S7::class_integer,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || value <= 0L) "must be one positive integer"
  }
)

RhoHttpClient <- S7::new_class(
  "RhoHttpClient",
  properties = list(
    headers = S7::class_list,
    timeout_ms = S7::class_integer,
    tls = S7::class_any,
    stream_buffer_size = rho_positive_integer
  )
)

RhoHttpResponseHead <- S7::new_class(
  "RhoHttpResponseHead",
  properties = list(
    status = S7::class_integer,
    headers = S7::class_list,
    url = rho_non_empty_string
  )
)

RhoHttpRequest <- S7::new_class(
  "RhoHttpRequest",
  properties = list(
    method = rho_non_empty_string,
    url = rho_non_empty_string,
    headers = S7::class_list,
    body = S7::class_any,
    timeout_ms = S7::class_integer,
    response_headers = S7::class_character,
    convert = S7::class_logical
  ),
  validator = function(self) {
    if (!toupper(self@method) %in% c("GET", "POST", "PUT", "PATCH", "DELETE", "HEAD")) {
      "@method must be GET, POST, PUT, PATCH, DELETE, or HEAD"
    }
  }
)

RhoHttpResponse <- S7::new_class(
  "RhoHttpResponse",
  properties = list(
    status = S7::class_integer,
    headers = S7::class_list,
    data = S7::class_any,
    url = S7::class_character
  )
)

RhoSseEvent <- S7::new_class(
  "RhoSseEvent",
  properties = list(
    event = S7::class_character,
    data = S7::class_character,
    id = S7::class_character,
    retry = S7::class_integer
  )
)

RhoSseDecoder <- S7::new_class(
  "RhoSseDecoder",
  properties = list(state = S7::class_environment),
  validator = function(self) {
    required <- c(
      "buffer",
      "started",
      "data",
      "event",
      "last_event_id",
      "retry",
      "closed"
    )
    missing <- setdiff(required, ls(self@state, all.names = TRUE))
    if (length(missing)) {
      sprintf("@state missing field(s): %s", paste(missing, collapse = ", "))
    }
  }
)

RhoHttpBodyStream <- S7::new_class(
  "RhoHttpBodyStream",
  parent = rho.async::RhoStream
)

RhoSseStream <- S7::new_class(
  "RhoSseStream",
  parent = rho.async::RhoStream
)

RhoHttpError <- S7::new_class(
  "RhoHttpError",
  abstract = TRUE,
  properties = list(
    message = rho_non_empty_string,
    url = rho_non_empty_string
  )
)

RhoHttpTransportError <- S7::new_class(
  "RhoHttpTransportError",
  parent = RhoHttpError,
  properties = list(parent = S7::class_any)
)

RhoHttpStatusError <- S7::new_class(
  "RhoHttpStatusError",
  parent = RhoHttpError,
  properties = list(
    status = S7::class_integer,
    headers = S7::class_list
  )
)
