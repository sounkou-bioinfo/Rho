RhoDuckDbConn <- S7::new_class("RhoDuckDbConn", properties = list(conn = S7::class_any))

rho_duckdb_connect <- function(path = ":memory:", read_only = FALSE, ...) {
  conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = read_only, ...)
  RhoDuckDbConn(conn = conn)
}

rho_duckdb_disconnect <- function(conn, shutdown = TRUE) {
  DBI::dbDisconnect(conn@conn, shutdown = shutdown)
  invisible(TRUE)
}

rho_assert_readonly_sql <- function(sql) {
  x <- trimws(sql)
  first <- tolower(strsplit(x, "\\s+")[[1L]][[1L]])
  allowed <- c("select", "with", "describe", "pragma", "explain")
  if (!first %in% allowed) {
    stop(sprintf("SQL must be read-only; got statement starting with '%s'", first), call. = FALSE)
  }
  forbidden <- "\\b(insert|update|delete|merge|create|drop|alter|copy|attach|detach|install|load)\\b"
  if (grepl(forbidden, tolower(x), perl = TRUE)) {
    stop("SQL contains forbidden write/DDL/extension keyword", call. = FALSE)
  }
  invisible(sql)
}

S7::method(rho_sql_all, RhoDuckDbConn) <- function(conn, sql, params = list(), ...) {
  rho.async::rho_task_from_function(
    function() {
      rho_assert_readonly_sql(sql)
      DBI::dbGetQuery(conn@conn, sql, params = params)
    },
    label = "duckdb-query"
  )
}

S7::method(rho_sql_run, RhoDuckDbConn) <- function(conn, sql, params = list(), ...) {
  rho.async::rho_task_from_function(
    function() {
      rho_assert_readonly_sql(sql)
      DBI::dbExecute(conn@conn, sql, params = params)
      invisible(NULL)
    },
    label = "duckdb-run"
  )
}
