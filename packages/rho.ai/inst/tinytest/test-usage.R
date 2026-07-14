# Generated from packages/rho.ai/inst/tinytest/rmd/usage.Rmd; do not edit.

library(tinytest)
library(rho.ai)

usage <- rho_usage(
  input = 1e6,
  output = 1e5,
  cache_read = 5e5,
  cache_write = 1e5,
  cache_write_1h = 4e4,
  reasoning = 2e4
)

expect_true(S7::S7_inherits(usage, Usage))
expect_equal(usage@total, 1.7e6)
expect_equal(usage@reasoning, 2e4)
expect_equal(usage@cache_write_1h, 4e4)
expect_error(
  rho_usage(output = 3, reasoning = 4),
  "subset of @output"
)
expect_error(
  rho_usage(cache_write = 1, cache_write_1h = 2),
  "subset of @cache_write"
)

model <- rho_model(
  provider = "fixture",
  id = "priced",
  pricing = rho_model_pricing(
    input = 2,
    output = 8,
    cache_read = 0.2,
    cache_write = 2.5
  )
)
priced <- rho_price_usage(model, usage)

expect_true(S7::S7_inherits(priced@cost, UsageCost))
expect_equal(priced@cost@input, 2)
expect_equal(priced@cost@output, 0.8)
expect_equal(priced@cost@cache_read, 0.1)
expect_equal(priced@cost@cache_write, 0.31)
expect_equal(priced@cost@total, 3.21)
expect_equal(usage@cost@total, 0)

tiered <- rho_model(
  provider = "fixture",
  id = "tiered",
  pricing = rho_model_pricing(
    input = 1,
    output = 2,
    tiers = list(rho_model_pricing_tier(
      input_tokens_above = 1e6,
      input = 3,
      output = 6,
      cache_read = 0.3,
      cache_write = 3.75
    ))
  )
)
tiered_usage <- rho_price_usage(
  tiered,
  rho_usage(input = 9e5, output = 1e5, cache_read = 2e5)
)

expect_equal(tiered_usage@cost@input, 2.7)
expect_equal(tiered_usage@cost@output, 0.6)
expect_equal(tiered_usage@cost@cache_read, 0.06)
expect_equal(tiered_usage@cost@total, 3.36)
