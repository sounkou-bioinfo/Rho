# Generated from packages/rho.coding/inst/tinytest/rmd/coding-tools.Rmd; do not edit.

library(tinytest)
library(rho.async)
library(rho.ai)
library(rho.coding)

tmp <- tempfile()
write_tool <- rho_tool_write()
read_tool <- rho_tool_read()
rho_await(rho_execute_tool(write_tool, ToolCall("1", "write", list(path = tmp, text = "hello"))))
out <- rho_await(rho_execute_tool(read_tool, ToolCall("2", "read", list(path = tmp))))
expect_equal(out@content[[1]]@text, "hello")

shell <- rho_resolve_bash(rho_current_platform())
expect_true(
  S7::S7_inherits(shell, RhoShellConfig) ||
    S7::S7_inherits(shell, RhoShellUnavailable)
)

fake_git_bash <- tempfile(fileext = "bash.exe")
file.create(fake_git_bash)
windows <- RhoWindowsPlatform(bash = fake_git_bash)
resolved <- rho_resolve_bash(windows)
expect_true(S7::S7_inherits(resolved, RhoBashShell))
expect_equal(resolved@executable, fake_git_bash)

missing <- rho_resolve_bash(windows, shell_path = paste0(fake_git_bash, "-missing"))
expect_true(S7::S7_inherits(missing, RhoShellUnavailable))

if (S7::S7_inherits(shell, RhoShellConfig)) {
  bash <- rho_tool_bash(shell = shell)
  success <- rho_execute_tool(
    bash,
    ToolCall("shell-1", "bash", list(command = "printf rho-shell-ok"))
  )
  expect_true(rho_is_task(success))
  success <- rho_await(success, timeout = 10000)
  expect_equal(success@content[[1]]@text, "rho-shell-ok")

  failure <- rho_execute_tool(
    bash,
    ToolCall("shell-2", "bash", list(command = "printf shell-error >&2; exit 7"))
  ) |>
    rho_await(timeout = 10000)
  expect_true(S7::S7_inherits(failure, ToolErrorResult))
  expect_equal(failure@details$exit_status, 7L)
  expect_true(grepl("shell-error", failure@content[[1]]@text, fixed = TRUE))
}

r_tool <- rho_tool_r()
r_task <- rho_execute_tool(
  r_tool,
  ToolCall("r-1", "r", list(code = "21L * 2L"))
)

expect_true(rho_is_task(r_task))
r_result <- rho_await(r_task, timeout = 10000)
expect_true(S7::S7_inherits(r_result, ToolResult))
expect_equal(r_result@details$value, 42L)
expect_true(grepl("42", r_result@content[[1]]@text, fixed = TRUE))
expect_true(S7::S7_inherits(r_tool@overlap, ToolMayOverlap))

r_failure <- rho_execute_tool(
  r_tool,
  ToolCall("r-2", "r", list(code = "stop('r-eval-failed', call. = FALSE)"))
) |>
  rho_await(timeout = 10000)
expect_true(S7::S7_inherits(r_failure, ToolErrorResult))
expect_true(grepl("r-eval-failed", r_failure@content[[1]]@text, fixed = TRUE))

session <- new.env(parent = baseenv())
evaluator <- RhoCurrentSessionREvaluator(environment = session)
r_repl <- rho_tool_r(evaluator)

rho_execute_tool(
  r_repl,
  ToolCall("r-3", "r", list(code = "answer <- 41L"))
) |>
  rho_await(timeout = 5000)
repl_result <- rho_execute_tool(
  r_repl,
  ToolCall("r-4", "r", list(code = "answer + 1L"))
) |>
  rho_await(timeout = 5000)

expect_equal(repl_result@details$value, 42L)
expect_equal(session$answer, 41L)
expect_true(S7::S7_inherits(r_repl@overlap, ToolRequiresExclusiveExecution))
