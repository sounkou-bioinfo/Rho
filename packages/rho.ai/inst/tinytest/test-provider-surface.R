# Generated from packages/rho.ai/inst/tinytest/rmd/provider-surface.Rmd; do not edit.

library(tinytest)
library(rho.async)
library(rho.ai)

provider <- rho_faux_provider()
model <- rho_model("faux", "faux")
context <- rho_context(messages = list(rho_user_message("hi")))
events <- rho_stream(provider, model, context) |> rho_stream_collect()
expect_equal(
  vapply(events, rho_assistant_event_type, character(1)),
  c("start", "text_start", "text_delta", "text_end", "done")
)
expect_equal(events[[5]]@message@content[[1]]@text, "faux: hi")

context <- rho_context("system", list(rho_user_message("hello")))
test_auth <- rho_model_auth(api_key = "test")

openai_provider <- rho_openai_provider()
openai_model <- rho_openai_model("gpt-5.4")
openai <- rho_openai_request(
  openai_provider,
  openai_model,
  context,
  options = list(auth = test_auth)
)
expect_equal(openai@method, "POST")
expect_true(grepl("/responses$", openai@url))
expect_equal(openai@headers$Authorization, "Bearer test")
expect_identical(openai@body$store, FALSE)
expect_identical(openai@body$stream, TRUE)
expect_true(S7::S7_inherits(openai_model, OpenAIResponsesModel))

anthropic <- rho_anthropic_messages_request(
  rho_anthropic_provider(),
  rho_model("anthropic", "claude-test"),
  context,
  options = list(auth = test_auth)
)
expect_equal(anthropic@method, "POST")
expect_true(grepl("/messages$", anthropic@url))
expect_equal(anthropic@headers$`x-api-key`, "test")

ollama <- rho_ollama_chat_request(
  rho_ollama_provider(),
  rho_model("ollama", "llama3"),
  context
)
expect_equal(ollama@method, "POST")
expect_true(grepl("/api/chat$", ollama@url))

credential <- rho_openai_codex_credential(
  access_token = "test-access-token",
  account_id = "test-account",
  expires = Inf
)
codex <- rho_openai_codex_provider()
spark <- rho_openai_codex_spark()
resolved_auth <- rho_await(rho_auth_to_request(codex@auth@oauth, credential))
request <- rho_openai_codex_request(
  codex@implementation,
  spark,
  context,
  options = list(auth = resolved_auth)
)

expect_equal(request@url, "https://chatgpt.com/backend-api/codex/responses")
expect_equal(request@body$model, "gpt-5.3-codex-spark")
expect_identical(request@body$store, FALSE)
expect_identical(request@body$stream, TRUE)
expect_equal(request@headers$`chatgpt-account-id`, "test-account")
expect_equal(request@headers$`OpenAI-Beta`, "responses=experimental")
expect_equal(request@headers$Accept, "text/event-stream")
expect_true(s7contract::implements(OpenAICodexOAuthAuth, OAuthAuth))
expect_true(s7contract::implements(OpenAICodexApi, ProviderRequestTranslator))

named_tool <- rho_tool_spec(
  name = "r",
  description = "Evaluate R code",
  parameters = list(type = "object", properties = list()),
  execute = function(...) NULL
)
tool_context <- rho_context(
  messages = list(rho_user_message("calculate")),
  tools = list(r = named_tool)
)
tool_request <- rho_openai_codex_request(
  codex@implementation,
  spark,
  tool_context,
  options = list(auth = resolved_auth)
)
expect_true(is.null(names(tool_request@body$tools)))
encoded_tool_request <- yyjsonr::write_json_str(
  tool_request@body,
  auto_unbox = TRUE
)
expect_true(grepl('"tools":\\[', encoded_tool_request))

credentials <- rho_memory_credential_store(list(`openai-codex` = credential))
models <- rho_models(list(codex), credentials)
resolution <- rho_resolve_model_auth(models, spark) |> rho_await()

expect_true(resolution@configured)
expect_equal(resolution@source, credential@source)
expect_equal(resolution@auth@headers$`chatgpt-account-id`, "test-account")
expect_true(s7contract::implements(RhoMemoryCredentialStore, CredentialStore))

refresh_count <- 0L
expired <- rho_openai_codex_credential(
  access_token = "expired-access",
  account_id = "test-account",
  refresh_token = "refresh",
  expires = 0,
  source = "test-store"
)
refresh_strategy <- rho_oauth_auth(
  name = "fixture",
  login = function(provider_id, io) expired,
  refresh = function(current) {
    refresh_count <<- refresh_count + 1L
    rho_openai_codex_credential(
      access_token = "fresh-access",
      account_id = current@account_id,
      refresh_token = "rotated-refresh",
      expires = Inf,
      source = current@source
    )
  },
  to_request = function(current) rho_model_auth(api_key = current@state$access)
)
refresh_provider <- rho_provider(
  id = "openai-codex",
  implementation = rho_faux_provider(),
  auth = rho_provider_auth(oauth = refresh_strategy),
  models = list(spark)
)
refresh_models <- rho_models(
  list(refresh_provider),
  rho_memory_credential_store(list(`openai-codex` = expired))
)

first_resolution <- rho_resolve_model_auth(refresh_models, spark) |> rho_await()
second_resolution <- rho_resolve_model_auth(refresh_models, spark) |> rho_await()
expect_true(first_resolution@configured)
expect_true(second_resolution@configured)
expect_equal(first_resolution@auth@api_key, "fresh-access")
expect_equal(refresh_count, 1L)

pkce <- rho.ai:::rho_openai_codex_pkce()
second_pkce <- rho.ai:::rho_openai_codex_pkce()

expect_equal(nchar(pkce$verifier), 43L)
expect_equal(nchar(pkce$challenge), 43L)
expect_true(grepl("^[A-Za-z0-9_-]+$", pkce$verifier))
expect_true(grepl("^[A-Za-z0-9_-]+$", pkce$challenge))
expect_true(grepl("^[0-9a-f]{32}$", pkce$state))
expected_challenge <- digest::digest(
  charToRaw(pkce$verifier),
  algo = "sha256",
  serialize = FALSE,
  raw = TRUE
)
expected_challenge <- base64enc::base64encode(expected_challenge)
expected_challenge <- sub("=+$", "", chartr("+/", "-_", expected_challenge))
expect_equal(pkce$challenge, expected_challenge)
expect_false(identical(pkce$verifier, second_pkce$verifier))
expect_false(identical(pkce$state, second_pkce$state))
expect_equal(rho.ai:::rho_base64url_encode(charToRaw("foo?")), "Zm9vPw")
expect_equal(rawToChar(rho.ai:::rho_base64url_decode("Zm9vPw")), "foo?")

expect_equal(
  rho_supported_thinking_levels(spark),
  c("off", "minimal", "low", "medium", "high", "xhigh")
)
expect_equal(rho_map_thinking_level(spark, "minimal"), "low")
expect_equal(rho_clamp_thinking_level(spark, "max"), "xhigh")
expect_true(rho_model_supports_input(spark, "text"))
expect_false(rho_model_supports_input(spark, "image"))
expect_true(rho_model_supports_transport(spark, "websocket"))
expect_equal(spark@pricing@cache_read, 0.175)
expect_equal(spark@limits@context_window, 128000L)

fixture_tool <- function(name) {
  rho_tool_spec(
    name = name,
    description = name,
    parameters = list(type = "object", properties = list()),
    execute = function(...) NULL
  )
}
loader <- fixture_tool("search_tools")
weather <- fixture_tool("lookup_weather")
loader_call <- rho_assistant_message(content = list(
  ToolCall(id = "call_1", name = "search_tools", arguments = list())
))
loader_result <- rho_tool_result_message(
  tool_call_id = "call_1",
  tool_name = "search_tools",
  content = list(rho_text("loaded")),
  added_tool_names = "lookup_weather"
)
dynamic_context <- rho_context(
  messages = list(loader_call, loader_result),
  tools = list(loader, weather)
)

spark_placement <- rho_plan_tools(codex@implementation, spark, dynamic_context)
expect_true(S7::S7_inherits(spark_placement, RhoFullToolPlacement))
expect_equal(spark_placement@cache_expectation, "replace-prefix")
expect_equal(
  vapply(spark_placement@immediate, function(tool) tool@name, character(1)),
  c("search_tools", "lookup_weather")
)

tool_search_model <- rho_openai_codex_spark()
tool_search_model@compatibility <- rho_openai_responses_compatibility(
  supports_tool_search = TRUE
)
native_placement <- rho_plan_tools(codex@implementation, tool_search_model, dynamic_context)
expect_true(S7::S7_inherits(native_placement, RhoOpenAIToolSearchPlacement))
expect_equal(native_placement@cache_expectation, "preserve-prefix")
expect_equal(native_placement@immediate[[1]]@name, "search_tools")
expect_equal(native_placement@deferred[[1]]@name, "lookup_weather")

native_request <- rho_build_provider_request(
  codex@implementation,
  tool_search_model,
  dynamic_context,
  options = list(auth = resolved_auth)
)
expect_equal(native_request@body$tools[[1]]$name, "search_tools")
input_types <- vapply(native_request@body$input, `[[`, character(1), "type")
expect_equal(
  input_types,
  c("function_call", "function_call_output", "tool_search_call", "tool_search_output")
)
expect_true(native_request@body$input[[4]]$tools[[1]]$defer_loading)

decoder <- rho_openai_responses_decoder(spark)
sse <- function(value) {
  rho.http::RhoSseEvent(
    event = "message",
    data = yyjsonr::write_json_str(value, auto_unbox = TRUE),
    id = "",
    retry = NA_integer_
  )
}

started <- rho_decode_provider_event(decoder, sse(list(
  type = "response.output_item.added",
  output_index = 0L,
  item = list(type = "message", id = "msg_1", content = list())
)))
delta <- rho_decode_provider_event(decoder, sse(list(
  type = "response.output_text.delta",
  output_index = 0L,
  delta = "hello"
)))
finished <- rho_decode_provider_event(decoder, sse(list(
  type = "response.output_item.done",
  output_index = 0L,
  item = list(
    type = "message",
    id = "msg_1",
    content = list(list(type = "output_text", text = "hello"))
  )
)))
done <- rho_decode_provider_event(decoder, sse(list(
  type = "response.completed",
  response = list(
    id = "resp_1",
    status = "completed",
    usage = list(
      input_tokens = 10,
      output_tokens = 4,
      total_tokens = 14,
      input_tokens_details = list(cached_tokens = 3, cache_write_tokens = 2),
      output_tokens_details = list(reasoning_tokens = 1)
    )
  )
)))
events <- c(started, delta, finished, done)

expect_equal(
  vapply(events, rho_assistant_event_type, character(1)),
  c("start", "text_start", "text_delta", "text_end", "done")
)
expect_equal(events[[5]]@message@content[[1]]@text, "hello")
expect_equal(events[[5]]@message@model, "gpt-5.3-codex-spark")
expect_equal(events[[5]]@message@response_id, "resp_1")
expect_equal(events[[5]]@message@usage@input, 5)
expect_equal(events[[5]]@message@usage@cache_read, 3)
expect_equal(events[[5]]@message@usage@cache_write, 2)
expect_equal(events[[5]]@message@usage@reasoning, 1)
expect_equal(events[[5]]@message@usage@total, 14)
expect_equal(
  events[[5]]@message@usage@cost@total,
  5 * 1.75e-6 + 3 * 0.175e-6 + 4 * 14e-6
)
expect_true(S7::S7_inherits(events[[3]], AssistantTextDeltaEvent))

transport_events <- rho_decode_provider_event(
  rho_openai_responses_decoder(spark),
  rho.http::RhoHttpTransportError(
    message = "connection closed",
    url = "https://example.test/responses",
    parent = simpleError("connection closed")
  )
)
expect_equal(
  vapply(transport_events, rho_assistant_event_type, character(1)),
  c("start", "error")
)
expect_equal(transport_events[[2]]@error@kind, "transport")
expect_true(transport_events[[2]]@error@retryable)

status_events <- rho_decode_provider_event(
  rho_openai_responses_decoder(spark),
  rho.http::RhoHttpStatusError(
    message = "HTTP stream returned status 429",
    url = "https://example.test/responses",
    status = 429L,
    headers = list(`retry-after` = "1")
  )
)
expect_equal(status_events[[2]]@error@code, "429")
expect_true(status_events[[2]]@error@retryable)

unsupported_events <- rho_decode_provider_event(rho_openai_responses_decoder(spark), list())
expect_equal(unsupported_events[[2]]@error@code, "unsupported_event")
expect_true(s7contract::implements(OpenAIResponseDecoder, ProviderEventDecoder))
expect_true(s7contract::implements(OpenAIResponseTextDelta, ProviderWireEvent))
expect_true(s7contract::implements(OpenAIMessageItem, ResponseItemProtocol))
