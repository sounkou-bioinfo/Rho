OllamaProvider <- S7::new_class(
  "OllamaProvider",
  properties = list(
    base_url = S7::class_character,
    http = rho.http::RhoHttpClient
  )
)

rho_ollama_provider <- function(
  base_url = "http://localhost:11434",
  http = rho.http::rho_http_client()
) {
  OllamaProvider(base_url = base_url, http = http)
}

rho_ollama_chat_request <- function(provider, model, context, stream = TRUE) {
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
  request_body <- list(model = model@id, messages = messages, stream = isTRUE(stream))
  rho.http::rho_http_request(
    "POST",
    paste0(provider@base_url, "/api/chat"),
    headers = list(`Content-Type` = "application/json"),
    body = request_body,
    timeout_ms = 120000L,
    response_headers = "content-type",
    convert = TRUE
  )
}

rho_ollama_chat_task <- function(provider, model, context, options = list()) {
  request <- rho_ollama_chat_request(provider, model, context, stream = TRUE)
  rho.http::rho_http_send(provider@http, request)
}
