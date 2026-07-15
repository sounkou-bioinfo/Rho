#' Session context and compaction contracts
#'
#' The session transcript is append-only. Message entries retain the complete
#' interaction, while [rho_build_agent_context()] projects the active provider
#' context through the latest compaction entry and any explicit exclusions.
#'
#' [rho_compact()] prepares a stable cut point, runs an asynchronous compactor,
#' appends a semantic checkpoint, and invokes before/after policy methods.
#' Automatic threshold compaction and one bounded provider-input recovery use the
#' same protocol. Applications can supply another `RhoCompactor` class or
#' specialize the public generics without replacing the agent loop.
#'
#' @name rho_compaction_contracts
#' @aliases RhoCompactionReason RhoManualCompaction RhoThresholdCompaction
#' @aliases RhoProviderInputLimitCompaction RhoCompactionSource
#' @aliases RhoGeneratedCompaction
#' @aliases RhoProvidedCompaction RhoCompactor RhoSummaryCompactor
#' @aliases RhoCompactionOutcome RhoCompactionSkipped
#' @aliases RhoCompactionSettings RhoContextUsage RhoSessionEntry
#' @aliases RhoSessionMessageEntry RhoSessionCompactionEntry
#' @aliases RhoSessionContextExclusionEntry RhoCompactionPreparation
#' @aliases RhoCompactionCheckpoint RhoCompactionCut RhoCompactionResult
#' @aliases RhoCompactionErrorValue RhoNothingToCompact
#' @aliases RhoCompactionCancelled RhoCompactionFailure RhoCompactionBusy
#' @aliases RhoBeforeCompactionContext RhoBeforeCompactionDecision
#' @aliases RhoAfterCompactionContext RhoCompactionStartEvent
#' @aliases RhoCompactionEndEvent rho_compaction_settings
#' @aliases rho_before_compaction_decision rho_compaction_result rho_compact
#' @aliases rho_state_entries rho_append_session_entry rho_build_agent_context
#' @aliases rho_project_session_entry rho_estimate_tokens rho_context_usage
#' @aliases rho_should_compact rho_prepare_compaction rho_compact_preparation
#' @aliases rho_before_compaction rho_after_compaction
#' @aliases rho_compaction_cut_allowed rho_compaction_message_cut_allowed
#' @aliases rho_compaction_text rho_error_requests_compaction
#' @export RhoCompactionReason
#' @export RhoManualCompaction
#' @export RhoThresholdCompaction
#' @export RhoProviderInputLimitCompaction
#' @export RhoCompactionSource
#' @export RhoGeneratedCompaction
#' @export RhoProvidedCompaction
#' @export RhoCompactionOutcome
#' @export RhoCompactionSkipped
#' @export RhoCompactor
#' @export RhoSummaryCompactor
#' @export RhoCompactionSettings
#' @export RhoContextUsage
#' @export RhoSessionEntry
#' @export RhoSessionMessageEntry
#' @export RhoSessionCompactionEntry
#' @export RhoSessionContextExclusionEntry
#' @export RhoCompactionPreparation
#' @export RhoCompactionCheckpoint
#' @export RhoCompactionCut
#' @export RhoCompactionResult
#' @export RhoCompactionErrorValue
#' @export RhoNothingToCompact
#' @export RhoCompactionCancelled
#' @export RhoCompactionFailure
#' @export RhoCompactionBusy
#' @export RhoBeforeCompactionContext
#' @export RhoBeforeCompactionDecision
#' @export RhoAfterCompactionContext
#' @export RhoCompactionStartEvent
#' @export RhoCompactionEndEvent
#' @export rho_compaction_settings
#' @export rho_before_compaction_decision
#' @export rho_compaction_result
#' @export rho_compact
#' @export rho_state_entries
#' @export rho_append_session_entry
#' @export rho_build_agent_context
#' @export rho_project_session_entry
#' @export rho_estimate_tokens
#' @export rho_context_usage
#' @export rho_should_compact
#' @export rho_prepare_compaction
#' @export rho_compact_preparation
#' @export rho_before_compaction
#' @export rho_after_compaction
#' @export rho_compaction_cut_allowed
#' @export rho_compaction_message_cut_allowed
#' @export rho_compaction_text
#' @export rho_error_requests_compaction
NULL
