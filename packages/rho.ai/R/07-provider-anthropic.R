AnthropicProvider <- S7::new_class(
  "AnthropicProvider",
  properties = list(
    base_url = S7::class_character,
    version = S7::class_character,
    http = rho.http::RhoHttpClient
  )
)

rho_anthropic_provider <- function(
  base_url = "https://api.anthropic.com/v1",
  version = "2023-06-01",
  http = rho.http::rho_http_client()
) {
  AnthropicProvider(base_url = base_url, version = version, http = http)
}

rho_anthropic_messages_request <- function(provider, model, context, options = list()) {
  rho_build_provider_request(provider, model, context, options = options)
}

S7::method(
  rho_build_provider_request,
  list(AnthropicProvider, Model, Context)
) <- function(provider, model, context, options = list(), ...) {
  auth <- options$auth
  if (!S7::S7_inherits(auth, RhoModelAuth) || !nzchar(auth@api_key)) {
    rho_abort("Anthropic requests require explicit resolved auth in `options$auth`")
  }
  messages <- lapply(context@messages, function(message) {
    if (S7::S7_inherits(message, UserMessage)) {
      list(role = "user", content = as.character(message@content))
    } else if (S7::S7_inherits(message, AssistantMessage)) {
      list(
        role = "assistant",
        content = paste(
          vapply(
            message@content,
            function(content) {
              if (S7::S7_inherits(content, TextContent)) content@text else ""
            },
            character(1)
          ),
          collapse = ""
        )
      )
    } else {
      NULL
    }
  })
  messages <- Filter(Negate(is.null), messages)
  request_body <- list(
    model = model@id,
    messages = messages,
    max_tokens = model@limits@max_tokens,
    stream = isTRUE(options$stream %||% TRUE)
  )
  if (nzchar(context@system_prompt)) {
    request_body$system <- context@system_prompt
  }
  headers <- utils::modifyList(
    list(
      `x-api-key` = auth@api_key,
      `anthropic-version` = provider@version,
      `Content-Type` = "application/json"
    ),
    auth@headers
  )
  base_url <- if (nzchar(auth@base_url)) auth@base_url else provider@base_url
  rho.http::rho_http_request(
    "POST",
    paste0(sub("/+$", "", base_url), "/messages"),
    headers = headers,
    body = request_body,
    timeout_ms = as.integer(options$timeout_ms %||% 120000L),
    response_headers = "content-type",
    convert = TRUE
  )
}

rho_anthropic_sse_task <- function(provider, model, context, options = list()) {
  options$stream <- TRUE
  request <- rho_anthropic_messages_request(provider, model, context, options)
  rho.http::rho_sse_connect(provider@http, request)
}
