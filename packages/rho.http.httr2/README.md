
# rho.http.httr2

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

[`rho.http.httr2`](https://rgenomicsetl.github.io/Rho/rho.http.httr2/)
implements the
[`rho.http`](https://rgenomicsetl.github.io/Rho/rho.http/) client
interface in compute workers. Complete requests use httr2. Streaming
requests use curl’s native multi event loop because httr2’s public
connection API is a pull interface rather than an event driver.

The worker captures the final response head before relaying the first
raw body chunk over a private localhost NNG pair socket. The socket
provides backpressure; closing or cancelling the Rho stream cancels the
worker. The calling R event loop does not parse HTTP or wait for network
I/O.

``` r
library(rho.http.httr2)

client <- rho_httr2_http_client()
S7::S7_inherits(client, rho.http::RhoHttpClient)
#> [1] TRUE
s7contract::implements(client, rho.http::HttpClient)
#> [1] TRUE
S7::S7_inherits(
  rho.http::rho_http_open_execution(client),
  rho.http::RhoHttpWorkerOpen
)
#> [1] TRUE
rho.http::rho_http_client_close(client)
```

Providers receive only the `HttpClient` contract. Selecting this adapter
does not change request translation, SSE decoding, or normalized
provider events.

See the [`rho.http.httr2`
reference](https://rgenomicsetl.github.io/Rho/rho.http.httr2/reference/)
and the shared [`rho.http`
contract](https://rgenomicsetl.github.io/Rho/rho.http/).
