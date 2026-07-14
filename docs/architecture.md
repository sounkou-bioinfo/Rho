# Architecture

Rho is organized around acyclic package boundaries and async effects.

```text
rho.async -> rho.http -> rho.ai -> rho.agent -> rho.ext -> rho.coding
rho.async -> rho.compute -> rho.graphics
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

The worker boundary is represented by values rather than inferred from an R
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

Provider token reports become `Usage` values before entering the agent. Input,
cache-read, cache-write, and output counts are disjoint; reasoning and one-hour
cache writes are typed subsets of their parent counts. `rho_price_usage()` applies
the model catalog's component rates and long-context tiers through S7 dispatch.

OpenAI Responses request bodies are composed from `OpenAIRequestSection` values.
The standard OpenAI, Codex, and Copilot model subclasses select their sections
through `rho_openai_request_sections()`. Wire names are emitted only by
`rho_openai_request_fields()` methods, so extensions can replace one policy or
append a section without copying the complete request builder.

For dynamic tools, `ToolResultMessage@added_tool_names` is the portable transcript
fact. `rho_plan_tools()` returns one of these successful plans:

- `RhoFullToolPlacement`: advertise every active definition at the request
  boundary and state whether that may replace the cached prefix.
- `RhoOpenAIToolSearchPlacement`: put newly activated definitions into completed
  client tool-search items at the recorded tool-result position.
- `RhoAnthropicToolReferencePlacement`: defer definitions and expose references at
  the recorded tool-result position.

The complete-placement plan is not an error: all requested tools remain available.
Only the cache optimization differs. Provider support is queried through typed
operation values and `rho_provider_support()` instead of a universal boolean map.

## Compaction boundary

Session compaction is an agent-harness concern, not an AI-provider concern.

- `rho.ai` may expose `rho_compact_provider_input()` for a provider-native wire
  primitive such as encrypted Responses input compaction. Its broad method returns
  a typed unsupported value because no equivalent provider operation was performed.
- `rho.agent` owns the generic session preparation, cut point, summary generation,
  durable entry, overflow recovery, and before/after protocol. Its broad method is
  the working model-summary implementation.
- `rho.coding` specializes retained coding facts such as file reads and edits.
- `rho.bio.agent` specializes retained evidence such as resource receipts,
  observations, artifact identifiers, and provenance.

A provider-native encrypted item is not treated as a durable semantic summary. The
agent layer may select it as an input optimization only when its session contract
can still be satisfied.

## Authentication boundary

Credentials are effects supplied through an explicit `CredentialStore`; provider
implementations do not read API keys from environment variables. Login and token
refresh are open auth generics. Resolution produces a typed `RhoModelAuth` value
that is passed to request translation in `options$auth`. A provider implementation
contains transport configuration, never ambient process credentials. Concurrent
refresh is serialized by the credential-store gate and publishes the refreshed
credential back to that store before another request resolves auth.

## Interactive safe points and presentation

The optional `rho.async` task-callback bridge drains already-ready
`later`/promise notifications after top-level R expressions. It never waits and
is not registered during package loading. Native graphics windows, terminal
renderers, and desktop toolkits own their presentation lifecycle without taking
over provider or agent scheduling.

Candidate R-native presentation and secure-storage components, together with
their package-boundary decisions, are recorded in
[R-native interaction and secure storage](r-native-runtime.md).

## Publication gate

Development remains private while provider and agent parity is incomplete. The
repository becomes public only after the parity ledger is satisfied, every
package installs and checks on supported platforms, live provider checks
pass without stored credentials, generated documentation is current, and a
secret scan is clean. The public repository can then be added to
`sounkou-bioinfo/sounkou-bioinfo.r-universe.dev`; r-universe inclusion is a
release consequence, not a substitute for those checks.
