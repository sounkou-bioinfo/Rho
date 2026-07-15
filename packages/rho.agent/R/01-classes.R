RhoToolExecutionMode <- S7::new_class("RhoToolExecutionMode", abstract = TRUE)
RhoParallelToolExecution <- S7::new_class(
  "RhoParallelToolExecution",
  parent = RhoToolExecutionMode
)
RhoSequentialToolExecution <- S7::new_class(
  "RhoSequentialToolExecution",
  parent = RhoToolExecutionMode
)

RhoQueueMode <- S7::new_class("RhoQueueMode", abstract = TRUE)
RhoOneAtATimeQueue <- S7::new_class("RhoOneAtATimeQueue", parent = RhoQueueMode)
RhoAllQueue <- S7::new_class("RhoAllQueue", parent = RhoQueueMode)

rho_agent_run_status <- S7::new_property(
  S7::class_character,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || !value %in% c("completed", "error", "aborted")) {
      "must be 'completed', 'error', or 'aborted'"
    }
  }
)

rho_nonnegative_integer <- S7::new_property(
  S7::class_integer,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || value < 0L) "must be one non-negative integer"
  }
)

RhoAgentPolicy <- S7::new_class("RhoAgentPolicy", abstract = TRUE)
RhoDefaultAgentPolicy <- S7::new_class("RhoDefaultAgentPolicy", parent = RhoAgentPolicy)

RhoAgentOptions <- S7::new_class(
  "RhoAgentOptions",
  properties = list(
    provider = S7::class_any,
    model = rho.ai::Model,
    system_prompt = S7::class_character,
    operations = S7::class_list,
    tool_execution = RhoToolExecutionMode,
    steering_mode = RhoQueueMode,
    follow_up_mode = RhoQueueMode,
    policy = RhoAgentPolicy,
    stream_options = S7::class_list
  )
)

RhoAgent <- S7::new_class(
  "RhoAgent",
  properties = list(state = S7::class_environment, options = RhoAgentOptions),
  validator = function(self) {
    required <- c(
      "messages",
      "tools",
      "listeners",
      "steering_queue",
      "follow_up_queue",
      "phase",
      "pending_tool_calls",
      "events",
      "event_sequence",
      "run_sequence",
      "idle_condition",
      "idle_waiters",
      "cancelled",
      "cancel_reason"
    )
    missing <- setdiff(required, ls(self@state, all.names = TRUE))
    if (length(missing)) sprintf("@state missing field(s): %s", paste(missing, collapse = ", "))
  }
)

rho_run_context_id <- S7::new_property(
  S7::class_character,
  validator = function(value) {
    if (length(value) != 1L || is.na(value) || !nzchar(value)) {
      "must be one non-empty string"
    }
  }
)

rho_optional_update_handler <- S7::new_property(
  S7::class_any,
  default = NULL,
  validator = function(value) {
    if (!is.null(value) && !is.function(value)) "must be NULL or a function"
  }
)

RhoRunContext <- S7::new_class(
  "RhoRunContext",
  properties = list(
    id = rho_run_context_id,
    agent = RhoAgent,
    application = S7::class_any,
    state = S7::class_environment
  )
)

RhoToolContext <- S7::new_class(
  "RhoToolContext",
  properties = list(
    run = RhoRunContext,
    model_context = rho.ai::Context,
    assistant = rho.ai::AssistantMessage,
    tool = rho.ai::ToolSpec,
    call = rho.ai::ToolCall,
    arguments = S7::class_list,
    signal = S7::new_property(S7::class_any, default = NULL),
    on_update = rho_optional_update_handler
  )
)

RhoCompletedToolContext <- S7::new_class(
  "RhoCompletedToolContext",
  parent = RhoToolContext,
  properties = list(
    result = rho.ai::ToolResult,
    is_error = S7::class_logical
  )
)

rho_optional_run_context <- S7::new_property(
  S7::class_any,
  default = NULL,
  validator = function(value) {
    if (!is.null(value) && !S7::S7_inherits(value, RhoRunContext)) {
      "must be NULL or a RhoRunContext value"
    }
  }
)

RhoAgentErrorValue <- S7::new_class(
  "RhoAgentErrorValue",
  properties = list(
    kind = S7::class_character,
    message = S7::class_character,
    retryable = S7::class_logical,
    details = S7::class_list
  )
)

RhoAgentRunResult <- S7::new_class(
  "RhoAgentRunResult",
  properties = list(
    messages = S7::class_list,
    tool_results = S7::class_list,
    events = S7::class_list,
    status = rho_agent_run_status,
    error = S7::class_any,
    context = rho_optional_run_context
  )
)

RhoBeforeToolCallDecision <- S7::new_class(
  "RhoBeforeToolCallDecision",
  properties = list(block = S7::class_logical, reason = S7::class_character)
)

RhoAfterToolCallDecision <- S7::new_class(
  "RhoAfterToolCallDecision",
  properties = list(result = rho.ai::ToolResult, is_error = S7::class_logical)
)

RhoNextTurnDecision <- S7::new_class(
  "RhoNextTurnDecision",
  properties = list(
    stop = S7::class_logical,
    context = S7::class_any,
    model = S7::class_any,
    stream_options = S7::class_list
  )
)

RhoAssistantTurn <- S7::new_class(
  "RhoAssistantTurn",
  properties = list(state = S7::class_environment),
  validator = function(self) {
    required <- c("agent", "message_index", "message", "terminal", "error")
    missing <- setdiff(required, ls(self@state, all.names = TRUE))
    if (length(missing)) sprintf("@state missing field(s): %s", paste(missing, collapse = ", "))
  }
)

RhoAssistantResponse <- S7::new_class(
  "RhoAssistantResponse",
  properties = list(message = rho.ai::AssistantMessage, error = S7::class_any)
)

RhoToolBatch <- S7::new_class(
  "RhoToolBatch",
  properties = list(messages = S7::class_list, terminate = S7::class_logical)
)

RhoAgentEvent <- S7::new_class(
  "RhoAgentEvent",
  abstract = TRUE,
  properties = list(
    type = S7::class_character,
    sequence = rho_nonnegative_integer,
    timestamp = S7::class_double
  )
)

RhoAgentStartEvent <- S7::new_class("RhoAgentStartEvent", parent = RhoAgentEvent)
RhoAgentEndEvent <- S7::new_class(
  "RhoAgentEndEvent",
  parent = RhoAgentEvent,
  properties = list(messages = S7::class_list)
)
RhoAgentSettledEvent <- S7::new_class(
  "RhoAgentSettledEvent",
  parent = RhoAgentEvent,
  properties = list(status = rho_agent_run_status)
)
RhoTurnStartEvent <- S7::new_class(
  "RhoTurnStartEvent",
  parent = RhoAgentEvent,
  properties = list(turn = rho_nonnegative_integer)
)
RhoTurnEndEvent <- S7::new_class(
  "RhoTurnEndEvent",
  parent = RhoAgentEvent,
  properties = list(
    turn = rho_nonnegative_integer,
    message = rho.ai::AssistantMessage,
    tool_results = S7::class_list
  )
)
RhoMessageEvent <- S7::new_class(
  "RhoMessageEvent",
  abstract = TRUE,
  parent = RhoAgentEvent,
  properties = list(message = S7::class_any)
)
RhoMessageStartEvent <- S7::new_class("RhoMessageStartEvent", parent = RhoMessageEvent)
RhoMessageEndEvent <- S7::new_class("RhoMessageEndEvent", parent = RhoMessageEvent)
RhoMessageUpdateEvent <- S7::new_class(
  "RhoMessageUpdateEvent",
  parent = RhoMessageEvent,
  properties = list(assistant_event = rho.ai::AssistantUpdateEvent)
)
RhoToolExecutionStartEvent <- S7::new_class(
  "RhoToolExecutionStartEvent",
  parent = RhoAgentEvent,
  properties = list(call = rho.ai::ToolCall)
)
RhoToolExecutionUpdateEvent <- S7::new_class(
  "RhoToolExecutionUpdateEvent",
  parent = RhoAgentEvent,
  properties = list(call = rho.ai::ToolCall, partial_result = S7::class_any)
)
RhoToolExecutionEndEvent <- S7::new_class(
  "RhoToolExecutionEndEvent",
  parent = RhoAgentEvent,
  properties = list(
    call = rho.ai::ToolCall,
    result = rho.ai::ToolResult,
    is_error = S7::class_logical
  )
)
RhoQueueUpdateEvent <- S7::new_class(
  "RhoQueueUpdateEvent",
  parent = RhoAgentEvent,
  properties = list(queue = S7::class_character, size = rho_nonnegative_integer)
)
