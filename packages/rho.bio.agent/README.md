
# rho.bio.agen

[`rho.bio.agent`](https://sounkou-bioinfo.github.io/Rho/rho.bio.agent/)
exposes declared bioinformatics resources to an agent through the
ordinary [`rho.ext`](../rho.ext/README.md) and
[`rho.ai`](../rho.ai/README.md) tool contracts. It is downstream of the
provider and agent core.

## Register and call a bio tool (runs at render time)

``` r
library(rho.async)
library(rho.ai)
library(rho.bio)
library(rho.ext)
library(rho.bio.agent)

registry <- rho_bio_registry()
rho_register_manifest(registry, rho_manifest(
  id = "example",
  version = "1.0.0",
  title = "Example manifest",
  description = "A registered manifest"
))

runtime <- rho_extension_runtime()
rho_register_bio_extension(rho_extension_api(runtime), registry)
tool <- get("bio_describe_manifest", runtime@state$tools)
result <- rho_execute_tool(
  tool,
  ToolCall("bio-1", "bio_describe_manifest", list())
) |>
  rho_await(timeout = 1000)

list(
  tool = tool@name,
  manifests = result@details$coun
)
#> $tool
#> [1] "bio_describe_manifest"
#>
#> $manifests
#> [1] 1
```

The extension translates registry facts into tool results; it does no
make the model the authority for those facts. Additional bio workflows
can register tools without changing `rho.agent`.

See the [`rho.bio.agent`
reference](https://sounkou-bioinfo.github.io/Rho/rho.bio.agent/) and the
underlying [`rho.bio`](../rho.bio/README.md) substrate.
