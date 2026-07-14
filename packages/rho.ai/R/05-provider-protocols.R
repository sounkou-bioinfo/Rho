rho_unique_tools <- function(tools) {
  if (!length(tools)) {
    return(list())
  }
  names <- vapply(tools, function(tool) tool@name, character(1))
  tools[!duplicated(names, fromLast = TRUE)]
}

rho_class_label <- function(value) {
  s7_class <- S7::S7_class(value)
  if (is.null(s7_class)) {
    return(class(value)[[1L]])
  }
  s7_class@name
}

rho_deferred_tool_names <- function(context) {
  used <- character()
  deferred <- character()
  for (message in context@messages) {
    if (S7::S7_inherits(message, AssistantMessage)) {
      calls <- Filter(function(content) S7::S7_inherits(content, ToolCall), message@content)
      used <- unique(c(used, vapply(calls, function(call) call@name, character(1))))
    } else if (S7::S7_inherits(message, ToolResultMessage)) {
      newly_deferred <- setdiff(message@added_tool_names, used)
      deferred <- unique(c(deferred, newly_deferred))
    }
  }
  deferred
}

rho_split_deferred_tools <- function(context) {
  tools <- rho_unique_tools(context@tools)
  if (!length(tools)) {
    return(list(immediate = list(), deferred = list()))
  }
  deferred_names <- rho_deferred_tool_names(context)
  tool_names <- vapply(tools, function(tool) tool@name, character(1))
  is_deferred <- tool_names %in% deferred_names
  list(immediate = tools[!is_deferred], deferred = tools[is_deferred])
}

rho_full_tool_placement <- function(tools, reason, cache_expectation = "replace-prefix") {
  RhoFullToolPlacement(
    immediate = rho_unique_tools(tools),
    deferred = list(),
    cache_expectation = cache_expectation,
    reason = reason
  )
}

rho_openai_tool_search_placement <- function(immediate, deferred) {
  RhoOpenAIToolSearchPlacement(
    immediate = immediate,
    deferred = deferred,
    cache_expectation = if (length(deferred)) "preserve-prefix" else "unchanged",
    reason = "OpenAI tool-search placement is verified for this endpoint and model"
  )
}

rho_anthropic_tool_reference_placement <- function(immediate, deferred) {
  RhoAnthropicToolReferencePlacement(
    immediate = immediate,
    deferred = deferred,
    cache_expectation = if (length(deferred)) "preserve-prefix" else "unchanged",
    reason = "Anthropic deferred tool references are verified for this endpoint and model"
  )
}

S7::method(
  rho_provider_support,
  list(S7::class_any, Model, RhoProviderOperation)
) <- function(provider, model, operation, ...) {
  rho_provider_support_value(
    supported = FALSE,
    source = "default",
    details = list(
      provider_class = rho_class_label(provider),
      operation_class = rho_class_label(operation)
    )
  )
}

S7::method(
  rho_plan_tools,
  list(S7::class_any, Model, Context)
) <- function(provider, model, context, ...) {
  rho_full_tool_placement(
    context@tools,
    reason = "The provider has no verified native deferred-tool protocol"
  )
}

S7::method(
  rho_build_provider_request,
  list(S7::class_any, Model, Context)
) <- function(provider, model, context, options = list(), ...) {
  rho_unsupported_provider_operation(
    operation = "build_request",
    message = sprintf("No request translator is registered for %s", rho_class_label(provider))
  )
}

S7::method(
  rho_compact_provider_input,
  list(S7::class_any, Model, Context)
) <- function(provider, model, context, options = list(), ...) {
  rho.async::rho_task(rho_unsupported_provider_operation(
    operation = "compact_provider_input",
    message = sprintf(
      "No provider-native input compactor is registered for %s",
      rho_class_label(provider)
    )
  ))
}

S7::method(
  rho_provider_support,
  list(RhoProvider, Model, RhoProviderOperation)
) <- function(provider, model, operation, ...) {
  rho_provider_support(provider@implementation, model, operation, ...)
}

S7::method(
  rho_plan_tools,
  list(RhoProvider, Model, Context)
) <- function(provider, model, context, ...) {
  rho_plan_tools(provider@implementation, model, context, ...)
}

S7::method(
  rho_build_provider_request,
  list(RhoProvider, Model, Context)
) <- function(provider, model, context, options = list(), ...) {
  rho_build_provider_request(provider@implementation, model, context, options = options, ...)
}

S7::method(
  rho_compact_provider_input,
  list(RhoProvider, Model, Context)
) <- function(provider, model, context, options = list(), ...) {
  rho_compact_provider_input(provider@implementation, model, context, options = options, ...)
}
