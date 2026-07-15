# Generated from packages/rho.agent/inst/tinytest/rmd/compaction.Rmd; do not edit.

library(tinytest)
library(rho.async)
library(rho.ai)
library(rho.agent)

RhoCompactionFixtureProvider <- S7::new_class(
  "RhoCompactionFixtureProvider",
  properties = list(state = S7::class_environment)
)

rho_compaction_fixture_provider <- function(responses) {
  state <- new.env(parent = emptyenv())
  state$responses <- responses
  state$index <- 0L
  state$contexts <- list()
  state$summary_calls <- 0L
  RhoCompactionFixtureProvider(state = state)
}

S7::method(
  rho_stream,
  list(RhoCompactionFixtureProvider, Model, Context)
) <- function(provider, model, context, options = list(), ...) {
  if (grepl("context checkpoint", context@system_prompt, fixed = TRUE)) {
    provider@state$summary_calls <- provider@state$summary_calls + 1L
    message <- rho_assistant_message(
      content = list(rho_text("semantic fixture checkpoint")),
      provider = model@provider,
      model = model@id
    )
    return(rho_list_stream(rho_faux_message_events(message)))
  }

  provider@state$index <- provider@state$index + 1L
  provider@state$contexts[[provider@state$index]] <- context
  response <- provider@state$responses[[provider@state$index]]
  if (S7::S7_inherits(response, ProviderErrorValue)) {
    message <- rho_assistant_message(
      provider = model@provider,
      model = model@id,
      stop_reason = "error"
    )
    return(rho_list_stream(list(rho_assistant_error_event(response, message))))
  }
  rho_list_stream(rho_faux_message_events(response))
}

rho_compaction_fixture_message <- function(text = "completed") {
  rho_assistant_message(
    content = list(rho_text(text)),
    provider = "fixture",
    model = "fixture"
  )
}

rho_long_fixture_text <- function(letter) {
  paste(rep(letter, 480L), collapse = "")
}

RhoFixtureCompactor <- S7::new_class(
  "RhoFixtureCompactor",
  parent = RhoCompactor,
  properties = list(state = S7::class_environment)
)

rho_fixture_compactor <- function(summary = "provided fixture checkpoint") {
  state <- new.env(parent = emptyenv())
  state$calls <- 0L
  state$summary <- summary
  RhoFixtureCompactor(state = state)
}

S7::method(
  rho_compact_preparation,
  list(RhoFixtureCompactor, RhoCompactionPreparation)
) <- function(
  compactor,
  preparation,
  agent,
  custom_instructions = "",
  ...
) {
  compactor@state$calls <- compactor@state$calls + 1L
  rho_task(rho_compaction_result(
    summary = compactor@state$summary,
    first_kept_entry_id = preparation@first_kept_entry_id,
    tokens_before = preparation@tokens_before,
    details = list(custom_instructions = custom_instructions),
    source = RhoProvidedCompaction()
  ))
}

usage_message <- rho_assistant_message(
  content = list(rho_text("accounted")),
  usage = rho_usage(input = 40, output = 10),
  timestamp = 1
)
trailing_message <- rho_user_message(paste(rep("x", 40L), collapse = ""), timestamp = 2)
usage <- rho_context_usage(list(usage_message, trailing_message))

expect_equal(usage@usage_tokens, 50)
expect_equal(usage@trailing_tokens, 10)
expect_equal(usage@tokens, 60)
expect_equal(usage@last_usage_index, 1L)

provider <- rho_compaction_fixture_provider(rep(
  list(rho_compaction_fixture_message()),
  3L
))
agent <- rho_agent(
  provider,
  rho_model("fixture", "fixture", context_window = 100000L),
  compaction = rho_compaction_settings(
    enabled = FALSE,
    reserve_tokens = 100L,
    keep_recent_tokens = 5L
  )
)
for (letter in c("a", "b", "c")) {
  rho_prompt(agent, rho_long_fixture_text(letter)) |>
    rho_await(timeout = 5000L)
}

messages_before <- rho_state_messages(agent)
result <- rho_compact(agent) |> rho_await(timeout = 5000L)
context <- rho_build_agent_context(agent)

expect_true(S7::S7_inherits(result, RhoCompactionResult))
expect_true(S7::S7_inherits(result@source, RhoGeneratedCompaction))
expect_equal(rho_state_messages(agent), messages_before)
expect_true(length(context@messages) < length(messages_before))
expect_true(grepl(
  "semantic fixture checkpoint",
  context@messages[[1L]]@content,
  fixed = TRUE
))
expect_true(S7::S7_inherits(
  rho_state_entries(agent)[[length(rho_state_entries(agent))]],
  RhoSessionCompactionEntry
))
expect_true(provider@state$summary_calls >= 1L)
expect_equal(
  vapply(tail(agent@state$events, 2L), function(event) event@type, character(1)),
  c("compaction_start", "compaction_end")
)
expect_true(S7::S7_inherits(
  tail(agent@state$events, 1L)[[1L]]@outcome,
  RhoCompactionResult
))

provider <- rho_compaction_fixture_provider(rep(
  list(rho_compaction_fixture_message()),
  2L
))
compactor <- rho_fixture_compactor("threshold checkpoint")
agent <- rho_agent(
  provider,
  rho_model("fixture", "fixture", context_window = 120L),
  compaction = rho_compaction_settings(
    enabled = TRUE,
    reserve_tokens = 20L,
    keep_recent_tokens = 5L
  ),
  compactor = compactor
)

rho_prompt(agent, rho_long_fixture_text("a")) |>
  rho_await(timeout = 5000L)
rho_prompt(agent, rho_long_fixture_text("b")) |>
  rho_await(timeout = 5000L)

expect_equal(compactor@state$calls, 1L)
expect_true(grepl(
  "threshold checkpoint",
  provider@state$contexts[[2L]]@messages[[1L]]@content,
  fixed = TRUE
))
threshold_start <- Filter(
  function(event) S7::S7_inherits(event, RhoCompactionStartEvent),
  agent@state$events
)[[1L]]
expect_true(S7::S7_inherits(threshold_start@reason, RhoThresholdCompaction))
expect_false(threshold_start@will_retry)

RhoFixtureCompactionPolicy <- S7::new_class(
  "RhoFixtureCompactionPolicy",
  parent = RhoDefaultAgentPolicy,
  properties = list(state = S7::class_environment)
)
policy_state <- new.env(parent = emptyenv())
policy_state$before <- 0L
policy_state$after <- 0L
policy_state$entry <- NULL
policy <- RhoFixtureCompactionPolicy(state = policy_state)

S7::method(
  rho_before_compaction,
  list(RhoFixtureCompactionPolicy, RhoBeforeCompactionContext)
) <- function(policy, context, ...) {
  policy@state$before <- policy@state$before + 1L
  preparation <- context@preparation
  rho_task(rho_before_compaction_decision(result = rho_compaction_result(
    summary = "policy checkpoint",
    first_kept_entry_id = preparation@first_kept_entry_id,
    tokens_before = preparation@tokens_before,
    source = RhoProvidedCompaction()
  )))
}

S7::method(
  rho_after_compaction,
  list(RhoFixtureCompactionPolicy, RhoAfterCompactionContext)
) <- function(policy, context, ...) {
  policy@state$after <- policy@state$after + 1L
  policy@state$entry <- context@entry
  rho_task(NULL)
}

provider <- rho_compaction_fixture_provider(rep(
  list(rho_compaction_fixture_message()),
  3L
))
unused_compactor <- rho_fixture_compactor()
agent <- rho_agent(
  provider,
  rho_model("fixture", "fixture", context_window = 100000L),
  policy = policy,
  compaction = rho_compaction_settings(FALSE, 100L, 5L),
  compactor = unused_compactor
)
for (letter in c("a", "b", "c")) {
  rho_prompt(agent, rho_long_fixture_text(letter)) |>
    rho_await(timeout = 5000L)
}
result <- rho_compact(agent) |> rho_await(timeout = 5000L)

expect_equal(policy@state$before, 1L)
expect_equal(policy@state$after, 1L)
expect_equal(unused_compactor@state$calls, 0L)
expect_true(S7::S7_inherits(result@source, RhoProvidedCompaction))
expect_true(S7::S7_inherits(policy@state$entry, RhoSessionCompactionEntry))
expect_true(s7contract::implements(RhoFixtureCompactionPolicy, AgentPolicy))

RhoCancelCompactionPolicy <- S7::new_class(
  "RhoCancelCompactionPolicy",
  parent = RhoDefaultAgentPolicy
)

S7::method(
  rho_before_compaction,
  list(RhoCancelCompactionPolicy, RhoBeforeCompactionContext)
) <- function(policy, context, ...) {
  rho_task(rho_before_compaction_decision(cancel = TRUE))
}

provider <- rho_compaction_fixture_provider(rep(
  list(rho_compaction_fixture_message()),
  2L
))
agent <- rho_agent(
  provider,
  rho_model("fixture", "fixture", context_window = 100000L),
  policy = RhoCancelCompactionPolicy(),
  compaction = rho_compaction_settings(FALSE, 100L, 5L)
)
for (letter in c("a", "b")) {
  rho_prompt(agent, rho_long_fixture_text(letter)) |>
    rho_await(timeout = 5000L)
}
cancelled <- rho_compact(agent) |> rho_await(timeout = 5000L)
cancel_event <- tail(agent@state$events, 1L)[[1L]]

expect_true(S7::S7_inherits(cancelled, RhoCompactionCancelled))
expect_true(S7::S7_inherits(cancelled, RhoCompactionSkipped))
expect_false(S7::S7_inherits(cancelled, RhoCompactionErrorValue))
expect_true(S7::S7_inherits(cancel_event@outcome, RhoCompactionCancelled))
expect_true(is.null(cancel_event@error))

RhoFailingCompactor <- S7::new_class(
  "RhoFailingCompactor",
  parent = RhoCompactor
)

S7::method(
  rho_compact_preparation,
  list(RhoFailingCompactor, RhoCompactionPreparation)
) <- function(compactor, preparation, agent, custom_instructions = "", ...) {
  rho_task(RhoCompactionFailure(
    kind = "compaction",
    message = "fixture compactor failed",
    retryable = FALSE,
    details = list()
  ))
}

provider <- rho_compaction_fixture_provider(rep(
  list(rho_compaction_fixture_message()),
  2L
))
agent <- rho_agent(
  provider,
  rho_model("fixture", "fixture", context_window = 120L),
  compaction = rho_compaction_settings(TRUE, 20L, 5L),
  compactor = RhoFailingCompactor()
)
rho_prompt(agent, rho_long_fixture_text("a")) |>
  rho_await(timeout = 5000L)
failed_run <- rho_prompt(agent, rho_long_fixture_text("b")) |>
  rho_await(timeout = 5000L)

expect_equal(failed_run@status, "error")
expect_true(S7::S7_inherits(failed_run@error, RhoCompactionFailure))
expect_equal(provider@state$index, 1L)

empty_agent <- rho_agent(
  rho_faux_provider(),
  rho_model("faux", "faux")
)
nothing <- rho_compact(empty_agent) |> rho_await(timeout = 1000L)

expect_true(S7::S7_inherits(nothing, RhoNothingToCompact))
expect_true(S7::S7_inherits(nothing, RhoCompactionSkipped))
expect_false(S7::S7_inherits(nothing, RhoCompactionErrorValue))

overflow <- rho_provider_context_overflow(
  "fixture context is too large",
  code = "fixture_context_overflow"
)
provider <- rho_compaction_fixture_provider(list(
  rho_compaction_fixture_message("history one"),
  rho_compaction_fixture_message("history two"),
  overflow,
  rho_compaction_fixture_message("recovered")
))
compactor <- rho_fixture_compactor("overflow checkpoint")
agent <- rho_agent(
  provider,
  rho_model("fixture", "fixture", context_window = 100000L),
  compaction = rho_compaction_settings(FALSE, 100L, 5L),
  compactor = compactor
)
rho_prompt(agent, rho_long_fixture_text("a")) |>
  rho_await(timeout = 5000L)
rho_prompt(agent, rho_long_fixture_text("b")) |>
  rho_await(timeout = 5000L)
run <- rho_prompt(agent, "retry this request") |>
  rho_await(timeout = 5000L)

expect_equal(run@status, "completed")
expect_equal(run@messages[[length(run@messages)]]@content[[1L]]@text, "recovered")
expect_equal(compactor@state$calls, 1L)
expect_true(any(vapply(
  rho_state_messages(agent),
  function(message) {
    S7::S7_inherits(message, AssistantMessage) &&
      identical(message@stop_reason, "error")
  },
  logical(1)
)))
expect_false(any(vapply(
  rho_build_agent_context(agent)@messages,
  function(message) {
    S7::S7_inherits(message, AssistantMessage) &&
      identical(message@stop_reason, "error")
  },
  logical(1)
)))
expect_true(any(vapply(
  rho_state_entries(agent),
  function(entry) S7::S7_inherits(entry, RhoSessionContextExclusionEntry),
  logical(1)
)))
compaction_entry <- Filter(
  function(entry) S7::S7_inherits(entry, RhoSessionCompactionEntry),
  rho_state_entries(agent)
)[[1L]]
expect_true(S7::S7_inherits(
  compaction_entry@reason,
  RhoProviderInputLimitCompaction
))
expect_true(compaction_entry@will_retry)
expect_true(grepl(
  "overflow checkpoint",
  provider@state$contexts[[4L]]@messages[[1L]]@content,
  fixed = TRUE
))

provider <- rho_compaction_fixture_provider(list(
  rho_compaction_fixture_message("history one"),
  rho_compaction_fixture_message("history two"),
  overflow,
  overflow
))
compactor <- rho_fixture_compactor()
agent <- rho_agent(
  provider,
  rho_model("fixture", "fixture", context_window = 100000L),
  compaction = rho_compaction_settings(FALSE, 100L, 5L),
  compactor = compactor
)
rho_prompt(agent, rho_long_fixture_text("a")) |>
  rho_await(timeout = 5000L)
rho_prompt(agent, rho_long_fixture_text("b")) |>
  rho_await(timeout = 5000L)
run <- rho_prompt(agent, "retry once") |> rho_await(timeout = 5000L)

expect_equal(run@status, "error")
expect_equal(provider@state$index, 4L)
expect_equal(compactor@state$calls, 1L)

agent <- rho_agent(
  rho_faux_provider(),
  rho_model("faux", "faux"),
  compaction = rho_compaction_settings(FALSE, 100L, 20L)
)
entries <- list(
  RhoSessionMessageEntry(
    id = "user-1",
    timestamp = 1,
    message = rho_user_message(rho_long_fixture_text("a"), timestamp = 1)
  ),
  RhoSessionMessageEntry(
    id = "assistant-1",
    timestamp = 2,
    message = rho_assistant_message(
      content = list(ToolCall(
        id = "call-1",
        name = "fixture",
        arguments = list(value = rho_long_fixture_text("b"))
      )),
      timestamp = 2
    )
  ),
  RhoSessionMessageEntry(
    id = "tool-1",
    timestamp = 3,
    message = rho_tool_result_message(
      "call-1",
      "fixture",
      list(rho_text(rho_long_fixture_text("c"))),
      timestamp = 3
    )
  ),
  RhoSessionMessageEntry(
    id = "user-2",
    timestamp = 4,
    message = rho_user_message("continue", timestamp = 4)
  )
)
for (entry in entries) {
  rho_append_session_entry(agent, entry) |> rho_await(timeout = 1000L)
}
preparation <- rho_prepare_compaction(agent, agent@options@compaction)

expect_true(S7::S7_inherits(preparation, RhoCompactionPreparation))
expect_false(identical(preparation@first_kept_entry_id, "tool-1"))
expect_true(preparation@first_kept_entry_id %in% c("assistant-1", "user-2"))
