# Generated from packages/rho.http/inst/tinytest/rmd/streaming-sse.Rmd; do not edit.

library(tinytest)
library(rho.async)
library(rho.http)

server_connection <- NULL
server <- nanonext::http_server(
  url = "http://127.0.0.1:0",
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

client <- rho_http_client(timeout_ms = 2000L, stream_buffer_size = 1L)
request <- rho_http_request(
  "GET",
  paste0(server$url, "/events"),
  timeout_ms = 2000L
)
events <- rho_sse_connect(client, request)

first <- rho_await(rho_stream_next(events), timeout = 2000L)
expect_true(S7::S7_inherits(first, RhoStreamValue))
expect_true(S7::S7_inherits(first@value, RhoSseEvent))
expect_equal(first@value@data, "first")

expect_equal(server_connection$send(nanonext::format_sse(data = "second")), 0L)
second <- rho_await(rho_stream_next(events), timeout = 2000L)
expect_true(S7::S7_inherits(second@value, RhoSseEvent))
expect_equal(second@value@data, "second")

expect_equal(server_connection$close(), 0L)
ending <- rho_await(rho_stream_next(events), timeout = 2000L)
expect_true(S7::S7_inherits(ending, RhoStreamEnd))
expect_equal(server$close(), 0L)

server <- nanonext::http_server(
  url = "http://127.0.0.1:0",
  handlers = list(nanonext::handler_stream(
    "/limited",
    on_request = function(connection, request) {
      connection$set_status(429L)
      connection$set_header("Content-Type", "text/event-stream")
      connection$send(nanonext::format_sse(data = "rate limited"))
    }
  ))
)
expect_equal(server$start(), 0L)

events <- rho_sse_connect(
  rho_http_client(timeout_ms = 2000L),
  rho_http_request(
    "GET",
    paste0(server$url, "/limited"),
    timeout_ms = 2000L
  )
)
item <- rho_await(rho_stream_next(events), timeout = 2000L)
expect_true(S7::S7_inherits(item, RhoStreamValue))
expect_true(S7::S7_inherits(item@value, RhoHttpStatusError))
expect_equal(item@value@status, 429L)
expect_equal(server$close(), 0L)

server_connection <- NULL
server <- nanonext::http_server(
  url = "http://127.0.0.1:0",
  handlers = list(nanonext::handler_stream(
    "/pending",
    on_request = function(connection, request) {
      server_connection <<- connection
      connection$set_status(200L)
      connection$set_header("Content-Type", "text/event-stream")
      connection$send(nanonext::format_sse(data = "ready"))
    }
  ))
)
expect_equal(server$start(), 0L)

events <- rho_sse_connect(
  rho_http_client(timeout_ms = 2000L),
  rho_http_request(
    "GET",
    paste0(server$url, "/pending"),
    timeout_ms = 2000L
  )
)
ready <- rho_await(rho_stream_next(events), timeout = 2000L)
expect_equal(ready@value@data, "ready")

pending <- rho_stream_next(events)
rho_stream_close(events)
cancelled <- rho_await(pending, timeout = 2000L)

expect_true(S7::S7_inherits(cancelled, RhoStreamValue))
expect_true(S7::S7_inherits(cancelled@value, RhoHttpTransportError))
expect_equal(server_connection$close(), 0L)
later::run_now(timeoutSecs = 0)
expect_equal(server$close(), 0L)
