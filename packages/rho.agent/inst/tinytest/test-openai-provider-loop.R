# Generated from packages/rho.agent/inst/tinytest/rmd/openai-provider-loop.Rmd; do not edit.

library(tinytest)
library(rho.async)
library(rho.ai)
library(rho.agent)

server <- nanonext::http_server(
  "http://127.0.0.1:0",
  handlers = list(nanonext::handler_stream(
    "/responses",
    function(connection, request) {
      values <- list(
        list(
          type = "response.output_item.added",
          output_index = 0L,
          item = list(type = "message", id = "msg_1", content = list())
        ),
        list(
          type = "response.output_text.delta",
          output_index = 0L,
          delta = "agent response"
        ),
        list(
          type = "response.output_item.done",
          output_index = 0L,
          item = list(
            type = "message",
            id = "msg_1",
            content = list(list(type = "output_text", text = "agent response"))
          )
        ),
        list(
          type = "response.completed",
          response = list(
            id = "resp_1",
            status = "completed",
            usage = list(input_tokens = 2, output_tokens = 2, total_tokens = 4)
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

provider <- rho_openai_provider(
  base_url = server$url,
  http = rho.http::rho_http_client(timeout_ms = 2000L)
)
models <- rho_models(
  list(provider),
  rho_memory_credential_store(list(
    openai = rho_api_key_credential("openai", "agent-test-key")
  ))
)
agent <- rho_agent(
  provider = models,
  model = rho_openai_model("gpt-5.4")
)
result <- rho_prompt(agent, "hello") |>
  rho_await(timeout = 3000L)

expect_equal(result@status, "completed")
expect_equal(result@messages[[2L]]@content[[1L]]@text, "agent response")
expect_equal(result@messages[[2L]]@response_id, "resp_1")
expect_equal(result@messages[[2L]]@usage@total, 4)
expect_equal(server$close(), 0L)
