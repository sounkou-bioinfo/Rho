# Generated from packages/rho.http/inst/tinytest/rmd/sse-parser.Rmd; do not edit.

library(tinytest)
library(rho.http)

client <- rho_http_client()
expect_true(inherits(client@tls, "tlsConfig"))

certificate <- nanonext::write_cert()
authenticated <- nanonext::tls_config(client = certificate$client)
configured <- rho_http_client(tls = authenticated)
expect_identical(configured@tls, authenticated)

events <- rho_sse_parse("event: delta\ndata: hello\nid: 1\n\ndata: done\n\n")
expect_equal(length(events), 2)
expect_equal(events[[1]]@event, "delta")
expect_equal(events[[1]]@data, "hello")
expect_equal(events[[1]]@id, "1")
expect_equal(events[[2]]@event, "message")
expect_equal(events[[2]]@data, "done")
