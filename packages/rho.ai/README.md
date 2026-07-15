
# rho.ai

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

[`rho.ai`](https://sounkou-bioinfo.github.io/Rho/rho.ai/) defines the
provider surface shared by the rest of [Rho](../../README.md): typed
messages and content, model capabilities, tool contracts, credentials,
provider operations, and normalized assistant event streams.

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

Token accounting is normalized before it reaches the agent. Ordinary
input, cache reads, and cache writes are disjoint; reasoning is an
optional subset of output. Pricing is an S7 generic, so the catalog
supplies the common method and specialized models can define different
rules.

``` r
usage <- rho_usage(
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

GitHub Copilot uses device authorization and a short-lived session
credential. Z.ai keeps its Coding Plan endpoint, preserved-thinking
policy, and streamed tool-call policy in typed values. Both remain
ordinary providers to the agent loop.

Provider request configuration is typed. OpenAI and Anthropic request
bodies are reduced from S7 sections for tools, generation controls,
caching, and reasoning. Codex defaults are methods on
`OpenAICodexResponsesModel`; Anthropic thinking, temperature, cache, and
tool-input behavior comes from a typed model capability profile.

Continue with the [`rho.agent`](../rho.agent/README.md) loop, or see the
[`rho.ai` reference](https://sounkou-bioinfo.github.io/Rho/rho.ai/).
