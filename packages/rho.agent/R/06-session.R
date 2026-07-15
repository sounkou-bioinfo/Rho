rho_next_session_entry_id <- function(agent) {
  agent@state$entry_sequence <- agent@state$entry_sequence + 1L
  sprintf("entry-%08d", agent@state$entry_sequence)
}

rho_session_message_entry <- function(agent, message) {
  RhoSessionMessageEntry(
    id = rho_next_session_entry_id(agent),
    timestamp = message@timestamp,
    message = message
  )
}

S7::method(
  rho_append_session_entry,
  list(RhoAgent, RhoSessionEntry)
) <- function(agent, entry, ...) {
  agent@state$entries[[length(agent@state$entries) + 1L]] <- entry
  rho.async::rho_task(entry)
}

S7::method(
  rho_append_session_entry,
  list(RhoAgent, RhoSessionMessageEntry)
) <- function(agent, entry, ...) {
  agent@state$entries[[length(agent@state$entries) + 1L]] <- entry
  agent@state$messages[[length(agent@state$messages) + 1L]] <- entry@message
  rho.async::rho_task(entry)
}

rho_record_agent_message <- function(agent, message) {
  entry <- rho_session_message_entry(agent, message)
  rho.async::rho_then(
    rho_append_session_entry(agent, entry),
    function(recorded) recorded
  )
}

rho_replace_agent_message <- function(agent, message_index, entry_index, message) {
  agent@state$messages[[message_index]] <- message
  entry <- agent@state$entries[[entry_index]]
  entry@message <- message
  entry@timestamp <- message@timestamp
  agent@state$entries[[entry_index]] <- entry
  rho.async::rho_task(message)
}

rho_exclude_session_entry <- function(agent, target_entry_id, reason) {
  entry <- RhoSessionContextExclusionEntry(
    id = rho_next_session_entry_id(agent),
    timestamp = as.double(Sys.time()),
    target_entry_id = target_entry_id,
    reason = reason
  )
  rho_append_session_entry(agent, entry)
}

rho_latest_compaction_index <- function(entries) {
  indexes <- which(vapply(
    entries,
    function(entry) S7::S7_inherits(entry, RhoSessionCompactionEntry),
    logical(1)
  ))
  if (!length(indexes)) NULL else indexes[[length(indexes)]]
}

rho_latest_compaction_entry <- function(agent) {
  index <- rho_latest_compaction_index(agent@state$entries)
  if (is.null(index)) NULL else agent@state$entries[[index]]
}

rho_session_context_entries <- function(agent) {
  entries <- agent@state$entries
  compaction_index <- rho_latest_compaction_index(entries)
  selected <- entries

  if (!is.null(compaction_index)) {
    compaction <- entries[[compaction_index]]
    ids <- vapply(entries, function(entry) entry@id, character(1))
    first_kept <- match(compaction@result@first_kept_entry_id, ids)
    retained <- if (!is.na(first_kept) && first_kept < compaction_index) {
      entries[seq.int(first_kept, compaction_index - 1L)]
    } else {
      list()
    }
    following <- if (compaction_index < length(entries)) {
      entries[seq.int(compaction_index + 1L, length(entries))]
    } else {
      list()
    }
    selected <- c(list(compaction), retained, following)
  }

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
    selected
  )
}

S7::method(
  rho_project_session_entry,
  list(RhoSessionEntry, RhoAgent)
) <- function(entry, agent, ...) {
  list()
}

S7::method(
  rho_project_session_entry,
  list(RhoSessionMessageEntry, RhoAgent)
) <- function(entry, agent, ...) {
  list(entry@message)
}

rho_compaction_summary_message <- function(entry) {
  rho.ai::rho_user_message(
    paste0(
      "The conversation history before this point was compacted into the following summary:\n\n",
      "<summary>\n",
      entry@result@summary,
      "\n</summary>"
    ),
    timestamp = entry@timestamp
  )
}

S7::method(
  rho_project_session_entry,
  list(RhoSessionCompactionEntry, RhoAgent)
) <- function(entry, agent, ...) {
  list(rho_compaction_summary_message(entry))
}

S7::method(rho_build_agent_context, RhoAgent) <- function(agent, ...) {
  entries <- rho_session_context_entries(agent)
  messages <- unlist(
    lapply(entries, rho_project_session_entry, agent = agent),
    recursive = FALSE
  )
  rho.ai::rho_context(
    agent@options@system_prompt,
    messages,
    agent@state$tools,
    agent@options@operations
  )
}
