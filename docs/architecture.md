# Architecture

Rho has an acyclic package graph and asynchronous effects.

```text
rho.async -> rho.http -> rho.ai -> rho.agent -> rho.ext -> rho.coding
rho.async -> rho.compute -> rho.graphics
rho.http + rho.compute -> rho.http.httr2
rho.async -> rho.bio -> rho.duckdb -> rho.bio.agent
```

The central rule is that effectful public APIs return `RhoTask` or `RhoStream`.
Synchronous waiting is explicit through `rho.async::rho_await()` and test helpers.

## Tool scheduling and execution

Agent scheduling does not decide where code runs. `rho.agent` opens tool tasks,
joins them, emits lifecycle events, and returns results in source order. Each
`ToolSpec` carries a typed overlap value:

- `ToolMayOverlap` permits the agent to start the call beside other calls.
- `ToolRequiresExclusiveExecution` makes the batch serial.

`rho_tool_overlap()` is a generic, so a specialized tool may derive the value
from the call or its context. A tool then chooses the backend that realizes its
task. Network tools may return nanonext-backed tasks, CPU or blocking R work may
return `rho.compute` mirai tasks, and already available values may return
immediate tasks. `rho.agent` neither imports mirai nor moves work between
backends implicitly.

The distinction matters: two main-session tasks can be concurrent without
executing R bytecode in parallel. True R-process parallelism comes from the
tool-selected mirai compute profile. Compute-profile size and placement remain
deployment decisions.

Worker selection is represented by values rather than inferred from an R
expression. `RhoComputeExpressionSpec` carries quoted code plus explicitly named
arguments. `RhoComputeCallSpec` carries a worker function plus explicitly named
arguments. `rho_submit_compute()` dispatches on both the backend and the spec;
higher packages use `rho_mirai_eval()` or `rho_mirai_call()` and do not inject
temporary globals into a worker expression. Results cross the mirai promise
bridge in a success envelope so language objects remain values, while worker
failures resolve to typed `RhoComputeErrorValue` objects.

## Shell and R evaluation

The coding shell keeps Bash-compatible command semantics on every platform.
On Unix it selects Bash when available and records an explicit POSIX-shell
alternative when Bash is absent. On Windows it selects a configured Bash, Git
Bash, or Bash found on `PATH`; it does not reinterpret a Bash command through
`cmd.exe`. Legacy WSL Bash uses stdin command transport. Shell processes run in
a mirai worker through `rho.compute`, with `processx` handling argument passing,
timeouts, UTF-8 output, and process-tree cleanup.

R evaluation has two deliberately different values:

- `RhoMiraiExpressionEvaluator` evaluates an isolated expression asynchronously
  and may run in parallel according to its compute profile.
- `RhoCurrentSessionREvaluator` evaluates in an explicitly supplied environment,
  preserves that environment across calls, and requires exclusive scheduling.

A pool of interchangeable mirai daemons is not a persistent REPL. Persistent
daemon-global setup uses a separate mirai contract and must state its routing
and lifetime semantics.

## Open provider protocols

Rho normalizes requests for behavior, not provider wire formats. Stable questions
are S7 generics with broad, explicit default methods. Provider/API classes add
narrower methods only for verified behavior, and extension packages may add still
narrower methods without editing the agent loop.

HTTP implementation and provider-turn execution are separate protocols.
`rho.http::HttpClient` owns complete HTTP requests and incremental response
bodies; nanonext and the worker-owned httr2 adapter implement the same methods.
`rho.ai::rho_stream()` owns the normalized assistant-event result. Its default
method selects a typed `ProviderTransport` implemented by both the provider and
model, then dispatches through `rho_open_provider_transport()`. SSE, WebSocket,
cached WebSocket, and embedded execution are distinct values. An in-process model
uses `RhoEmbeddedProvider` with an explicit `EmbeddedExecutor`; it does not
construct an HTTP request. An executor returns a `RhoStream` or a
`RhoTask<RhoStream>`, so an embedded R object, a native engine, and a remote
relay can share provider semantics without sharing an I/O implementation.
The selection is a typed value with a reason, while an unavailable explicit
choice resolves through `ProviderTransportUnsupported`.

Provider token reports become `Usage` values before entering the agent. Input,
cache-read, cache-write, and output counts are disjoint; reasoning and one-hour
cache writes are typed subsets of their parent counts. `rho_price_usage()` applies
the model catalog's component rates and long-context tiers through S7 dispatch.

Provider request bodies are composed from `ProviderRequestSection` values, with
OpenAI and Anthropic subclasses for their wire dialects. The standard OpenAI,
Codex, and Copilot model subclasses select OpenAI sections through
`rho_openai_request_sections()`; Anthropic models select sections through
`rho_anthropic_request_sections()`. Wire names are emitted only by
`rho_request_fields()` methods, so extensions can replace one policy or append
a section without copying a complete request builder.

`AnthropicMessagesEndpoint` separates Messages semantics from endpoint auth and
transport. Anthropic and GitHub Copilot share content translation, request
sections, and typed stream reduction while implementing different endpoint
methods. Model capability profiles select adaptive or budget thinking,
temperature acceptance, cache retention, tool-input streaming, and hosted
operation dialects without request-time model-name tests.

`ToolSpec` and `RhoOperation` are deliberately different. A `ToolSpec` names
host code that the agent may execute after receiving a `ToolCall`.
`RhoOperation` states a semantic capability requested by the conversation.
`rho_plan_operations()` asks a handler to bind each operation for the selected
model; every `RhoOperationBinding` records that handler and the reason for its
selection. An OpenAI or Anthropic web-search binding is translated into a
provider-hosted tool declaration. Its response becomes typed content and
operation lifecycle events, never an executable local `ToolCall`.

Bindings are the override point. A context may carry a binding supplied by an
extension or host, while an unbound operation must pass through
`rho_plan_operations()`. Low-level request translation returns a typed
configuration error when handed an unbound semantic operation. The same
protocol applies outside providers: `rho.coding` binds an `RhoRExpression` to a
current-session or mirai evaluator, and a remote NNG evaluator can implement
the same methods without changing the agent loop.

For dynamic tools, `ToolResultMessage@added_tool_names` is the portable transcript
fact. `rho_plan_tools()` returns one of these successful plans:

- `RhoFullToolPlacement`: advertise every active definition at the request
  request and state whether that may replace the cached prefix.
- `RhoOpenAIToolSearchPlacement`: put newly activated definitions into completed
  client tool-search items at the recorded tool-result position.
- `RhoAnthropicToolReferencePlacement`: defer definitions and expose references at
  the recorded tool-result position.

The complete-placement plan is not an error: all requested tools remain available.
Only the cache optimization differs. Provider support is queried through typed
operation values and `rho_provider_support()` instead of a universal boolean map.

## Session compaction

Session compaction belongs to the agent harness. A provider-native compaction
primitive is one possible binding of that semantic operation, not the owner of
the policy.

`rho.ai` defines `RhoCompactionOperation`, the provider-binding point, and typed
unsupported defaults. `rho.agent` owns the append-only session, stable cut point,
semantic summary, durable compaction entry, threshold trigger, provider-input
recovery, and before/after policy methods. An application may provide another
compactor or specialize the public generics without replacing the loop. A
provider-encrypted item is an input optimization, not a durable semantic summary.

## Authentication

Credentials are effects supplied through an explicit `CredentialStore`; provider
implementations do not read API keys from environment variables. Login and token
refresh are open auth generics. Resolution produces a typed `RhoModelAuth` value
that is passed to request translation in `options$auth`. A provider implementation
contains transport configuration, never ambient process credentials. Concurrent
refresh is serialized by the credential-store queue and publishes the refreshed
credential back to that store before another request resolves auth.

The process-scoped memory store and durable file store implement the same
protocol. The file store is opt-in through an explicit path, persists login and
rotated refresh credentials, replaces its JSON document, and requests `0600`
permissions. Its payload is not encrypted; an encrypted store can implement the
same protocol without changing providers or the agent loop.

## Interactive safe points and presentation

The optional `rho.async` task-callback bridge drains already-ready
`later`/promise notifications after top-level R expressions. It never waits and
is not registered during package loading. Native graphics windows, terminal
renderers, and desktop toolkits own their presentation lifecycle without taking
over provider or agent scheduling.

Candidate R-native presentation and secure-storage components, together with
their package responsibilities, are recorded in
[R-native interaction and secure storage](r-native-runtime.md).

## Publication gate

Development remains private while provider and agent parity is incomplete. The
repository becomes public only after the parity ledger is satisfied, every
package installs and checks on supported platforms, live provider checks
pass without stored credentials, generated documentation is current, and a
secret scan is clean. The public repository can then be added to
`sounkou-bioinfo/sounkou-bioinfo.r-universe.dev`; r-universe inclusion is a
release consequence, not a substitute for those checks.
