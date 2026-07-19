S7::method(rho_estimate_tokens, S7::class_any) <- function(x, ...) 0

S7::method(rho_estimate_tokens, S7::class_character) <- function(x, ...) {
  as.double(ceiling(sum(nchar(x, type = "bytes"), na.rm = TRUE) / 4))
}

S7::method(rho_estimate_tokens, S7::class_list) <- function(x, ...) {
  as.double(sum(vapply(x, rho_estimate_tokens, double(1))))
}

S7::method(rho_estimate_tokens, rho.ai::TextContent) <- function(x, ...) {
  rho_estimate_tokens(x@text)
}

S7::method(rho_estimate_tokens, rho.ai::ThinkingContent) <- function(x, ...) {
  rho_estimate_tokens(x@text)
}

S7::method(rho_estimate_tokens, rho.ai::ImageContent) <- function(x, ...) 1200

S7::method(rho_estimate_tokens, rho.ai::ArtifactRefContent) <- function(x, ...) {
  rho_estimate_tokens(c(x@artifact_id, x@media_type))
}

S7::method(rho_estimate_tokens, rho.ai::ToolCall) <- function(x, ...) {
  arguments <- paste(deparse(x@arguments, width.cutoff = 500L), collapse = "")
  rho_estimate_tokens(c(x@name, arguments))
}

S7::method(rho_estimate_tokens, rho.ai::UserMessage) <- function(x, ...) {
  rho_estimate_tokens(x@content)
}

S7::method(rho_estimate_tokens, rho.ai::AssistantMessage) <- function(x, ...) {
  rho_estimate_tokens(x@content)
}

S7::method(rho_estimate_tokens, rho.ai::ToolResultMessage) <- function(x, ...) {
  rho_estimate_tokens(x@content)
}

rho_assistant_usage_is_current <- function(message, after) {
  S7::S7_inherits(message, rho.ai::AssistantMessage) &&
    message@timestamp > after &&
    !message@stop_reason %in% c("aborted", "error") &&
    S7::S7_inherits(message@usage, rho.ai::Usage) &&
    message@usage@total > 0
}

S7::method(rho_context_usage, S7::class_list) <- function(
  messages,
  after = -Inf,
  ...
) {
  usage_indexes <- which(vapply(
    messages,
    rho_assistant_usage_is_current,
    logical(1),
    after = after
  ))
  if (!length(usage_indexes)) {
    tokens <- rho_estimate_tokens(messages)
    return(RhoContextUsage(
      tokens = tokens,
      usage_tokens = 0,
      trailing_tokens = tokens,
      last_usage_index = NULL
    ))
  }

  last_usage_index <- usage_indexes[[length(usage_indexes)]]
  usage_tokens <- messages[[last_usage_index]]@usage@total
  trailing <- if (last_usage_index < length(messages)) {
    rho_estimate_tokens(messages[seq.int(last_usage_index + 1L, length(messages))])
  } else {
    0
  }
  RhoContextUsage(
    tokens = as.double(usage_tokens + trailing),
    usage_tokens = as.double(usage_tokens),
    trailing_tokens = as.double(trailing),
    last_usage_index = as.integer(last_usage_index)
  )
}

S7::method(
  rho_should_compact,
  list(RhoCompactionSettings, RhoContextUsage, rho.ai::Model)
) <- function(settings, usage, model, ...) {
  settings@enabled &&
    usage@tokens > as.double(model@limits@context_window) - settings@reserve_tokens
}

S7::method(rho_compaction_message_cut_allowed, S7::class_any) <- function(
  message,
  ...
) {
  FALSE
}

S7::method(rho_compaction_message_cut_allowed, rho.ai::UserMessage) <- function(
  message,
  ...
) {
  TRUE
}

S7::method(
  rho_compaction_message_cut_allowed,
  rho.ai::AssistantMessage
) <- function(message, ...) {
  TRUE
}

S7::method(rho_compaction_cut_allowed, RhoSessionEntry) <- function(entry, ...) {
  FALSE
}

S7::method(
  rho_compaction_cut_allowed,
  RhoSessionMessageEntry
) <- function(entry, ...) {
  rho_compaction_message_cut_allowed(entry@message)
}

rho_compaction_active_entries <- function(agent) {
  entries <- rho_active_session_entries(agent@state$entries)
  excluded <- vapply(
    Filter(
      function(entry) S7::S7_inherits(entry, RhoSessionContextExclusionEntry),
      entries
    ),
    function(entry) entry@target_entry_id,
    character(1)
  )
  Filter(
    function(entry) {
      !S7::S7_inherits(entry, RhoSessionMessageEntry) ||
        !entry@id %in% excluded
    },
    entries
  )
}

rho_compaction_turn_start <- function(entries, index, start) {
  for (candidate in seq.int(index, start)) {
    entry <- entries[[candidate]]
    if (
      S7::S7_inherits(entry, RhoSessionMessageEntry) &&
        S7::S7_inherits(entry@message, rho.ai::UserMessage)
    ) {
      return(candidate)
    }
  }
  NULL
}

rho_compaction_cut <- function(entries, start, keep_recent_tokens) {
  valid <- which(vapply(entries, rho_compaction_cut_allowed, logical(1)))
  valid <- valid[valid >= start]
  if (!length(valid)) {
    return(NULL)
  }

  cut <- valid[[1L]]
  accumulated <- 0
  for (index in seq.int(length(entries), start)) {
    entry <- entries[[index]]
    if (!S7::S7_inherits(entry, RhoSessionMessageEntry)) {
      next
    }
    accumulated <- accumulated + rho_estimate_tokens(entry@message)
    if (accumulated >= keep_recent_tokens) {
      candidates <- valid[valid >= index]
      if (length(candidates)) {
        cut <- candidates[[1L]]
      }
      break
    }
  }

  entry <- entries[[cut]]
  starts_turn <- S7::S7_inherits(entry, RhoSessionMessageEntry) &&
    S7::S7_inherits(entry@message, rho.ai::UserMessage)
  turn_start <- if (starts_turn) NULL else rho_compaction_turn_start(entries, cut, start)
  RhoCompactionCut(
    first_kept = cut,
    turn_start = turn_start,
    split_turn = !starts_turn && !is.null(turn_start)
  )
}

rho_compaction_message_entries <- function(entries) {
  lapply(
    Filter(
      function(entry) S7::S7_inherits(entry, RhoSessionMessageEntry),
      entries
    ),
    function(entry) entry@message
  )
}

rho_compaction_checkpoint <- function(entries) {
  compaction_index <- rho_latest_compaction_index(entries)
  if (is.null(compaction_index)) {
    return(RhoCompactionCheckpoint(
      start = 1L,
      previous_summary = "",
      timestamp = -Inf
    ))
  }
  compaction <- entries[[compaction_index]]
  ids <- vapply(entries, function(entry) entry@id, character(1))
  first_kept <- match(compaction@result@first_kept_entry_id, ids)
  start <- if (is.na(first_kept)) compaction_index + 1L else first_kept
  RhoCompactionCheckpoint(
    start = as.integer(start),
    previous_summary = compaction@result@summary,
    timestamp = compaction@timestamp
  )
}

S7::method(
  rho_prepare_compaction,
  list(RhoAgent, RhoCompactionSettings)
) <- function(agent, settings, ...) {
  entries <- rho_compaction_active_entries(agent)
  if (!length(entries)) {
    return(rho_nothing_to_compact(
      "The session has no messages to compact"
    ))
  }

  checkpoint <- rho_compaction_checkpoint(entries)
  cut <- rho_compaction_cut(entries, checkpoint@start, settings@keep_recent_tokens)
  if (is.null(cut) || cut@first_kept <= checkpoint@start) {
    return(rho_nothing_to_compact(
      "The retained-token budget already covers the active session context"
    ))
  }

  history_end <- if (cut@split_turn) cut@turn_start else cut@first_kept
  history <- if (history_end > checkpoint@start) {
    entries[seq.int(checkpoint@start, history_end - 1L)]
  } else {
    list()
  }
  turn_prefix <- if (cut@split_turn && cut@first_kept > cut@turn_start) {
    entries[seq.int(cut@turn_start, cut@first_kept - 1L)]
  } else {
    list()
  }
  messages <- rho_compaction_message_entries(history)
  prefix_messages <- rho_compaction_message_entries(turn_prefix)
  if (!length(messages) && !length(prefix_messages)) {
    return(rho_nothing_to_compact(
      "The selected cut point contains no messages to summarize"
    ))
  }

  context <- rho_build_agent_context(agent)
  usage <- rho_context_usage(context@messages, after = checkpoint@timestamp)
  RhoCompactionPreparation(
    first_kept_entry_id = entries[[cut@first_kept]]@id,
    messages = messages,
    turn_prefix = prefix_messages,
    split_turn = cut@split_turn,
    tokens_before = usage@tokens,
    previous_summary = checkpoint@previous_summary,
    settings = settings
  )
}

S7::method(rho_compaction_text, S7::class_any) <- function(x, ...) {
  sprintf("[%s]", class(x)[[1L]])
}

S7::method(rho_compaction_text, S7::class_character) <- function(x, ...) {
  paste(x, collapse = "\n")
}

S7::method(rho_compaction_text, S7::class_list) <- function(x, ...) {
  paste(vapply(x, rho_compaction_text, character(1)), collapse = "\n")
}

S7::method(rho_compaction_text, rho.ai::TextContent) <- function(x, ...) x@text

S7::method(rho_compaction_text, rho.ai::ThinkingContent) <- function(x, ...) {
  paste0("<thinking>\n", x@text, "\n</thinking>")
}

S7::method(rho_compaction_text, rho.ai::ImageContent) <- function(x, ...) {
  sprintf("[image: %s]", x@mime_type)
}

S7::method(rho_compaction_text, rho.ai::ArtifactRefContent) <- function(x, ...) {
  sprintf("[artifact: %s; %s]", x@artifact_id, x@media_type)
}

S7::method(rho_compaction_text, rho.ai::ToolCall) <- function(x, ...) {
  arguments <- paste(deparse(x@arguments, width.cutoff = 500L), collapse = "")
  sprintf("[tool call: %s]\n%s", x@name, arguments)
}

S7::method(rho_compaction_text, rho.ai::UserMessage) <- function(x, ...) {
  paste0("user:\n", rho_compaction_text(x@content))
}

S7::method(rho_compaction_text, rho.ai::AssistantMessage) <- function(x, ...) {
  paste0("assistant:\n", rho_compaction_text(x@content))
}

S7::method(rho_compaction_text, rho.ai::ToolResultMessage) <- function(x, ...) {
  paste0("tool result (", x@tool_name, "):\n", rho_compaction_text(x@content))
}

rho_compaction_system_prompt <- function() {
  paste(
    "Summarize the supplied conversation as a context checkpoint.",
    "Do not continue the conversation or answer its questions.",
    "Preserve exact paths, identifiers, constraints, decisions, progress, and next steps."
  )
}

rho_compaction_summary_prompt <- function(
  messages,
  previous_summary,
  custom_instructions
) {
  sections <- c(
    "<conversation>",
    vapply(messages, rho_compaction_text, character(1)),
    "</conversation>"
  )
  if (nzchar(previous_summary)) {
    sections <- c(
      sections,
      "<previous-summary>",
      previous_summary,
      "</previous-summary>",
      "Update the previous summary with the new conversation."
    )
  }
  sections <- c(
    sections,
    "Use sections for goal, constraints, completed work, current work, decisions, next steps, and critical context."
  )
  if (nzchar(custom_instructions)) {
    sections <- c(sections, "Additional focus:", custom_instructions)
  }
  paste(sections, collapse = "\n\n")
}

rho_compaction_prefix_prompt <- function(messages) {
  paste(
    "<conversation-prefix>",
    paste(vapply(messages, rho_compaction_text, character(1)), collapse = "\n\n"),
    "</conversation-prefix>",
    paste(
      "This is the omitted prefix of a turn whose recent suffix remains in context.",
      "Summarize the original request, early progress, and facts needed to understand that suffix."
    ),
    sep = "\n\n"
  )
}

rho_compaction_completion <- function(agent, preparation, prompt, fraction) {
  max_tokens <- max(
    1L,
    min(
      floor(fraction * preparation@settings@reserve_tokens),
      agent@options@model@limits@max_tokens
    )
  )
  context <- rho.ai::rho_context(
    system_prompt = rho_compaction_system_prompt(),
    messages = list(rho.ai::rho_user_message(prompt))
  )
  options <- utils::modifyList(
    agent@options@stream_options,
    list(max_tokens = as.integer(max_tokens))
  )
  rho.ai::rho_complete(
    agent@options@provider,
    agent@options@model,
    context,
    options = options
  )
}

rho_compaction_completion_text <- function(value) {
  if (S7::S7_inherits(value, rho.ai::ProviderErrorValue)) {
    return(rho_compaction_error(
      RhoCompactionFailure,
      paste("Compaction summarization failed:", value@message),
      details = list(provider_error = value)
    ))
  }
  if (!S7::S7_inherits(value, rho.ai::AssistantMessage)) {
    return(rho_compaction_error(
      RhoCompactionFailure,
      "The compaction provider returned a value outside the assistant-message protocol",
      details = list(value = value)
    ))
  }
  text <- paste(
    vapply(
      Filter(
        function(content) S7::S7_inherits(content, rho.ai::TextContent),
        value@content
      ),
      function(content) content@text,
      character(1)
    ),
    collapse = "\n"
  )
  if (!nzchar(text)) {
    return(rho_compaction_error(
      RhoCompactionFailure,
      "The compaction provider returned no text summary"
    ))
  }
  text
}

S7::method(
  rho_compact_preparation,
  list(RhoSummaryCompactor, RhoCompactionPreparation)
) <- function(
  compactor,
  preparation,
  agent,
  custom_instructions = "",
  ...
) {
  rho.async::rho_coro_task(
    function() {
      history_prompt <- rho_compaction_summary_prompt(
        preparation@messages,
        preparation@previous_summary,
        custom_instructions
      )
      history <- coro::await(rho.async::rho_as_promise(
        rho_compaction_completion(agent, preparation, history_prompt, 0.8)
      ))
      summary <- rho_compaction_completion_text(history)
      if (S7::S7_inherits(summary, RhoCompactionErrorValue)) {
        return(summary)
      }

      if (preparation@split_turn && length(preparation@turn_prefix)) {
        prefix <- coro::await(rho.async::rho_as_promise(
          rho_compaction_completion(
            agent,
            preparation,
            rho_compaction_prefix_prompt(preparation@turn_prefix),
            0.5
          )
        ))
        prefix <- rho_compaction_completion_text(prefix)
        if (S7::S7_inherits(prefix, RhoCompactionErrorValue)) {
          return(prefix)
        }
        summary <- paste0(
          summary,
          "\n\n---\n\nTurn context for the retained suffix:\n\n",
          prefix
        )
      }

      rho_compaction_result(
        summary = summary,
        first_kept_entry_id = preparation@first_kept_entry_id,
        tokens_before = preparation@tokens_before,
        source = RhoGeneratedCompaction()
      )
    },
    label = "session-compaction-summary"
  )
}

S7::method(
  rho_before_compaction,
  list(RhoDefaultAgentPolicy, RhoBeforeCompactionContext)
) <- function(policy, context, ...) {
  rho.async::rho_task(rho_before_compaction_decision())
}

S7::method(
  rho_after_compaction,
  list(RhoDefaultAgentPolicy, RhoAfterCompactionContext)
) <- function(policy, context, ...) {
  rho.async::rho_task(NULL)
}

rho_compaction_start_event <- function(reason, will_retry, preparation) {
  rho_agent_event(
    RhoCompactionStartEvent,
    "compaction_start",
    reason = reason,
    will_retry = will_retry,
    preparation = preparation
  )
}

rho_compaction_end_event <- function(
  reason,
  will_retry,
  outcome = NULL,
  error = NULL
) {
  rho_agent_event(
    RhoCompactionEndEvent,
    "compaction_end",
    reason = reason,
    will_retry = will_retry,
    outcome = outcome,
    error = error
  )
}

rho_validate_compaction_result <- function(agent, result) {
  if (!S7::S7_inherits(result, RhoCompactionResult)) {
    return(rho_compaction_error(
      RhoCompactionFailure,
      "A compactor must return a RhoCompactionResult"
    ))
  }
  entry <- Filter(
    function(candidate) identical(candidate@id, result@first_kept_entry_id),
    agent@state$entries
  )
  if (
    length(entry) != 1L ||
      !S7::S7_inherits(entry[[1L]], RhoSessionMessageEntry) ||
      !rho_compaction_cut_allowed(entry[[1L]])
  ) {
    return(rho_compaction_error(
      RhoCompactionFailure,
      "The compaction result does not reference a valid retained message entry"
    ))
  }
  result
}

rho_compaction_task_value <- function(action, message) {
  task <- tryCatch(
    action(),
    error = function(error) {
      rho.async::rho_task(rho_compaction_error(
        RhoCompactionFailure,
        paste(message, conditionMessage(error)),
        details = list(parent = error)
      ))
    }
  )
  rho.async::rho_catch(
    rho.async::rho_as_task(task),
    function(error) {
      rho_compaction_error(
        RhoCompactionFailure,
        paste(message, conditionMessage(error)),
        details = list(parent = error)
      )
    }
  )
}

rho_run_compaction <- function(
  agent,
  reason,
  custom_instructions = "",
  will_retry = FALSE
) {
  preparation <- rho_prepare_compaction(agent, agent@options@compaction)
  if (
    S7::S7_inherits(preparation, RhoCompactionSkipped) ||
      S7::S7_inherits(preparation, RhoCompactionErrorValue)
  ) {
    return(rho.async::rho_task(preparation))
  }

  rho.async::rho_coro_task(
    function() {
      coro::await(rho.async::rho_as_promise(
        rho_emit_agent_event(
          agent,
          rho_compaction_start_event(reason, will_retry, preparation)
        )
      ))
      before_context <- RhoBeforeCompactionContext(
        agent = agent,
        preparation = preparation,
        reason = reason,
        will_retry = will_retry,
        custom_instructions = custom_instructions
      )
      decision <- coro::await(rho.async::rho_as_promise(
        rho_compaction_task_value(
          function() rho_before_compaction(agent@options@policy, before_context),
          "Before-compaction policy failed:"
        )
      ))
      if (S7::S7_inherits(decision, RhoCompactionErrorValue)) {
        coro::await(rho.async::rho_as_promise(rho_emit_agent_event(
          agent,
          rho_compaction_end_event(reason, will_retry, error = decision)
        )))
        return(decision)
      }
      if (!S7::S7_inherits(decision, RhoBeforeCompactionDecision)) {
        error <- rho_compaction_error(
          RhoCompactionFailure,
          "Before-compaction policy must return a RhoBeforeCompactionDecision"
        )
        coro::await(rho.async::rho_as_promise(rho_emit_agent_event(
          agent,
          rho_compaction_end_event(reason, will_retry, error = error)
        )))
        return(error)
      }
      if (decision@cancel) {
        outcome <- rho_compaction_cancelled(
          "Compaction was cancelled by the agent policy"
        )
        coro::await(rho.async::rho_as_promise(rho_emit_agent_event(
          agent,
          rho_compaction_end_event(reason, will_retry, outcome = outcome)
        )))
        return(outcome)
      }

      result <- decision@result
      if (is.null(result)) {
        result <- coro::await(rho.async::rho_as_promise(
          rho_compaction_task_value(
            function() {
              rho_compact_preparation(
                agent@options@compactor,
                preparation,
                agent,
                custom_instructions = custom_instructions
              )
            },
            "Compactor failed:"
          )
        ))
      }
      result <- rho_validate_compaction_result(agent, result)
      if (S7::S7_inherits(result, RhoCompactionErrorValue)) {
        coro::await(rho.async::rho_as_promise(rho_emit_agent_event(
          agent,
          rho_compaction_end_event(reason, will_retry, error = result)
        )))
        return(result)
      }

      entry <- RhoSessionCompactionEntry(
        id = rho_next_session_entry_id(agent),
        timestamp = as.double(Sys.time()),
        result = result,
        reason = reason,
        will_retry = will_retry
      )
      commit <- coro::await(rho.async::rho_as_promise(
        rho_append_session_entry(agent, entry)
      ))
      if (S7::S7_inherits(commit, RhoSessionJournalErrorValue)) {
        error <- rho_compaction_error(
          RhoCompactionFailure,
          commit@message,
          details = list(journal = commit)
        )
        coro::await(rho.async::rho_as_promise(rho_emit_agent_event(
          agent,
          rho_compaction_end_event(reason, will_retry, error = error)
        )))
        return(error)
      }
      after_context <- RhoAfterCompactionContext(
        agent = agent,
        entry = entry,
        result = result,
        reason = reason,
        will_retry = will_retry
      )
      after <- coro::await(rho.async::rho_as_promise(
        rho_compaction_task_value(
          function() rho_after_compaction(agent@options@policy, after_context),
          "After-compaction policy failed:"
        )
      ))
      after_error <- NULL
      if (S7::S7_inherits(after, RhoCompactionErrorValue)) {
        after_error <- after
      }
      coro::await(rho.async::rho_as_promise(rho_emit_agent_event(
        agent,
        rho_compaction_end_event(
          reason,
          will_retry,
          outcome = result,
          error = after_error
        )
      )))
      result
    },
    label = "session-compaction"
  )
}

S7::method(rho_compact, RhoAgent) <- function(
  agent,
  custom_instructions = "",
  reason = RhoManualCompaction(),
  will_retry = FALSE,
  ...
) {
  if (!identical(agent@state$phase, "idle")) {
    return(rho.async::rho_task(rho_compaction_error(
      RhoCompactionBusy,
      "Compaction requires an idle agent"
    )))
  }
  agent@state$phase <- "compaction"
  rho.async::rho_coro_task(
    function() {
      on.exit(rho_set_agent_idle(agent), add = TRUE)
      coro::await(rho.async::rho_as_promise(rho_run_compaction(
        agent,
        reason,
        custom_instructions,
        will_retry
      )))
    },
    label = "manual-session-compaction"
  )
}

S7::method(
  rho_error_requests_compaction,
  list(S7::class_any, rho.ai::Model)
) <- function(error, model, ...) {
  FALSE
}

S7::method(
  rho_error_requests_compaction,
  list(rho.ai::ProviderInputLimitError, rho.ai::Model)
) <- function(error, model, ...) {
  TRUE
}

S7::method(
  rho_error_requests_compaction,
  list(RhoAgentErrorValue, rho.ai::Model)
) <- function(error, model, ...) {
  provider_error <- error@details$provider_error
  !is.null(provider_error) && rho_error_requests_compaction(provider_error, model)
}

rho_context_after_threshold_compaction <- function(agent) {
  context <- rho_build_agent_context(agent)
  compaction <- rho_latest_compaction_entry(agent)
  after <- if (is.null(compaction)) -Inf else compaction@timestamp
  usage <- rho_context_usage(context@messages, after = after)
  if (!rho_should_compact(agent@options@compaction, usage, agent@options@model)) {
    return(rho.async::rho_task(context))
  }
  rho.async::rho_then(
    rho_run_compaction(agent, RhoThresholdCompaction()),
    function(result) {
      if (S7::S7_inherits(result, RhoCompactionResult)) {
        return(rho_build_agent_context(agent))
      }
      if (S7::S7_inherits(result, RhoCompactionSkipped)) {
        return(context)
      }
      result
    }
  )
}
