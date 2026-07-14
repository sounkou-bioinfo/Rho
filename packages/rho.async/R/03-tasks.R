rho_task <- function(value) {
  RhoImmediateTask(
    state = rho_new_state(
      status = "resolved",
      value = value,
      created_at = Sys.time(),
      cancelled = FALSE
    )
  )
}

rho_rejected <- function(error) {
  RhoRejectedTask(
    state = rho_new_state(
      status = "rejected",
      error = error,
      created_at = Sys.time(),
      cancelled = FALSE
    )
  )
}

rho_task_from_function <- function(fun, label = NULL) {
  if (!is.function(fun)) {
    rho_abort("`fun` must be a function")
  }
  RhoFunctionTask(
    state = rho_new_state(
      status = "pending",
      fun = fun,
      promise = NULL,
      label = label %||% "function-task",
      created_at = Sys.time(),
      cancelled = FALSE
    )
  )
}

rho_task_from_promise <- function(promise, cancel = NULL, label = NULL) {
  if (!promises::is.promise(promise)) {
    rho_abort("`promise` must be a promises promise")
  }
  if (!is.null(cancel) && !is.function(cancel)) {
    rho_abort("`cancel` must be NULL or a function")
  }
  state <- rho_new_state(
    status = "pending",
    promise = promise,
    cancel = cancel,
    value = NULL,
    error = NULL,
    label = label %||% "promise-task",
    created_at = Sys.time(),
    cancelled = FALSE
  )
  observed <- promises::then(
    promise,
    onFulfilled = function(value) {
      state$status <- "resolved"
      state$value <- value
      value
    },
    onRejected = function(error) {
      state$status <- "rejected"
      state$error <- error
      stop(error)
    }
  )
  state$promise <- observed
  RhoPromiseTask(state = state)
}

rho_coro_task <- function(fun, ..., label = NULL) {
  fun_expression <- substitute(fun)
  if (!is.function(eval(fun_expression, envir = parent.frame()))) {
    rho_abort("`fun` must be an anonymous function")
  }
  factory_call <- substitute(coro::async(FUN), list(FUN = fun_expression))
  coroutine <- eval(factory_call, envir = parent.frame())
  rho_task_from_promise(
    do.call(coroutine, list(...)),
    label = label %||% "coroutine-task"
  )
}

rho_wrap_aio <- function(aio, collect = nanonext::collect_aio_) {
  if (!nanonext::is_aio(aio)) {
    rho_abort("`aio` must be a nanonext Aio object")
  }
  if (!is.function(collect)) {
    rho_abort("`collect` must be a function")
  }
  RhoNanonextAioTask(
    state = rho_new_state(
      status = "pending",
      handle = aio,
      collect = collect,
      created_at = Sys.time(),
      cancelled = FALSE
    )
  )
}

rho_function_task_promise <- function(task) {
  if (!is.null(task@state$promise)) {
    return(task@state$promise)
  }
  task@state$promise <- promises::promise(function(resolve, reject) {
    later::later(function() {
      if (isTRUE(task@state$cancelled)) {
        reject(simpleError(task@state$cancel_reason %||% "Task was cancelled"))
        return()
      }
      tryCatch(
        resolve(task@state$fun()),
        error = reject
      )
    })
  })
  task@state$promise
}

rho_promise_result <- function(value) {
  if (rho_is_task(value)) {
    return(rho_as_promise(value))
  }
  value
}

rho_await_promise <- function(promise, timeout = NULL) {
  settled <- new.env(parent = emptyenv())
  settled$done <- FALSE
  settled$value <- NULL
  settled$error <- NULL

  promises::then(
    promise,
    onFulfilled = function(value) {
      settled$value <- value
      settled$done <- TRUE
      NULL
    },
    onRejected = function(error) {
      settled$error <- error
      settled$done <- TRUE
      NULL
    }
  )

  started <- proc.time()[["elapsed"]]
  while (!settled$done) {
    wait_seconds <- Inf
    if (!is.null(timeout)) {
      elapsed_ms <- (proc.time()[["elapsed"]] - started) * 1000
      remaining_ms <- as.double(timeout) - elapsed_ms
      if (remaining_ms <= 0) {
        stop("Task deadline elapsed", call. = FALSE)
      }
      wait_seconds <- remaining_ms / 1000
    }
    later::run_now(timeoutSecs = wait_seconds)
  }
  if (!is.null(settled$error)) {
    stop(settled$error)
  }
  settled$value
}

S7::method(rho_pending, RhoImmediateTask) <- function(x, ...) FALSE
S7::method(rho_pending, RhoRejectedTask) <- function(x, ...) FALSE
S7::method(rho_pending, RhoFunctionTask) <- function(x, ...) identical(x@state$status, "pending")
S7::method(rho_pending, RhoNanonextAioTask) <- function(x, ...) nanonext::unresolved(x@state$handle)
S7::method(rho_pending, RhoPromiseTask) <- function(x, ...) identical(x@state$status, "pending")

S7::method(rho_await, RhoImmediateTask) <- function(x, timeout = NULL, ...) x@state$value

S7::method(rho_await, RhoRejectedTask) <- function(x, timeout = NULL, ...) {
  error <- x@state$error
  if (inherits(error, "condition")) {
    stop(error)
  }
  stop(as.character(error), call. = FALSE)
}

S7::method(rho_await, RhoFunctionTask) <- function(x, timeout = NULL, ...) {
  rho_await_promise(rho_as_promise(x), timeout)
}

S7::method(rho_await, RhoNanonextAioTask) <- function(x, timeout = NULL, ...) {
  if (isTRUE(x@state$cancelled)) {
    rho_abort("Task was cancelled")
  }
  x@state$collect(x@state$handle)
}

S7::method(rho_await, RhoPromiseTask) <- function(x, timeout = NULL, ...) {
  if (isTRUE(x@state$cancelled)) {
    rho_abort("Task was cancelled")
  }
  rho_await_promise(x@state$promise, timeout)
}

S7::method(rho_as_promise, RhoImmediateTask) <- function(x, ...) {
  promises::promise_resolve(x@state$value)
}
S7::method(rho_as_promise, RhoRejectedTask) <- function(x, ...) {
  error <- x@state$error
  if (!inherits(error, "condition")) {
    error <- simpleError(as.character(error))
  }
  promises::promise_reject(error)
}
S7::method(rho_as_promise, RhoFunctionTask) <- function(x, ...) {
  rho_function_task_promise(x)
}
S7::method(rho_as_promise, RhoNanonextAioTask) <- function(x, ...) {
  promises::as.promise(x@state$handle)
}
S7::method(rho_as_promise, RhoPromiseTask) <- function(x, ...) x@state$promise

S7::method(rho_cancel, RhoTask) <- function(x, reason = NULL, ...) {
  x@state$cancelled <- TRUE
  x@state$cancel_reason <- reason
  invisible(TRUE)
}

S7::method(rho_cancel, RhoNanonextAioTask) <- function(x, reason = NULL, ...) {
  x@state$cancelled <- TRUE
  x@state$cancel_reason <- reason
  nanonext::stop_aio(x@state$handle)
  invisible(TRUE)
}

S7::method(rho_cancel, RhoPromiseTask) <- function(x, reason = NULL, ...) {
  x@state$cancelled <- TRUE
  x@state$cancel_reason <- reason
  if (!is.null(x@state$cancel)) {
    x@state$cancel(reason)
  }
  invisible(TRUE)
}

S7::method(rho_then, RhoTask) <- function(x, on_fulfilled, on_rejected = NULL, ...) {
  if (!is.function(on_fulfilled)) {
    rho_abort("`on_fulfilled` must be a function")
  }
  if (!is.null(on_rejected) && !is.function(on_rejected)) {
    rho_abort("`on_rejected` must be NULL or a function")
  }
  promise <- promises::then(
    rho_as_promise(x),
    onFulfilled = function(value) rho_promise_result(on_fulfilled(value)),
    onRejected = if (is.null(on_rejected)) {
      NULL
    } else {
      function(error) {
        rho_promise_result(on_rejected(error))
      }
    }
  )
  rho_task_from_promise(promise, label = "then")
}

S7::method(rho_catch, RhoTask) <- function(x, on_rejected, ...) {
  rho_then(x, identity, on_rejected)
}

S7::method(rho_as_task, RhoTask) <- function(x, ...) x
S7::method(rho_as_task, S7::class_any) <- function(x, ...) rho_task(x)

rho_all <- function(tasks) {
  promises <- lapply(tasks, function(task) rho_as_promise(rho_as_task(task)))
  rho_task_from_promise(promises::promise_all(.list = promises), label = "all")
}

rho_timeout <- function(task, ms) {
  task <- rho_as_task(task)
  deadline <- promises::promise(function(resolve, reject) {
    later::later(
      function() resolve(RhoTimeoutError(message = "Task deadline elapsed", parent = NULL)),
      delay = as.double(ms) / 1000
    )
  })
  race <- promises::promise_race(.list = list(rho_as_promise(task), deadline))
  rho_task_from_promise(race, cancel = function(reason) rho_cancel(task, reason), label = "timeout")
}

rho_poll_pending <- function(delay_ms) RhoPollPending(delay_ms = as.integer(delay_ms))
rho_poll_complete <- function(value) RhoPollComplete(value = value)
rho_poll_failed <- function(error) RhoPollFailed(error = error)

rho_poll <- function(action, timeout_ms) {
  if (!is.function(action)) {
    rho_abort("`action` must be a function")
  }
  timeout_ms <- as.integer(timeout_ms)
  if (is.na(timeout_ms) || timeout_ms <= 0L) {
    rho_abort("`timeout_ms` must be positive")
  }

  rho_task_from_function(
    function() {
      started <- proc.time()[["elapsed"]]
      wake <- nanonext::cv()
      attempt <- 1L
      repeat {
        elapsed_ms <- as.integer((proc.time()[["elapsed"]] - started) * 1000)
        if (elapsed_ms >= timeout_ms) {
          return(RhoTimeoutError(message = "Polling deadline elapsed", parent = NULL))
        }
        decision <- rho_await(rho_as_task(action(attempt)))
        if (S7::S7_inherits(decision, RhoPollComplete)) {
          return(decision@value)
        }
        if (S7::S7_inherits(decision, RhoPollFailed)) {
          return(decision@error)
        }
        if (!S7::S7_inherits(decision, RhoPollPending)) {
          return(RhoAsyncError(
            message = "Polling action must return a RhoPollDecision value",
            parent = decision
          ))
        }
        remaining_ms <- timeout_ms - elapsed_ms
        delay_ms <- min(decision@delay_ms, remaining_ms)
        nanonext::until(wake, as.integer(delay_ms))
        attempt <- attempt + 1L
      }
    },
    label = "poll"
  )
}
