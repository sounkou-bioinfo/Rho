# Generated from packages/rho.bio/inst/tinytest/rmd/manifest-validation.Rmd; do not edit.

library(tinytest)
library(rho.async)
library(rho.bio)

reg <- rho_bio_registry()
res <- rho_resolver_spec("file.scan", "0.1.0", "File scan", "scan file")
vr <- rho_virtual_resource("variants", "Variants", "file.scan", list(path = "x.csv"))
manifest <- rho_manifest("demo", "0.1.0", "Demo", "Demo", provides = list(resolvers = list(res), resources = list(vr)))
rho_register_manifest(reg, manifest)
expect_error(rho_await(rho_resolve_resource(reg, "variants")), "unbound")
