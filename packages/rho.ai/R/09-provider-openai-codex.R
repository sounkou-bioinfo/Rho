OpenAICodexApi <- S7::new_class(
  "OpenAICodexApi",
  properties = list(
    base_url = rho_non_empty_string,
    originator = rho_non_empty_string,
    http = rho.http::RhoHttpClient
  )
)

OpenAICodexOAuthAuth <- S7::new_class(
  "OpenAICodexOAuthAuth",
  parent = RhoOAuthAuth,
  properties = list(
    auth_base_url = rho_non_empty_string,
    originator = rho_non_empty_string,
    http = rho.http::RhoHttpClient
  )
)

rho_openai_codex_client_id <- "app_EMoamEEZ73f0CkXaXp7hrann"

rho_form_urlencode <- function(fields) {
  if (!length(fields)) {
    return("")
  }
  values <- vapply(
    fields,
    function(value) {
      utils::URLencode(as.character(value), reserved = TRUE)
    },
    character(1)
  )
  paste(paste(utils::URLencode(names(values), reserved = TRUE), values, sep = "="), collapse = "&")
}

rho_base64url_encode <- function(value) {
  encoded <- base64enc::base64encode(value)
  sub("=+$", "", chartr("+/", "-_", encoded))
}

rho_base64url_decode <- function(value) {
  encoded <- chartr("-_", "+/", value)
  padding <- (4L - nchar(encoded) %% 4L) %% 4L
  if (padding) {
    encoded <- paste0(encoded, strrep("=", padding))
  }
  base64enc::base64decode(encoded)
}

rho_openai_codex_pkce <- function() {
  verifier <- rho_base64url_encode(nanonext::random(32L, convert = FALSE))
  list(
    verifier = verifier,
    challenge = rho_base64url_encode(digest::digest(
      charToRaw(verifier),
      algo = "sha256",
      serialize = FALSE,
      raw = TRUE
    )),
    state = nanonext::random(16L)
  )
}

rho_openai_codex_json_document <- function(response, operation) {
  if (is.na(response@status) || response@status < 200L || response@status >= 300L) {
    return(rho_auth_error(
      sprintf("OpenAI Codex %s failed with HTTP status %s", operation, response@status),
      code = "http",
      retryable = response@status %in% c(408L, 409L, 429L) || response@status >= 500L,
      details = list(status = response@status)
    ))
  }
  parsed <- tryCatch(
    yyjsonr::read_json_str(
      as.character(response@data),
      arr_of_objs_to_df = FALSE,
      obj_of_arrs_to_df = FALSE
    ),
    error = function(error) error
  )
  if (inherits(parsed, "error")) {
    return(rho_auth_error(
      sprintf("OpenAI Codex %s returned invalid JSON", operation),
      code = "response_format"
    ))
  }
  parsed
}

rho_openai_codex_http_task <- function(auth, request, operation) {
  rho.async::rho_then(
    rho.http::rho_http_send(auth@http, request),
    function(response) rho_openai_codex_json_document(response, operation),
    function(error) {
      rho_auth_error(
        sprintf("OpenAI Codex %s transport failed: %s", operation, conditionMessage(error)),
        code = "transport",
        retryable = TRUE
      )
    }
  )
}

rho_openai_codex_token_request <- function(auth, fields, operation) {
  request <- rho.http::rho_http_request(
    method = "POST",
    url = paste0(auth@auth_base_url, "/oauth/token"),
    headers = list(`Content-Type` = "application/x-www-form-urlencoded"),
    body = rho_form_urlencode(fields),
    timeout_ms = 30000L,
    response_headers = "content-type",
    convert = TRUE
  )
  rho_openai_codex_http_task(auth, request, operation)
}

rho_openai_codex_credential_from_token <- function(document, source, refresh_token = NULL) {
  if (S7::S7_inherits(document, ProviderErrorValue)) {
    return(document)
  }
  access <- document$access_token
  refresh <- document$refresh_token %||% refresh_token
  expires_in <- suppressWarnings(as.double(document$expires_in))
  if (
    !is.character(access) ||
      length(access) != 1L ||
      !nzchar(access) ||
      !is.character(refresh) ||
      length(refresh) != 1L ||
      !nzchar(refresh) ||
      length(expires_in) != 1L ||
      is.na(expires_in) ||
      expires_in <= 0
  ) {
    return(rho_auth_error(
      "OpenAI Codex token response is missing access_token, refresh_token, or expires_in",
      code = "response_fields"
    ))
  }
  account_id <- tryCatch(rho_openai_codex_account_id(access), error = function(error) error)
  if (inherits(account_id, "error")) {
    return(rho_auth_error(conditionMessage(account_id), code = "token_claims"))
  }
  rho_openai_codex_credential(
    access_token = access,
    account_id = account_id,
    refresh_token = refresh,
    expires = as.double(Sys.time()) * 1000 + expires_in * 1000,
    source = source
  )
}

rho_openai_codex_exchange_code <- function(auth, code, verifier, redirect_uri, source = "login") {
  rho.async::rho_then(
    rho_openai_codex_token_request(
      auth,
      fields = list(
        grant_type = "authorization_code",
        client_id = rho_openai_codex_client_id,
        code = code,
        code_verifier = verifier,
        redirect_uri = redirect_uri
      ),
      operation = "authorization-code exchange"
    ),
    function(document) rho_openai_codex_credential_from_token(document, source)
  )
}

rho_openai_codex_query <- function(input) {
  value <- trimws(input)
  if (!nzchar(value)) {
    return(list())
  }
  query <- if (grepl("?", value, fixed = TRUE)) {
    sub("^[^?]*\\?", "", value)
  } else {
    value
  }
  query <- sub("#.*$", "", query)
  fields <- strsplit(query, "&", fixed = TRUE)[[1L]]
  pairs <- lapply(fields, function(field) strsplit(field, "=", fixed = TRUE)[[1L]])
  names <- vapply(pairs, function(pair) utils::URLdecode(pair[[1L]]), character(1))
  values <- vapply(
    pairs,
    function(pair) {
      utils::URLdecode(paste(pair[-1L], collapse = "="))
    },
    character(1)
  )
  as.list(stats::setNames(values, names))
}

rho_openai_codex_authorization_input <- function(input, expected_state) {
  value <- trimws(input)
  if (grepl("#", value, fixed = TRUE) && !grepl("?", value, fixed = TRUE)) {
    pieces <- strsplit(value, "#", fixed = TRUE)[[1L]]
    parsed <- list(code = pieces[[1L]], state = pieces[[2L]] %||% "")
  } else if (grepl("code=", value, fixed = TRUE) || grepl("?", value, fixed = TRUE)) {
    parsed <- rho_openai_codex_query(value)
  } else {
    parsed <- list(code = value, state = "")
  }
  if (nzchar(parsed$state %||% "") && !identical(parsed$state, expected_state)) {
    return(rho_auth_error("OpenAI Codex authorization state mismatch", code = "state"))
  }
  if (!is.character(parsed$code) || length(parsed$code) != 1L || !nzchar(parsed$code)) {
    return(rho_auth_error(
      "OpenAI Codex authorization code is missing",
      code = "authorization_code"
    ))
  }
  parsed$code
}

rho_openai_codex_browser_login <- function(auth, io) {
  pkce <- rho_openai_codex_pkce()
  redirect_uri <- "http://localhost:1455/auth/callback"
  authorize_url <- paste0(
    auth@auth_base_url,
    "/oauth/authorize?",
    rho_form_urlencode(list(
      response_type = "code",
      client_id = rho_openai_codex_client_id,
      redirect_uri = redirect_uri,
      scope = "openid profile email offline_access",
      code_challenge = pkce$challenge,
      code_challenge_method = "S256",
      state = pkce$state,
      id_token_add_organizations = "true",
      codex_cli_simplified_flow = "true",
      originator = auth@originator
    ))
  )
  rho.async::rho_then(
    rho_auth_notify(
      io,
      RhoAuthUrlEvent(
        url = authorize_url,
        instructions = "Complete login, then paste the authorization code or redirect URL."
      )
    ),
    function(ignored) {
      rho.async::rho_then(
        rho_auth_prompt(
          io,
          RhoManualCodeAuthPrompt(
            message = "Paste the OpenAI authorization code or redirect URL:",
            placeholder = redirect_uri
          )
        ),
        function(input) {
          code <- rho_openai_codex_authorization_input(input, pkce$state)
          if (S7::S7_inherits(code, ProviderErrorValue)) {
            return(code)
          }
          rho_openai_codex_exchange_code(auth, code, pkce$verifier, redirect_uri)
        }
      )
    }
  )
}

rho_openai_codex_start_device_login <- function(auth) {
  request <- rho.http::rho_http_request(
    method = "POST",
    url = paste0(auth@auth_base_url, "/api/accounts/deviceauth/usercode"),
    headers = list(`Content-Type` = "application/json"),
    body = list(client_id = rho_openai_codex_client_id),
    timeout_ms = 30000L,
    response_headers = "content-type",
    convert = TRUE
  )
  rho.async::rho_then(
    rho_openai_codex_http_task(auth, request, "device-code start"),
    function(document) {
      if (S7::S7_inherits(document, ProviderErrorValue)) {
        return(document)
      }
      interval <- suppressWarnings(as.double(document$interval))
      if (
        !is.character(document$device_auth_id) ||
          !nzchar(document$device_auth_id) ||
          !is.character(document$user_code) ||
          !nzchar(document$user_code) ||
          length(interval) != 1L ||
          is.na(interval) ||
          interval < 0
      ) {
        return(rho_auth_error(
          "OpenAI Codex device-code response is missing fields",
          "response_fields"
        ))
      }
      list(
        device_auth_id = document$device_auth_id,
        user_code = document$user_code,
        interval_seconds = interval
      )
    }
  )
}

rho_openai_codex_poll_device_login <- function(auth, device) {
  interval_ms <- max(250L, as.integer(device$interval_seconds * 1000))
  rho.async::rho_poll(
    function(attempt) {
      request <- rho.http::rho_http_request(
        method = "POST",
        url = paste0(auth@auth_base_url, "/api/accounts/deviceauth/token"),
        headers = list(`Content-Type` = "application/json"),
        body = list(device_auth_id = device$device_auth_id, user_code = device$user_code),
        timeout_ms = 30000L,
        response_headers = "content-type",
        convert = TRUE
      )
      rho.async::rho_then(
        rho.http::rho_http_send(auth@http, request),
        function(response) {
          if (response@status >= 200L && response@status < 300L) {
            document <- rho_openai_codex_json_document(response, "device-code poll")
            if (S7::S7_inherits(document, ProviderErrorValue)) {
              return(rho.async::rho_poll_failed(document))
            }
            if (
              !is.character(document$authorization_code) ||
                !nzchar(document$authorization_code) ||
                !is.character(document$code_verifier) ||
                !nzchar(document$code_verifier)
            ) {
              return(rho.async::rho_poll_failed(rho_auth_error(
                "OpenAI Codex device authorization response is missing fields",
                "response_fields"
              )))
            }
            return(rho.async::rho_poll_complete(document))
          }
          if (response@status %in% c(403L, 404L)) {
            return(rho.async::rho_poll_pending(interval_ms))
          }
          document <- tryCatch(
            yyjsonr::read_json_str(
              as.character(response@data),
              arr_of_objs_to_df = FALSE,
              obj_of_arrs_to_df = FALSE
            ),
            error = function(error) list()
          )
          error_value <- document$error
          error_code <- if (is.list(error_value)) error_value$code else error_value
          if (identical(error_code, "deviceauth_authorization_pending")) {
            return(rho.async::rho_poll_pending(interval_ms))
          }
          if (identical(error_code, "slow_down")) {
            return(rho.async::rho_poll_pending(interval_ms + 5000L))
          }
          rho.async::rho_poll_failed(rho_auth_error(
            sprintf(
              "OpenAI Codex device authorization failed with HTTP status %s",
              response@status
            ),
            "device_authorization",
            details = list(status = response@status, attempt = attempt)
          ))
        },
        function(error) {
          rho.async::rho_poll_failed(rho_auth_error(
            sprintf(
              "OpenAI Codex device authorization transport failed: %s",
              conditionMessage(error)
            ),
            "transport",
            retryable = TRUE
          ))
        }
      )
    },
    timeout_ms = 15L * 60L * 1000L
  )
}

rho_openai_codex_device_login <- function(auth, io) {
  rho.async::rho_then(rho_openai_codex_start_device_login(auth), function(device) {
    if (S7::S7_inherits(device, ProviderErrorValue)) {
      return(device)
    }
    rho.async::rho_then(
      rho_auth_notify(
        io,
        RhoDeviceCodeEvent(
          user_code = device$user_code,
          verification_uri = paste0(auth@auth_base_url, "/codex/device"),
          interval_seconds = device$interval_seconds,
          expires_in_seconds = 15 * 60
        )
      ),
      function(ignored) {
        rho.async::rho_then(rho_openai_codex_poll_device_login(auth, device), function(code) {
          if (
            S7::S7_inherits(code, rho.async::RhoAsyncError) ||
              S7::S7_inherits(code, ProviderErrorValue)
          ) {
            return(code)
          }
          rho_openai_codex_exchange_code(
            auth,
            code$authorization_code,
            code$code_verifier,
            paste0(auth@auth_base_url, "/deviceauth/callback")
          )
        })
      }
    )
  })
}

rho_openai_codex_auth <- function(
  http = rho.http::rho_http_client(timeout_ms = 30000L),
  auth_base_url = "https://auth.openai.com",
  originator = "rho"
) {
  OpenAICodexOAuthAuth(
    name = "OpenAI (ChatGPT Plus/Pro)",
    auth_base_url = sub("/+$", "", auth_base_url),
    originator = originator,
    http = http
  )
}

S7::method(rho_auth_login, OpenAICodexOAuthAuth) <- function(auth, provider_id, io, ...) {
  rho.async::rho_then(
    rho_auth_prompt(
      io,
      RhoSelectAuthPrompt(
        message = "Select OpenAI Codex login method:",
        placeholder = "browser",
        options = list(
          list(id = "browser", label = "Browser login"),
          list(id = "device_code", label = "Device code login")
        )
      )
    ),
    function(method) {
      if (identical(method, "browser")) {
        return(rho_openai_codex_browser_login(auth, io))
      }
      if (identical(method, "device_code")) {
        return(rho_openai_codex_device_login(auth, io))
      }
      rho_auth_error(sprintf("Unknown OpenAI Codex login method: %s", method), "login_method")
    }
  )
}

S7::method(rho_auth_refresh, OpenAICodexOAuthAuth) <- function(auth, credential, ...) {
  if (!S7::S7_inherits(credential, RhoOAuthCredential) || !nzchar(credential@state$refresh)) {
    return(rho.async::rho_task(rho_auth_error(
      "OpenAI Codex refresh requires an OAuth credential with a refresh token",
      "credential_type"
    )))
  }
  rho.async::rho_then(
    rho_openai_codex_token_request(
      auth,
      fields = list(
        grant_type = "refresh_token",
        refresh_token = credential@state$refresh,
        client_id = rho_openai_codex_client_id
      ),
      operation = "token refresh"
    ),
    function(document) {
      rho_openai_codex_credential_from_token(
        document,
        source = credential@source,
        refresh_token = credential@state$refresh
      )
    }
  )
}

S7::method(rho_auth_to_request, OpenAICodexOAuthAuth) <- function(auth, credential, ...) {
  if (!S7::S7_inherits(credential, RhoOAuthCredential) || !nzchar(credential@state$access)) {
    return(rho.async::rho_task(rho_auth_error(
      "OpenAI Codex request auth requires an OAuth credential",
      "credential_type"
    )))
  }
  rho.async::rho_task(rho_model_auth(
    api_key = credential@state$access,
    headers = list(`chatgpt-account-id` = credential@account_id),
    metadata = list(provider = credential@provider, source = credential@source)
  ))
}

rho_decode_jwt_payload <- function(token) {
  parts <- strsplit(token, ".", fixed = TRUE)[[1L]]
  if (length(parts) != 3L) {
    rho_abort("OAuth access token is not a JWT")
  }
  decoded <- rawToChar(rho_base64url_decode(parts[[2L]]))
  yyjsonr::read_json_str(decoded, arr_of_objs_to_df = FALSE, obj_of_arrs_to_df = FALSE)
}

rho_openai_codex_account_id <- function(access_token) {
  payload <- rho_decode_jwt_payload(access_token)
  account_id <- payload[["https://api.openai.com/auth"]]$chatgpt_account_id
  if (!is.character(account_id) || length(account_id) != 1L || !nzchar(account_id)) {
    rho_abort("OAuth token does not contain a ChatGPT account id")
  }
  account_id
}

rho_openai_codex_credential <- function(
  access_token,
  account_id = NULL,
  refresh_token = "",
  expires = NA_real_,
  source = ""
) {
  if (!is.character(access_token) || length(access_token) != 1L || !nzchar(access_token)) {
    rho_abort("`access_token` must be one non-empty string")
  }
  account_id <- account_id %||% rho_openai_codex_account_id(access_token)
  secret_state <- new.env(parent = emptyenv())
  secret_state$access <- access_token
  secret_state$refresh <- refresh_token
  RhoOAuthCredential(
    provider = "openai-codex",
    account_id = account_id,
    expires = as.double(expires),
    source = source,
    metadata = list(),
    state = secret_state
  )
}

rho_openai_codex_credential_from_document <- function(document, source) {
  pi_credential <- document[["openai-codex"]]
  if (
    is.list(pi_credential) && is.character(pi_credential$access) && nzchar(pi_credential$access)
  ) {
    return(rho_openai_codex_credential(
      access_token = pi_credential$access,
      account_id = pi_credential$accountId,
      refresh_token = pi_credential$refresh %||% "",
      expires = pi_credential$expires %||% NA_real_,
      source = source
    ))
  }
  codex_tokens <- document$tokens
  if (
    is.list(codex_tokens) &&
      is.character(codex_tokens$access_token) &&
      nzchar(codex_tokens$access_token)
  ) {
    payload <- rho_decode_jwt_payload(codex_tokens$access_token)
    return(rho_openai_codex_credential(
      access_token = codex_tokens$access_token,
      account_id = codex_tokens$account_id,
      refresh_token = codex_tokens$refresh_token %||% "",
      expires = as.double(payload$exp %||% NA_real_) * 1000,
      source = source
    ))
  }
  rho_auth_error("The supplied file contains no OpenAI Codex credential", "credential_format")
}

rho_load_openai_codex_credential <- function(path) {
  rho.async::rho_task_from_function(
    function() {
      if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
        return(rho_auth_error("`path` must be supplied explicitly", "credential_path"))
      }
      if (!file.exists(path)) {
        return(rho_auth_error(
          sprintf("Credential file does not exist: %s", path),
          "credential_path"
        ))
      }
      document <- tryCatch(
        yyjsonr::read_json_file(path, arr_of_objs_to_df = FALSE, obj_of_arrs_to_df = FALSE),
        error = function(error) error
      )
      if (inherits(document, "error")) {
        return(rho_auth_error(
          sprintf("Could not parse credential file: %s", conditionMessage(document)),
          "credential_format"
        ))
      }
      source <- normalizePath(path, winslash = "/", mustWork = TRUE)
      rho_openai_codex_credential_from_document(document, source)
    },
    label = "openai-codex-credential-import"
  )
}

rho_openai_codex_provider <- function(
  base_url = "https://chatgpt.com/backend-api",
  originator = "rho",
  http = rho.http::rho_http_client(timeout_ms = 120000L)
) {
  implementation <- OpenAICodexApi(
    base_url = base_url,
    originator = originator,
    http = http
  )
  rho_provider(
    id = "openai-codex",
    name = "OpenAI Codex",
    implementation = implementation,
    auth = rho_provider_auth(oauth = rho_openai_codex_auth(http)),
    models = list(rho_openai_codex_spark())
  )
}

rho_openai_codex_spark <- function() {
  rho_model(
    provider = "openai-codex",
    id = "gpt-5.3-codex-spark",
    name = "GPT-5.3 Codex Spark",
    api = "openai-codex-responses",
    base_url = "https://chatgpt.com/backend-api",
    context_window = 128000L,
    max_tokens = 128000L,
    input = "text",
    reasoning = TRUE,
    thinking_level_map = list(xhigh = "xhigh", minimal = "low"),
    transports = c("sse", "websocket", "websocket-cached", "auto"),
    pricing = rho_model_pricing(
      input = 1.75,
      output = 14,
      cache_read = 0.175,
      cache_write = 0
    ),
    compatibility = rho_openai_responses_compatibility(
      supports_tool_search = FALSE,
      supports_native_compaction = FALSE
    )
  )
}

rho_openai_codex_url <- function(base_url) {
  normalized <- sub("/+$", "", base_url)
  if (endsWith(normalized, "/codex/responses")) {
    return(normalized)
  }
  if (endsWith(normalized, "/codex")) {
    return(paste0(normalized, "/responses"))
  }
  paste0(normalized, "/codex/responses")
}

rho_openai_codex_content_text <- function(content) {
  if (is.character(content)) {
    return(paste(content, collapse = ""))
  }
  if (!is.list(content)) {
    return(as.character(content))
  }
  paste(
    vapply(
      content,
      function(part) {
        if (S7::S7_inherits(part, TextContent)) part@text else ""
      },
      character(1)
    ),
    collapse = ""
  )
}

rho_openai_codex_input <- function(context, placement) {
  input <- list()
  deferred <- placement@deferred
  deferred_names <- if (length(deferred)) {
    vapply(deferred, function(tool) tool@name, character(1))
  } else {
    character()
  }
  loaded_names <- character()
  for (message_index in seq_along(context@messages)) {
    message <- context@messages[[message_index]]
    if (S7::S7_inherits(message, UserMessage)) {
      input[[length(input) + 1L]] <- list(
        role = "user",
        content = list(list(
          type = "input_text",
          text = rho_openai_codex_content_text(message@content)
        ))
      )
    } else if (S7::S7_inherits(message, AssistantMessage)) {
      text <- rho_openai_codex_content_text(message@content)
      if (nzchar(text)) {
        input[[length(input) + 1L]] <- list(
          role = "assistant",
          content = list(list(type = "output_text", text = text))
        )
      }
      for (content in message@content) {
        if (S7::S7_inherits(content, ToolCall)) {
          input[[length(input) + 1L]] <- list(
            type = "function_call",
            call_id = content@id,
            name = content@name,
            arguments = yyjsonr::write_json_str(content@arguments, auto_unbox = TRUE)
          )
        }
      }
    } else if (S7::S7_inherits(message, ToolResultMessage)) {
      input[[length(input) + 1L]] <- list(
        type = "function_call_output",
        call_id = message@tool_call_id,
        output = rho_openai_codex_content_text(message@content)
      )
      names_to_load <- intersect(message@added_tool_names, setdiff(deferred_names, loaded_names))
      if (length(names_to_load)) {
        loaded_names <- c(loaded_names, names_to_load)
        loaded_tools <- deferred[deferred_names %in% names_to_load]
        search_call_id <- sprintf("rho_tool_load_%d", message_index)
        input[[length(input) + 1L]] <- list(
          type = "tool_search_call",
          call_id = search_call_id,
          execution = "client",
          status = "completed",
          arguments = list(
            query = paste(names_to_load, collapse = " "),
            limit = length(names_to_load)
          )
        )
        input[[length(input) + 1L]] <- list(
          type = "tool_search_output",
          call_id = search_call_id,
          execution = "client",
          status = "completed",
          tools = rho_openai_codex_tools(loaded_tools, defer_loading = TRUE)
        )
      }
    }
  }
  input
}

rho_openai_codex_tools <- function(tools, defer_loading = FALSE) {
  lapply(tools, function(tool) {
    definition <- list(
      type = "function",
      name = tool@name,
      description = tool@description,
      parameters = tool@parameters
    )
    if (isTRUE(defer_loading)) {
      definition$defer_loading <- TRUE
    }
    definition
  })
}

rho_openai_codex_request <- function(provider, model, context, options = list()) {
  rho_build_provider_request(provider, model, context, options = options)
}

S7::method(
  rho_provider_support,
  list(OpenAICodexApi, Model, RhoToolSearchOperation)
) <- function(provider, model, operation, ...) {
  compatibility <- model@compatibility
  supported <- S7::S7_inherits(compatibility, OpenAIResponsesCompatibility) &&
    compatibility@supports_tool_search
  rho_provider_support_value(
    supported,
    source = "openai-responses-compatibility",
    details = list(api = model@api, model = model@id)
  )
}

S7::method(
  rho_provider_support,
  list(OpenAICodexApi, Model, RhoNativeCompactionOperation)
) <- function(provider, model, operation, ...) {
  compatibility <- model@compatibility
  supported <- S7::S7_inherits(compatibility, OpenAIResponsesCompatibility) &&
    compatibility@supports_native_compaction
  rho_provider_support_value(
    supported,
    source = "openai-responses-compatibility",
    details = list(api = model@api, model = model@id)
  )
}

S7::method(
  rho_plan_tools,
  list(OpenAICodexApi, Model, Context)
) <- function(provider, model, context, ...) {
  support <- rho_provider_support(provider, model, RhoToolSearchOperation())
  if (!support@supported) {
    return(rho_full_tool_placement(
      context@tools,
      reason = sprintf(
        "OpenAI tool search is not verified for %s; all active definitions are advertised at the request boundary",
        model@id
      ),
      cache_expectation = if (length(rho_deferred_tool_names(context))) {
        "replace-prefix"
      } else {
        "unchanged"
      }
    ))
  }
  placement <- rho_split_deferred_tools(context)
  rho_openai_tool_search_placement(placement$immediate, placement$deferred)
}

S7::method(
  rho_build_provider_request,
  list(OpenAICodexApi, Model, Context)
) <- function(provider, model, context, options = list(), ...) {
  auth <- options$auth
  if (!S7::S7_inherits(auth, RhoModelAuth) || !nzchar(auth@api_key)) {
    rho_abort("OpenAI Codex requests require explicit resolved auth in `options$auth`")
  }

  placement <- options$tool_placement %||% rho_plan_tools(provider, model, context)
  if (!S7::S7_inherits(placement, RhoToolPlacement)) {
    rho_abort("`options$tool_placement` must inherit from RhoToolPlacement")
  }

  request_body <- list(
    model = model@id,
    store = FALSE,
    stream = TRUE,
    instructions = if (nzchar(context@system_prompt)) {
      context@system_prompt
    } else {
      "You are a helpful assistant."
    },
    input = rho_openai_codex_input(context, placement),
    text = list(verbosity = options$text_verbosity %||% "low"),
    include = list("reasoning.encrypted_content"),
    tool_choice = options$tool_choice %||% "auto",
    parallel_tool_calls = model@capabilities@parallel_tool_calls
  )
  if (model@capabilities@tools && length(placement@immediate)) {
    request_body$tools <- rho_openai_codex_tools(placement@immediate)
  }
  reasoning_effort <- options$reasoning_effort %||% "low"
  if (!identical(reasoning_effort, "off")) {
    request_body$reasoning <- list(
      effort = rho_map_thinking_level(model, reasoning_effort),
      summary = options$reasoning_summary %||% "auto"
    )
  }
  if (!is.null(options$session_id)) {
    request_body$prompt_cache_key <- options$session_id
  }

  headers <- utils::modifyList(
    list(
      Authorization = paste("Bearer", auth@api_key),
      originator = provider@originator,
      `User-Agent` = sprintf(
        "rho (%s %s; %s)",
        Sys.info()[["sysname"]],
        Sys.info()[["release"]],
        R.version$arch
      ),
      `OpenAI-Beta` = "responses=experimental",
      Accept = "text/event-stream",
      `Content-Type` = "application/json"
    ),
    auth@headers
  )
  if (!is.null(options$session_id)) {
    headers$`session-id` <- options$session_id
    headers$`x-client-request-id` <- options$session_id
  }

  rho.http::rho_http_request(
    method = "POST",
    url = rho_openai_codex_url(if (nzchar(auth@base_url)) auth@base_url else provider@base_url),
    headers = headers,
    body = request_body,
    timeout_ms = as.integer(options$timeout_ms %||% 120000L),
    response_headers = c("content-type", "retry-after", "retry-after-ms"),
    convert = TRUE
  )
}

S7::method(rho_stream, list(OpenAICodexApi, Model, Context)) <- function(
  provider,
  model,
  context,
  options = list(),
  ...
) {
  if (!identical(model@api, "openai-codex-responses")) {
    rho_abort("OpenAI Codex provider requires an openai-codex-responses model")
  }
  request <- rho_openai_codex_request(provider, model, context, options)
  raw_stream <- rho.http::rho_sse_connect(provider@http, request)
  decoder <- rho_openai_codex_decoder(model)
  rho.async::rho_stream_flat_map(
    raw_stream,
    function(event) rho_decode_provider_event(decoder, event)
  )
}
