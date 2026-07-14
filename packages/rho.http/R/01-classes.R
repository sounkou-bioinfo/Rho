rho_non_empty_string <- S7::new_property(
  S7::class_character,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || !nzchar(value)) "must be one non-empty string"
  }
)

RhoHttpClient <- S7::new_class(
  "RhoHttpClient",
  properties = list(
    headers = S7::class_list,
    timeout_ms = S7::class_integer,
    tls = S7::class_any
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
