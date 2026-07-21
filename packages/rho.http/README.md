
# rho.http

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

[`rho.http`](https://rgenomicsetl.github.io/Rho/rho.http/) gives Rho
one typed HTTP contract. Provider implementations build `RhoHttpRequest`
values and receive tasks or SSE streams; request encoding, TLS, and
connection handling remain in this package.

`HttpClient` is the transport interface. A client implements complete
requests and response-head opening; its body-stream class implements
next and close. `rho_http_open_execution()` returns a typed value
describing whether opening is performed by an Aio, a worker, or the
calling R process. A client that does not declare asynchronous opening
receives the conservative caller-process default. SSE decoding composes
over those methods and never receives a transport handle.
`rho_http_client()` selects the built-in nanonext implementation. Rho
keeps that implementation pinned while [nanonext issue
\#329](https://github.com/r-lib/nanonext/issues/329) establishes an
upstream incremental-response API.
[`rho.http.httr2`](https://rgenomicsetl.github.io/Rho/rho.http.httr2/)
implements the same interface with worker-owned httr2 connections;
provider code and the SSE decoder are unchanged when that client is
selected.

## TLS and SSE

``` r
library(rho.http)

client <- rho_http_client()
inherits(client@tls, "tlsConfig")
#> [1] TRUE
opening <- rho_http_open_execution(client)
S7::S7_inherits(opening, RhoHttpAioOpen)
#> [1] TRUE

events <- rho_sse_parse(paste0(
  "event: delta\n",
  "data: first\n\n",
  "data: done\n\n"
))
vapply(events, function(event) event@event, character(1))
#> [1] "delta"   "message"
vapply(events, function(event) event@data, character(1))
#> [1] "first" "done"
```

`rho_http_client()` uses nanonext’s in-memory mbedTLS configuration. A
caller that requires peer authentication passes a configured `tlsConfig`
value; the package never searches operating-system certificate paths.
SSE values feed typed provider decoders in
[`rho.ai`](https://rgenomicsetl.github.io/Rho/rho.ai/).

See the [`rho.http`
reference](https://rgenomicsetl.github.io/Rho/rho.http/reference/)
and the underlying
[`rho.async`](https://rgenomicsetl.github.io/Rho/rho.async/)
contract.
