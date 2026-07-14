# Generated from packages/rho.ai/inst/tinytest/rmd/github-copilot.Rmd; do not edit.

library(tinytest)
library(rho.async)
library(rho.ai)

provider <- rho_github_copilot_provider()
model <- rho_github_copilot_gpt_5_3_codex()
credential <- rho_github_copilot_credential(
  session_token = paste0(
    "tid=test;exp=9999999999;",
    "proxy-ep=proxy.individual.githubcopilot.com;"
  ),
  github_token = "github-test-token",
  expires = Inf,
  source = "fixture"
)
auth <- rho_auth_to_request(provider@auth@oauth, credential) |> rho_await()
context <- rho_context(messages = list(rho_user_message("hello")))
request <- rho_github_copilot_request(
  provider@implementation,
  model,
  context,
  options = list(auth = auth)
)

expect_true(S7::S7_inherits(model, OpenAIResponsesModel))
expect_true(S7::S7_inherits(credential, GitHubCopilotCredential))
expect_true(S7::S7_inherits(auth, GitHubCopilotModelAuth))
expect_equal(request@url, "https://api.individual.githubcopilot.com/responses")
expect_equal(request@headers$Authorization, paste("Bearer", credential@state$access))
expect_equal(request@headers$`X-Initiator`, "user")
expect_equal(request@headers$`Openai-Intent`, "conversation-edits")
expect_equal(request@headers$`Copilot-Integration-Id`, "vscode-chat")
expect_equal(request@body$model, "gpt-5.3-codex")
expect_true(s7contract::implements(GitHubCopilotOAuthAuth, OAuthAuth))
expect_true(s7contract::implements(GitHubCopilotApi, ProviderRequestTranslator))

image <- ImageContent(data = "base64", mime_type = "image/png")
image_context <- rho_context(messages = list(
  rho_user_message(list(image)),
  rho_assistant_message(content = list(rho_text("working")))
))
headers <- rho_provider_headers(
  provider@implementation,
  model,
  image_context
)

expect_equal(headers$`X-Initiator`, "agent")
expect_equal(headers$`Copilot-Vision-Request`, "true")
expect_true(rho_has_image_input(image_context@messages))
expect_equal(rho_message_initiator(image_context@messages[[1L]]), "user")
expect_equal(rho_message_initiator(image_context@messages[[2L]]), "agent")

received_headers <- NULL
server <- nanonext::http_server(
  "http://127.0.0.1:0",
  handlers = list(nanonext::handler(
    "/copilot-token",
    function(request) {
      received_headers <<- request$headers
      list(
        status = 200L,
        headers = c("Content-Type" = "application/json"),
        body = yyjsonr::write_json_str(list(
          token = paste0(
            "tid=test;exp=9999999999;",
            "proxy-ep=proxy.individual.githubcopilot.com;"
          ),
          expires_at = 9999999999
        ), auto_unbox = TRUE)
      )
    }
  ))
)
expect_equal(server$start(), 0L)

endpoints <- GitHubCopilotEndpoints(
  device_code = paste0(server$url, "/unused-device"),
  access_token = paste0(server$url, "/unused-access"),
  copilot_token = paste0(server$url, "/copilot-token")
)
strategy <- rho_github_copilot_auth(
  endpoints = endpoints,
  http = rho.http::rho_http_client(timeout_ms = 2000L)
)
refreshed <- rho_github_copilot_credential_from_github_token(
  strategy,
  "github-test-token",
  source = "explicit-test"
) |> rho_await(timeout = 2000L)

expect_true(S7::S7_inherits(refreshed, GitHubCopilotCredential))
expect_equal(refreshed@source, "explicit-test")
expect_equal(refreshed@session_base_url, "https://api.individual.githubcopilot.com")
expect_equal(received_headers[["Authorization"]], "Bearer github-test-token")
expect_true(grepl("GitHubCopilotChat", received_headers[["User-Agent"]]))
expect_equal(server$close(), 0L)

poll_count <- 0L
notified <- list()
server <- nanonext::http_server(
  "http://127.0.0.1:0",
  handlers = list(
    nanonext::handler(
      "/device",
      function(request) {
        list(
          status = 200L,
          headers = c("Content-Type" = "application/json"),
          body = yyjsonr::write_json_str(list(
            device_code = "device-code",
            user_code = "ABCD-EFGH",
            verification_uri = "https://github.com/login/device",
            interval = 0,
            expires_in = 30
          ), auto_unbox = TRUE)
        )
      },
      method = "POST"
    ),
    nanonext::handler(
      "/access",
      function(request) {
        poll_count <<- poll_count + 1L
        body <- if (poll_count == 1L) {
          list(error = "authorization_pending")
        } else {
          list(access_token = "github-device-token")
        }
        list(
          status = 200L,
          headers = c("Content-Type" = "application/json"),
          body = yyjsonr::write_json_str(body, auto_unbox = TRUE)
        )
      },
      method = "POST"
    ),
    nanonext::handler(
      "/token",
      function(request) {
        list(
          status = 200L,
          headers = c("Content-Type" = "application/json"),
          body = yyjsonr::write_json_str(list(
            token = paste0(
              "tid=test;exp=9999999999;",
              "proxy-ep=proxy.individual.githubcopilot.com;"
            ),
            expires_at = 9999999999
          ), auto_unbox = TRUE)
        )
      }
    )
  )
)
expect_equal(server$start(), 0L)

strategy <- rho_github_copilot_auth(
  endpoints = GitHubCopilotEndpoints(
    device_code = paste0(server$url, "/device"),
    access_token = paste0(server$url, "/access"),
    copilot_token = paste0(server$url, "/token")
  ),
  http = rho.http::rho_http_client(timeout_ms = 2000L)
)
io <- rho_login_io(
  prompt = function(prompt) stop("GitHub device login must not prompt for a secret"),
  notify = function(event) {
    notified[[length(notified) + 1L]] <<- event
    NULL
  }
)
logged_in <- rho_auth_login(strategy, "github-copilot", io) |>
  rho_await(timeout = 5000L)

expect_true(S7::S7_inherits(logged_in, GitHubCopilotCredential))
expect_equal(poll_count, 2L)
expect_equal(length(notified), 1L)
expect_true(S7::S7_inherits(notified[[1L]], RhoDeviceCodeEvent))
expect_equal(notified[[1L]]@user_code, "ABCD-EFGH")
expect_equal(server$close(), 0L)

request_headers <- NULL
server <- nanonext::http_server(
  "http://127.0.0.1:0",
  handlers = list(nanonext::handler_stream(
    "/responses",
    function(connection, request) {
      request_headers <<- request$headers
      values <- list(
        list(
          type = "response.output_item.added",
          output_index = 0L,
          item = list(type = "message", id = "msg_1", content = list())
        ),
        list(type = "response.output_text.delta", output_index = 0L, delta = "hello"),
        list(
          type = "response.output_item.done",
          output_index = 0L,
          item = list(
            type = "message",
            id = "msg_1",
            content = list(list(type = "output_text", text = "hello"))
          )
        ),
        list(
          type = "response.completed",
          response = list(
            id = "resp_1",
            status = "completed",
            usage = list(
              input_tokens = 4,
              output_tokens = 2,
              total_tokens = 6,
              input_tokens_details = list(cached_tokens = 1),
              output_tokens_details = list(reasoning_tokens = 1)
            )
          )
        )
      )
      connection$set_status(200L)
      connection$set_header("Content-Type", "text/event-stream")
      for (value in values) {
        connection$send(nanonext::format_sse(
          data = yyjsonr::write_json_str(value, auto_unbox = TRUE)
        ))
      }
      connection$close()
    }
  ))
)
expect_equal(server$start(), 0L)

credential <- rho_github_copilot_credential(
  session_token = paste0(
    "tid=test;exp=9999999999;",
    "proxy-ep=proxy.individual.githubcopilot.com;"
  ),
  github_token = "github-test-token",
  expires = Inf,
  session_base_url = server$url,
  source = "stream-fixture"
)
provider <- rho_github_copilot_provider(
  http = rho.http::rho_http_client(timeout_ms = 2000L)
)
models <- rho_models(
  list(provider),
  rho_memory_credential_store(list(`github-copilot` = credential))
)
events <- rho_stream(
  models,
  provider@models[[1L]],
  rho_context(messages = list(rho_user_message("hello")))
) |> rho_stream_collect(timeout = 2000L)

expect_equal(
  vapply(events, rho_assistant_event_type, character(1)),
  c("start", "text_start", "text_delta", "text_end", "done")
)
expect_equal(events[[5L]]@message@provider, "github-copilot")
expect_equal(events[[5L]]@message@content[[1L]]@text, "hello")
expect_equal(events[[5L]]@message@usage@input, 3)
expect_equal(events[[5L]]@message@usage@cache_read, 1)
expect_equal(events[[5L]]@message@usage@reasoning, 1)
expect_equal(events[[5L]]@message@usage@total, 6)
expect_equal(request_headers[["X-Initiator"]], "user")
expect_equal(server$close(), 0L)
