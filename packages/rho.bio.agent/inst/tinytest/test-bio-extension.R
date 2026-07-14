# Generated from packages/rho.bio.agent/inst/tinytest/rmd/bio-extension.Rmd; do not edit.

library(tinytest)
library(rho.bio)
library(rho.ext)
library(rho.bio.agent)

reg <- rho_bio_registry()
rt <- rho_extension_runtime()
api <- rho_extension_api(rt)
rho_register_bio_extension(api, reg)
expect_true(exists("bio_describe_manifest", rt@state$tools, inherits = FALSE))
