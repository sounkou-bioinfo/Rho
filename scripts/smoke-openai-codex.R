#!/usr/bin/env Rscript

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 1L || !nzchar(arguments[[1L]])) {
  stop(
    "Usage: Rscript scripts/smoke-openai-codex.R /absolute/path/to/auth.json",
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(rho.async)
  library(rho.ai)
  library(rho.agent)
})

credential <- rho_load_openai_codex_credential(arguments[[1L]]) |>
  rho_await(timeout = 5000)
if (S7::S7_inherits(credential, AuthErrorValue)) {
  stop(credential@message, call. = FALSE)
}

provider <- rho_openai_codex_provider()
model <- rho_openai_codex_spark()
models <- rho_models(
  providers = list(provider),
  credentials = rho_memory_credential_store(
    list(`openai-codex` = credential)
  )
)
agent <- rho_agent(
  provider = models,
  model = model,
  stream_options = list(reasoning_effort = "minimal")
)

run <- rho_prompt(
  agent,
  "Reply with exactly rho-live-ok and nothing else."
) |>
  rho_await(timeout = 120000)

assistant_messages <- Filter(
  function(message) S7::S7_inherits(message, AssistantMessage),
  run@messages
)
text_parts <- unlist(
  lapply(assistant_messages, function(message) {
    Filter(
      function(content) S7::S7_inherits(content, TextContent),
      message@content
    )
  }),
  recursive = FALSE
)
answer <- paste(
  vapply(text_parts, function(content) content@text, character(1)),
  collapse = ""
)

writeLines(c(
  sprintf("model: %s", model@id),
  sprintf("status: %s", run@status),
  sprintf("answer: %s", answer),
  sprintf("events: %d", length(run@events))
))
