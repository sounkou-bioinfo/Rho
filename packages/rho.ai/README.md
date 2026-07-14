
# rho.ai

[`rho.ai`](https://sounkou-bioinfo.github.io/Rho/rho.ai/) defines the
provider surface shared by the rest of [Rho](../../README.md): typed
messages and content, model capabilities, tool contracts, credentials,
provider operations, and normalized assistant event streams.

## One stream protocol (runs at render time)

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
events[[length(events)]]@message@content[[1L]]@tex
#> [1] "faux: hello"
```

The faux provider is deterministic, but it emits the same typed events
as the OpenAI, OpenAI Codex, Anthropic, and Ollama implementations.
Capabilities are queried through values and generics instead of
provider-name conditionals:

``` r
spark <- rho_openai_codex_spark()
list(
  text_input = rho_model_supports_input(spark, "text"),
  image_input = rho_model_supports_input(spark, "image"),
  thinking = rho_supported_thinking_levels(spark)
)
#> $text_inpu
#> [1] TRUE
#>
#> $image_inpu
#> [1] FALSE
#>
#> $thinking
#> [1] "off"     "minimal" "low"     "medium"  "high"    "xhigh"
```

Credentials are explicit `RhoCredential` values resolved by a
`CredentialStore`. A request translator receives typed request auth;
provider code does not discover secrets through environment variables.

Continue with the [`rho.agent`](../rho.agent/README.md) loop, or see the
[`rho.ai` reference](https://sounkou-bioinfo.github.io/Rho/rho.ai/).
