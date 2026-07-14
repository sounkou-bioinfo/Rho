# Generated from packages/rho.ext/inst/tinytest/rmd/extension-runtime.Rmd; do not edit.

library(tinytest)
library(rho.async)
library(rho.ext)

rt <- rho_extension_runtime()
api <- rho_extension_api(rt)
rho_on(api, "ping", function(event, ctx) list(ok = TRUE))
out <- rho_await(rho_dispatch_event(rt, list(type = "ping")))
expect_equal(length(out), 1)
expect_true(out[[1]]$ok)
