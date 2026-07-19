rho_http_contract_close <- function(client = NULL, stream = NULL, server = NULL) {
  if (!is.null(stream)) {
    try(rho.async::rho_stream_close(stream), silent = TRUE)
  }
  if (!is.null(client)) {
    try(rho.http::rho_http_client_close(client), silent = TRUE)
  }
  if (!is.null(server)) {
    try(server$close(), silent = TRUE)
  }
  invisible(TRUE)
}

rho_http_contract_client <- function(
  client_factory,
  timeout_ms,
  stream_buffer_size = 1L,
  max_error_body_bytes = 8L
) {
  client_factory(
    timeout_ms = timeout_ms,
    stream_buffer_size = stream_buffer_size,
    max_error_body_bytes = max_error_body_bytes
  )
}

rho_http_contract_header <- function(headers, name) {
  position <- match(tolower(name), tolower(names(headers)))
  if (is.na(position)) NULL else headers[[position]]
}

rho_http_contract_raw_peer <- function(head, body, body_delay_ms = 0L) {
  candidates <- sample.int(20000L, 100L) + 30000L
  listener <- NULL
  port <- NULL
  for (candidate in candidates) {
    listener <- tryCatch(
      serverSocket(candidate),
      error = function(error) NULL
    )
    if (!is.null(listener)) {
      port <- candidate
      break
    }
  }
  if (is.null(listener)) {
    stop("Could not reserve a local TCP port for the HTTP contract test")
  }

  state <- new.env(parent = emptyenv())
  state$listener <- listener
  state$connection <- NULL
  state$closed <- FALSE
  state$head <- head
  state$body <- body
  state$body_delay_ms <- body_delay_ms
  state$accept <- NULL
  state$write_body <- NULL

  state$write_body <- function() {
    if (isTRUE(state$closed) || is.null(state$connection)) {
      return(invisible(TRUE))
    }
    if (length(state$body)) {
      writeBin(state$body, state$connection)
      flush(state$connection)
    }
    close(state$connection)
    state$connection <- NULL
    state$closed <- TRUE
    invisible(TRUE)
  }

  state$accept <- function() {
    if (isTRUE(state$closed)) {
      return(invisible(TRUE))
    }
    connection <- tryCatch(
      socketAccept(
        state$listener,
        blocking = FALSE,
        open = "a+b",
        timeout = 1L
      ),
      error = function(error) NULL
    )
    if (is.null(connection)) {
      later::later(state$accept, delay = 0.001)
      return(invisible(TRUE))
    }
    state$connection <- connection
    readBin(connection, "raw", n = 8192L)
    writeBin(state$head, connection)
    flush(connection)
    later::later(state$write_body, delay = state$body_delay_ms / 1000)
    invisible(TRUE)
  }

  later::later(state$accept, delay = 0)
  list(
    url = sprintf("http://127.0.0.1:%d", port),
    state = state
  )
}

rho_http_contract_raw_peer_close <- function(peer) {
  state <- peer$state
  state$closed <- TRUE
  if (!is.null(state$connection)) {
    try(close(state$connection), silent = TRUE)
    state$connection <- NULL
  }
  try(close(state$listener), silent = TRUE)
  invisible(TRUE)
}

rho_http_contract_read_until_terminal <- function(stream, timeout_ms) {
  values <- list()
  for (index in seq_len(100L)) {
    item <- rho.async::rho_stream_next(stream) |>
      rho.async::rho_await(timeout = timeout_ms)
    if (S7::S7_inherits(item, rho.async::RhoStreamEnd)) {
      return(list(values = values, terminal = item))
    }
    if (!S7::S7_inherits(item, rho.async::RhoStreamValue)) {
      stop("HTTP body stream returned an invalid item")
    }
    values[[length(values) + 1L]] <- item@value
    if (S7::S7_inherits(item@value, rho.http::RhoHttpError)) {
      return(list(values = values, terminal = item@value))
    }
  }
  stop("HTTP body stream did not reach a terminal value")
}

rho_http_contract_open_execution <- function(
  client_factory,
  expected_open_execution,
  timeout_ms
) {
  client <- rho_http_contract_client(client_factory, timeout_ms)
  on.exit(rho_http_contract_close(client = client), add = TRUE)

  execution <- rho.http::rho_http_open_execution(client)
  expect_true(S7::S7_inherits(execution, expected_open_execution))
  expect_true(S7::S7_inherits(
    execution,
    rho.http::RhoHttpCancellableOpen
  ))
  expect_true(nzchar(execution@reason))
  expect_true(s7contract::implements(client, rho.http::HttpClient))
}

rho_http_contract_complete_request <- function(client_factory, timeout_ms) {
  server <- nanonext::http_server(
    "http://127.0.0.1:0",
    handlers = list(nanonext::handler(
      "/complete",
      function(request) {
        list(
          status = 201L,
          headers = c("Content-Type" = "text/plain"),
          body = "created"
        )
      },
      method = "POST"
    ))
  )
  expect_equal(server$start(), 0L)
  client <- rho_http_contract_client(client_factory, timeout_ms)
  on.exit(rho_http_contract_close(client = client, server = server), add = TRUE)

  request <- rho.http::rho_http_request(
    "POST",
    paste0(server$url, "/complete"),
    body = list(value = 1L),
    timeout_ms = timeout_ms
  )
  task <- rho.http::rho_http_send(client, request)
  expect_true(S7::S7_inherits(task, rho.async::RhoTask))
  response <- rho.async::rho_await(task, timeout = timeout_ms)
  expect_true(S7::S7_inherits(response, rho.http::RhoHttpResponse))
  expect_equal(response@status, 201L)
  expect_equal(response@data, "created")
}

rho_http_contract_fixed_body <- function(client_factory, timeout_ms) {
  server <- nanonext::http_server(
    "http://127.0.0.1:0",
    handlers = list(nanonext::handler(
      "/fixed",
      function(request) {
        list(
          status = 200L,
          headers = c("Content-Type" = "application/octet-stream"),
          body = charToRaw("fixed body")
        )
      }
    ))
  )
  expect_equal(server$start(), 0L)
  client <- rho_http_contract_client(client_factory, timeout_ms)
  stream <- NULL
  on.exit(
    rho_http_contract_close(client = client, stream = stream, server = server),
    add = TRUE
  )

  opening <- rho.http::rho_http_open_stream(
    client,
    rho.http::rho_http_request(
      "GET",
      paste0(server$url, "/fixed"),
      timeout_ms = timeout_ms
    )
  )
  expect_true(S7::S7_inherits(opening, rho.async::RhoTask))
  stream <- rho.async::rho_await(opening, timeout = timeout_ms)
  expect_true(S7::S7_inherits(stream, rho.http::RhoHttpBodyStream))
  expect_equal(stream@head@status, 200L)
  expect_equal(
    rho_http_contract_header(stream@head@headers, "Content-Length"),
    "10"
  )

  chunks <- rho.async::rho_stream_collect(stream, timeout = timeout_ms)
  ending <- rho.async::rho_stream_next(stream) |>
    rho.async::rho_await(timeout = timeout_ms)
  repeated_end <- rho.async::rho_stream_next(stream) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_equal(rawToChar(do.call(c, chunks)), "fixed body")
  expect_true(S7::S7_inherits(ending, rho.async::RhoStreamEnd))
  expect_true(S7::S7_inherits(repeated_end, rho.async::RhoStreamEnd))

  close_error <- tryCatch(
    {
      rho.async::rho_stream_close(stream)
      rho.async::rho_stream_close(stream)
      NULL
    },
    error = function(error) error
  )
  expect_true(is.null(close_error))
}

rho_http_contract_connection_delimited_body <- function(
  client_factory,
  timeout_ms,
  body_delay_ms = 100L
) {
  peer <- rho_http_contract_raw_peer(
    head = charToRaw(paste0(
      "HTTP/1.1 200 OK\r\n",
      "Content-Type: application/octet-stream\r\n",
      "Connection: close\r\n\r\n"
    )),
    body = charToRaw("close body"),
    body_delay_ms = body_delay_ms
  )
  client <- rho_http_contract_client(client_factory, timeout_ms)
  stream <- NULL
  on.exit(
    {
      rho_http_contract_raw_peer_close(peer)
      rho_http_contract_close(client = client, stream = stream)
    },
    add = TRUE
  )

  stream <- rho.http::rho_http_open_stream(
    client,
    rho.http::rho_http_request(
      "GET",
      paste0(peer$url, "/close-delimited"),
      timeout_ms = timeout_ms
    )
  ) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_true(S7::S7_inherits(stream, rho.http::RhoHttpBodyStream))
  observed <- rho_http_contract_read_until_terminal(stream, timeout_ms)
  expect_equal(rawToChar(do.call(c, observed$values)), "close body")
  expect_true(S7::S7_inherits(observed$terminal, rho.async::RhoStreamEnd))
  repeated_end <- rho.async::rho_stream_next(stream) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_true(S7::S7_inherits(repeated_end, rho.async::RhoStreamEnd))
}

rho_http_contract_truncated_content_length <- function(client_factory, timeout_ms) {
  peer <- rho_http_contract_raw_peer(
    head = charToRaw(paste0(
      "HTTP/1.1 200 OK\r\n",
      "Content-Type: application/octet-stream\r\n",
      "Content-Length: 10\r\n",
      "Connection: close\r\n\r\n"
    )),
    body = charToRaw("short"),
    body_delay_ms = 500L
  )
  client <- rho_http_contract_client(client_factory, timeout_ms)
  stream <- NULL
  on.exit(
    {
      rho_http_contract_raw_peer_close(peer)
      rho_http_contract_close(client = client, stream = stream)
    },
    add = TRUE
  )

  stream <- rho.http::rho_http_open_stream(
    client,
    rho.http::rho_http_request(
      "GET",
      paste0(peer$url, "/truncated-content-length"),
      timeout_ms = timeout_ms
    )
  ) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_true(S7::S7_inherits(stream, rho.http::RhoHttpBodyStream))
  observed <- rho_http_contract_read_until_terminal(stream, timeout_ms)
  payload <- observed$values[
    !vapply(
      observed$values,
      function(value) S7::S7_inherits(value, rho.http::RhoHttpError),
      logical(1)
    )
  ]
  expect_equal(rawToChar(do.call(c, payload)), "short")
  expect_true(S7::S7_inherits(
    observed$terminal,
    rho.http::RhoHttpTransportError
  ))
  ending <- rho.async::rho_stream_next(stream) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_true(S7::S7_inherits(ending, rho.async::RhoStreamEnd))
}

rho_http_contract_malformed_chunked_body <- function(client_factory, timeout_ms) {
  peer <- rho_http_contract_raw_peer(
    head = charToRaw(paste0(
      "HTTP/1.1 200 OK\r\n",
      "Content-Type: application/octet-stream\r\n",
      "Transfer-Encoding: chunked\r\n",
      "Connection: close\r\n\r\n"
    )),
    body = charToRaw("not-a-chunk\r\n"),
    body_delay_ms = 500L
  )
  client <- rho_http_contract_client(client_factory, timeout_ms)
  stream <- NULL
  on.exit(
    {
      rho_http_contract_raw_peer_close(peer)
      rho_http_contract_close(client = client, stream = stream)
    },
    add = TRUE
  )

  stream <- rho.http::rho_http_open_stream(
    client,
    rho.http::rho_http_request(
      "GET",
      paste0(peer$url, "/malformed-chunk"),
      timeout_ms = timeout_ms
    )
  ) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_true(S7::S7_inherits(stream, rho.http::RhoHttpBodyStream))
  expect_equal(stream@head@status, 200L)
  observed <- rho_http_contract_read_until_terminal(stream, timeout_ms)
  payload <- observed$values[
    !vapply(
      observed$values,
      function(value) S7::S7_inherits(value, rho.http::RhoHttpError),
      logical(1)
    )
  ]
  expect_equal(length(payload), 0L)
  expect_true(S7::S7_inherits(
    observed$terminal,
    rho.http::RhoHttpTransportError
  ))
  ending <- rho.async::rho_stream_next(stream) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_true(S7::S7_inherits(ending, rho.async::RhoStreamEnd))
}

rho_http_contract_incremental_sse <- function(client_factory, timeout_ms) {
  server_connection <- NULL
  server <- nanonext::http_server(
    "http://127.0.0.1:0",
    handlers = list(nanonext::handler_stream(
      "/events",
      on_request = function(connection, request) {
        server_connection <<- connection
        connection$set_status(200L)
        connection$set_header("Content-Type", "text/event-stream")
        connection$send(nanonext::format_sse(data = "first"))
      }
    ))
  )
  expect_equal(server$start(), 0L)
  client <- rho_http_contract_client(client_factory, timeout_ms)
  events <- NULL
  on.exit(
    {
      if (!is.null(server_connection)) {
        try(server_connection$close(), silent = TRUE)
      }
      rho_http_contract_close(client = client, stream = events, server = server)
    },
    add = TRUE
  )

  events <- rho.http::rho_sse_connect(
    client,
    rho.http::rho_http_request(
      "GET",
      paste0(server$url, "/events"),
      timeout_ms = timeout_ms
    )
  )
  first <- rho.async::rho_stream_next(events) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_equal(first@value@data, "first")

  expect_equal(
    server_connection$send(nanonext::format_sse(data = "second")),
    0L
  )
  second <- rho.async::rho_stream_next(events) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_equal(second@value@data, "second")

  expect_equal(server_connection$close(), 0L)
  ending <- rho.async::rho_stream_next(events) |>
    rho.async::rho_await(timeout = timeout_ms)
  repeated_end <- rho.async::rho_stream_next(events) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_true(S7::S7_inherits(ending, rho.async::RhoStreamEnd))
  expect_true(S7::S7_inherits(repeated_end, rho.async::RhoStreamEnd))
}

rho_http_contract_receive_cancellation <- function(client_factory, timeout_ms) {
  server_connection <- NULL
  server <- nanonext::http_server(
    "http://127.0.0.1:0",
    handlers = list(nanonext::handler_stream(
      "/cancel",
      on_request = function(connection, request) {
        server_connection <<- connection
        connection$set_status(200L)
        connection$set_header("Content-Type", "text/event-stream")
        connection$send(nanonext::format_sse(data = "ready"))
      }
    ))
  )
  expect_equal(server$start(), 0L)
  client <- rho_http_contract_client(client_factory, timeout_ms)
  events <- NULL
  on.exit(
    {
      if (!is.null(server_connection)) {
        try(server_connection$close(), silent = TRUE)
      }
      rho_http_contract_close(client = client, stream = events, server = server)
    },
    add = TRUE
  )

  events <- rho.http::rho_sse_connect(
    client,
    rho.http::rho_http_request(
      "GET",
      paste0(server$url, "/cancel"),
      timeout_ms = timeout_ms
    )
  )
  ready <- rho.async::rho_stream_next(events) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_equal(ready@value@data, "ready")

  pending <- rho.async::rho_stream_next(events)
  expect_true(rho.async::rho_cancel(pending, "contract cancellation"))
  cancelled <- rho.async::rho_await(pending, timeout = timeout_ms)
  expect_true(S7::S7_inherits(
    cancelled,
    rho.async::RhoCancellation
  ))
  ending <- rho.async::rho_stream_next(events) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_true(S7::S7_inherits(ending, rho.async::RhoStreamEnd))
}

rho_http_contract_receive_timeout <- function(client_factory, timeout_ms) {
  server_connection <- NULL
  server <- nanonext::http_server(
    "http://127.0.0.1:0",
    handlers = list(nanonext::handler_stream(
      "/timeout",
      on_request = function(connection, request) {
        server_connection <<- connection
        connection$set_status(200L)
        connection$set_header("Content-Type", "text/event-stream")
        connection$send(nanonext::format_sse(data = "ready"))
      }
    ))
  )
  expect_equal(server$start(), 0L)
  client <- rho_http_contract_client(client_factory, timeout_ms)
  events <- NULL
  on.exit(
    {
      if (!is.null(server_connection)) {
        try(server_connection$close(), silent = TRUE)
      }
      rho_http_contract_close(client = client, stream = events, server = server)
    },
    add = TRUE
  )

  events <- rho.http::rho_sse_connect(
    client,
    rho.http::rho_http_request(
      "GET",
      paste0(server$url, "/timeout"),
      timeout_ms = timeout_ms
    )
  )
  ready <- rho.async::rho_stream_next(events) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_equal(ready@value@data, "ready")

  timed <- rho.async::rho_stream_next(events, timeout = 50L) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_true(S7::S7_inherits(timed, rho.async::RhoStreamValue))
  expect_true(S7::S7_inherits(
    timed@value,
    rho.http::RhoHttpTransportError
  ))
  ending <- rho.async::rho_stream_next(events) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_true(S7::S7_inherits(ending, rho.async::RhoStreamEnd))
}

rho_http_contract_status_body <- function(client_factory, timeout_ms) {
  server <- nanonext::http_server(
    "http://127.0.0.1:0",
    handlers = list(nanonext::handler_stream(
      "/large-error",
      on_request = function(connection, request) {
        connection$set_status(429L)
        connection$set_header("Content-Type", "text/plain")
        connection$send("1234567890")
        connection$close()
      }
    ))
  )
  expect_equal(server$start(), 0L)
  client <- rho_http_contract_client(
    client_factory,
    timeout_ms,
    max_error_body_bytes = 8L
  )
  events <- NULL
  on.exit(
    rho_http_contract_close(client = client, stream = events, server = server),
    add = TRUE
  )

  events <- rho.http::rho_sse_connect(
    client,
    rho.http::rho_http_request(
      "GET",
      paste0(server$url, "/large-error"),
      timeout_ms = timeout_ms
    )
  )
  item <- rho.async::rho_stream_next(events) |>
    rho.async::rho_await(timeout = timeout_ms)
  expect_true(S7::S7_inherits(item, rho.async::RhoStreamValue))
  expect_true(S7::S7_inherits(
    item@value,
    rho.http::RhoHttpStatusError
  ))
  expect_equal(item@value@status, 429L)
  expect_equal(rawToChar(item@value@body), "12345678")
  expect_true(item@value@body_truncated)
}

rho_http_contract_open_cancellation <- function(client_factory, timeout_ms) {
  server_connection <- NULL
  server <- nanonext::http_server(
    "http://127.0.0.1:0",
    handlers = list(nanonext::handler_stream(
      "/pending-head",
      on_request = function(connection, request) {
        server_connection <<- connection
        NULL
      }
    ))
  )
  expect_equal(server$start(), 0L)
  client <- rho_http_contract_client(client_factory, timeout_ms)
  on.exit(
    {
      if (!is.null(server_connection)) {
        try(server_connection$close(), silent = TRUE)
      }
      rho_http_contract_close(client = client, server = server)
    },
    add = TRUE
  )

  opening <- rho.http::rho_http_open_stream(
    client,
    rho.http::rho_http_request(
      "GET",
      paste0(server$url, "/pending-head"),
      timeout_ms = timeout_ms
    )
  )
  expect_true(rho.async::rho_pending(opening))
  later::run_now(timeoutSecs = 0.05)
  expect_true(rho.async::rho_cancel(opening, "cancel response open"))
  cancelled <- rho.async::rho_await(opening, timeout = timeout_ms)
  expect_true(S7::S7_inherits(
    cancelled,
    rho.async::RhoCancellation
  ))
  if (!is.null(server_connection)) {
    expect_equal(server_connection$close(), 0L)
  }
  later::run_now(timeoutSecs = 0)
}

rho_http_client_contract <- function(
  client_factory,
  expected_open_execution,
  timeout_ms = 5000L
) {
  rho_http_contract_open_execution(
    client_factory,
    expected_open_execution,
    timeout_ms
  )
  rho_http_contract_complete_request(client_factory, timeout_ms)
  rho_http_contract_fixed_body(client_factory, timeout_ms)
  rho_http_contract_incremental_sse(client_factory, timeout_ms)
  rho_http_contract_receive_cancellation(client_factory, timeout_ms)
  rho_http_contract_receive_timeout(client_factory, timeout_ms)
  rho_http_contract_status_body(client_factory, timeout_ms)
  rho_http_contract_open_cancellation(client_factory, timeout_ms)
  invisible(TRUE)
}
