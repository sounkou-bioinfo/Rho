rho_bio_describe_manifest_tool <- function(registry) {
  rho.ai::rho_tool_spec(
    name = "bio_describe_manifest",
    label = "Describe manifest",
    description = "Describe registered bio manifests",
    parameters = list(),
    execute = function(tool_call_id, params, signal, on_update, ctx) {
      rho.async::rho_task_from_function(
        function() {
          ids <- ls(registry@state$manifests, all.names = TRUE)
          rows <- lapply(ids, function(id) {
            m <- get(id, registry@state$manifests)
            list(id = m@id, version = m@version, title = m@title)
          })
          rho.ai::rho_tool_result(
            list(rho.ai::rho_text(yyjsonr::write_json_str(
              rows,
              auto_unbox = TRUE,
              pretty = TRUE
            ))),
            details = list(count = length(rows))
          )
        },
        label = "bio-describe-manifest"
      )
    }
  )
}

rho_register_bio_extension <- function(api, registry) {
  rho.ext::rho_register_tool(api, rho_bio_describe_manifest_tool(registry))
  invisible(api)
}
