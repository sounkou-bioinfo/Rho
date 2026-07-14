OpenAIProvider <- S7::new_class(
  "OpenAIProvider",
  properties = list(
    base_url = S7::class_character,
    http = rho.http::RhoHttpClient
  )
)

rho_openai_provider <- function(
  base_url = "https://api.openai.com/v1",
  http = rho.http::rho_http_client()
) {
  OpenAIProvider(base_url = base_url, http = http)
}

rho_openai_chat_request <- function(provider, model, context, options = list()) {
  rho_build_provider_request(provider, model, context, options = options)
}

S7::method(
  rho_build_provider_request,
  list(OpenAIProvider, Model, Context)
) <- function(provider, model, context, options = list(), ...) {
  auth <- options$auth
  if (!S7::S7_inherits(auth, RhoModelAuth) || !nzchar(auth@api_key)) {
    rho_abort("OpenAI requests require explicit resolved auth in `options$auth`")
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
  if (nzchar(context@system_prompt)) {
    messages <- c(list(list(role = "system", content = context@system_prompt)), messages)
  }
  request_body <- list(
    model = model@id,
    messages = messages,
    stream = isTRUE(options$stream %||% TRUE)
  )
  headers <- utils::modifyList(
    list(
      Authorization = paste("Bearer", auth@api_key),
      `Content-Type` = "application/json"
    ),
    auth@headers
  )
  base_url <- if (nzchar(auth@base_url)) auth@base_url else provider@base_url
  rho.http::rho_http_request(
    "POST",
    paste0(sub("/+$", "", base_url), "/chat/completions"),
    headers = headers,
    body = request_body,
    timeout_ms = as.integer(options$timeout_ms %||% 120000L),
    response_headers = "content-type",
    convert = TRUE
  )
}

rho_openai_sse_task <- function(provider, model, context, options = list()) {
  options$stream <- TRUE
  request <- rho_openai_chat_request(provider, model, context, options)
  rho.http::rho_sse_connect(provider@http, request)
}
