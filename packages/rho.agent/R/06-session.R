rho_next_session_entry_id <- function(agent) {
  used <- vapply(agent@state$entries, function(entry) entry@id, character(1))
  repeat {
    agent@state$entry_sequence <- agent@state$entry_sequence + 1L
    candidate <- sprintf("entry-%08d", agent@state$entry_sequence)
    if (!candidate %in% used) {
      return(candidate)
    }
  }
}

rho_session_message_entry <- function(agent, message) {
  RhoSessionMessageEntry(
    id = rho_next_session_entry_id(agent),
    timestamp = message@timestamp,
    message = message
  )
}

rho_memory_session_journal <- function() {
  RhoMemorySessionJournal(
    state = rho_new_state(entries = list(), position = 0L)
  )
}

S7::method(
  rho_commit_session_entry,
  list(RhoMemorySessionJournal, RhoSessionAppend)
) <- function(journal, append, ...) {
  state <- journal@state
  if (!identical(append@after, state$position)) {
    return(rho.async::rho_task(rho_session_conflict(
      "The session journal has advanced beyond the expected position",
      details = list(expected = append@after, current = state$position)
    )))
  }
  ids <- vapply(state$entries, function(committed) committed@id, character(1))
  if (append@entry@id %in% ids) {
    return(rho.async::rho_task(rho_session_conflict(
      "A session entry with this identifier is already committed",
      details = list(
        entry_id = append@entry@id,
        position = match(append@entry@id, ids)
      )
    )))
  }
  position <- state$position + 1L
  state$entries[[position]] <- append@entry
  state$position <- position
  rho.async::rho_task(RhoSessionCommit(
    entry = append@entry,
    position = position
  ))
}

S7::method(
  rho_session_snapshot,
  RhoMemorySessionJournal
) <- function(journal, ...) {
  rho.async::rho_task(RhoSessionSnapshot(
    entries = journal@state$entries,
    position = journal@state$position
  ))
}

rho_project_session_messages <- function(entries) {
  lapply(
    Filter(
      function(entry) S7::S7_inherits(entry, RhoSessionMessageEntry),
      rho_active_session_entries(entries)
    ),
    function(entry) entry@message
  )
}

S7::method(
  rho_apply_session_snapshot,
  list(RhoAgent, RhoSessionSnapshot)
) <- function(agent, snapshot, ...) {
  if (!identical(agent@state$phase, "idle")) {
    return(rho.async::rho_task(rho_session_conflict(
      "A running agent cannot synchronize its session"
    )))
  }

  current_position <- agent@state$journal_position
  if (snapshot@position < current_position) {
    return(rho.async::rho_task(rho_session_conflict(
      "The session snapshot is behind the agent projection",
      details = list(
        agent_position = current_position,
        snapshot_position = snapshot@position
      )
    )))
  }

  current <- agent@state$entries
  prefix <- if (length(current)) {
    snapshot@entries[seq_along(current)]
  } else {
    list()
  }
  if (length(current) > length(snapshot@entries) || !identical(current, prefix)) {
    return(rho.async::rho_task(rho_session_conflict(
      "The session snapshot diverges from the agent projection",
      details = list(
        agent_position = current_position,
        snapshot_position = snapshot@position
      )
    )))
  }

  agent@state$entries <- snapshot@entries
  agent@state$messages <- rho_project_session_messages(snapshot@entries)
  agent@state$journal_position <- snapshot@position
  agent@state$entry_sequence <- max(
    agent@state$entry_sequence,
    snapshot@position
  )
  rho.async::rho_task(agent)
}

S7::method(rho_sync_session, RhoAgent) <- function(agent, ...) {
  if (!identical(agent@state$phase, "idle")) {
    return(rho.async::rho_task(rho_session_conflict(
      "A running agent cannot synchronize its session"
    )))
  }
  rho.async::rho_then(
    rho_session_snapshot(agent@journal),
    function(snapshot) {
      if (S7::S7_inherits(snapshot, RhoSessionJournalErrorValue)) {
        return(snapshot)
      }
      if (!S7::S7_inherits(snapshot, RhoSessionSnapshot)) {
        return(rho_session_journal_error(
          "A session journal snapshot must resolve to RhoSessionSnapshot or RhoSessionJournalErrorValue"
        ))
      }
      rho_apply_session_snapshot(agent, snapshot)
    }
  )
}

rho_apply_session_commit <- function(agent, commit) {
  if (S7::S7_inherits(commit, RhoSessionJournalErrorValue)) {
    return(commit)
  }
  if (!S7::S7_inherits(commit, RhoSessionCommit)) {
    rho.async::rho_signal_contract_violation(
      "A session journal append must resolve to RhoSessionCommit or RhoSessionJournalErrorValue"
    )
  }
  if (commit@position != agent@state$journal_position + 1L) {
    return(rho_session_conflict(
      "The session journal returned a non-consecutive commit position",
      details = list(
        expected = agent@state$journal_position + 1L,
        received = commit@position
      )
    ))
  }
  agent@state$journal_position <- commit@position
  agent@state$entries[[length(agent@state$entries) + 1L]] <- commit@entry
  if (S7::S7_inherits(commit@entry, RhoSessionMessageEntry)) {
    agent@state$messages[[length(agent@state$messages) + 1L]] <- commit@entry@message
  }
  commit
}

S7::method(
  rho_append_session_entry,
  list(RhoAgent, RhoSessionEntry)
) <- function(agent, entry, ...) {
  rho.async::rho_then(
    rho_commit_session_entry(
      agent@journal,
      RhoSessionAppend(
        entry = entry,
        after = agent@state$journal_position
      )
    ),
    function(commit) rho_apply_session_commit(agent, commit)
  )
}

rho_record_agent_message <- function(agent, message) {
  entry <- rho_session_message_entry(agent, message)
  rho_append_session_entry(agent, entry)
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
  entries <- rho_active_session_entries(agent@state$entries)
  index <- rho_latest_compaction_index(entries)
  if (is.null(index)) NULL else entries[[index]]
}

rho_active_session_entries <- function(entries) {
  resets <- which(vapply(
    entries,
    function(entry) S7::S7_inherits(entry, RhoSessionResetEntry),
    logical(1)
  ))
  if (!length(resets)) {
    return(entries)
  }
  start <- resets[[length(resets)]] + 1L
  if (start > length(entries)) list() else entries[seq.int(start, length(entries))]
}

rho_session_context_entries <- function(agent) {
  entries <- rho_active_session_entries(agent@state$entries)
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
  messages <- if (length(entries)) {
    unlist(
      lapply(entries, rho_project_session_entry, agent = agent),
      recursive = FALSE
    )
  } else {
    list()
  }
  rho.ai::rho_context(
    agent@options@system_prompt,
    messages,
    agent@state$tools,
    agent@options@operations
  )
}
