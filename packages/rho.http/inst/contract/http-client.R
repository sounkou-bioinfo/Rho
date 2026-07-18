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
