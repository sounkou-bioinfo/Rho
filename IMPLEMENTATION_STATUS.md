# Implementation status

This workspace contains package code, S7 classes and generics, async task and
stream contracts, nanonext HTTP adapters, mirai task adapters, graphics artifact
rendering, Rmd-driven tinytest specs, and provider request builders. Package API
documentation and namespaces are generated from roxygen2 tags. Air is the
authoritative formatter; the local verified version is 0.10.0.

All thirteen source packages are versioned `0.0.1.9000`, build from tarballs, and
report `Status: OK` under `R CMD check --no-manual` with R 4.6.0 on Linux. The check driver treats every
NOTE, WARNING, or ERROR as a failed monorepo gate. This establishes package
health; it does not claim provider or Pi behavioral parity.

Verified executable behavior now includes typed assistant events, repeated agent
turns, awaited listeners, steering/follow-up machinery, cancellation, typed
per-tool overlap requirements, concurrent task joining with source-order
results, real parallel mirai workers, cross-platform resolution of an actual
Bash executable, shell execution in mirai workers, isolated R expression
evaluation, and an opt-in stateful current-session R evaluator. Provider request
builders require explicit resolved `RhoModelAuth`; they do not read API keys
from process-global environment variables. Successful login and refresh values
can be retained by the process-scoped memory store or an explicitly selected,
owner-readable JSON store; both implement the same serialized credential
protocol. JSON parsing and serialization use `yyjsonr` throughout.
Semantic operations are planned separately from executable tools. OpenAI and
Anthropic web search use typed, catalog-backed provider bindings, normalize
provider activity as content, and reject unbound operations at request
translation. R expression evaluators use the same binding protocol.
Task continuations propagate cancellation to their active child. Task groups
cancel their children when cancelled or rejected, races cancel losing tasks,
and deadlines cancel their source. Derived streams preserve timeout and close
semantics, and stream collection applies one total deadline. A serial task queue
orders asynchronous mutations without blocking the R event loop or allowing a
cancelled queued entry to cancel active work. Extension handlers, provider
completion, credential refresh, and bio resolution compose tasks directly;
none performs an internal blocking wait.

Agent provider context is projected from message, compaction, and exclusion
entries held in memory. Compaction has manual and threshold triggers, open
policy and compactor methods, typed successful skips and operational failures,
lifecycle events, and one retry for typed provider input-limit values.
The HTTP stream retains a configurable bounded body for non-success responses so
provider adapters can classify structured wire errors without matching message
text.

Known incomplete work, stated directly:

- `rho.ai::rho_faux_provider()` is the deterministic provider used by tests.
- OpenAI Responses/Codex and Anthropic Messages have typed request and event
  protocols with end-to-end agent fixtures. Ollama still needs normalized NDJSON
  decoding. External-account checks remain recorded in the parity ledger.
- Z.ai authentication is explicitly API-key based. Its
  [documented API surface](https://docs.z.ai/guides/develop/http/introduction)
  offers API-key and JWT bearer authentication, not an OAuth device grant;
  requesting OAuth therefore resolves to a typed unsupported login-method value
  without prompting or issuing a network request.
- `rho.http::rho_sse_connect()` opens the response with the pinned nanonext
  `ncurl_stream_aio()` fork and incrementally decodes arbitrary body chunks. The
  transport remains pinned while
  [nanonext issue #329](https://github.com/r-lib/nanonext/issues/329) establishes
  the upstream API; replacing the pin will require the same receive,
  cancellation, completion, and close semantics.
- `rho.http.httr2` implements the same complete-request and incremental-body
  contract with worker-owned httr2 connections. Its fixtures verify response
  heads, incremental SSE delivery, completion, and cancellation without making
  provider code depend on httr2.
- Provider turns select typed SSE, WebSocket, cached-WebSocket, or embedded
  strategies before opening a normalized assistant-event stream. OpenAI Codex
  implements one-shot `response.create` WebSocket execution with the nanonext
  WebSocket client and the same event decoder as SSE. Cached connection reuse
  remains an explicit unsupported strategy until its lifecycle and fixtures
  exist. Embedded providers run through an explicit executor that returns a
  stream or a task resolving to one.
- `rho.duckdb` has a conservative read-only SQL guard; production hardening should add a parser-backed guard before enabling untrusted SQL.
- The Bash tool currently returns complete combined output. Pi-equivalent
  incremental output updates, bounded tail retention, and persisted full-output
  artifacts remain explicit coding-agent parity work.
- `RhoMiraiExpressionEvaluator` gives isolated worker evaluation.
  `RhoCurrentSessionREvaluator` preserves state only in the environment supplied
  by its caller and requires exclusive execution.
- `rho_task_from_function()` defers an R closure but does not move blocking work
  out of the main R process. Credential-file reads, coding filesystem tools, and
  DuckDB calls still need explicit compute bindings where they may block.
- Agent session entries have no durable store, replay, or crash recovery, and
  streaming message updates still replace their in-memory entry.
- Graphics, tool output, and bio resources do not yet share an artifact store.
- `rho.compute` does not yet model pool lifecycle, placement, affinity, bounded
  queues, or remote execution receipts.

The parity ledger records provider and agent-core behavior. It is not a claim
that durable storage, execution placement, coding tools, or the downstream bio
agent are complete.
