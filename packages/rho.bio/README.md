
# rho.bio

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

[`rho.bio`](https://rgenomicsetl.github.io/Rho/rho.bio/) is the
typed, agent-independent substrate for declared bioinformatics
resources. Manifests name resolvers and operations; resolution produces
a receipt that keeps source observations and provenance separate from
model-authored text.

## Declare and resolve a resource

``` r
library(rho.async)
library(rho.bio)

resolver <- rho_resolver_spec(
  id = "memory.table",
  version = "1.0.0",
  title = "In-memory table",
  description = "Resolve the table declared in this example"
)
resource <- rho_virtual_resource(
  id = "genes",
  title = "Example genes",
  resolver = "memory.table"
)
manifest <- rho_manifest(
  id = "readme",
  version = "1.0.0",
  title = "README resources",
  description = "A small executable manifest",
  provides = list(
    resolvers = list(resolver),
    resources = list(resource)
  )
)

registry <- rho_bio_registry()
rho_register_manifest(registry, manifest)
rho_bind_resolver_impl(registry, "memory.table", function(resource, context) {
  list(
    result = rho_resource_handle(
      kind = "data.frame",
      value = data.frame(gene = c("TP53", "BRCA1"))
    ),
    provenance = list(method = "declared example")
  )
})

receipt <- rho_resolve_resource(registry, "genes") |>
  rho_await(timeout = 1000)
list(
  resource = receipt@resource_id,
  resolver = paste(receipt@resolver_id, receipt@resolver_version, sep = "@"),
  rows = nrow(receipt@result@value),
  digest = substr(receipt@params_digest, 1L, 19L)
)
#> $resource
#> [1] "genes"
#>
#> $resolver
#> [1] "memory.table@1.0.0"
#>
#> $rows
#> [1] 2
#>
#> $digest
#> [1] "sha256:4f53cda18c2b"
```

The registry fails closed when a resource, resolver declaration, or
resolver implementation is absent. Database implementations are
separate; the generic SQL contract is implemented for DuckDB by
[`rho.duckdb`](https://rgenomicsetl.github.io/Rho/rho.duckdb/).

See the [`rho.bio`
reference](https://rgenomicsetl.github.io/Rho/rho.bio/reference/).
