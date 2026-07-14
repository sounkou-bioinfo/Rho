
# rho.compute

[`rho.compute`](https://sounkou-bioinfo.github.io/Rho/rho.compute/)
adapts mirai worker evaluation to [`rho.async`](../rho.async/README.md).
Expressions and function calls are typed specifications; the agent sees
only a `RhoTask` and does not acquire hidden worker policy.

## Worker evaluation (runs at render time)

``` r
library(rho.async)
library(rho.compute)

task <- rho_mirai_eval(value * 2L, args = list(value = 21L))
rho_is_task(task)
#> [1] TRUE
rho_await(task, timeout = 5000)
#> [1] 42

failure <- rho_mirai_eval(stop("worker failed", call. = FALSE)) |>
  rho_await(timeout = 5000)
list(
  typed_error = S7::S7_inherits(failure, RhoComputeErrorValue),
  message_preserved = grepl("worker failed", failure@message, fixed = TRUE)
)
#> $typed_error
#> [1] TRUE
#>
#> $message_preserved
#> [1] TRUE
```

Worker failures resolve as typed values, so callers can dispatch on
their semantics. A tool chooses whether it uses this backend and
separately declares whether multiple calls may overlap.

[`rho.graphics`](../rho.graphics/README.md) uses the same backend to
render away from the interactive device. See the [`rho.compute`
reference](https://sounkou-bioinfo.github.io/Rho/rho.compute/).
