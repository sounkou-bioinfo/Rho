
# rho.async

[`rho.async`](https://sounkou-bioinfo.github.io/Rho/rho.async/) is the
small asynchronous contract at the base of [Rho](../../README.md). A
`RhoTask` represents one eventual value; a `RhoStream` represents an
asynchronous sequence. Both are open S7 protocols, so transports and
worker systems can add methods without changing callers.

## Tasks and streams (runs at render time)

``` r
library(rho.async)

tasks <- list(
  rho_task(20L),
  rho_then(rho_task(21L), function(value) value + 1L)
)
rho_await(rho_all(tasks), timeout = 1000)
#> [[1]]
#> [1] 20
#>
#> [[2]]
#> [1] 22

stream <- rho_list_stream(c("start", "delta", "done"))
rho_stream_collect(stream, timeout = 1000)
#> [[1]]
#> [1] "start"
#>
#> [[2]]
#> [1] "delta"
#>
#> [[3]]
#> [1] "done"
```

Composition stays asynchronous. `rho_await()` is deliberately
conspicuous and is reserved for boundaries such as a CLI, a test, or an
interactive request for the finished value. Cancellation and timeou
operations use the same task contract; adapters own the mechanics of
stopping their underlying handle.

Continue with [`rho.http`](../rho.http/README.md), or see the
[`rho.async`
reference](https://sounkou-bioinfo.github.io/Rho/rho.async/).
