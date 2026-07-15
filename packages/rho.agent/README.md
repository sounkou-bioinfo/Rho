
# rho.agent

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

[`rho.agent`](https://sounkou-bioinfo.github.io/Rho/rho.agent/) is Rho’s
provider-neutral, multi-turn agent loop. It turns provider streams into
an ordered lifecycle, schedules typed tools, drains steering and
follow-up queues, and propagates cancellation without placing coding or
bioinformatics policy in the core.

## Run an agent

``` r
library(rho.async)
library(rho.ai)
library(rho.agent)

agent <- rho_agent(
  rho_faux_provider(),
  rho_model(provider = "faux", id = "faux")
)
task <- rho_prompt(agent, "show the protocol")
rho_is_task(task)
#> [1] TRUE

run <- rho_await(task, timeout = 5000)
list(
  status = run@status,
  answer = run@messages[[2L]]@content[[1L]]@text,
  events = length(run@events)
)
#> $status
#> [1] "completed"
#>
#> $answer
#> [1] "faux: show the protocol"
#>
#> $events
#> [1] 12
```

Listeners are awaited in registration order. Tool calls that declare
`ToolMayOverlap` may run concurrently, while results remain in source
order; `ToolRequiresExclusiveExecution` makes stateful semantics
explicit. Agent policy is an S7 protocol, so applications can override
context transforms and before/after-tool decisions without replacing the
loop.

Extensions build on this lifecycle in [`rho.ext`](../rho.ext/README.md).
See the [`rho.agent`
reference](https://sounkou-bioinfo.github.io/Rho/rho.agent/).
