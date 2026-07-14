# Generated from packages/rho.duckdb/inst/tinytest/rmd/sql-guard.Rmd; do not edit.

library(tinytest)
library(rho.duckdb)

expect_silent(rho_assert_readonly_sql("select 1"))
expect_error(rho_assert_readonly_sql("drop table x"), "read-only|forbidden")
