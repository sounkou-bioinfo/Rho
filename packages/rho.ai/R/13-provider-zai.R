ThinkingControl <- S7::new_class("ThinkingControl", abstract = TRUE)

ZaiThinkingControl <- S7::new_class(
  "ZaiThinkingControl",
  parent = ThinkingControl,
  properties = list(preserve_previous = rho_scalar_logical)
)

ToolCallStreamingPolicy <- S7::new_class("ToolCallStreamingPolicy", abstract = TRUE)
BufferedToolCallStreaming <- S7::new_class(
  "BufferedToolCallStreaming",
  parent = ToolCallStreamingPolicy
)
ZaiToolCallStreaming <- S7::new_class(
  "ZaiToolCallStreaming",
  parent = ToolCallStreamingPolicy
)

ZaiChatCompletionsModel <- S7::new_class(
  "ZaiChatCompletionsModel",
  parent = OpenAIChatCompletionsModel,
  properties = list(
    thinking_control = ThinkingControl,
    tool_call_streaming = ToolCallStreamingPolicy
  )
)

ZaiEndpoint <- S7::new_class(
  "ZaiEndpoint",
  abstract = TRUE,
  properties = list(
    provider_id = rho_non_empty_string,
    name = rho_non_empty_string,
    base_url = rho_non_empty_string
  )
)
ZaiCodingEndpoint <- S7::new_class("ZaiCodingEndpoint", parent = ZaiEndpoint)
ZaiGeneralEndpoint <- S7::new_class("ZaiGeneralEndpoint", parent = ZaiEndpoint)

ZaiApi <- S7::new_class(
  "ZaiApi",
  properties = list(endpoint = ZaiEndpoint, http = rho.http::RhoHttpClient)
)

ZaiApiKeyAuth <- S7::new_class(
  "ZaiApiKeyAuth",
  properties = list(name = rho_non_empty_string, provider_id = rho_non_empty_string)
)

S7::method(
  rho_model_expression,
  list(ZaiModelCatalogProvider, OpenAIChatCompletionsProtocol, ModelCatalogRecord)
) <- function(provider, protocol, record, ...) {
  extra <- substitute(
    list(
      thinking_control = ZaiThinkingControl(preserve_previous = preserve),
      tool_call_streaming = ZaiToolCallStreaming()
    ),
    list(preserve = provider@preserve_thinking)
  )
  rho_catalog_model_call(
    "ZaiChatCompletionsModel",
    record,
    api = "openai-chat-completions",
    extra = extra
  )
}

rho_zai_coding_endpoint <- function() {
  ZaiCodingEndpoint(
    provider_id = "zai",
    name = "Z.ai Coding Plan",
    base_url = "https://api.z.ai/api/coding/paas/v4"
  )
}

rho_zai_china_coding_endpoint <- function() {
  ZaiCodingEndpoint(
    provider_id = "zai-coding-cn",
    name = "Z.ai Coding Plan China",
    base_url = "https://open.bigmodel.cn/api/coding/paas/v4"
  )
}

rho_zai_general_endpoint <- function() {
  ZaiGeneralEndpoint(
    provider_id = "zai-api",
    name = "Z.ai API",
    base_url = "https://api.z.ai/api/paas/v4"
  )
}

rho_apply_thinking_control <- S7::new_generic(
  "rho_apply_thinking_control",
  "control",
  function(control, request, model, options = list(), ...) S7::S7_dispatch()
)

S7::method(rho_apply_thinking_control, ThinkingControl) <- function(
  control,
  request,
  model,
  options = list(),
  ...
) {
  request
}

S7::method(rho_apply_thinking_control, ZaiThinkingControl) <- function(
  control,
  request,
  model,
  options = list(),
  ...
) {
  level <- options$reasoning_effort %||% "max"
  mapped <- rho_map_thinking_level(model, level)
  enabled <- !identical(level, "off") && !mapped %in% c("none", "minimal")
  request$thinking <- list(
    type = if (enabled) "enabled" else "disabled",
    clear_thinking = !control@preserve_previous
  )
  if (enabled) {
    request$reasoning_effort <- mapped
  }
  request
}

rho_apply_tool_call_streaming <- S7::new_generic(
  "rho_apply_tool_call_streaming",
  "policy",
  function(policy, request, has_tools, ...) S7::S7_dispatch()
)

S7::method(rho_apply_tool_call_streaming, BufferedToolCallStreaming) <- function(
  policy,
  request,
  has_tools,
  ...
) {
  request
}

S7::method(rho_apply_tool_call_streaming, ZaiToolCallStreaming) <- function(
  policy,
  request,
  has_tools,
  ...
) {
  if (isTRUE(has_tools)) {
    request$tool_stream <- TRUE
  }
  request
}

rho_openai_chat_message <- S7::new_generic(
  "rho_openai_chat_message",
  "message",
  function(message, ...) S7::S7_dispatch()
)

S7::method(rho_openai_chat_message, UserMessage) <- function(message, ...) {
  list(role = "user", content = rho_openai_content_text(message@content))
}

S7::method(rho_openai_chat_message, AssistantMessage) <- function(message, ...) {
  text <- paste(
    vapply(
      Filter(function(content) S7::S7_inherits(content, TextContent), message@content),
      function(content) content@text,
      character(1)
    ),
    collapse = ""
  )
  thinking <- paste(
    vapply(
      Filter(function(content) S7::S7_inherits(content, ThinkingContent), message@content),
      function(content) content@text,
      character(1)
    ),
    collapse = ""
  )
  calls <- Filter(function(content) S7::S7_inherits(content, ToolCall), message@content)
  value <- list(role = "assistant", content = text)
  if (nzchar(thinking)) {
    value$reasoning_content <- thinking
  }
  if (length(calls)) {
    value$tool_calls <- unname(lapply(calls, function(call) {
      list(
        id = call@id,
        type = "function",
        `function` = list(
          name = call@name,
          arguments = yyjsonr::write_json_str(call@arguments, auto_unbox = TRUE)
        )
      )
    }))
  }
  value
}

S7::method(rho_openai_chat_message, ToolResultMessage) <- function(message, ...) {
  list(
    role = "tool",
    tool_call_id = message@tool_call_id,
    content = rho_openai_content_text(message@content)
  )
}

S7::method(rho_openai_chat_message, S7::class_any) <- function(message, ...) NULL

rho_openai_chat_messages <- function(context) {
  messages <- Filter(
    Negate(is.null),
    lapply(context@messages, rho_openai_chat_message)
  )
  if (nzchar(context@system_prompt)) {
    messages <- c(list(list(role = "system", content = context@system_prompt)), messages)
  }
  messages
}

rho_openai_chat_tools <- function(tools) {
  unname(lapply(tools, function(tool) {
    list(
      type = "function",
      `function` = list(
        name = tool@name,
        description = tool@description,
        parameters = tool@parameters
      )
    )
  }))
}

rho_zai_request_body <- function(model, context, options = list()) {
  request <- list(
    model = model@id,
    messages = rho_openai_chat_messages(context),
    stream = TRUE,
    stream_options = list(include_usage = TRUE)
  )
  has_tools <- model@capabilities@tools && length(context@tools) > 0L
  if (has_tools) {
    request$tools <- rho_openai_chat_tools(context@tools)
    request$tool_choice <- "auto"
  }
  if (!is.null(options$max_tokens)) {
    request$max_tokens <- as.integer(options$max_tokens)
  }
  if (!is.null(options$temperature)) {
    request$temperature <- as.double(options$temperature)
  }
  if (!is.null(options$top_p)) {
    request$top_p <- as.double(options$top_p)
  }
  request <- rho_apply_thinking_control(
    model@thinking_control,
    request,
    model,
    options
  )
  rho_apply_tool_call_streaming(model@tool_call_streaming, request, has_tools)
}

S7::method(rho_auth_login, ZaiApiKeyAuth) <- function(auth, provider_id, io, ...) {
  rho.async::rho_then(
    rho_auth_prompt(
      io,
      RhoSecretAuthPrompt(
        message = sprintf("Enter the API key for %s:", auth@name),
        placeholder = ""
      )
    ),
    function(key) {
      if (!is.character(key) || length(key) != 1L || !nzchar(key)) {
        return(rho_auth_error("Z.ai API key was not supplied", code = "missing"))
      }
      rho_api_key_credential(auth@provider_id, key, source = "login")
    }
  )
}

S7::method(rho_auth_to_request, ZaiApiKeyAuth) <- function(auth, credential, ...) {
  valid <- S7::S7_inherits(credential, RhoApiKeyCredential) &&
    identical(credential@provider, auth@provider_id) &&
    nzchar(credential@state$key)
  if (!valid) {
    return(rho.async::rho_task(rho_auth_error(
      "Z.ai request auth requires a matching API-key credential",
      code = "credential_type"
    )))
  }
  rho.async::rho_task(rho_model_auth(
    api_key = credential@state$key,
    metadata = list(provider = credential@provider, source = credential@source)
  ))
}

rho_zai_glm_5_2 <- function(
  provider_id = "zai",
  base_url = "https://api.z.ai/api/coding/paas/v4",
  preserve_thinking = TRUE
) {
  catalog <- rho_default_model_catalog()
  record <- rho_catalog_records_for(catalog, "zai", "glm-5.2")[[1L]]
  provider <- ZaiModelCatalogProvider(
    id = provider_id,
    name = record@provider@name,
    base_url = base_url,
    preserve_thinking = isTRUE(preserve_thinking)
  )
  rho_compile_catalog_model(rho_catalog_record_with_provider(record, provider))
}

rho_zai_provider <- function(
  endpoint = rho_zai_coding_endpoint(),
  http = rho.http::rho_http_client(timeout_ms = 120000L)
) {
  api <- ZaiApi(endpoint = endpoint, http = http)
  rho_provider(
    id = endpoint@provider_id,
    name = endpoint@name,
    implementation = api,
    auth = rho_provider_auth(
      api_key = ZaiApiKeyAuth(
        name = endpoint@name,
        provider_id = endpoint@provider_id
      )
    ),
    models = list(rho_zai_glm_5_2(
      provider_id = endpoint@provider_id,
      base_url = endpoint@base_url,
      preserve_thinking = S7::S7_inherits(endpoint, ZaiCodingEndpoint)
    ))
  )
}

rho_zai_request <- function(provider, model, context, options = list()) {
  rho_build_provider_request(provider, model, context, options = options)
}

S7::method(
  rho_build_provider_request,
  list(ZaiApi, ZaiChatCompletionsModel, Context)
) <- function(provider, model, context, options = list(), ...) {
  auth <- options$auth
  if (!S7::S7_inherits(auth, RhoModelAuth) || !nzchar(auth@api_key)) {
    rho_abort("Z.ai requests require explicit resolved auth in `options$auth`")
  }
  base_url <- if (nzchar(auth@base_url)) auth@base_url else provider@endpoint@base_url
  headers <- utils::modifyList(
    list(
      Authorization = paste("Bearer", auth@api_key),
      Accept = "text/event-stream",
      `Content-Type` = "application/json"
    ),
    rho_provider_headers(provider, model, context, options = options)
  )
  headers <- utils::modifyList(headers, auth@headers)
  rho.http::rho_http_request(
    method = "POST",
    url = paste0(sub("/+$", "", base_url), "/chat/completions"),
    headers = headers,
    body = rho_zai_request_body(model, context, options),
    timeout_ms = as.integer(options$timeout_ms %||% 120000L),
    response_headers = c("content-type", "retry-after"),
    convert = TRUE
  )
}

S7::method(rho_stream, list(ZaiApi, ZaiChatCompletionsModel, Context)) <- function(
  provider,
  model,
  context,
  options = list(),
  ...
) {
  request <- rho_zai_request(provider, model, context, options)
  stream <- rho.http::rho_sse_connect(provider@http, request)
  decoder <- rho_openai_chat_decoder(model)
  rho.async::rho_stream_flat_map(
    stream,
    function(event) rho_decode_provider_event(decoder, event)
  )
}
