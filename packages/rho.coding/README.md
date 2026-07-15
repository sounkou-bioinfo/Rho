
# rho.coding

[`rho.coding`](https://sounkou-bioinfo.github.io/Rho/rho.coding/)
supplies coding tools with explicit execution semantics: file
operations, Bash with a typed cross-platform resolution, isolated R
evaluation in mirai, and opt-in evaluation in a caller-supplied
current-session environment.

## Isolated R evaluation

``` r
library(rho.async)
library(rho.ai)
library(rho.coding)

r_tool <- rho_tool_r()
result <- rho_execute_tool(
  r_tool,
  ToolCall(
    id = "readme-r-1",
    name = "r",
    arguments = list(code = "sum((1:6)^2)")
  ),
  context = NULL
) |>
  rho_await(timeout = 10000)

list(
  value = result@details$value,
  may_overlap = S7::S7_inherits(r_tool@overlap, ToolMayOverlap)
)
#> $value
#> [1] 91
#>
#> $may_overlap
#> [1] TRUE
```

The ordinary R tool is isolated and may overlap with another call. A
`RhoCurrentSessionREvaluator` instead receives an explicit environment
and requires exclusive scheduling. `RhoRExpression` is also a
`RhoOperation`, and the chosen evaluator is recorded in a
`RhoREvaluationBinding`. A remote NNG evaluator therefore adds evaluator
methods rather than another agent execution path. Bash follows the same
discipline: on Windows it resolves a real Bash implementation rather
than translating model-generated Bash into another shell language.

See the [`rho.coding`
reference](https://sounkou-bioinfo.github.io/Rho/rho.coding/) and its
worker substrate, [`rho.compute`](../rho.compute/README.md).
