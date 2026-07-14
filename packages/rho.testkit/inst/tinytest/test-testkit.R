# Generated from packages/rho.testkit/inst/tinytest/rmd/testkit.Rmd; do not edit.

library(tinytest)
library(rho.async)
library(rho.testkit)

value <- expect_resolves(rho_task(1), 1)
expect_equal(value, 1)
