# Rho roadmap

Rho has a working provider and agent substrate. The next work is to make its
execution, storage, and transport semantics as complete as its provider surface.
This roadmap orders that work; [the parity ledger](docs/pi-parity.md) records
only behavior already supported by an executable fixture.

## Current foundation

- Thirteen packages share version `0.0.1.9000` and pass the monorepo package
  checks.
- `rho.async`, `rho.http`, `rho.ai`, and `rho.agent` provide the task, stream,
  provider, and multi-turn agent contracts.
- OpenAI, OpenAI Codex, GitHub Copilot, Anthropic, Z.ai, Kimi Code, Kimi
  Platform, Ollama, and the deterministic faux provider use the same normalized
  assistant-event stream.
- HTTP clients dispatch through `rho_http_send()` and
  `rho_http_open_stream()`. The nanonext and httr2 implementations can be
  selected without changing provider code.
- Typed operations separate a semantic request from its local, provider-hosted,
  extension, worker, or remote implementation.

## 1. Publication integrity

- Register `rho.http.httr2` beside the other twelve packages in the
  sounkou-bioinfo R-universe manifest, then require successful builds in
  dependency order.
- Keep every package README, reference site, `NEWS.md`, lifecycle badge, and
  package link reproducible from the checkout.
- Make the package check, publication check, parity ledger, generated-file
  check, model-catalog check, and secret scan required release evidence.
- Correct any ledger wording that implies durable state before a durable session
  store exists. In-memory compaction and durable replay are different features.

## 2. Transport correctness

- Continue using the nanonext fork while
  [nanonext issue #329](https://github.com/r-lib/nanonext/issues/329) defines the
  upstream incremental-response API. The proposed shape and the remaining
  questions are recorded in
  [the HTTP streaming design note](docs/nanonext-http-streaming.md).
- Preserve `rho.http.httr2` as an independent implementation of the same HTTP
  client interface. It is also the executable alternative when opening a
  nanonext response remains synchronous.
- Run one shared transport fixture suite against each HTTP implementation:
  response head before body completion, arbitrary chunk splits, fixed-length,
  chunked and connection-ended bodies, clean end-of-stream, cancellation,
  timeout, bounded error bodies, and idempotent close.
- Record whether opening a response occupies the main R process as a typed
  client capability. Returning a `RhoTask` must not conceal synchronous work.
- Implement the declared OpenAI Codex WebSocket strategies and feed their data
  into the same normalized assistant-event stream used by SSE.
- Add an embedded-provider transport for an in-process model without routing it
  through HTTP. This will exercise the distinction between provider semantics
  and wire transport.

## 3. Durable sessions and artifacts

- Define an open `RhoSessionStore` interface for appending entries, reading a
  transcript, saving checkpoints, and replaying after process failure.
- Give session entries stable identifiers and define atomic append and
  checkpoint rules before choosing a file or database implementation.
- Make compaction write an ordinary typed session entry through that interface.
  Keep provider-native compaction, extension compaction, and the default Rho
  compactor as dispatchable implementations.
- Define one artifact-store interface shared by graphics, tool output, and bio
  resources. Content hashes identify immutable bytes; metadata and provenance
  remain typed values.
- Resolve [oversized tool results](https://github.com/sounkou-bioinfo/Rho/issues/3)
  by storing the complete result and returning a bounded model-facing view with
  an artifact reference.
- Compare the resulting dependency and invalidation semantics with `targets`
  before adding a scheduler or another content-addressed store. Rho should reuse
  an R-native implementation when it already supplies the required semantics.

## 4. Compute and remote execution

- Extend `rho.compute` with explicit pool creation and shutdown, queue limits,
  worker placement, affinity, cancellation, and execution receipts.
- Let a tool or operation select current-session R, an isolated mirai worker, a
  persistent worker, or a remote NNG endpoint through typed bindings. The agent
  schedules tasks but does not choose a worker on the tool's behalf.
- Preserve source-order results while allowing genuinely independent calls to
  run concurrently.
- Move credential-file access, coding filesystem operations, and long DuckDB
  work off the main R process when their selected implementation can block.
- Add remote execution fixtures that cover disconnects, cancellation, repeated
  delivery, and receipt verification before the bio agent depends on them.

## 5. Coding-agent completeness

- Stream Bash and R tool updates, retain a bounded recent tail, and persist the
  complete output through the artifact store.
- Resolve Bash explicitly on every supported platform and report the selected
  executable. Do not translate Bash syntax into another shell language.
- Implement [portable typed text search](https://github.com/sounkou-bioinfo/Rho/issues/4)
  with a native R implementation and an explicitly selected external engine
  where available.
- Complete file, edit, search, and process tools with typed operational results,
  cancellation, size limits, and path policy supplied through tool context.
- Keep current-session R evaluation explicit and exclusive; keep ordinary
  mirai evaluation isolated. Persistent and remote R sessions become separate
  evaluator classes rather than modes encoded as strings.

## 6. Provider and agent completion

- Add native Ollama NDJSON decoding instead of relying on an SSE-shaped path.
- Exercise image input for each catalog profile that declares image support and
  reject unsupported content before request transmission.
- Complete WebSocket request reuse and cache-preserving dynamic tool changes for
  providers that declare those capabilities.
- Keep provider-hosted web search, compaction, and future operations as typed
  bindings. A host, extension, provider, or remote service may implement the
  same semantic operation through S7 methods.
- Add durable-session recovery, oversized-result continuation, and transport
  interruption to the agent fixtures.

## 7. Downstream R applications

- Finish the shared artifact layer before expanding `rho.graphics` into
  previews, comparison, alternative text, and interactive display.
- Build an R-native terminal interface as a client of agent events, not as agent
  policy. Graphics display and user input remain replaceable interfaces.
- Re-implement `pi-bio-agent` concepts only after the session, artifact,
  compute, and operation contracts above are stable. Use R-native relational
  composition, DuckDB, mirai, NNG, and `targets` where their semantics fit.
- Treat DuckDB extension ABI support as its own release concern: build against
  declared DuckDB header versions, carry documented patches only where needed,
  and test each supported ABI.

## Release evidence

A roadmap item is complete only when its public behavior has documentation and
an executable fixture. A release candidate must also satisfy:

- every package reports `Status: OK` under the supported R versions;
- the complete R-universe package set builds in dependency order;
- live account exercises and deterministic wire fixtures agree on normalized
  provider behavior;
- cancellation and end-of-stream tests pass for every advertised transport;
- session recovery and artifact integrity survive a killed process;
- generated files, documentation, model data, and repository history pass the
  publication checks.
