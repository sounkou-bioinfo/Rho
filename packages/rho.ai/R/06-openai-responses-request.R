rho_thinking_level_name <- S7::new_property(
  S7::class_character,
  validator = function(value) {
    if (
      length(value) != 1L ||
        is.na(value) ||
        !value %in% c("off", "minimal", "low", "medium", "high", "xhigh", "max")
    ) {
      "must be one canonical thinking level"
    }
  }
)

ThinkingRequest <- S7::new_class("ThinkingRequest", abstract = TRUE)
ThinkingUnspecified <- S7::new_class("ThinkingUnspecified", parent = ThinkingRequest)
ThinkingLevel <- S7::new_class(
  "ThinkingLevel",
  parent = ThinkingRequest,
  abstract = TRUE,
  properties = list(name = rho_thinking_level_name)
)
ThinkingOff <- S7::new_class("ThinkingOff", parent = ThinkingLevel)
ThinkingEnabled <- S7::new_class("ThinkingEnabled", parent = ThinkingLevel)

rho_thinking_level <- function(value = NULL) {
  if (S7::S7_inherits(value, ThinkingRequest)) {
    return(value)
  }
  if (is.null(value)) {
    return(ThinkingUnspecified())
  }
  value <- as.character(value)
  if (identical(value, "off")) {
    ThinkingOff(name = value)
  } else {
    ThinkingEnabled(name = value)
  }
}

OpenAIRequestSection <- S7::new_class("OpenAIRequestSection", abstract = TRUE)
OpenAIOmittedRequestSection <- S7::new_class(
  "OpenAIOmittedRequestSection",
  parent = OpenAIRequestSection
)
OpenAICoreRequestSection <- S7::new_class(
  "OpenAICoreRequestSection",
  parent = OpenAIRequestSection,
  properties = list(model = rho_non_empty_string, input = S7::class_list)
)
OpenAIInstructionsRequestSection <- S7::new_class(
  "OpenAIInstructionsRequestSection",
  parent = OpenAIRequestSection,
  properties = list(instructions = rho_non_empty_string)
)

rho_openai_tool_choice_wire <- S7::new_property(
  S7::class_any,
  validator = function(value) {
    valid_name <- is.character(value) &&
      length(value) == 1L &&
      !is.na(value) &&
      value %in% c("auto", "none", "required")
    valid_function <- is.list(value) &&
      identical(value$type, "function") &&
      is.character(value$name) &&
      length(value$name) == 1L &&
      !is.na(value$name) &&
      nzchar(value$name)
    if (!valid_name && !valid_function) {
      "must be auto, none, required, or a named function choice"
    }
  }
)

OpenAIToolChoice <- S7::new_class(
  "OpenAIToolChoice",
  properties = list(wire = rho_openai_tool_choice_wire)
)
OpenAIToolsRequestSection <- S7::new_class(
  "OpenAIToolsRequestSection",
  parent = OpenAIRequestSection,
  properties = list(
    tools = S7::class_list,
    choice = OpenAIToolChoice,
    parallel = rho_scalar_logical
  )
)
OpenAIMaxOutputTokensRequestSection <- S7::new_class(
  "OpenAIMaxOutputTokensRequestSection",
  parent = OpenAIRequestSection,
  properties = list(value = rho_positive_integer)
)
OpenAITemperatureRequestSection <- S7::new_class(
  "OpenAITemperatureRequestSection",
  parent = OpenAIRequestSection,
  properties = list(value = rho_nonnegative_double),
  validator = function(self) {
    if (self@value > 2) "@value must not exceed two"
  }
)

rho_openai_service_tier_value <- S7::new_property(
  S7::class_character,
  validator = function(value) {
    if (
      length(value) != 1L ||
        is.na(value) ||
        !value %in% c("auto", "default", "flex", "priority")
    ) {
      "must be auto, default, flex, or priority"
    }
  }
)

OpenAIServiceTierRequestSection <- S7::new_class(
  "OpenAIServiceTierRequestSection",
  parent = OpenAIRequestSection,
  properties = list(value = rho_openai_service_tier_value)
)

rho_openai_text_verbosity_value <- S7::new_property(
  S7::class_character,
  validator = function(value) {
    if (
      length(value) != 1L ||
        is.na(value) ||
        !value %in% c("low", "medium", "high")
    ) {
      "must be low, medium, or high"
    }
  }
)

OpenAITextVerbosityRequestSection <- S7::new_class(
  "OpenAITextVerbosityRequestSection",
  parent = OpenAIRequestSection,
  properties = list(value = rho_openai_text_verbosity_value)
)
OpenAICacheKeyRequestSection <- S7::new_class(
  "OpenAICacheKeyRequestSection",
  parent = OpenAIRequestSection,
  properties = list(key = rho_non_empty_string)
)
OpenAIReasoningDisabledRequestSection <- S7::new_class(
  "OpenAIReasoningDisabledRequestSection",
  parent = OpenAIRequestSection,
  properties = list(effort = rho_non_empty_string)
)
OpenAIReasoningEnabledRequestSection <- S7::new_class(
  "OpenAIReasoningEnabledRequestSection",
  parent = OpenAIRequestSection,
  properties = list(effort = rho_non_empty_string, summary = rho_non_empty_string)
)

rho_openai_instruction_section <- function(value, default = NULL) {
  candidates <- c(value, default)
  candidates <- candidates[nzchar(candidates)]
  if (!length(candidates)) {
    OpenAIOmittedRequestSection()
  } else {
    OpenAIInstructionsRequestSection(instructions = candidates[[1L]])
  }
}

rho_openai_tool_choice <- function(value = NULL) {
  OpenAIToolChoice(wire = value %||% "auto")
}

rho_openai_tool_section <- function(model, placement, choice) {
  advertise <- model@capabilities@tools && length(placement@immediate) > 0L
  if (!advertise) {
    return(OpenAIOmittedRequestSection())
  }
  OpenAIToolsRequestSection(
    tools = rho_openai_responses_tools(placement@immediate),
    choice = choice,
    parallel = model@capabilities@parallel_tool_calls
  )
}

rho_openai_max_output_tokens_section <- function(value = NULL) {
  if (is.null(value)) {
    OpenAIOmittedRequestSection()
  } else {
    OpenAIMaxOutputTokensRequestSection(value = as.integer(value))
  }
}

rho_openai_temperature_section <- function(value = NULL) {
  if (is.null(value)) {
    OpenAIOmittedRequestSection()
  } else {
    OpenAITemperatureRequestSection(value = as.double(value))
  }
}

rho_openai_service_tier_section <- function(value = NULL) {
  if (is.null(value)) {
    OpenAIOmittedRequestSection()
  } else {
    OpenAIServiceTierRequestSection(value = as.character(value))
  }
}

rho_openai_text_verbosity_section <- function(value = NULL) {
  if (is.null(value)) {
    OpenAIOmittedRequestSection()
  } else {
    OpenAITextVerbosityRequestSection(value = as.character(value))
  }
}

rho_openai_cache_key_section <- function(value = NULL) {
  if (is.null(value)) {
    OpenAIOmittedRequestSection()
  } else {
    OpenAICacheKeyRequestSection(key = as.character(value))
  }
}

S7::method(
  rho_openai_reasoning_section,
  list(Model, ThinkingUnspecified)
) <- function(model, level, summary = "auto", ...) {
  OpenAIOmittedRequestSection()
}

S7::method(
  rho_openai_reasoning_section,
  list(Model, ThinkingOff)
) <- function(model, level, summary = "auto", ...) {
  OpenAIReasoningDisabledRequestSection(
    effort = rho_map_thinking_level(model, level@name)
  )
}

S7::method(
  rho_openai_reasoning_section,
  list(Model, ThinkingEnabled)
) <- function(model, level, summary = "auto", ...) {
  OpenAIReasoningEnabledRequestSection(
    effort = rho_map_thinking_level(model, level@name),
    summary = summary
  )
}

rho_openai_standard_request_sections <- function(
  model,
  context,
  placement,
  options,
  instruction_default = NULL,
  reasoning_default = NULL,
  verbosity_default = NULL
) {
  list(
    OpenAICoreRequestSection(
      model = model@id,
      input = rho_openai_responses_input(context, placement)
    ),
    rho_openai_instruction_section(context@system_prompt, instruction_default),
    rho_openai_tool_section(
      model,
      placement,
      rho_openai_tool_choice(options$tool_choice)
    ),
    rho_openai_max_output_tokens_section(options$max_tokens),
    rho_openai_temperature_section(options$temperature),
    rho_openai_service_tier_section(options$service_tier),
    rho_openai_text_verbosity_section(options$text_verbosity %||% verbosity_default),
    rho_openai_cache_key_section(options$session_id),
    rho_openai_reasoning_section(
      model,
      rho_thinking_level(options$reasoning_effort %||% reasoning_default),
      summary = options$reasoning_summary %||% "auto"
    )
  )
}

S7::method(
  rho_openai_request_sections,
  list(OpenAIResponsesModel, Context, RhoToolPlacement)
) <- function(model, context, placement, options = list(), ...) {
  rho_openai_standard_request_sections(model, context, placement, options)
}

S7::method(
  rho_openai_request_sections,
  list(OpenAICodexResponsesModel, Context, RhoToolPlacement)
) <- function(model, context, placement, options = list(), ...) {
  rho_openai_standard_request_sections(
    model,
    context,
    placement,
    options,
    instruction_default = "You are a helpful assistant.",
    reasoning_default = "low",
    verbosity_default = "low"
  )
}

S7::method(rho_openai_request_fields, OpenAIOmittedRequestSection) <- function(section, ...) {
  list()
}

S7::method(rho_openai_request_fields, OpenAICoreRequestSection) <- function(section, ...) {
  list(
    model = section@model,
    input = section@input,
    store = FALSE,
    stream = TRUE
  )
}

S7::method(
  rho_openai_request_fields,
  OpenAIInstructionsRequestSection
) <- function(section, ...) {
  list(instructions = section@instructions)
}

S7::method(rho_openai_request_fields, OpenAIToolsRequestSection) <- function(section, ...) {
  list(
    tools = section@tools,
    tool_choice = section@choice@wire,
    parallel_tool_calls = section@parallel
  )
}

S7::method(
  rho_openai_request_fields,
  OpenAIMaxOutputTokensRequestSection
) <- function(section, ...) {
  list(max_output_tokens = section@value)
}

S7::method(
  rho_openai_request_fields,
  OpenAITemperatureRequestSection
) <- function(section, ...) {
  list(temperature = section@value)
}

S7::method(
  rho_openai_request_fields,
  OpenAIServiceTierRequestSection
) <- function(section, ...) {
  list(service_tier = section@value)
}

S7::method(
  rho_openai_request_fields,
  OpenAITextVerbosityRequestSection
) <- function(section, ...) {
  list(text = list(verbosity = section@value))
}

S7::method(rho_openai_request_fields, OpenAICacheKeyRequestSection) <- function(section, ...) {
  list(prompt_cache_key = section@key)
}

S7::method(
  rho_openai_request_fields,
  OpenAIReasoningDisabledRequestSection
) <- function(section, ...) {
  list(reasoning = list(effort = section@effort))
}

S7::method(
  rho_openai_request_fields,
  OpenAIReasoningEnabledRequestSection
) <- function(section, ...) {
  list(
    reasoning = list(effort = section@effort, summary = section@summary),
    include = list("reasoning.encrypted_content")
  )
}

S7::method(
  rho_openai_responses_body,
  list(OpenAIResponsesModel, Context, RhoToolPlacement)
) <- function(model, context, placement, options = list(), ...) {
  sections <- rho_openai_request_sections(
    model,
    context,
    placement,
    options = options
  )
  Reduce(
    utils::modifyList,
    lapply(sections, rho_openai_request_fields),
    init = list()
  )
}
