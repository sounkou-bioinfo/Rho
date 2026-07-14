rho_error_assistant_message <- function(agent, stop_reason = "error") {
  rho.ai::rho_assistant_message(
    content = list(),
    provider = agent@options@model@provider,
    model = agent@options@model@id,
    stop_reason = stop_reason
  )
}

rho_assistant_turn <- function(agent) {
  RhoAssistantTurn(
    state = rho_new_state(
      agent = agent,
      message_index = 0L,
      message = NULL,
      terminal = FALSE,
      error = NULL
    )
  )
}

rho_store_assistant_message <- function(turn, message) {
  agent <- turn@state$agent
  turn@state$message <- message
  if (turn@state$message_index == 0L) {
    agent@state$messages[[length(agent@state$messages) + 1L]] <- message
    turn@state$message_index <- length(agent@state$messages)
    return(rho_emit_agent_event(agent, rho_message_start_event(message)))
  }
  agent@state$messages[[turn@state$message_index]] <- message
  rho.async::rho_task(message)
}

rho_end_assistant_turn <- function(turn, message, error = NULL) {
  rho.async::rho_then(rho_store_assistant_message(turn, message), function(ignored) {
    turn@state$terminal <- TRUE
    turn@state$error <- error
    rho_emit_agent_event(turn@state$agent, rho_message_end_event(message))
  })
}

rho_fail_assistant_turn <- function(turn, error) {
  stop_reason <- if (identical(error@kind, "aborted")) "aborted" else "error"
  message <- turn@state$message
  if (is.null(message)) {
    message <- rho_error_assistant_message(turn@state$agent, stop_reason)
  } else {
    message@stop_reason <- stop_reason
  }
  rho_end_assistant_turn(turn, message, error)
}

S7::method(
  rho_reduce_assistant_event,
  rho.ai::AssistantEvent
) <- function(event, turn, ...) {
  error <- rho_agent_error(
    sprintf("No agent reducer is defined for %s", class(event)[[1L]]),
    kind = "provider_protocol"
  )
  rho_fail_assistant_turn(turn, error)
}

S7::method(
  rho_reduce_assistant_event,
  rho.ai::AssistantStartEvent
) <- function(event, turn, ...) {
  rho_store_assistant_message(turn, event@partial)
}

S7::method(
  rho_reduce_assistant_event,
  rho.ai::AssistantUpdateEvent
) <- function(event, turn, ...) {
  rho.async::rho_then(rho_store_assistant_message(turn, event@partial), function(ignored) {
    rho_emit_agent_event(
      turn@state$agent,
      rho_message_update_event(event@partial, event)
    )
  })
}

S7::method(
  rho_reduce_assistant_event,
  rho.ai::AssistantDoneEvent
) <- function(event, turn, ...) {
  rho_end_assistant_turn(turn, event@message)
}

S7::method(
  rho_reduce_assistant_event,
  rho.ai::AssistantErrorEvent
) <- function(event, turn, ...) {
  error <- rho_agent_error(
    event@error@message,
    kind = "provider",
    retryable = event@error@retryable,
    details = list(provider_error = event@error)
  )
  rho_end_assistant_turn(turn, event@message, error)
}

rho_receive_assistant <- function(agent, context) {
  rho.async::rho_coro_task(
    function() {
      turn <- rho_assistant_turn(agent)
      transformed <- tryCatch(
        coro::await(rho.async::rho_as_promise(
          rho_transform_agent_context(agent@options@policy, agent, context)
        )),
        error = function(error) error
      )
      if (inherits(transformed, "error")) {
        error <- rho_agent_error(conditionMessage(transformed), "policy")
        coro::await(rho.async::rho_as_promise(rho_fail_assistant_turn(turn, error)))
        return(RhoAssistantResponse(message = turn@state$message, error = error))
      }
      if (!S7::S7_inherits(transformed, rho.ai::Context)) {
        error <- rho_agent_error(
          "Agent context policy did not return a Context",
          "policy"
        )
        coro::await(rho.async::rho_as_promise(rho_fail_assistant_turn(turn, error)))
        return(RhoAssistantResponse(message = turn@state$message, error = error))
      }

      stream <- tryCatch(
        rho.ai::rho_stream(
          agent@options@provider,
          agent@options@model,
          transformed,
          options = agent@options@stream_options
        ),
        error = function(error) error
      )
      if (inherits(stream, "error") || !rho.async::rho_is_stream(stream)) {
        if (inherits(stream, "error")) {
          message <- conditionMessage(stream)
        } else {
          message <- "Provider did not return a RhoStream"
        }
        error <- rho_agent_error(message, "provider")
        coro::await(rho.async::rho_as_promise(rho_fail_assistant_turn(turn, error)))
        return(RhoAssistantResponse(message = turn@state$message, error = error))
      }

      agent@state$current_stream <- stream
      on.exit(
        {
          agent@state$current_stream <- NULL
        },
        add = TRUE
      )

      repeat {
        if (isTRUE(agent@state$cancelled)) {
          error <- rho_agent_error(
            agent@state$cancel_reason %||% "Agent run was cancelled",
            "aborted"
          )
          coro::await(rho.async::rho_as_promise(rho_fail_assistant_turn(turn, error)))
          break
        }

        item <- tryCatch(
          coro::await(rho.async::rho_as_promise(
            rho.async::rho_stream_next(stream)
          )),
          error = function(error) error
        )
        if (inherits(item, "error")) {
          error <- rho_agent_error(
            conditionMessage(item),
            "provider",
            retryable = TRUE
          )
          coro::await(rho.async::rho_as_promise(rho_fail_assistant_turn(turn, error)))
          break
        }
        if (S7::S7_inherits(item, rho.async::RhoStreamEnd)) {
          break
        }
        if (
          !S7::S7_inherits(item, rho.async::RhoStreamValue) ||
            !S7::S7_inherits(item@value, rho.ai::AssistantEvent)
        ) {
          error <- rho_agent_error(
            "Provider stream yielded a value outside the AssistantEvent protocol",
            "provider_protocol"
          )
          coro::await(rho.async::rho_as_promise(rho_fail_assistant_turn(turn, error)))
          break
        }

        reduced <- tryCatch(
          coro::await(rho.async::rho_as_promise(
            rho_reduce_assistant_event(item@value, turn)
          )),
          error = function(error) error
        )
        if (inherits(reduced, "error")) {
          error <- rho_agent_error(conditionMessage(reduced), "provider_protocol")
          coro::await(rho.async::rho_as_promise(rho_fail_assistant_turn(turn, error)))
          break
        }
        if (isTRUE(turn@state$terminal)) break
      }

      if (!isTRUE(turn@state$terminal)) {
        error <- rho_agent_error(
          "Provider stream ended without a terminal event",
          "provider_protocol"
        )
        coro::await(rho.async::rho_as_promise(rho_fail_assistant_turn(turn, error)))
      }
      RhoAssistantResponse(
        message = turn@state$message,
        error = turn@state$error
      )
    },
    label = "assistant-response"
  )
}
