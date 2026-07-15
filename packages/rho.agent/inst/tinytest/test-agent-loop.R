# Generated from packages/rho.agent/inst/tinytest/rmd/agent-loop.Rmd; do not edit.

library(tinytest)
library(rho.async)
library(rho.ai)
library(rho.agent)

RhoScriptedAgentProvider <- S7::new_class(
  "RhoScriptedAgentProvider",
  properties = list(state = S7::class_environment)
)

rho_scripted_agent_provider <- function(messages) {
  state <- new.env(parent = emptyenv())
  state$messages <- messages
  state$index <- 0L
  RhoScriptedAgentProvider(state = state)
}

S7::method(
  rho_stream,
  list(RhoScriptedAgentProvider, Model, Context)
) <- function(provider, model, context, options = list(), ...) {
  provider@state$index <- provider@state$index + 1L
  message <- provider@state$messages[[provider@state$index]]
  rho_list_stream(rho_faux_message_events(message))
}

rho_scripted_tool_turn <- function(calls, stop_reason = "toolUse") {
  rho_assistant_message(content = calls, model = "fixture", stop_reason = stop_reason)
}

rho_scripted_text_turn <- function(text = "done") {
  rho_assistant_message(content = list(rho_text(text)), model = "fixture")
}

rho_fixture_tool <- function(name, execute, overlap = ToolMayOverlap()) {
  rho_tool_spec(
    name = name,
    description = name,
    parameters = list(type = "object", properties = list(), required = "value"),
    execute = execute,
    overlap = overlap
  )
}

agent <- rho_agent(rho_faux_provider(), rho_model("faux", "faux"))
run <- rho_prompt(agent, "hello")
expect_true(rho_is_task(run))
result <- rho_await(run)
expect_equal(result@status, "completed")
expect_equal(length(result@messages), 2)
expect_equal(
  vapply(result@events, function(event) event@type, character(1)),
  c(
    "agent_start", "turn_start", "message_start", "message_end",
    "message_start", "message_update", "message_update", "message_update",
    "message_end", "turn_end", "agent_end", "agent_settled"
  )
)
expect_true(s7contract::implements(RhoDefaultAgentPolicy, AgentPolicy))

provider <- rho_scripted_agent_provider(list(
  rho_scripted_tool_turn(list(ToolCall(
    id = "call_1",
    name = "echo",
    arguments = list(value = "hello")
  ))),
  rho_scripted_text_turn("finished")
))
echo <- rho_fixture_tool(
  "echo",
  function(id, args, signal, on_update, ctx) {
    rho_tool_result(list(rho_text(args$value)), added_tool_names = "new_tool")
  }
)
agent <- rho_agent(provider, rho_model("fixture", "fixture"), tools = list(echo))
result <- rho_prompt(agent, "go") |> rho_await()

expect_equal(result@status, "completed")
expect_equal(length(result@messages), 4)
expect_equal(length(result@tool_results), 1)
expect_equal(result@tool_results[[1]]@added_tool_names, "new_tool")
expect_equal(
  sum(vapply(result@events, function(event) identical(event@type, "turn_start"), logical(1))),
  2L
)
expect_true(S7::S7_inherits(result@messages[[3]], ToolResultMessage))
expect_equal(result@messages[[4]]@content[[1]]@text, "finished")

executions <- 0L
local_search <- rho_fixture_tool(
  "web_search",
  function(id, args, signal, on_update, ctx) {
    executions <<- executions + 1L
    rho_tool_result()
  }
)
provider <- rho_scripted_agent_provider(list(rho_assistant_message(
  content = list(WebSearchCallContent(
    id = "search_1",
    status = OperationCompleted(),
    action = WebSearchSearchAction(
      queries = "current R release",
      sources = list()
    )
  )),
  model = "fixture"
)))
agent <- rho_agent(
  provider,
  rho_model("fixture", "fixture"),
  tools = list(local_search),
  operations = list(rho_web_search())
)
result <- rho_prompt(agent, "search") |> rho_await(timeout = 1000L)

expect_equal(result@status, "completed")
expect_equal(executions, 0L)
expect_equal(length(result@tool_results), 0L)
expect_true(S7::S7_inherits(result@messages[[2L]]@content[[1L]], WebSearchCallContent))
expect_false(S7::S7_inherits(result@messages[[2L]]@content[[1L]], ToolCall))

listener_order <- character()
agent <- rho_agent(rho_faux_provider(), rho_model("faux", "faux"))
unsubscribe_first <- rho_subscribe(agent, function(event, agent) {
  if (!identical(event@type, "agent_start")) return(NULL)
  rho_task_from_function(function() {
    listener_order <<- c(listener_order, "first")
    NULL
  })
})
rho_subscribe(agent, function(event, agent) {
  if (identical(event@type, "agent_start")) listener_order <<- c(listener_order, "second")
  NULL
})
rho_prompt(agent, "listeners") |> rho_await()
expect_equal(listener_order, c("first", "second"))
expect_true(unsubscribe_first())

provider <- rho_scripted_agent_provider(list(
  rho_scripted_text_turn("first"),
  rho_scripted_text_turn("second")
))
agent <- rho_agent(provider, rho_model("fixture", "fixture"))
queued <- FALSE
rho_subscribe(agent, function(event, current_agent) {
  if (queued || !identical(event@type, "message_end") ||
      !S7::S7_inherits(event@message, AssistantMessage)) return(NULL)
  queued <<- TRUE
  rho_follow_up(current_agent, "one more")
})
result <- rho_prompt(agent, "start") |> rho_await()

expect_equal(result@status, "completed")
expect_equal(length(result@messages), 4)
expect_true(S7::S7_inherits(result@messages[[3]], UserMessage))
expect_equal(result@messages[[3]]@content, "one more")
expect_equal(provider@state$index, 2L)

queue_agent <- rho_agent(rho_faux_provider(), rho_model("faux", "faux"))
queue_agent@state$phase <- "provider"

rho_steer(queue_agent, "first") |> rho_await()
rho_steer(queue_agent, "second") |> rho_await()

first <- rho_take_agent_queue(
  RhoOneAtATimeQueue(),
  queue_agent,
  "steering_queue",
  "steering"
) |> rho_await()
expect_equal(length(first), 1L)
expect_equal(first[[1L]]@content, "first")
expect_equal(length(queue_agent@state$steering_queue), 1L)

remaining <- rho_take_agent_queue(
  RhoAllQueue(),
  queue_agent,
  "steering_queue",
  "steering"
) |> rho_await()
expect_equal(length(remaining), 1L)
expect_equal(remaining[[1L]]@content, "second")
expect_equal(length(queue_agent@state$steering_queue), 0L)

RhoBlockingAgentPolicy <- S7::new_class(
  "RhoBlockingAgentPolicy",
  parent = RhoDefaultAgentPolicy
)
S7::method(
  rho_before_tool_call,
  list(RhoBlockingAgentPolicy, RhoToolContext)
) <- function(
  policy, context, ...
) {
  expect_true(S7::S7_inherits(context, RhoToolContext))
  rho_task(rho_before_tool_call_decision(TRUE, "blocked by fixture policy"))
}

executions <- 0L
blocked_tool <- rho_fixture_tool("blocked", function(id, args, signal, on_update, ctx) {
  executions <<- executions + 1L
  rho_tool_result()
})
provider <- rho_scripted_agent_provider(list(
  rho_scripted_tool_turn(list(ToolCall(
    id = "blocked_1",
    name = "blocked",
    arguments = list(value = "x")
  ))),
  rho_scripted_text_turn()
))
agent <- rho_agent(
  provider,
  rho_model("fixture", "fixture"),
  tools = list(blocked_tool),
  policy = RhoBlockingAgentPolicy()
)
result <- rho_prompt(agent, "try") |> rho_await()

expect_equal(executions, 0L)
expect_true(result@tool_results[[1]]@is_error)
expect_true(grepl("blocked by fixture policy", result@tool_results[[1]]@content[[1]]@text))

RhoFixtureApplicationContext <- S7::new_class(
  "RhoFixtureApplicationContext",
  properties = list(user_id = S7::class_character)
)

contexts <- list()
context_tool <- rho_fixture_tool("context", function(id, args, signal, on_update, ctx) {
  contexts[[length(contexts) + 1L]] <<- ctx
  ctx@run@state$count <- (ctx@run@state$count %||% 0L) + 1L
  rho_tool_result(list(rho_text(as.character(ctx@run@state$count))))
})
provider <- rho_scripted_agent_provider(list(
  rho_scripted_tool_turn(list(
    ToolCall(id = "context_1", name = "context", arguments = list(value = "one")),
    ToolCall(id = "context_2", name = "context", arguments = list(value = "two"))
  )),
  rho_scripted_text_turn()
))
application <- RhoFixtureApplicationContext(user_id = "user-1")
agent <- rho_agent(
  provider,
  rho_model("fixture", "fixture"),
  tools = list(context_tool)
)
result <- rho_prompt(agent, "context", context = application) |> rho_await()

expect_true(S7::S7_inherits(result@context, RhoRunContext))
expect_identical(result@context@application, application)
expect_equal(length(contexts), 2L)
expect_true(all(vapply(
  contexts,
  function(context) S7::S7_inherits(context, RhoToolContext),
  logical(1)
)))
expect_true(all(vapply(
  contexts,
  function(context) identical(context@run, result@context),
  logical(1)
)))
expect_true(all(vapply(
  contexts,
  function(context) S7::S7_inherits(context@model_context, Context),
  logical(1)
)))
expect_equal(result@context@state$count, 2L)

trace <- character()
make_async_tool <- function(name, overlap = ToolMayOverlap()) {
  rho_fixture_tool(name, function(id, args, signal, on_update, ctx) {
    trace <<- c(trace, paste0("start-", name))
    rho_task_from_function(function() {
      trace <<- c(trace, paste0("finish-", name))
      rho_tool_result(list(rho_text(name)))
    })
  }, overlap = overlap)
}
calls <- list(
  ToolCall(id = "a_1", name = "a", arguments = list(value = "a")),
  ToolCall(id = "b_1", name = "b", arguments = list(value = "b"))
)
provider <- rho_scripted_agent_provider(list(
  rho_scripted_tool_turn(calls),
  rho_scripted_text_turn()
))
agent <- rho_agent(
  provider,
  rho_model("fixture", "fixture"),
  tools = list(make_async_tool("a"), make_async_tool("b"))
)
result <- rho_prompt(agent, "parallel") |> rho_await()

expect_equal(trace, c("start-a", "start-b", "finish-a", "finish-b"))
expect_equal(vapply(result@tool_results, function(message) message@tool_name, character(1)), c("a", "b"))

trace <- character()
provider <- rho_scripted_agent_provider(list(
  rho_scripted_tool_turn(calls),
  rho_scripted_text_turn()
))
agent <- rho_agent(
  provider,
  rho_model("fixture", "fixture"),
  tools = list(
    make_async_tool("a", ToolRequiresExclusiveExecution()),
    make_async_tool("b")
  )
)
rho_prompt(agent, "sequential") |> rho_await()
expect_equal(trace, c("start-a", "finish-a", "start-b", "finish-b"))

executions <- 0L
unsafe <- rho_fixture_tool("unsafe", function(id, args, signal, on_update, ctx) {
  executions <<- executions + 1L
  rho_tool_result()
})
provider <- rho_scripted_agent_provider(list(
  rho_scripted_tool_turn(
    list(ToolCall(id = "unsafe_1", name = "unsafe", arguments = list(value = "partial"))),
    stop_reason = "length"
  ),
  rho_scripted_text_turn()
))
agent <- rho_agent(provider, rho_model("fixture", "fixture"), tools = list(unsafe))
result <- rho_prompt(agent, "truncate") |> rho_await()

expect_equal(executions, 0L)
expect_true(result@tool_results[[1]]@is_error)
expect_true(grepl("may be truncated", result@tool_results[[1]]@content[[1]]@text))

agent <- rho_agent(rho_faux_provider(), rho_model("faux", "faux"))
cancelled <- FALSE
rho_subscribe(agent, function(event, current_agent) {
  if (cancelled || !identical(event@type, "message_start") ||
      !S7::S7_inherits(event@message, AssistantMessage)) return(NULL)
  cancelled <<- TRUE
  rho_abort_agent(current_agent, "fixture cancellation")
})
result <- rho_prompt(agent, "cancel") |> rho_await()

expect_equal(result@status, "aborted")
expect_true(S7::S7_inherits(result@error, RhoAgentErrorValue))
expect_equal(result@error@message, "fixture cancellation")
expect_equal(agent@state$phase, "idle")

state_agent <- rho_agent(rho_faux_provider(), rho_model("faux", "faux"))
rho_prompt(state_agent, "state") |> rho_await()

expect_true(length(rho_state_messages(state_agent)) > 0L)
expect_true(rho_is_task(rho_wait_for_idle(state_agent)))
expect_true(is.null(rho_wait_for_idle(state_agent) |> rho_await()))

rho_reset(state_agent) |> rho_await()
expect_equal(length(rho_state_messages(state_agent)), 0L)
expect_equal(length(state_agent@state$events), 0L)
expect_equal(length(state_agent@state$pending_tool_calls), 0L)
expect_equal(length(state_agent@state$steering_queue), 0L)
expect_equal(length(state_agent@state$follow_up_queue), 0L)

agent <- rho_agent(rho_faux_provider(), rho_model("faux", "faux"))
result <- rho_continue(agent) |> rho_await()
expect_equal(result@status, "error")
expect_equal(result@error@kind, "invalid_state")
