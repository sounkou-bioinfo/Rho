
# Rho: async agents in modern R

<!-- badges: start -->

[![R-CMD-check](https://github.com/sounkou-bioinfo/Rho/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/sounkou-bioinfo/Rho/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**Rho is an asynchronous provider and agent runtime built from R’s own
abstractions: S7 dispatch for open protocols, nanonext for I/O, and
mirai for worker evaluation.**

An effectful operation returns a task or stream. Waiting is an explici
edge operation, so a CLI can block while a Shiny application, extension,
or another agent keeps composing work.

## An agent run (runs at render time)

The deterministic provider is the executable specification for the same
event protocol used by live providers. `rho_prompt()` returns before the
result is collected; `rho_await()` marks the blocking boundary.

``` r
library(rho.async)
library(rho.ai)
library(rho.agent)

agent <- rho_agent(
  provider = rho_faux_provider(),
  model = rho_model(provider = "faux", id = "faux")
)

run_task <- rho_prompt(agent, "hello from R")
rho_is_task(run_task)
#> [1] TRUE

run <- rho_await(run_task, timeout = 5000)
c(
  status = run@status,
  answer = run@messages[[2L]]@content[[1L]]@tex
)
#>               status               answer
#>          "completed" "faux: hello from R"
```

The transcript contains typed messages and content; the lifecycle is an
ordered sequence of typed events rather than callbacks hidden inside the
provider.

``` r
vapply(run@events, function(event) event@type, character(1))
#>  [1] "agent_start"    "turn_start"     "message_start"  "message_end"
#>  [5] "message_start"  "message_update" "message_update" "message_update"
#>  [9] "message_end"    "turn_end"       "agent_end"      "agent_settled"
```

## OpenAI Codex with explicit credentials

Live authentication is a value passed to the provider catalog. Rho does
not search environment variables or process-global credential state. The
importer accepts a Pi or Codex auth file only when its path is supplied
by the caller.

``` r
credential <- rho_load_openai_codex_credential(
  path = "/absolute/path/to/auth.json"
) |>
  rho_await(timeout = 5000)

codex <- rho_openai_codex_provider()
models <- rho_models(
  providers = list(codex),
  credentials = rho_memory_credential_store(
    list(`openai-codex` = credential)
  )
)

agent <- rho_agent(
  provider = models,
  model = rho_openai_codex_spark(),
  stream_options = list(reasoning_effort = "minimal")
)
run <- rho_prompt(agent, "Reply with exactly rho-live-ok and nothing else.") |>
  rho_await(timeout = 120000)
```

Recorded on 2026-07-14 against the live Codex endpoint:

``` tex
model: gpt-5.3-codex-spark
status: completed
answer: rho-live-ok
events: 14
```

The same probe is available as a script; it prints model, status,
answer, and event count, never credential material:

``` bash
make smoke-codex CREDENTIAL=/absolute/path/to/auth.json
```

## The packages

Rho keeps transport, provider semantics, agent policy, and applications
in separate installable packages. Each package README below contains an
example that is executed when the documentation is rendered.

| package           | role                                                                    | documentation                                                                                                  |
|-------------------|-------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| **rho.async**     | tasks, streams, cancellation, timeouts, and composition                 | [README](packages/rho.async/README.md) · [reference](https://sounkou-bioinfo.github.io/Rho/rho.async/)         |
| **rho.http**      | typed HTTP requests, nanonext transport, and SSE decoding               | [README](packages/rho.http/README.md) · [reference](https://sounkou-bioinfo.github.io/Rho/rho.http/)           |
| **rho.ai**        | messages, models, capabilities, credentials, providers, and tools       | [README](packages/rho.ai/README.md) · [reference](https://sounkou-bioinfo.github.io/Rho/rho.ai/)               |
| **rho.agent**     | multi-turn execution, tool scheduling, queues, cancellation, and events | [README](packages/rho.agent/README.md) · [reference](https://sounkou-bioinfo.github.io/Rho/rho.agent/)         |
| **rho.ext**       | asynchronous extension handlers and capability registration             | [README](packages/rho.ext/README.md) · [reference](https://sounkou-bioinfo.github.io/Rho/rho.ext/)             |
| **rho.compute**   | typed mirai expression and function-call tasks                          | [README](packages/rho.compute/README.md) · [reference](https://sounkou-bioinfo.github.io/Rho/rho.compute/)     |
| **rho.graphics**  | declared graphics devices and hashed artifacts                          | [README](packages/rho.graphics/README.md) · [reference](https://sounkou-bioinfo.github.io/Rho/rho.graphics/)   |
| **rho.coding**    | Bash, file, isolated-worker R, and explicit current-session R tools     | [README](packages/rho.coding/README.md) · [reference](https://sounkou-bioinfo.github.io/Rho/rho.coding/)       |
| **rho.bio**       | manifests, resolvers, receipts, and database-neutral SQL contracts      | [README](packages/rho.bio/README.md) · [reference](https://sounkou-bioinfo.github.io/Rho/rho.bio/)             |
| **rho.duckdb**    | DuckDB implementation of the asynchronous SQL contracts                 | [README](packages/rho.duckdb/README.md) · [reference](https://sounkou-bioinfo.github.io/Rho/rho.duckdb/)       |
| **rho.bio.agent** | bioinformatics tools registered through the extension API               | [README](packages/rho.bio.agent/README.md) · [reference](https://sounkou-bioinfo.github.io/Rho/rho.bio.agent/) |
| **rho.testkit**   | bounded assertions for asynchronous tests                               | [README](packages/rho.testkit/README.md) · [reference](https://sounkou-bioinfo.github.io/Rho/rho.testkit/)     |

Provider implementations with no independent dependency or ABI boundary
live in `rho.ai`. OpenAI, OpenAI Codex, Anthropic, Ollama, and the
deterministic faux provider therefore share one typed provider surface
without a package per API.

Bioinformatics remains downstream: `rho.bio`, `rho.duckdb`, and
`rho.bio.agent` consume the provider and agent substrate but do no
define it.

## Install and develop

Rho targets R 4.4 or newer. While the repository is private, install
from a checkout:

``` bash
git clone git@github.com:sounkou-bioinfo/Rho.gi
cd Rho
make deps
make install
```

The authored API documentation is roxygen; the authored tests are R
Markdown files under each package’s `inst/tinytest/rmd/` directory.
Generated manuals, namespaces, executable tests, and READMEs are
reproducible from their sources.

``` bash
make format       # Air
make rd           # roxygen2
make purl-tests   # Rmd tests -> executable tinytest files
make rdm          # execute and render all package READMEs
make tes
make check        # every package must report Status: OK
```

The [Pi parity ledger](docs/pi-parity.md) records behavioral contracts
and the fixtures that verify them. Public release and addition to the
[sounkou-bioinfo R-universe](https://sounkou-bioinfo.r-universe.dev)
follow green package checks, live-provider probes, documentation, and
secret scanning.

## License

MIT.
