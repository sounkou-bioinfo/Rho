
# rho.duckdb

[`rho.duckdb`](https://sounkou-bioinfo.github.io/Rho/rho.duckdb/)
implements the database-neutral [`rho.bio`](../rho.bio/README.md) SQL
generics for DuckDB. Queries return tasks, and declared read-only paths
are checked before execution.

## An asynchronous query (runs at render time)

``` r
library(rho.async)
library(rho.bio)
library(rho.duckdb)

connection <- rho_duckdb_connect()
rows <- rho_sql_all(
  connection,
  "select * from (values ('TP53', 12), ('BRCA1', 8)) as genes(gene, samples)"
) |>
  rho_await(timeout = 5000)
rho_duckdb_disconnect(connection)
rows
#>    gene samples
#> 1  TP53      12
#> 2 BRCA1       8
```

`rho_assert_readonly_sql()` rejects write, DDL, extension-loading, and
attach statements on this path. The S7 connection class is the dispatch
point, leaving room for other SQL backends without changing manifests or
agent tools.

See the [`rho.duckdb`
reference](https://sounkou-bioinfo.github.io/Rho/rho.duckdb/) and the
upstream [`rho.bio`](../rho.bio/README.md) contracts.
