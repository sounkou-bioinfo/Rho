# Generated from packages/rho.async/inst/tinytest/rmd/task-contract.Rmd; do not edit.

library(tinytest)
library(rho.async)

t <- rho_task(42)
expect_false(rho_pending(t))
expect_equal(rho_await(t), 42)

t <- rho_rejected("boom")
expect_error(rho_await(t), "boom")

t <- rho_task(2)
out <- rho_then(t, function(x) x + 3)
expect_equal(rho_await(out), 5)
