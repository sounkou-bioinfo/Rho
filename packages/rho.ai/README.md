
# rho.ai

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

[`rho.ai`](https://rgenomicsetl.github.io/Rho/rho.ai/) defines the
provider surface shared by the rest of
[Rho](https://rgenomicsetl.github.io/Rho/): typed messages and content,
model capabilities, tool contracts, credentials, provider operations,
and normalized assistant event streams.

## One stream protocol

``` r
library(rho.async)
library(rho.ai)

provider <- rho_faux_provider()
model <- rho_model(provider = "faux", id = "faux")
context <- rho_context(messages = list(rho_user_message("hello")))

events <- rho_stream(provider, model, context) |>
  rho_stream_collect(timeout = 1000)
vapply(events, rho_assistant_event_type, character(1))
#> [1] "start"      "text_start" "text_delta" "text_end"   "done"
events[[length(events)]]@message@content[[1L]]@text
#> [1] "faux: hello"
```

## Provider turns

`rho_stream()` is the normalized surface, not an HTTP operation. A model
records the turn transports it accepts, while a provider records the
transports it implements. Selection returns a typed strategy and its
reason before the provider opens an assistant-event stream.

``` r
codex_provider <- rho_openai_codex_provider()@implementation
codex_model <- rho_openai_codex_model("gpt-5.3-codex-spark")
selection <- rho_select_provider_transport(
  codex_provider,
  codex_model,
  AutomaticTransport()
)

rho_transport_id(selection@transport)
#> [1] "websocket"
selection@reason
#> [1] "websocket is the first provider implementation accepted by model gpt-5.3-codex-spark"
```

SSE, WebSocket, cached WebSocket, and embedded execution are separate S7
classes. Provider packages implement `rho_provider_transports()` and
`rho_open_provider_transport()`; the broad `rho_stream()` method
supplies the common selection behavior. An embedded model can therefore
return normalized events directly, while a remote model can use HTTP,
WebSocket, NNG, or another implementation without changing the agent.

The faux provider is deterministic. OpenAI and OpenAI Codex reduce
Responses events to the same protocol; Z.ai reduces Chat Completions
events; Anthropic reduces Messages events. GitHub Copilot selects either
the Responses or Messages dialect from the model while retaining its own
credentials and endpoint headers. Capabilities are queried through
values and generics instead of provider-name conditionals:

``` r
model <- rho_openai_codex_model("gpt-5.3-codex-spark")
list(
  text_input = rho_model_supports_input(model, "text"),
  image_input = rho_model_supports_input(model, "image"),
  thinking = rho_supported_thinking_levels(model)
)
#> $text_input
#> [1] TRUE
#>
#> $image_input
#> [1] FALSE
#>
#> $thinking
#> [1] "off"     "minimal" "low"     "medium"  "high"    "xhigh"
```

## Hosted operations

Provider-hosted search is a semantic operation, not a local function
tool. The selected provider and model bind the operation before request
translation:

``` r
search_provider <- rho_openai_provider()
search_model <- rho_openai_model("gpt-5.4")
search_context <- rho_context(
  messages = list(rho_user_message("Find the current R release.")),
  operations = list(rho_web_search(
    domains = rho_web_search_allowed_domains("r-project.org")
  ))
)
search_plan <- rho_plan_operations(
  search_provider,
  search_model,
  search_context
)
binding <- search_plan@bindings[[1L]]

list(
  binding = S7::S7_class(binding)@name,
  reason = binding@reason
)
#> $binding
#> [1] "OpenAIWebSearchBinding"
#>
#> $reason
#> [1] "The selected OpenAI Responses endpoint implements this search as a provider-hosted web_search tool"
```

OpenAI and Anthropic bindings emit their own wire declarations and
normalize search calls, results, and citations as content. The agent
executes only `ToolCall` content from its local `ToolSpec` registry. An
extension can provide a narrower binding without changing either
provider translator or the loop.

## Usage and cost

Token accounting carries its provenance before it reaches the agent.
`ProviderUsage` records counts supplied by a provider; `EstimatedUsage`
names the estimator and method; `UsageUnavailable` records that a
provider supplied no counts. Ordinary input, cache reads, and cache
writes are disjoint; reasoning is an optional subset of output. Pricing
is an S7 generic: it adds a `NominalUsageCost` calculated from the model
catalogue, not a subscription bill.

``` r
usage <- rho_provider_usage(
  provider = model@provider,
  input = 800,
  output = 120,
  cache_read = 200,
  reasoning = 40
)
priced <- rho_price_usage(model, usage)

c(
  tokens = priced@total,
  reasoning = priced@reasoning,
  input_cost = priced@cost@input,
  cache_read_cost = priced@cost@cache_read,
  total_cost = priced@cost@total
)
#>          tokens       reasoning      input_cost cache_read_cost      total_cost
#>       1.120e+03       4.000e+01       1.400e-03       3.500e-05       3.115e-03
```

Credentials are explicit `RhoCredential` values resolved by a
`CredentialStore`. A request translator receives typed request auth;
provider code does not discover secrets through environment variables.

The memory store is process-scoped. The file store is selected with an
explicit path and persists successful login and refresh results as
owner-readable JSON. It uses the same `CredentialStore` methods, so
provider auth code does not know which storage implementation owns the
credential.

## Secure credential stores

For portable durable credentials,
`rho_encrypted_file_credential_store()` uses an explicit passphrase or
32-byte key to encrypt the complete credential document with Argon2id
and XChaCha20-Poly1305. Provider and credential-kind metadata is
authenticated with the encrypted payload. A wrong secret or altered
envelope resolves to `AuthErrorValue`; it does not yield a partial
credential.

For desktop and workstation use, `rho_keychain_credential_store()`
stores each provider credential in the operating system keychain. It
accepts native macOS, Windows, and Secret Service keyring backends, and
refuses keyring’s environment and file backends. Both stores implement
the same explicit asynchronous `CredentialStore` operations as the
memory and plaintext-file stores, so login, refresh, and provider
request translation remain unchanged.

GitHub Copilot uses device authorization and a short-lived session
credential. Z.ai keeps its Coding Plan endpoint, preserved-thinking
policy, and streamed tool-call policy in typed values. Both remain
ordinary providers to the agent loop.

## Kimi credentials

Kimi Code and Kimi Platform are different credential products. A Kimi
Code subscription uses the managed `kimi-coding` provider and may be
authorized by device login or by an explicitly supplied subscription
key. A key from `platform.kimi.ai` belongs to the `moonshotai` provider;
a key from `platform.kimi.com` belongs to `moonshotai-cn`.

``` r
kimi_code <- rho_kimi_code_provider()
kimi_platform <- rho_kimi_platform_provider()
credentials <- rho_memory_credential_store(list(
  `kimi-coding` = rho_api_key_credential(
    "kimi-coding",
    "not-a-credential"
  ),
  moonshotai = rho_api_key_credential(
    "moonshotai",
    "not-a-credential"
  )
))
kimi_models <- rho_models(
  providers = list(kimi_code, kimi_platform),
  credentials = credentials
)
selected <- list(
  rho_kimi_code_model("k3"),
  rho_kimi_platform_model("kimi-k3")
)
resolved <- lapply(selected, function(model) {
  rho_resolve_model_auth(kimi_models, model) |>
    rho_await(timeout = 1000L)
})

data.frame(
  provider = vapply(selected, function(model) model@provider, character(1)),
  configured = vapply(resolved, function(auth) auth@configured, logical(1))
)
#>      provider configured
#> 1 kimi-coding       TRUE
#> 2  moonshotai       TRUE
```

Interactive subscription login calls `rho_login_provider()` with
`RhoOAuthLogin()` and a host-supplied `LoginIO`. The device code and
approval URL arrive as a typed `RhoDeviceCodeEvent`; successful access
and refresh tokens are written through the selected `CredentialStore`.
Provider code never searches environment variables or a Kimi CLI
directory.

Provider request configuration is typed. OpenAI and Anthropic request
bodies are reduced from S7 sections for tools, generation controls,
caching, and reasoning. Codex defaults are methods on
`OpenAICodexResponsesModel`; Anthropic thinking, temperature, cache, and
tool-input behavior comes from a typed model capability profile.

Continue with the
[`rho.agent`](https://rgenomicsetl.github.io/Rho/rho.agent/) loop, or
see the [`rho.ai`
reference](https://rgenomicsetl.github.io/Rho/rho.ai/reference/).
