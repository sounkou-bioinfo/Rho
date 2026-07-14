#' DuckDB implementation of the Rho SQL contract
#'
#' Connections are explicit `RhoDuckDbConn` values. Queries and statements
#' return tasks through the generic SQL API declared in `rho.bio`.
#' `rho_assert_readonly_sql()` is intentionally conservative and is not a
#' substitute for the parser-backed guard required before accepting untrusted
#' SQL.
#'
#' @name rho_duckdb_contracts
#' @aliases RhoDuckDbConn rho_duckdb_connect rho_duckdb_disconnect
#' @aliases rho_assert_readonly_sql
#' @export RhoDuckDbConn
#' @export rho_duckdb_connect
#' @export rho_duckdb_disconnect
#' @export rho_assert_readonly_sql
#' @importFrom rho.bio rho_sql_all rho_sql_run
#' @importFrom rho.async rho_task_from_function
NULL
