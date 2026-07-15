#!/usr/bin/env Rscript

rho_script_file <- function() {
  argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (!length(argument)) {
    stop("Cannot determine the compiler script location", call. = FALSE)
  }
  normalizePath(sub("^--file=", "", argument[[1L]]), mustWork = TRUE)
}

rho_catalog_argument <- function(name, default) {
  pattern <- sprintf("^--%s=", name)
  argument <- grep(pattern, commandArgs(trailingOnly = TRUE), value = TRUE)
  if (!length(argument)) default else sub(pattern, "", argument[[1L]])
}

rho_catalog_read <- function(path) {
  yyjsonr::read_json_file(
    path,
    arr_of_objs_to_df = FALSE,
    obj_of_arrs_to_df = FALSE
  )
}

rho_catalog_has_text <- function(value) {
  is.character(value) && length(value) == 1L && !is.na(value) && nzchar(value)
}

rho_catalog_validate_curation <- function(entry, label) {
  if (!rho_catalog_has_text(entry$reason)) {
    stop(sprintf("%s must declare a non-empty reason", label), call. = FALSE)
  }
  evidence <- entry$evidence
  if (
    !is.list(evidence) ||
      !rho_catalog_has_text(evidence$kind) ||
      !rho_catalog_has_text(evidence$reference)
  ) {
    stop(
      sprintf("%s must declare evidence.kind and evidence.reference", label),
      call. = FALSE
    )
  }
  invisible(entry)
}

rho_catalog_supported_input <- function(model) {
  input <- intersect(unlist(model$input, use.names = FALSE), c("text", "image"))
  if (!length(input)) {
    stop(sprintf("Model %s has no supported input modality", model$id), call. = FALSE)
  }
  input
}

rho_catalog_thinking_map <- function(model, provider_kind) {
  if (!isTRUE(model$reasoning)) {
    return(list())
  }
  levels <- unlist(model$reasoning_levels, use.names = FALSE)
  if (!length(levels)) {
    return(list())
  }
  canonical <- c("off", "minimal", "low", "medium", "high", "xhigh", "max")
  mapped <- lapply(canonical, function(level) {
    provider_level <- if (identical(level, "off")) {
      disabled <- intersect(c("none", "off"), levels)
      if (length(disabled)) disabled[[1L]] else NULL
    } else if (level %in% levels) {
      level
    } else {
      NULL
    }
    provider_level
  })
  names(mapped) <- canonical
  if (
    identical(provider_kind, "github_copilot") &&
      startsWith(model$id, "gpt-5") &&
      is.null(mapped$minimal) &&
      "low" %in% levels
  ) {
    mapped$minimal <- "low"
  }
  if (is.null(mapped$xhigh) && "max" %in% levels) {
    mapped$xhigh <- "max"
  }
  if (
    identical(provider_kind, "zai") &&
      identical(model$id, "glm-5.2")
  ) {
    mapped <- as.list(stats::setNames(canonical, canonical))
    mapped$off <- "none"
  }
  mapped
}

rho_catalog_record <- function(
  model,
  provider,
  protocol,
  provider_capabilities = list(),
  source = "models.dev"
) {
  if (is.null(model$context_window) || is.null(model$max_tokens)) {
    stop(sprintf("Model %s is missing declared limits", model$id), call. = FALSE)
  }
  pricing <- model$pricing
  required_pricing <- c("input", "output", "cache_read", "cache_write")
  if (!all(required_pricing %in% names(pricing))) {
    stop(sprintf("Model %s is missing declared pricing fields", model$id), call. = FALSE)
  }
  list(
    provider = provider,
    protocol = protocol,
    id = model$id,
    name = model$name,
    input = rho_catalog_supported_input(model),
    reasoning = isTRUE(model$reasoning),
    thinking_level_map = rho_catalog_thinking_map(model, provider$kind),
    tools = TRUE,
    parallel_tool_calls = TRUE,
    transports = "sse",
    context_window = as.integer(model$context_window),
    max_tokens = as.integer(model$max_tokens),
    pricing = lapply(pricing[required_pricing], as.double),
    headers = list(),
    provider_capabilities = provider_capabilities,
    source = source
  )
}

rho_catalog_active_tool_models <- function(provider) {
  Filter(
    function(model) isTRUE(model$tool_call) && !identical(model$status, "deprecated"),
    provider$models
  )
}

rho_compile_openai_models <- function(provider) {
  profile <- list(
    kind = "openai",
    id = "openai",
    name = "OpenAI",
    base_url = "https://api.openai.com/v1"
  )
  lapply(
    rho_catalog_active_tool_models(provider),
    rho_catalog_record,
    provider = profile,
    protocol = "openai_responses"
  )
}

rho_anthropic_provider_capabilities <- function(model) {
  modes <- unlist(model$reasoning_modes, use.names = FALSE)
  thinking <- if (!isTRUE(model$reasoning)) {
    "none"
  } else if ("effort" %in% modes) {
    "adaptive"
  } else {
    "budget"
  }
  list(
    thinking = thinking,
    temperature = isTRUE(model$temperature),
    long_cache_retention = TRUE,
    cache_tools = TRUE,
    tool_input = "eager",
    allow_empty_signature = FALSE,
    supports_tool_references = FALSE
  )
}

rho_compile_anthropic_models <- function(provider) {
  profile <- list(
    kind = "anthropic",
    id = "anthropic",
    name = "Anthropic",
    base_url = "https://api.anthropic.com"
  )
  lapply(rho_catalog_active_tool_models(provider), function(model) {
    rho_catalog_record(
      model,
      profile,
      "anthropic_messages",
      provider_capabilities = rho_anthropic_provider_capabilities(model)
    )
  })
}

rho_copilot_protocol <- function(model) {
  routes <- list(
    list(
      matches = function(id) grepl("^claude-(haiku|sonnet|opus)-4([.\\-]|$)", id),
      protocol = "anthropic_messages"
    ),
    list(
      matches = function(id) startsWith(id, "gpt-5") || startsWith(id, "oswe"),
      protocol = "openai_responses"
    ),
    list(matches = function(id) TRUE, protocol = "openai_chat_completions")
  )
  route <- Filter(function(candidate) candidate$matches(model$id), routes)[[1L]]
  route$protocol
}

rho_compile_copilot_models <- function(provider) {
  profile <- list(
    kind = "github_copilot",
    id = "github-copilot",
    name = "GitHub Copilot",
    base_url = "https://api.individual.githubcopilot.com"
  )
  lapply(rho_catalog_active_tool_models(provider), function(model) {
    protocol <- rho_copilot_protocol(model)
    capabilities <- if (identical(protocol, "anthropic_messages")) {
      rho_anthropic_provider_capabilities(model)
    } else {
      list()
    }
    rho_catalog_record(
      model,
      profile,
      protocol,
      provider_capabilities = capabilities
    )
  })
}

rho_compile_zai_models <- function(provider) {
  profiles <- list(
    list(
      kind = "zai",
      id = "zai",
      name = "Z.ai Coding Plan",
      base_url = "https://api.z.ai/api/coding/paas/v4",
      preserve_thinking = TRUE
    ),
    list(
      kind = "zai",
      id = "zai-coding-cn",
      name = "Z.ai Coding Plan China",
      base_url = "https://open.bigmodel.cn/api/coding/paas/v4",
      preserve_thinking = TRUE
    )
  )
  unlist(
    lapply(profiles, function(profile) {
      lapply(
        rho_catalog_active_tool_models(provider),
        rho_catalog_record,
        provider = profile,
        protocol = "openai_chat_completions"
      )
    }),
    recursive = FALSE,
    use.names = FALSE
  )
}

rho_catalog_compilers <- list(
  anthropic = rho_compile_anthropic_models,
  `github-copilot` = rho_compile_copilot_models,
  openai = rho_compile_openai_models,
  `zai-coding-plan` = rho_compile_zai_models
)

rho_compile_source_models <- function(snapshot) {
  unlist(
    lapply(names(rho_catalog_compilers), function(provider_id) {
      provider <- snapshot$providers[[provider_id]]
      if (is.null(provider)) {
        stop(sprintf("Source snapshot is missing provider %s", provider_id), call. = FALSE)
      }
      rho_catalog_compilers[[provider_id]](provider)
    }),
    recursive = FALSE,
    use.names = FALSE
  )
}

rho_catalog_normalize_override <- function(record) {
  rho_catalog_validate_curation(
    record,
    sprintf("Curated record %s/%s", record$provider$id, record$id)
  )
  record$input <- unlist(record$input, use.names = FALSE)
  record$transports <- unlist(record$transports, use.names = FALSE)
  record$context_window <- as.integer(record$context_window)
  record$max_tokens <- as.integer(record$max_tokens)
  record$pricing <- lapply(record$pricing, as.double)
  record$provider_capabilities <- record$provider_capabilities %||% list()
  record$source <- "rho"
  record$reason <- NULL
  record$evidence <- NULL
  record
}

rho_catalog_profile_key <- function(record) {
  paste(record$provider$id, record$id, sep = "/")
}

rho_catalog_apply_profile_overrides <- function(records, overrides) {
  profiles <- overrides$profile_overrides %||% list()
  if (!length(profiles)) {
    return(records)
  }
  for (index in seq_along(profiles)) {
    profile <- profiles[[index]]
    rho_catalog_validate_curation(
      profile,
      sprintf("Profile override %s/%s", profile$provider, profile$model)
    )
  }
  profile_keys <- vapply(
    profiles,
    function(profile) paste(profile$provider, profile$model, sep = "/"),
    character(1)
  )
  if (anyDuplicated(profile_keys)) {
    stop(
      sprintf(
        "Duplicate profile override key(s): %s",
        paste(unique(profile_keys[duplicated(profile_keys)]), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  record_keys <- vapply(records, rho_catalog_profile_key, character(1))
  unmatched <- setdiff(profile_keys, record_keys)
  if (length(unmatched)) {
    stop(
      sprintf("Profile override(s) match no catalog record: %s", paste(unmatched, collapse = ", ")),
      call. = FALSE
    )
  }
  names(profiles) <- profile_keys
  lapply(records, function(record) {
    profile <- profiles[[rho_catalog_profile_key(record)]]
    if (!is.null(profile)) {
      record$provider_capabilities <- utils::modifyList(
        record$provider_capabilities %||% list(),
        profile$values %||% list()
      )
      record$thinking_level_map <- utils::modifyList(
        record$thinking_level_map %||% list(),
        profile$thinking_level_map %||% list()
      )
    }
    record
  })
}

rho_catalog_data <- function(snapshot, overrides, override_path) {
  if (!identical(as.integer(snapshot$schema_version), 1L)) {
    stop("Unsupported models.dev snapshot schema", call. = FALSE)
  }
  if (!identical(as.integer(overrides$schema_version), 2L)) {
    stop("Unsupported model override schema", call. = FALSE)
  }
  records <- rho_catalog_apply_profile_overrides(
    c(
      rho_compile_source_models(snapshot),
      lapply(overrides$records, rho_catalog_normalize_override)
    ),
    overrides
  )
  keys <- vapply(
    records,
    function(record) paste(record$provider$id, record$id, sep = "/"),
    character(1)
  )
  if (anyDuplicated(keys)) {
    stop(
      sprintf(
        "Duplicate model catalog key(s): %s",
        paste(unique(keys[duplicated(keys)]), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  records <- records[order(keys)]
  list(
    schema_version = 1L,
    sources = list(
      list(
        id = "models.dev",
        location = snapshot$source$url,
        sha256 = snapshot$source$sha256
      ),
      list(
        id = "rho",
        location = "package:rho.ai/data-raw/model-overrides.json",
        sha256 = digest::digest(file = override_path, algo = "sha256")
      )
    ),
    records = records
  )
}

rho_catalog_check <- function(path, expected) {
  if (!file.exists(path)) {
    stop(sprintf("Generated catalog is missing: %s", path), call. = FALSE)
  }
  environment <- new.env(parent = emptyenv())
  load(path, envir = environment)
  if (!exists("rho_model_catalog_data", envir = environment, inherits = FALSE)) {
    stop("Generated catalog does not contain rho_model_catalog_data", call. = FALSE)
  }
  if (!identical(environment$rho_model_catalog_data, expected)) {
    stop("Generated model catalog is stale; run `make models`", call. = FALSE)
  }
  message("Generated model catalog is current")
}

script <- rho_script_file()
data_raw <- dirname(script)
package <- dirname(data_raw)
snapshot_path <- rho_catalog_argument(
  "snapshot",
  file.path(data_raw, "models-dev-selected.json")
)
override_path <- rho_catalog_argument(
  "overrides",
  file.path(data_raw, "model-overrides.json")
)
output_path <- rho_catalog_argument("output", file.path(package, "R", "sysdata.rda"))
snapshot <- rho_catalog_read(snapshot_path)
overrides <- rho_catalog_read(override_path)
rho_model_catalog_data <- rho_catalog_data(snapshot, overrides, override_path)
if ("--check" %in% commandArgs(trailingOnly = TRUE)) {
  rho_catalog_check(output_path, rho_model_catalog_data)
} else {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  save(rho_model_catalog_data, file = output_path, version = 3L, compress = "xz")
  message(sprintf(
    "Compiled %d models into %s",
    length(rho_model_catalog_data$records),
    output_path
  ))
}
