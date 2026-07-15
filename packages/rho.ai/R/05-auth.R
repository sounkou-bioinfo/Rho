RhoCredential <- S7::new_class(
  "RhoCredential",
  abstract = TRUE,
  properties = list(
    provider = rho_non_empty_string,
    source = S7::class_character
  )
)

RhoApiKeyCredential <- S7::new_class(
  "RhoApiKeyCredential",
  parent = RhoCredential,
  properties = list(
    provider_env = S7::class_list,
    state = S7::class_environment
  ),
  validator = function(self) {
    if (!exists("key", self@state, inherits = FALSE)) {
      return("@state must contain `key`")
    }
    key <- self@state$key
    if (!is.character(key) || length(key) != 1L || is.na(key) || !nzchar(key)) {
      "@state$key must be one non-empty string"
    }
  }
)

RhoOAuthCredential <- S7::new_class(
  "RhoOAuthCredential",
  parent = RhoCredential,
  properties = list(
    account_id = S7::class_character,
    expires = S7::class_double,
    metadata = S7::class_list,
    state = S7::class_environment
  ),
  validator = function(self) {
    required <- c("access", "refresh")
    missing <- setdiff(required, ls(self@state, all.names = TRUE))
    if (length(missing)) {
      return(sprintf("@state missing field(s): %s", paste(missing, collapse = ", ")))
    }
    access <- self@state$access
    if (!is.character(access) || length(access) != 1L || is.na(access) || !nzchar(access)) {
      return("@state$access must be one non-empty string")
    }
    refresh <- self@state$refresh
    if (!is.character(refresh) || length(refresh) != 1L || is.na(refresh)) {
      "@state$refresh must be one string"
    }
  }
)

RhoModelAuth <- S7::new_class(
  "RhoModelAuth",
  properties = list(
    api_key = S7::class_character,
    headers = S7::class_list,
    base_url = S7::class_character,
    metadata = S7::class_list
  )
)

RhoAuthResolution <- S7::new_class(
  "RhoAuthResolution",
  properties = list(
    configured = rho_scalar_logical,
    auth = S7::class_any,
    source = S7::class_character,
    error = S7::class_any
  )
)

RhoApiKeyAuth <- S7::new_class(
  "RhoApiKeyAuth",
  properties = list(
    name = rho_non_empty_string,
    login = S7::class_function,
    to_request = S7::class_function
  )
)

RhoOAuthAuth <- S7::new_class(
  "RhoOAuthAuth",
  abstract = TRUE,
  properties = list(name = rho_non_empty_string)
)

RhoFunctionOAuthAuth <- S7::new_class(
  "RhoFunctionOAuthAuth",
  parent = RhoOAuthAuth,
  properties = list(
    login = S7::class_function,
    refresh = S7::class_function,
    to_request = S7::class_function
  )
)

RhoLoginMethod <- S7::new_class("RhoLoginMethod", abstract = TRUE)
RhoApiKeyLogin <- S7::new_class("RhoApiKeyLogin", parent = RhoLoginMethod)
RhoOAuthLogin <- S7::new_class("RhoOAuthLogin", parent = RhoLoginMethod)

RhoProviderAuth <- S7::new_class(
  "RhoProviderAuth",
  properties = list(
    api_key = S7::class_any,
    oauth = S7::class_any
  ),
  validator = function(self) {
    if (is.null(self@api_key) && is.null(self@oauth)) {
      "at least one of @api_key and @oauth must be configured"
    }
  }
)

RhoCredentialGate <- S7::new_class(
  "RhoCredentialGate",
  properties = list(state = S7::class_environment),
  validator = function(self) {
    required <- "queue"
    missing <- setdiff(required, ls(self@state, all.names = TRUE))
    if (length(missing)) sprintf("@state missing field(s): %s", paste(missing, collapse = ", "))
  }
)

RhoMemoryCredentialStore <- S7::new_class(
  "RhoMemoryCredentialStore",
  properties = list(state = S7::class_environment),
  validator = function(self) {
    required <- c("credentials", "gates")
    missing <- setdiff(required, ls(self@state, all.names = TRUE))
    if (length(missing)) {
      return(sprintf("@state missing field(s): %s", paste(missing, collapse = ", ")))
    }
    credentials <- self@state$credentials
    if (!is.list(credentials)) {
      return("@state$credentials must be a list")
    }
    if (length(credentials)) {
      names <- names(credentials)
      if (is.null(names) || anyNA(names) || any(!nzchar(names))) {
        return("@state$credentials must have non-empty names")
      }
    }
    if (!is.list(self@state$gates)) {
      "@state$gates must be a list"
    }
  }
)

RhoAuthPrompt <- S7::new_class(
  "RhoAuthPrompt",
  abstract = TRUE,
  properties = list(message = rho_non_empty_string, placeholder = S7::class_character)
)
RhoTextAuthPrompt <- S7::new_class("RhoTextAuthPrompt", parent = RhoAuthPrompt)
RhoSecretAuthPrompt <- S7::new_class("RhoSecretAuthPrompt", parent = RhoAuthPrompt)
RhoManualCodeAuthPrompt <- S7::new_class("RhoManualCodeAuthPrompt", parent = RhoAuthPrompt)
RhoSelectAuthPrompt <- S7::new_class(
  "RhoSelectAuthPrompt",
  parent = RhoAuthPrompt,
  properties = list(options = S7::class_list)
)

RhoAuthEvent <- S7::new_class("RhoAuthEvent", abstract = TRUE)
RhoAuthUrlEvent <- S7::new_class(
  "RhoAuthUrlEvent",
  parent = RhoAuthEvent,
  properties = list(url = rho_non_empty_string, instructions = S7::class_character)
)
RhoDeviceCodeEvent <- S7::new_class(
  "RhoDeviceCodeEvent",
  parent = RhoAuthEvent,
  properties = list(
    user_code = rho_non_empty_string,
    verification_uri = rho_non_empty_string,
    interval_seconds = S7::class_double,
    expires_in_seconds = S7::class_double
  )
)
RhoAuthProgressEvent <- S7::new_class(
  "RhoAuthProgressEvent",
  parent = RhoAuthEvent,
  properties = list(message = rho_non_empty_string)
)

RhoFunctionLoginIO <- S7::new_class(
  "RhoFunctionLoginIO",
  properties = list(prompt = S7::class_function, notify = S7::class_function)
)

RhoProvider <- S7::new_class(
  "RhoProvider",
  properties = list(
    id = rho_non_empty_string,
    name = rho_non_empty_string,
    implementation = S7::class_any,
    auth = RhoProviderAuth,
    models = S7::class_list
  ),
  validator = function(self) {
    invalid <- Filter(function(model) !S7::S7_inherits(model, Model), self@models)
    if (length(invalid)) "@models must contain only Model values"
  }
)

RhoModels <- S7::new_class(
  "RhoModels",
  properties = list(
    providers = S7::class_list,
    credentials = S7::class_any,
    auth_context = S7::class_list
  )
)

S7::method(
  rho_login_strategy,
  list(RhoApiKeyLogin, RhoProvider)
) <- function(method, provider, ...) {
  strategy <- provider@auth@api_key
  if (is.null(strategy)) {
    return(rho_auth_error(
      sprintf("Provider %s does not support API-key login", provider@id),
      "login_method"
    ))
  }
  strategy
}

S7::method(
  rho_login_strategy,
  list(RhoOAuthLogin, RhoProvider)
) <- function(method, provider, ...) {
  strategy <- provider@auth@oauth
  if (is.null(strategy)) {
    return(rho_auth_error(
      sprintf("Provider %s does not support OAuth login", provider@id),
      "login_method"
    ))
  }
  strategy
}

rho_api_key_credential <- function(provider, key, provider_env = list(), source = "explicit") {
  state <- new.env(parent = emptyenv())
  state$key <- key
  RhoApiKeyCredential(
    provider = provider,
    source = source,
    provider_env = provider_env,
    state = state
  )
}

rho_model_auth <- function(api_key = "", headers = list(), base_url = "", metadata = list()) {
  RhoModelAuth(api_key = api_key, headers = headers, base_url = base_url, metadata = metadata)
}

rho_api_key_auth <- function(name, login, to_request) {
  RhoApiKeyAuth(name = name, login = login, to_request = to_request)
}

rho_oauth_auth <- function(name, login, refresh, to_request) {
  RhoFunctionOAuthAuth(name = name, login = login, refresh = refresh, to_request = to_request)
}

rho_provider_auth <- function(api_key = NULL, oauth = NULL) {
  RhoProviderAuth(api_key = api_key, oauth = oauth)
}

rho_credential_gate <- function() {
  state <- new.env(parent = emptyenv())
  state$queue <- rho.async::rho_serial_queue()
  RhoCredentialGate(state = state)
}

rho_memory_credential_store <- function(credentials = list()) {
  state <- new.env(parent = emptyenv())
  state$credentials <- credentials
  state$gates <- list()
  RhoMemoryCredentialStore(state = state)
}

rho_store_gate <- function(store, provider_id) {
  gate <- store@state$gates[[provider_id]]
  if (is.null(gate)) {
    gate <- rho_credential_gate()
    store@state$gates[[provider_id]] <- gate
  }
  gate
}

S7::method(rho_credential_read, RhoMemoryCredentialStore) <- function(store, provider_id, ...) {
  rho.async::rho_task(store@state$credentials[[provider_id]])
}

S7::method(rho_credential_modify, RhoMemoryCredentialStore) <- function(
  store,
  provider_id,
  update,
  ...
) {
  if (!is.function(update)) {
    rho.async::rho_signal_contract_violation("`update` must be a function")
  }
  gate <- rho_store_gate(store, provider_id)
  rho.async::rho_enqueue(
    gate@state$queue,
    function() {
      current <- store@state$credentials[[provider_id]]
      rho.async::rho_then(rho.async::rho_as_task(update(current)), function(next_value) {
        if (S7::S7_inherits(next_value, ProviderErrorValue)) {
          return(next_value)
        }
        if (!is.null(next_value)) {
          store@state$credentials[[provider_id]] <- next_value
        }
        next_value %||% current
      })
    },
    label = sprintf("credential-modify:%s", provider_id)
  )
}

S7::method(rho_credential_delete, RhoMemoryCredentialStore) <- function(store, provider_id, ...) {
  gate <- rho_store_gate(store, provider_id)
  rho.async::rho_enqueue(
    gate@state$queue,
    function() {
      store@state$credentials[[provider_id]] <- NULL
      NULL
    },
    label = sprintf("credential-delete:%s", provider_id)
  )
}

S7::method(rho_auth_login, RhoApiKeyAuth) <- function(auth, provider_id, io, ...) {
  rho.async::rho_as_task(auth@login(provider_id, io))
}

S7::method(rho_auth_to_request, RhoApiKeyAuth) <- function(auth, credential, ...) {
  rho.async::rho_as_task(auth@to_request(credential))
}

S7::method(rho_auth_login, RhoFunctionOAuthAuth) <- function(auth, provider_id, io, ...) {
  rho.async::rho_as_task(auth@login(provider_id, io))
}

S7::method(rho_auth_refresh, RhoFunctionOAuthAuth) <- function(auth, credential, ...) {
  rho.async::rho_as_task(auth@refresh(credential))
}

S7::method(rho_auth_to_request, RhoFunctionOAuthAuth) <- function(auth, credential, ...) {
  rho.async::rho_as_task(auth@to_request(credential))
}

S7::method(rho_auth_prompt, RhoFunctionLoginIO) <- function(io, prompt, ...) {
  rho.async::rho_as_task(io@prompt(prompt))
}

S7::method(rho_auth_notify, RhoFunctionLoginIO) <- function(io, event, ...) {
  rho.async::rho_as_task(io@notify(event))
}

rho_login_io <- function(prompt, notify = function(event) NULL) {
  RhoFunctionLoginIO(prompt = prompt, notify = notify)
}

rho_provider <- function(id, name = id, implementation, auth, models) {
  RhoProvider(id = id, name = name, implementation = implementation, auth = auth, models = models)
}

rho_models <- function(
  providers,
  credentials = rho_memory_credential_store(),
  auth_context = list()
) {
  if (length(providers) && is.null(names(providers))) {
    names(providers) <- vapply(providers, function(provider) provider@id, character(1))
  }
  s7contract::assert_implements(credentials, CredentialStore, arg = "credentials")
  RhoModels(providers = providers, credentials = credentials, auth_context = auth_context)
}

rho_models_provider <- function(models, provider_id) models@providers[[provider_id]]

S7::method(
  rho_provider_models,
  list(RhoProvider, S7::class_any)
) <- function(provider, credential, ...) {
  provider@models
}

S7::method(rho_available_models, RhoModels) <- function(models, provider_id, ...) {
  provider <- rho_models_provider(models, provider_id)
  if (is.null(provider)) {
    return(rho.async::rho_task(rho_auth_error(
      sprintf("Unknown provider: %s", provider_id),
      "provider"
    )))
  }
  rho.async::rho_then(
    rho_credential_read(models@credentials, provider_id),
    function(credential) rho_provider_models(provider, credential)
  )
}

rho_login_provider <- function(models, provider_id, io, method = RhoOAuthLogin()) {
  provider <- rho_models_provider(models, provider_id)
  if (is.null(provider)) {
    return(rho.async::rho_task(rho_auth_error(
      sprintf("Unknown provider: %s", provider_id),
      "provider"
    )))
  }
  strategy <- rho_login_strategy(method, provider)
  if (S7::S7_inherits(strategy, ProviderErrorValue)) {
    return(rho.async::rho_task(strategy))
  }
  rho.async::rho_then(rho_auth_login(strategy, provider_id, io), function(credential) {
    if (S7::S7_inherits(credential, ProviderErrorValue)) {
      return(credential)
    }
    rho_credential_modify(models@credentials, provider_id, function(current) credential)
  })
}

rho_oauth_resolution <- function(models, provider, credential) {
  strategy <- provider@auth@oauth
  if (is.null(strategy)) {
    return(rho.async::rho_task(RhoAuthResolution(
      configured = FALSE,
      auth = NULL,
      source = credential@source,
      error = rho_auth_error(
        "Stored OAuth credential has no matching provider strategy",
        "credential_type"
      )
    )))
  }
  current_time <- as.double(Sys.time()) * 1000
  credential_task <- if (is.na(credential@expires) || current_time < credential@expires) {
    rho.async::rho_task(credential)
  } else {
    rho_credential_modify(models@credentials, provider@id, function(current) {
      if (!S7::S7_inherits(current, RhoOAuthCredential)) {
        return(NULL)
      }
      if (is.na(current@expires) || as.double(Sys.time()) * 1000 < current@expires) {
        return(NULL)
      }
      rho_auth_refresh(strategy, current)
    })
  }
  rho.async::rho_then(credential_task, function(current) {
    if (S7::S7_inherits(current, ProviderErrorValue)) {
      return(RhoAuthResolution(
        configured = FALSE,
        auth = NULL,
        source = credential@source,
        error = current
      ))
    }
    rho.async::rho_then(rho_auth_to_request(strategy, current), function(auth) {
      if (S7::S7_inherits(auth, ProviderErrorValue)) {
        return(RhoAuthResolution(
          configured = FALSE,
          auth = NULL,
          source = current@source,
          error = auth
        ))
      }
      RhoAuthResolution(configured = TRUE, auth = auth, source = current@source, error = NULL)
    })
  })
}

rho_api_key_resolution <- function(provider, credential) {
  strategy <- provider@auth@api_key
  if (is.null(strategy)) {
    return(rho.async::rho_task(RhoAuthResolution(
      configured = FALSE,
      auth = NULL,
      source = credential@source,
      error = rho_auth_error("Stored API key has no matching provider strategy", "credential_type")
    )))
  }
  rho.async::rho_then(rho_auth_to_request(strategy, credential), function(auth) {
    if (S7::S7_inherits(auth, ProviderErrorValue)) {
      return(RhoAuthResolution(
        configured = FALSE,
        auth = NULL,
        source = credential@source,
        error = auth
      ))
    }
    RhoAuthResolution(configured = TRUE, auth = auth, source = credential@source, error = NULL)
  })
}

S7::method(rho_resolve_model_auth, RhoModels) <- function(models, model, ...) {
  provider <- rho_models_provider(models, model@provider)
  if (is.null(provider)) {
    return(rho.async::rho_task(RhoAuthResolution(
      configured = FALSE,
      auth = NULL,
      source = "",
      error = rho_auth_error(sprintf("Unknown provider: %s", model@provider), "provider")
    )))
  }
  rho.async::rho_then(rho_credential_read(models@credentials, provider@id), function(credential) {
    if (is.null(credential)) {
      return(RhoAuthResolution(
        configured = FALSE,
        auth = NULL,
        source = "",
        error = rho_auth_error(
          sprintf("No explicit credential for provider %s", provider@id),
          "missing"
        )
      ))
    }
    if (S7::S7_inherits(credential, RhoOAuthCredential)) {
      return(rho_oauth_resolution(models, provider, credential))
    }
    if (S7::S7_inherits(credential, RhoApiKeyCredential)) {
      return(rho_api_key_resolution(provider, credential))
    }
    RhoAuthResolution(
      configured = FALSE,
      auth = NULL,
      source = "",
      error = rho_auth_error("Unsupported credential value", "credential_type")
    )
  })
}

S7::method(rho_stream, list(RhoProvider, Model, Context)) <- function(
  provider,
  model,
  context,
  options = list(),
  ...
) {
  dialect <- rho_provider_dialect(provider@implementation, model)
  rho_stream(dialect, model, context, options = options, ...)
}

S7::method(rho_stream, list(RhoModels, Model, Context)) <- function(
  provider,
  model,
  context,
  options = list(),
  ...
) {
  models <- provider
  selected_provider <- rho_models_provider(models, model@provider)
  resolution <- rho.async::rho_then(rho_resolve_model_auth(models, model), function(auth) {
    if (!auth@configured) {
      message <- rho_assistant_message(
        provider = model@provider,
        model = model@id,
        stop_reason = "error"
      )
      return(rho.async::rho_list_stream(list(
        rho_assistant_error_event(auth@error, message)
      )))
    }
    request_options <- options
    request_options$auth <- auth@auth
    rho_stream(selected_provider, model, context, options = request_options)
  })
  rho.async::rho_stream_from_task(resolution)
}
