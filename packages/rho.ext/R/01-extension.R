RhoExtensionRuntime <- S7::new_class(
  "RhoExtensionRuntime",
  properties = list(state = S7::class_environment)
)
RhoExtensionAPI <- S7::new_class(
  "RhoExtensionAPI",
  properties = list(runtime = RhoExtensionRuntime, state = S7::class_environment)
)
RhoExtensionContext <- S7::new_class(
  "RhoExtensionContext",
  properties = list(runtime = RhoExtensionRuntime, signal = S7::class_any, data = S7::class_list)
)

rho_extension_runtime <- function() {
  RhoExtensionRuntime(
    state = rho_new_state(
      handlers = new.env(parent = emptyenv()),
      tools = new.env(parent = emptyenv()),
      commands = new.env(parent = emptyenv()),
      providers = new.env(parent = emptyenv()),
      stale = FALSE,
      bound = FALSE,
      pending_provider_registrations = list()
    )
  )
}

rho_extension_api <- function(runtime = rho_extension_runtime(), source = "<memory>") {
  RhoExtensionAPI(runtime = runtime, state = rho_new_state(source = source))
}

rho_on <- S7::new_generic("rho_on", "api", function(api, event, handler, ...) S7::S7_dispatch())
rho_register_tool <- S7::new_generic("rho_register_tool", "api", function(api, tool, ...) {
  S7::S7_dispatch()
})
rho_register_command <- S7::new_generic(
  "rho_register_command",
  "api",
  function(api, name, handler, description = NULL, ...) S7::S7_dispatch()
)
rho_register_provider <- S7::new_generic(
  "rho_register_provider",
  "api",
  function(api, name, provider, ...) S7::S7_dispatch()
)
rho_dispatch_event <- S7::new_generic(
  "rho_dispatch_event",
  "runtime",
  function(runtime, event, ctx = NULL, ...) S7::S7_dispatch()
)

S7::method(rho_on, RhoExtensionAPI) <- function(api, event, handler, ...) {
  if (!is.function(handler)) {
    rho_abort("`handler` must be a function")
  }
  handlers <- api@runtime@state$handlers
  current <- if (exists(event, handlers, inherits = FALSE)) get(event, handlers) else list()
  current[[length(current) + 1L]] <- handler
  assign(event, current, handlers)
  invisible(api)
}

S7::method(rho_register_tool, RhoExtensionAPI) <- function(api, tool, ...) {
  if (!S7::S7_inherits(tool, rho.ai::ToolSpec)) {
    rho_abort("`tool` must be a rho.ai ToolSpec value")
  }
  assign(tool@name, tool, api@runtime@state$tools)
  invisible(api)
}

S7::method(rho_register_command, RhoExtensionAPI) <- function(
  api,
  name,
  handler,
  description = NULL,
  ...
) {
  if (!is.function(handler)) {
    rho_abort("`handler` must be a function")
  }
  assign(
    name,
    list(name = name, handler = handler, description = description),
    api@runtime@state$commands
  )
  invisible(api)
}

S7::method(rho_register_provider, RhoExtensionAPI) <- function(api, name, provider, ...) {
  if (!isTRUE(api@runtime@state$bound)) {
    api@runtime@state$pending_provider_registrations[[
      length(api@runtime@state$pending_provider_registrations) + 1L
    ]] <- list(name = name, provider = provider)
  } else {
    assign(name, provider, api@runtime@state$providers)
  }
  invisible(api)
}

S7::method(rho_dispatch_event, RhoExtensionRuntime) <- function(runtime, event, ctx = NULL, ...) {
  rho.async::rho_task_from_function(
    function() {
      name <- event$type %||% event[["type"]]
      if (is.null(name) || !exists(name, runtime@state$handlers, inherits = FALSE)) {
        return(list())
      }
      handlers <- get(name, runtime@state$handlers)
      out <- list()
      for (handler in handlers) {
        value <- handler(event, ctx)
        if (rho.async::rho_is_task(value)) {
          value <- rho.async::rho_await(value)
        }
        if (!is.null(value)) out[[length(out) + 1L]] <- value
      }
      out
    },
    label = paste0("extension-event-", event$type %||% "unknown")
  )
}
