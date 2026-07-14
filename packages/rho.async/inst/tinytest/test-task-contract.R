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

ready <- new.env(parent = emptyenv())
ready$value <- FALSE
bridge <- rho_task_callback_bridge(
  name = paste0("rho.async.test.", Sys.getpid())
)
started <- rho_await(rho_register_task_callback(bridge), timeout = 1000)
on.exit({
  if (S7::S7_inherits(started, RhoTaskCallbackBridge) && started@registered) {
    rho_await(rho_remove_task_callback(started), timeout = 1000)
  }
}, add = TRUE)

expect_true(S7::S7_inherits(started, RhoTaskCallbackBridge))
expect_true(started@registered)
expect_false(is.null(started@callback_id))

later::later(function() ready$value <- TRUE, delay = 0)
started@manager$evaluate(quote(NULL), NULL, TRUE, FALSE)

expect_true(ready$value)
expect_equal(started@observations$invocations, 1L)
expect_true(S7::S7_inherits(
  started@observations$last_result,
  RhoEventPumpProgress
))

stopped <- rho_await(rho_remove_task_callback(started), timeout = 1000)
started <- stopped
expect_false(stopped@registered)
