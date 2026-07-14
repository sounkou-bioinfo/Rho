rho_sse_parse <- function(text) {
  if (length(text) != 1L) {
    text <- paste(text, collapse = "\n")
  }
  lines <- strsplit(gsub("\r\n?", "\n", text), "\n", fixed = TRUE)[[1L]]
  events <- list()
  current <- list(event = "message", data = character(), id = "", retry = NA_integer_)
  flush <- function() {
    if (
      !length(current$data) &&
        !nzchar(current$id) &&
        identical(current$event, "message") &&
        is.na(current$retry)
    ) {
      return(NULL)
    }
    RhoSseEvent(
      event = current$event %||% "message",
      data = paste(current$data, collapse = "\n"),
      id = current$id %||% "",
      retry = as.integer(current$retry %||% NA_integer_)
    )
  }
  for (line in lines) {
    if (!nzchar(line)) {
      ev <- flush()
      if (!is.null(ev)) {
        events[[length(events) + 1L]] <- ev
      }
      current <- list(event = "message", data = character(), id = "", retry = NA_integer_)
      next
    }
    if (startsWith(line, ":")) {
      next
    }
    pos <- regexpr(":", line, fixed = TRUE)[[1L]]
    if (pos < 0L) {
      field <- line
      value <- ""
    } else {
      field <- substr(line, 1L, pos - 1L)
      value <- substr(line, pos + 1L, nchar(line))
      if (startsWith(value, " ")) value <- substr(value, 2L, nchar(value))
    }
    if (identical(field, "event")) {
      current$event <- value
    }
    if (identical(field, "data")) {
      current$data <- c(current$data, value)
    }
    if (identical(field, "id")) {
      current$id <- value
    }
    if (identical(field, "retry") && grepl("^[0-9]+$", value)) current$retry <- as.integer(value)
  }
  ev <- flush()
  if (!is.null(ev)) {
    events[[length(events) + 1L]] <- ev
  }
  events
}

rho_sse_connect <- function(client, request) {
  request@headers <- c(request@headers, list(Accept = "text/event-stream"))
  task <- rho.async::rho_then(rho_http_send(client, request), function(response) {
    if (is.na(response@status) || response@status < 200L || response@status >= 300L) {
      rho_abort(
        "HTTP request failed with status %s: %s",
        response@status,
        as.character(response@data)
      )
    }
    events <- rho_sse_parse(response@data)
    rho.async::rho_list_stream(events)
  })
  rho.async::rho_stream_from_task(task)
}
