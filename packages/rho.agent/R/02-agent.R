rho_prompt <- S7::new_generic("rho_prompt", "agent", function(agent, input, images = NULL, ...) {
  S7::S7_dispatch()
})
rho_continue <- S7::new_generic("rho_continue", "agent", function(agent, ...) S7::S7_dispatch())
rho_subscribe <- S7::new_generic("rho_subscribe", "agent", function(agent, listener, ...) {
  S7::S7_dispatch()
})
rho_steer <- S7::new_generic("rho_steer", "agent", function(agent, message, ...) S7::S7_dispatch())
rho_follow_up <- S7::new_generic("rho_follow_up", "agent", function(agent, message, ...) {
  S7::S7_dispatch()
})
rho_reset <- S7::new_generic("rho_reset", "agent", function(agent, ...) S7::S7_dispatch())
rho_abort_agent <- S7::new_generic("rho_abort_agent", "agent", function(agent, reason = NULL, ...) {
  S7::S7_dispatch()
})
rho_wait_for_idle <- S7::new_generic("rho_wait_for_idle", "agent", function(agent, ...) {
  S7::S7_dispatch()
})
rho_emit_agent_event <- S7::new_generic(
  "rho_emit_agent_event",
  "agent",
  function(agent, event, ...) S7::S7_dispatch()
)
rho_handle_agent_event <- S7::new_generic(
  "rho_handle_agent_event",
  c("listener", "event"),
  function(listener, event, agent, ...) S7::S7_dispatch()
)

rho_transform_agent_context <- S7::new_generic(
  "rho_transform_agent_context",
  "policy",
  function(policy, agent, context, ...) S7::S7_dispatch()
)
rho_before_tool_call <- S7::new_generic(
  "rho_before_tool_call",
  "policy",
  function(policy, agent, assistant, tool, call, args, context, ...) S7::S7_dispatch()
)
rho_after_tool_call <- S7::new_generic(
  "rho_after_tool_call",
  "policy",
  function(policy, agent, assistant, tool, call, args, result, is_error, context, ...) {
    S7::S7_dispatch()
  }
)
rho_prepare_next_turn <- S7::new_generic(
  "rho_prepare_next_turn",
  "policy",
  function(policy, agent, message, tool_results, context, new_messages, ...) S7::S7_dispatch()
)
rho_reduce_assistant_event <- S7::new_generic(
  "rho_reduce_assistant_event",
  "event",
  function(event, turn, ...) S7::S7_dispatch()
)
rho_execute_tool_batch <- S7::new_generic(
  "rho_execute_tool_batch",
  "mode",
  function(mode, agent, assistant, context, calls, ...) S7::S7_dispatch()
)
rho_resolve_tool_execution <- S7::new_generic(
  "rho_resolve_tool_execution",
  c("mode", "overlap"),
  function(mode, overlap, ...) S7::S7_dispatch()
)
rho_take_agent_queue <- S7::new_generic(
  "rho_take_agent_queue",
  "mode",
  function(mode, agent, field, label, ...) S7::S7_dispatch()
)

rho_agent_error <- function(message, kind = "agent", retryable = FALSE, details = list()) {
  RhoAgentErrorValue(
    kind = kind,
    message = message,
    retryable = isTRUE(retryable),
    details = details
  )
}

rho_before_tool_call_decision <- function(block = FALSE, reason = "") {
  RhoBeforeToolCallDecision(block = isTRUE(block), reason = reason)
}

rho_after_tool_call_decision <- function(result, is_error = FALSE) {
  RhoAfterToolCallDecision(result = result, is_error = isTRUE(is_error))
}

rho_next_turn_decision <- function(
  stop = FALSE,
  context = NULL,
  model = NULL,
  stream_options = list()
) {
  RhoNextTurnDecision(
    stop = isTRUE(stop),
    context = context,
    model = model,
    stream_options = stream_options
  )
}

rho_tool_registry <- function(tools) {
  if (!is.list(tools)) {
    rho_abort("`tools` must be a list of ToolSpec values")
  }
  invalid <- vapply(
    tools,
    function(tool) !S7::S7_inherits(tool, rho.ai::ToolSpec),
    logical(1)
  )
  if (any(invalid)) {
    rho_abort("`tools` must contain only ToolSpec values")
  }
  tool_names <- vapply(tools, function(tool) tool@name, character(1))
  duplicated_names <- unique(tool_names[duplicated(tool_names)])
  if (length(duplicated_names)) {
    rho_abort("Tool names must be unique: %s", paste(duplicated_names, collapse = ", "))
  }
  stats::setNames(tools, tool_names)
}

rho_agent_event <- function(class, type, ...) {
  do.call(class, c(list(type = type, sequence = 0L, timestamp = as.double(Sys.time())), list(...)))
}

rho_agent_start_event <- function() rho_agent_event(RhoAgentStartEvent, "agent_start")
rho_agent_end_event <- function(messages) {
  rho_agent_event(RhoAgentEndEvent, "agent_end", messages = messages)
}
rho_agent_settled_event <- function(status) {
  rho_agent_event(RhoAgentSettledEvent, "agent_settled", status = status)
}
rho_turn_start_event <- function(turn) {
  rho_agent_event(RhoTurnStartEvent, "turn_start", turn = as.integer(turn))
}
rho_turn_end_event <- function(turn, message, tool_results) {
  rho_agent_event(
    RhoTurnEndEvent,
    "turn_end",
    turn = as.integer(turn),
    message = message,
    tool_results = tool_results
  )
}
rho_message_start_event <- function(message) {
  rho_agent_event(RhoMessageStartEvent, "message_start", message = message)
}
rho_message_update_event <- function(message, assistant_event) {
  rho_agent_event(
    RhoMessageUpdateEvent,
    "message_update",
    message = message,
    assistant_event = assistant_event
  )
}
rho_message_end_event <- function(message) {
  rho_agent_event(RhoMessageEndEvent, "message_end", message = message)
}
rho_tool_execution_start_event <- function(call) {
  rho_agent_event(RhoToolExecutionStartEvent, "tool_execution_start", call = call)
}
rho_tool_execution_update_event <- function(call, partial_result) {
  rho_agent_event(
    RhoToolExecutionUpdateEvent,
    "tool_execution_update",
    call = call,
    partial_result = partial_result
  )
}
rho_tool_execution_end_event <- function(call, result, is_error) {
  rho_agent_event(
    RhoToolExecutionEndEvent,
    "tool_execution_end",
    call = call,
    result = result,
    is_error = isTRUE(is_error)
  )
}
rho_queue_update_event <- function(queue, size) {
  rho_agent_event(RhoQueueUpdateEvent, "queue_update", queue = queue, size = as.integer(size))
}

rho_agent <- function(
  provider,
  model,
  tools = list(),
  system_prompt = "",
  tool_execution = RhoParallelToolExecution(),
  steering_mode = RhoOneAtATimeQueue(),
  follow_up_mode = RhoOneAtATimeQueue(),
  policy = RhoDefaultAgentPolicy(),
  stream_options = list()
) {
  state <- rho_new_state(
    messages = list(),
    tools = rho_tool_registry(tools),
    listeners = list(),
    steering_queue = list(),
    follow_up_queue = list(),
    phase = "idle",
    pending_tool_calls = character(),
    events = list(),
    event_sequence = 0L,
    idle_condition = nanonext::cv(),
    idle_waiters = list(),
    cancelled = FALSE,
    cancel_reason = NULL,
    current_stream = NULL
  )
  RhoAgent(
    state = state,
    options = RhoAgentOptions(
      provider = provider,
      model = model,
      system_prompt = system_prompt,
      tool_execution = tool_execution,
      steering_mode = steering_mode,
      follow_up_mode = follow_up_mode,
      policy = policy,
      stream_options = stream_options
    )
  )
}

rho_state_messages <- function(agent) agent@state$messages

S7::method(
  rho_handle_agent_event,
  list(S7::class_function, RhoAgentEvent)
) <- function(listener, event, agent, ...) {
  rho.async::rho_as_task(listener(event, agent))
}

S7::method(rho_emit_agent_event, RhoAgent) <- function(agent, event, ...) {
  rho.async::rho_coro_task(
    function() {
      agent@state$event_sequence <- agent@state$event_sequence + 1L
      event@sequence <- agent@state$event_sequence
      event@timestamp <- as.double(Sys.time())
      agent@state$events[[length(agent@state$events) + 1L]] <- event
      for (listener in agent@state$listeners) {
        coro::await(rho.async::rho_as_promise(
          rho_handle_agent_event(listener, event, agent)
        ))
      }
      event
    },
    label = paste0("agent-event-", event@type)
  )
}

S7::method(rho_subscribe, RhoAgent) <- function(agent, listener, ...) {
  listener_id <- paste0("listener-", length(agent@state$listeners) + 1L)
  agent@state$listeners[[listener_id]] <- listener
  function() {
    agent@state$listeners[[listener_id]] <- NULL
    invisible(TRUE)
  }
}

rho_agent_message <- function(message) {
  if (S7::S7_inherits(message, rho.ai::UserMessage)) {
    return(message)
  }
  rho.ai::rho_user_message(message)
}

S7::method(rho_steer, RhoAgent) <- function(agent, message, ...) {
  if (identical(agent@state$phase, "idle")) {
    return(rho.async::rho_task(rho_agent_error("Cannot steer an idle agent", "invalid_state")))
  }
  agent@state$steering_queue[[length(agent@state$steering_queue) + 1L]] <- rho_agent_message(
    message
  )
  rho.async::rho_then(
    rho_emit_agent_event(
      agent,
      rho_queue_update_event("steering", length(agent@state$steering_queue))
    ),
    function(event) NULL
  )
}

S7::method(rho_follow_up, RhoAgent) <- function(agent, message, ...) {
  if (identical(agent@state$phase, "idle")) {
    return(rho.async::rho_task(rho_agent_error(
      "Cannot queue a follow-up on an idle agent",
      "invalid_state"
    )))
  }
  agent@state$follow_up_queue[[length(agent@state$follow_up_queue) + 1L]] <- rho_agent_message(
    message
  )
  rho.async::rho_then(
    rho_emit_agent_event(
      agent,
      rho_queue_update_event("follow_up", length(agent@state$follow_up_queue))
    ),
    function(event) NULL
  )
}

S7::method(rho_abort_agent, RhoAgent) <- function(agent, reason = NULL, ...) {
  agent@state$cancelled <- TRUE
  agent@state$cancel_reason <- reason %||% "cancelled"
  if (!is.null(agent@state$current_stream)) {
    rho.async::rho_stream_close(agent@state$current_stream)
  }
  rho.async::rho_task(NULL)
}

S7::method(rho_wait_for_idle, RhoAgent) <- function(agent, ...) {
  if (identical(agent@state$phase, "idle")) {
    return(rho.async::rho_task(NULL))
  }
  waiter_id <- paste0("waiter-", length(agent@state$idle_waiters) + 1L)
  promise <- promises::promise(function(resolve, reject) {
    agent@state$idle_waiters[[waiter_id]] <- resolve
  })
  rho.async::rho_task_from_promise(promise, label = "agent-idle")
}

S7::method(rho_reset, RhoAgent) <- function(agent, ...) {
  if (!identical(agent@state$phase, "idle")) {
    return(rho.async::rho_task(rho_agent_error("Cannot reset a running agent", "busy")))
  }
  agent@state$messages <- list()
  agent@state$events <- list()
  agent@state$steering_queue <- list()
  agent@state$follow_up_queue <- list()
  agent@state$pending_tool_calls <- character()
  agent@state$cancelled <- FALSE
  agent@state$cancel_reason <- NULL
  rho.async::rho_task(NULL)
}

S7::method(rho_prompt, RhoAgent) <- function(agent, input, images = NULL, ...) {
  content <- if (is.null(images)) input else c(list(rho.ai::rho_text(input)), images)
  prompts <- list(rho.ai::rho_user_message(content))
  rho_run_agent_loop(agent, prompts, continue = FALSE)
}

S7::method(rho_continue, RhoAgent) <- function(agent, ...) {
  rho_run_agent_loop(agent, list(), continue = TRUE)
}

S7::method(rho_transform_agent_context, RhoDefaultAgentPolicy) <- function(
  policy,
  agent,
  context,
  ...
) {
  rho.async::rho_task(context)
}

S7::method(rho_before_tool_call, RhoDefaultAgentPolicy) <- function(
  policy,
  agent,
  assistant,
  tool,
  call,
  args,
  context,
  ...
) {
  rho.async::rho_task(rho_before_tool_call_decision())
}

S7::method(rho_after_tool_call, RhoDefaultAgentPolicy) <- function(
  policy,
  agent,
  assistant,
  tool,
  call,
  args,
  result,
  is_error,
  context,
  ...
) {
  rho.async::rho_task(rho_after_tool_call_decision(result, is_error))
}

S7::method(rho_prepare_next_turn, RhoDefaultAgentPolicy) <- function(
  policy,
  agent,
  message,
  tool_results,
  context,
  new_messages,
  ...
) {
  rho.async::rho_task(rho_next_turn_decision())
}
