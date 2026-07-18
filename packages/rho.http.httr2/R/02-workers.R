rho_httr2_http_client <- function(
  headers = list(),
  timeout_ms = 30000L,
  stream_buffer_size = 65536L,
  max_error_body_bytes = 1048576L,
  compute = rho.compute::rho_mirai_backend()
) {
  state <- new.env(parent = emptyenv())
  state$closed <- FALSE
  state$next_operation_id <- 1L
  state$operations <- list()
  RhoHttr2HttpClient(
    headers = headers,
    timeout_ms = as.integer(timeout_ms),
    stream_buffer_size = as.integer(stream_buffer_size),
    max_error_body_bytes = as.integer(max_error_body_bytes),
    compute = compute,
    state = state
  )
}

rho_httr2_request <- function(payload) {
  request <- httr2::request(payload@url)
  request <- httr2::req_method(request, payload@method)
  if (length(payload@headers)) {
    request <- do.call(
      httr2::req_headers,
      c(list(request), payload@headers)
    )
  }
  if (!is.null(payload@data)) {
    request <- httr2::req_body_raw(request, payload@data)
  }
  httr2::req_error(request, is_error = function(response) FALSE)
}

rho_httr2_complete_request <- function(payload) {
  rho_httr2_request(payload) |>
    httr2::req_timeout(payload@timeout_ms / 1000)
}

rho_httr2_response_headers <- function(response) {
  unclass(as.list(httr2::resp_headers(response)))
}

rho_httr2_response_head <- function(response) {
  rho.http::RhoHttpResponseHead(
    status = as.integer(httr2::resp_status(response)),
    headers = rho_httr2_response_headers(response),
    url = httr2::resp_url(response)
  )
}

rho_httr2_complete_worker <- function(payload) {
  tryCatch(
    {
      response <- httr2::req_perform(rho_httr2_complete_request(payload))
      data <- httr2::resp_body_raw(response)
      if (payload@convert) {
        data <- rawToChar(data)
      }
      rho.http::RhoHttpResponse(
        status = as.integer(httr2::resp_status(response)),
        headers = rho_httr2_response_headers(response),
        data = data,
        url = httr2::resp_url(response)
      )
    },
    error = function(error) {
      rho.http::RhoHttpTransportError(
        message = sprintf("httr2 request failed: %s", conditionMessage(error)),
        url = payload@url,
        parent = error
      )
    }
  )
}

rho_httr2_send_message <- function(socket, message) {
  sent <- nanonext::send(socket, message, mode = "serial")
  !nanonext::is_error_value(sent)
}

rho_httr2_wait_for_body <- function(response) {
  descriptors <- response$body$get_fdset()
  descriptor_count <- length(descriptors$reads) +
    length(descriptors$writes) +
    length(descriptors$exceptions)
  if (!descriptor_count) {
    return("httr2 exposed no file descriptor for an incomplete response body")
  }

  wait <- new.env(parent = emptyenv())
  wait$done <- FALSE
  wait$ready <- logical()
  cancel <- later::later_fd(
    function(ready) {
      wait$ready <- ready
      wait$done <- TRUE
    },
    readfds = descriptors$reads,
    writefds = descriptors$writes,
    exceptfds = descriptors$exceptions,
    timeout = descriptors$timeout
  )
  on.exit(cancel(), add = TRUE)
  while (!wait$done) {
    later::run_now(timeoutSecs = Inf)
  }
  if (length(wait$ready) && all(is.na(wait$ready))) {
    return("httr2 response readiness descriptors became invalid")
  }
  NULL
}

rho_httr2_stream_worker <- function(address, token, payload, buffer_bytes) {
  socket <- nanonext::socket("pair", dial = address)
  on.exit(close(socket), add = TRUE)

  tryCatch(
    {
      response <- httr2::req_perform_connection(
        rho_httr2_request(payload),
        blocking = FALSE
      )
      on.exit(close(response), add = TRUE)

      head <- RhoHttr2HeadMessage(
        token = token,
        head = rho_httr2_response_head(response)
      )
      if (!rho_httr2_send_message(socket, head)) {
        return(RhoHttr2WorkerFailure(message = "Could not relay the response head"))
      }

      repeat {
        chunk <- httr2::resp_stream_raw(
          response,
          kb = as.double(buffer_bytes) / 1024
        )
        if (length(chunk)) {
          relayed <- rho_httr2_send_message(
            socket,
            RhoHttr2ChunkMessage(token = token, data = chunk)
          )
          if (!relayed) {
            return(RhoHttr2WorkerFailure(message = "Could not relay a response-body chunk"))
          }
          if (httr2::resp_stream_is_complete(response)) {
            break
          }
          next
        }
        if (httr2::resp_stream_is_complete(response)) {
          break
        }
        wait_error <- rho_httr2_wait_for_body(response)
        if (!is.null(wait_error)) {
          rho_httr2_send_message(
            socket,
            RhoHttr2ErrorMessage(token = token, message = wait_error)
          )
          return(RhoHttr2WorkerFailure(message = wait_error))
        }
      }

      if (!rho_httr2_send_message(socket, RhoHttr2EndMessage(token = token))) {
        return(RhoHttr2WorkerFailure(message = "Could not relay response completion"))
      }
      RhoHttr2WorkerComplete()
    },
    error = function(error) {
      message <- sprintf("httr2 stream failed: %s", conditionMessage(error))
      rho_httr2_send_message(
        socket,
        RhoHttr2ErrorMessage(token = token, message = message)
      )
      RhoHttr2WorkerFailure(message = message)
    }
  )
}
