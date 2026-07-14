rho_stream <- S7::new_generic(
  "rho_stream",
  c("provider", "model", "context"),
  function(provider, model, context, options = list(), ...) S7::S7_dispatch()
)
rho_complete <- S7::new_generic(
  "rho_complete",
  c("provider", "model", "context"),
  function(provider, model, context, options = list(), ...) S7::S7_dispatch()
)
rho_validate_tool_args <- S7::new_generic(
  "rho_validate_tool_args",
  c("tool", "args"),
  function(tool, args, ...) S7::S7_dispatch()
)
rho_execute_tool <- S7::new_generic(
  "rho_execute_tool",
  c("tool", "call"),
  function(tool, call, ctx = NULL, signal = NULL, on_update = NULL, ...) S7::S7_dispatch()
)
rho_tool_overlap <- S7::new_generic(
  "rho_tool_overlap",
  c("tool", "call"),
  function(tool, call, ctx = NULL, ...) S7::S7_dispatch()
)
rho_decode_provider_event <- S7::new_generic(
  "rho_decode_provider_event",
  "decoder",
  function(decoder, event, ...) S7::S7_dispatch()
)
rho_reduce_provider_event <- S7::new_generic(
  "rho_reduce_provider_event",
  "event",
  function(event, decoder, ...) S7::S7_dispatch()
)
rho_start_response_item <- S7::new_generic(
  "rho_start_response_item",
  "item",
  function(item, decoder, output_index, ...) S7::S7_dispatch()
)
rho_finish_response_item <- S7::new_generic(
  "rho_finish_response_item",
  "item",
  function(item, decoder, output_index, ...) S7::S7_dispatch()
)
rho_supported_thinking_levels <- S7::new_generic(
  "rho_supported_thinking_levels",
  "model",
  function(model, ...) S7::S7_dispatch()
)
rho_clamp_thinking_level <- S7::new_generic(
  "rho_clamp_thinking_level",
  "model",
  function(model, level, ...) S7::S7_dispatch()
)
rho_map_thinking_level <- S7::new_generic(
  "rho_map_thinking_level",
  "model",
  function(model, level, ...) S7::S7_dispatch()
)
rho_model_supports_input <- S7::new_generic(
  "rho_model_supports_input",
  "model",
  function(model, input, ...) S7::S7_dispatch()
)
rho_model_supports_transport <- S7::new_generic(
  "rho_model_supports_transport",
  "model",
  function(model, transport, ...) S7::S7_dispatch()
)
rho_credential_read <- S7::new_generic(
  "rho_credential_read",
  "store",
  function(store, provider_id, ...) S7::S7_dispatch()
)
rho_credential_modify <- S7::new_generic(
  "rho_credential_modify",
  "store",
  function(store, provider_id, update, ...) S7::S7_dispatch()
)
rho_credential_delete <- S7::new_generic(
  "rho_credential_delete",
  "store",
  function(store, provider_id, ...) S7::S7_dispatch()
)
rho_auth_login <- S7::new_generic("rho_auth_login", "auth", function(auth, provider_id, io, ...) {
  S7::S7_dispatch()
})
rho_auth_refresh <- S7::new_generic("rho_auth_refresh", "auth", function(auth, credential, ...) {
  S7::S7_dispatch()
})
rho_auth_to_request <- S7::new_generic(
  "rho_auth_to_request",
  "auth",
  function(auth, credential, ...) S7::S7_dispatch()
)
rho_auth_prompt <- S7::new_generic("rho_auth_prompt", "io", function(io, prompt, ...) {
  S7::S7_dispatch()
})
rho_auth_notify <- S7::new_generic("rho_auth_notify", "io", function(io, event, ...) {
  S7::S7_dispatch()
})
rho_resolve_model_auth <- S7::new_generic(
  "rho_resolve_model_auth",
  "models",
  function(models, model, ...) S7::S7_dispatch()
)
rho_provider_support <- S7::new_generic(
  "rho_provider_support",
  c("provider", "model", "operation"),
  function(provider, model, operation, ...) S7::S7_dispatch()
)
rho_plan_tools <- S7::new_generic(
  "rho_plan_tools",
  c("provider", "model", "context"),
  function(provider, model, context, ...) S7::S7_dispatch()
)
rho_build_provider_request <- S7::new_generic(
  "rho_build_provider_request",
  c("provider", "model", "context"),
  function(provider, model, context, options = list(), ...) S7::S7_dispatch()
)
rho_compact_provider_input <- S7::new_generic(
  "rho_compact_provider_input",
  c("provider", "model", "context"),
  function(provider, model, context, options = list(), ...) S7::S7_dispatch()
)
rho_assistant_event_type <- S7::new_generic(
  "rho_assistant_event_type",
  "event",
  function(event, ...) S7::S7_dispatch()
)

S7::method(rho_assistant_event_type, AssistantStartEvent) <- function(event, ...) "start"
S7::method(rho_assistant_event_type, AssistantTextStartEvent) <- function(event, ...) "text_start"
S7::method(rho_assistant_event_type, AssistantTextDeltaEvent) <- function(event, ...) "text_delta"
S7::method(rho_assistant_event_type, AssistantTextEndEvent) <- function(event, ...) "text_end"
S7::method(rho_assistant_event_type, AssistantThinkingStartEvent) <- function(event, ...) {
  "thinking_start"
}
S7::method(rho_assistant_event_type, AssistantThinkingDeltaEvent) <- function(event, ...) {
  "thinking_delta"
}
S7::method(rho_assistant_event_type, AssistantThinkingEndEvent) <- function(event, ...) {
  "thinking_end"
}
S7::method(rho_assistant_event_type, AssistantToolCallStartEvent) <- function(event, ...) {
  "toolcall_start"
}
S7::method(rho_assistant_event_type, AssistantToolCallDeltaEvent) <- function(event, ...) {
  "toolcall_delta"
}
S7::method(rho_assistant_event_type, AssistantToolCallEndEvent) <- function(event, ...) {
  "toolcall_end"
}
S7::method(rho_assistant_event_type, AssistantDoneEvent) <- function(event, ...) "done"
S7::method(rho_assistant_event_type, AssistantErrorEvent) <- function(event, ...) "error"

S7::method(rho_complete, list(S7::class_any, Model, Context)) <- function(
  provider,
  model,
  context,
  options = list(),
  ...
) {
  rho.async::rho_task_from_function(
    function() {
      stream <- rho_stream(provider, model, context, options = options)
      events <- rho.async::rho_stream_collect(stream)
      terminal <- Filter(
        function(event) S7::S7_inherits(event, AssistantTerminalEvent),
        events
      )
      if (!length(terminal)) {
        rho_abort("Provider stream ended without a terminal event")
      }
      event <- terminal[[length(terminal)]]
      if (S7::S7_inherits(event, AssistantErrorEvent)) {
        rho_abort("%s", event@error@message)
      }
      event@message
    },
    label = "rho_complete"
  )
}

S7::method(rho_validate_tool_args, list(ToolSpec, S7::class_list)) <- function(tool, args, ...) {
  if (!is.null(tool@prepare_arguments)) {
    args <- tool@prepare_arguments(args)
  }
  required <- tool@parameters$required %||% character()
  missing <- setdiff(required, names(args))
  if (length(missing)) {
    rho_abort(
      "Tool `%s` missing required parameter(s): %s",
      tool@name,
      paste(missing, collapse = ", ")
    )
  }
  args
}

S7::method(rho_execute_tool, list(ToolSpec, ToolCall)) <- function(
  tool,
  call,
  ctx = NULL,
  signal = NULL,
  on_update = NULL,
  ...
) {
  args <- rho_validate_tool_args(tool, call@arguments)
  out <- tool@execute(call@id, args, signal, on_update, ctx)
  rho.async::rho_as_task(out)
}

S7::method(rho_tool_overlap, list(ToolSpec, ToolCall)) <- function(tool, call, ctx = NULL, ...) {
  tool@overlap
}
