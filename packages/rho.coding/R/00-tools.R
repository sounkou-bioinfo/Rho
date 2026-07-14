rho_tool_read <- function() {
  rho.ai::rho_tool_spec(
    name = "read",
    label = "Read",
    description = "Read a UTF-8 text file",
    parameters = list(required = "path"),
    execute = function(tool_call_id, params, signal, on_update, ctx) {
      rho.async::rho_task_from_function(
        function() {
          path <- params$path
          if (!file.exists(path)) {
            stop(sprintf("File not found: %s", path), call. = FALSE)
          }
          text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
          rho.ai::rho_tool_result(list(rho.ai::rho_text(text)), details = list(path = path))
        },
        label = "tool-read"
      )
    }
  )
}

rho_tool_write <- function() {
  rho.ai::rho_tool_spec(
    name = "write",
    label = "Write",
    description = "Write a UTF-8 text file",
    parameters = list(required = c("path", "text")),
    execute = function(tool_call_id, params, signal, on_update, ctx) {
      rho.async::rho_task_from_function(
        function() {
          dir.create(dirname(params$path), recursive = TRUE, showWarnings = FALSE)
          writeLines(params$text, params$path, useBytes = TRUE)
          rho.ai::rho_tool_result(
            list(rho.ai::rho_text(sprintf("wrote %s", params$path))),
            details = list(path = params$path)
          )
        },
        label = "tool-write"
      )
    }
  )
}

rho_coding_tools <- function() {
  list(rho_tool_read(), rho_tool_write(), rho_tool_bash(), rho_tool_r())
}
