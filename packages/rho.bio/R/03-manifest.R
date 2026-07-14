rho_validate_manifest <- function(manifest) {
  errors <- character()
  if (!isTRUE(tryCatch(S7::S7_inherits(manifest, BioManifest), error = function(e) FALSE))) {
    return("manifest must be a BioManifest")
  }
  if (!identical(manifest@schema, BIO_MANIFEST_SCHEMA)) {
    errors <- c(errors, sprintf("schema must be %s", BIO_MANIFEST_SCHEMA))
  }
  provides <- manifest@provides %||% list()
  errors <- c(
    errors,
    rho_strict_keys(provides, c("resources", "resolvers", "term_sets", "operations"), "provides")
  )
  res_ids <- vapply(provides$resolvers %||% list(), function(r) r@id, character(1))
  for (r in provides$resources %||% list()) {
    if (!identical(r@kind, "virtual")) {
      errors <- c(errors, sprintf("resource '%s' must have kind 'virtual'", r@id))
    }
    if (!r@resolver %in% res_ids) {
      errors <- c(
        errors,
        sprintf("resource '%s' points to undeclared resolver '%s'", r@id, r@resolver)
      )
    }
  }
  errors
}

rho_register_manifest <- S7::new_generic(
  "rho_register_manifest",
  c("registry", "manifest"),
  function(registry, manifest, ...) S7::S7_dispatch()
)
rho_bind_resolver_impl <- S7::new_generic(
  "rho_bind_resolver_impl",
  "registry",
  function(registry, resolver_id, impl, replace = FALSE, ...) S7::S7_dispatch()
)
rho_resolve_resource <- S7::new_generic(
  "rho_resolve_resource",
  "registry",
  function(registry, resource_id, ctx = list(), ...) S7::S7_dispatch()
)
rho_get_operation <- S7::new_generic(
  "rho_get_operation",
  "registry",
  function(registry, operation_id, ...) S7::S7_dispatch()
)
rho_sql_all <- S7::new_generic("rho_sql_all", "conn", function(conn, sql, params = list(), ...) {
  S7::S7_dispatch()
})
rho_sql_run <- S7::new_generic("rho_sql_run", "conn", function(conn, sql, params = list(), ...) {
  S7::S7_dispatch()
})

S7::method(rho_register_manifest, list(BioRegistry, BioManifest)) <- function(
  registry,
  manifest,
  ...
) {
  errors <- rho_validate_manifest(manifest)
  if (length(errors)) {
    rho_abort("Invalid manifest:\n- %s", paste(errors, collapse = "\n- "))
  }
  assign(manifest@id, manifest, registry@state$manifests)
  for (x in manifest@provides$resources %||% list()) {
    assign(x@id, x, registry@state$resources)
  }
  for (x in manifest@provides$resolvers %||% list()) {
    assign(x@id, x, registry@state$resolvers)
  }
  for (x in manifest@provides$term_sets %||% list()) {
    assign(x@id, x, registry@state$term_sets)
  }
  for (x in manifest@provides$operations %||% list()) {
    assign(x@id, x, registry@state$operations)
  }
  invisible(registry)
}

S7::method(rho_bind_resolver_impl, BioRegistry) <- function(
  registry,
  resolver_id,
  impl,
  replace = FALSE,
  ...
) {
  if (!exists(resolver_id, registry@state$resolvers, inherits = FALSE)) {
    rho_abort("Resolver spec not declared: %s", resolver_id)
  }
  if (!replace && exists(resolver_id, registry@state$resolver_impls, inherits = FALSE)) {
    rho_abort("Resolver impl already bound: %s", resolver_id)
  }
  if (!is.function(impl)) {
    rho_abort("Resolver impl must be a function")
  }
  assign(resolver_id, impl, registry@state$resolver_impls)
  invisible(registry)
}

S7::method(rho_resolve_resource, BioRegistry) <- function(
  registry,
  resource_id,
  ctx = list(),
  ...
) {
  rho.async::rho_task_from_function(
    function() {
      if (!exists(resource_id, registry@state$resources, inherits = FALSE)) {
        rho_abort("Unknown resource: %s", resource_id)
      }
      resource <- get(resource_id, registry@state$resources)
      if (!exists(resource@resolver, registry@state$resolvers, inherits = FALSE)) {
        rho_abort("Missing resolver spec: %s", resource@resolver)
      }
      if (!exists(resource@resolver, registry@state$resolver_impls, inherits = FALSE)) {
        rho_abort("Resolver impl is unbound: %s", resource@resolver)
      }
      spec <- get(resource@resolver, registry@state$resolvers)
      impl <- get(resource@resolver, registry@state$resolver_impls)
      out <- impl(resource, ctx)
      if (rho.async::rho_is_task(out)) {
        out <- rho.async::rho_await(out)
      }
      if (
        !is.list(out) ||
          !isTRUE(tryCatch(S7::S7_inherits(out$result, ResourceHandle), error = function(e) FALSE))
      ) {
        rho_abort(
          "Resolver impl must return list(result = ResourceHandle, source_snapshots = list(), provenance = list())"
        )
      }
      digest <- paste0(
        "sha256:",
        digest::digest(rho_canonical_json(resource@params), algo = "sha256", serialize = FALSE)
      )
      ResolutionReceipt(
        RESOLUTION_RECEIPT_SCHEMA,
        resource@id,
        spec@id,
        spec@version,
        format(Sys.time(), "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC"),
        digest,
        out$source_snapshots %||% list(),
        out$result,
        out$provenance %||% list()
      )
    },
    label = paste0("resolve-", resource_id)
  )
}

S7::method(rho_get_operation, BioRegistry) <- function(registry, operation_id, ...) {
  if (!exists(operation_id, registry@state$operations, inherits = FALSE)) {
    return(NULL)
  }
  get(operation_id, registry@state$operations)
}
