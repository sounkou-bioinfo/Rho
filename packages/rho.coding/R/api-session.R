#' JSON session documents and the coding-host JSONL journal
#'
#' [rho_json_session_codec()] derives an allowlist of session-reachable S7
#' classes from `rho.agent` and `rho.ai`. [rho_encode_session_value()] and
#' [rho_decode_session_value()] preserve S7 class identity, properties, R atomic
#' storage modes, list names, missing values, and arbitrary JSON-compatible tool
#' arguments. Hosts can supply additional S7 classes explicitly or specialize
#' the codec generics for another document representation. JSON tags are
#' normalized once into validated internal S7 document classes; recursive
#' decoding proceeds by S7 dispatch.
#'
#' [rho_jsonl_session_journal()] implements the `SessionJournal` interface as a
#' coding-host adapter. File reads, locking, validation, and append run in mirai
#' workers. Each LF-delimited record carries a schema version, committed
#' position, and typed entry document. A file lock and the append request's
#' expected position reject stale writers before mutation. A missing final LF,
#' malformed record, or invalid S7 document resolves to a typed error value.
#'
#' @name rho_coding_session_contracts
#' @aliases RhoJsonSessionCodec RhoSessionCodecErrorValue
#' @aliases RhoJsonlSessionJournal RhoJsonlSessionJournalErrorValue
#' @aliases rho_json_session_codec rho_jsonl_session_journal
#' @aliases rho_encode_session_value rho_decode_session_value
#' @export RhoJsonSessionCodec
#' @export RhoSessionCodecErrorValue
#' @export RhoJsonlSessionJournal
#' @export RhoJsonlSessionJournalErrorValue
#' @export rho_json_session_codec
#' @export rho_jsonl_session_journal
#' @export rho_encode_session_value
#' @export rho_decode_session_value
#' @importFrom rho.agent rho_commit_session_entry rho_session_snapshot
NULL
