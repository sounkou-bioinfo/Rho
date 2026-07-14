# Generated from packages/rho.duckdb/inst/tinytest/rmd/sql-guard.Rmd; do not edit.

library(tinytest)
library(rho.duckdb)

expect_silent(rho_assert_readonly_sql("select 1"))
expect_error(rho_assert_readonly_sql("drop table x"), "read-only|forbidden")

connection <- rho_duckdb_connect()
result <- rho.bio::rho_sql_all(connection, "select 42::integer as answer") |>
  rho.async::rho_await(timeout = 5000)
rho_duckdb_disconnect(connection)

expect_equal(result$answer, 42L)
