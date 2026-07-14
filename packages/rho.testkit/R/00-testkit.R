expect_resolves <- function(task, expected = NULL, timeout = 5000L) {
  value <- rho.async::rho_await(task, timeout = timeout)
  if (!is.null(expected)) {
    tinytest::expect_equal(value, expected)
  } else {
    tinytest::expect_true(TRUE)
  }
  invisible(value)
}

expect_rejects <- function(task, pattern = NULL, timeout = 5000L) {
  tinytest::expect_error(rho.async::rho_await(task, timeout = timeout), pattern = pattern)
}

expect_stream_length <- function(stream, n, timeout = 5000L) {
  out <- rho.async::rho_stream_collect(stream, limit = n, timeout = timeout)
  tinytest::expect_equal(length(out), n)
  invisible(out)
}

rho_test_agent <- function(script = list()) {
  provider <- rho.ai::rho_faux_provider(script)
  model <- rho.ai::rho_model("faux", "faux")
  rho.agent::rho_agent(provider, model)
}
