# Session and resource topologies

Durability is not synonymous with a local file. The stable questions are who
owns ordered session state, who resolves a virtual resource, where immutable
bytes live, where changing coordination facts live, and where work executes.
Those questions are independent.

## Ports

- A session journal appends typed entries and exposes identity, lineage,
  committed cursors, optional snapshots, flush, and close.
- A resolver binds a serializable virtual resource to a handle and receipt.
- CAS admits and reads immutable bytes by content identity.
- A coordination port publishes and awaits changing notes, observations, jobs,
  leases, or checkpoints.
- An execution binding returns a task or stream from local, worker, embedded,
  recursive, or remote work.

The host injects each capability. A file path, DuckDB connection, NNG socket,
mirai daemon, or remote machine is an implementation detail represented by a
typed handle, not a branch in the agent loop.

## Useful topology profiles

One R process may combine an in-memory journal, environment blackboard,
condition variables, current-session evaluation, and a local CAS. A coding
host may replace only the journal with JSONL. A multi-process deployment may
put journal and coordination ownership in one NNG service while mirai or remote
workers execute tasks. A bioinformatics extension may project committed
session entries into an independently owned DuckDB ledger.

Large immutable payloads belong in CAS with typed references in the journal or
ledger. CAS does not carry session order or mutable blackboard state. Shared
collection requires roots or leases supplied by an authority that can see the
live references.

## Authored memory and prompt composition

An agent-authored memory note is a temporal observation, not a hidden message
and not a mutation of the agent's base system prompt. The write is an ordinary
tool or operation with an explicit observation store. Its receipt connects the
session tool call, the authored revision, its source, and any typed links. The
tool result is committed to the session journal; the memory revision is owned by
the observation store. Neither store substitutes for the other.

The concrete coding-host protocol distinguishes mutation rather than hiding it
behind an upsert. `rho_remember()` creates a live slot and refuses to replace an
existing note. `rho_edit_memory()` receives a typed edit plus the expected
current revision; the shipped `RhoMemoryReplacement` stores a complete new note
and names the revision it supersedes. `rho_forget()` requires the same expected
revision and appends a tombstone. A stale request returns
`RhoMemoryConflict`. Revisions remain ordered and queryable, and every link
removed by an edit or tombstone is carried as an explicit retraction. Another
store can implement these generics without inheriting the in-memory layout.

Prompt composition has three distinct inputs:

1. The host supplies the base system prompt and its authority.
2. An extension may supply stable orientation about capabilities and operating
   rules.
3. A memory policy may select a bounded index of current note identities and
   retrieval hooks at a declared instant.

Full note bodies do not enter every prompt. The model recalls one through a
tool, graph walk, or other bounded query, and that result then becomes visible
in the session. This preserves the useful two-stage retrieval exercised by
`pi-bio-agent` without treating a complete graph neighborhood as prompt text.

Prompt composition must also preserve provider prefix caches. Layers are
ordered from least to most volatile:

1. the host base prompt;
2. stable extension orientation;
3. a memory index pinned to an explicit revision set for the session or run;
4. turn-local material.

The first three layers may form the provider's system or instruction prefix.
Their rendering is canonical: source order, separators, and text remain
byte-for-byte stable, while timestamps, receipts, and digests stay in metadata.
Agent-authored writes do not mutate the pinned index during the active run. A
host activates a new memory revision set at an explicit refresh, accepting the
corresponding cache change. Turn-local recall belongs in a tool result or other
late transcript entry, not in a rewritten system prompt.

This ordering is semantic rather than a provider flag. A provider method may
lower the same layers to automatic prefix caching, explicit cache-control
breakpoints, or no cache facility at all. Reported cache reads and writes remain
usage observations; they can verify the expected placement but never define
the memory policy.

A dynamic prompt layer needs a receipt containing its source revisions,
selection instant, ordering, limits, and rendered digest. A live-current policy
and a session-pinned policy are different implementations. Failure to obtain a
layer is a typed policy result: the host decides whether the run may continue
without it. An adapter must not silently omit memory and call that equivalent
behavior.

The first authored-memory implementation belongs to the coding host. It owns
the note schema, discovery rules, tools, and selected observation store. The
agent substrate owns only an open context-contribution generic and the typed
plan produced by composing contributions. A coding-memory object or an
extension-defined object can implement that generic through an S7 method; the
agent loop does not switch on extension names or storage types.

The existing context-transform policy is the lifecycle point at which the
contributions are awaited. It must not remain an unconstrained whole-context
replacement API. The exercised memory implementation should derive the
smaller contract: a contribution carries its authority, cache stability,
selected revisions, rendered content, and receipt. The composed plan is pinned
in the run context and is the value seen by provider lowering and context
accounting.

## Compaction and contributed context

Compaction belongs to the generic agent harness because every model-backed
agent has a finite context window. A coding host may supply a richer compactor,
but it does not own the session operation.

Compaction walks the selected session trajectory, finds a safe cut, summarizes
the older transcript, and appends a `RhoSessionCompactionEntry`. It never
deletes the original nodes. Future provider context projects the compaction
summary, the retained recent nodes, and later descendants. Moving to an
ancestor branch naturally removes a compaction entry that is not on that path.

Contributed context is not part of the text selected for summarization. The
base prompt, extension orientation, and pinned memory index remain unchanged;
recalled note bodies that appeared as tool results are ordinary transcript and
may be summarized. Their durable authored revisions remain in the observation
store, and the original tool calls and receipts remain in the journal.

The effective context budget must nevertheless include every contribution,
tool definition, provider operation, and transcript node. A provider usage
observation is reusable for later accounting only when it identifies the same
pinned context-plan revision. After a memory refresh, tool-plan change, model
change, or compaction, accounting either uses usage reported for the new plan or
estimates the complete plan. It must not combine an old provider count with a
new prefix.

A provider-native compaction method and a generated-summary compactor are
implementations of the same compactor generic. Both must return a semantic
compaction result that can be committed to the session. An opaque provider
handle may accompany that result as provider-specific detail; it cannot replace
the durable summary and cut identity.

## Sub-agents and recursive models

A sub-agent is an execution binding of the same Rho agent substrate. It carries
typed parentage, budget, cancellation lineage, capabilities, and a bounded
access list. It does not inherit ambient credentials, files, stores, or the
whole parent transcript.

A Fugu-shaped scaffold can launch all workers and let each await its declared
upstream notes on a blackboard. A central executor can walk the same dependency
declarations. Neither topology belongs in `rho.agent`; both consume the same
resource, execution, and coordination ports.

A recursive LLM call is the same composition with another model binding. The
host chooses stopping rules and placement. Durable output returns through
handles, receipts, notes, session lineage, and CAS references.

## Lazy R surface

R promises can defer a virtual resource until a consumer needs it. The promise
contains the specification and explicit resolution context; forcing returns a
task and never blocks invisibly. Active bindings may expose a handle or task but
must not call `rho_await()`.

Quoted calls can describe computation when their arguments and authority are
explicit. `codetools` inspection can discover free variables before admission.
The runtime closure that binds a resolver or evaluator remains separate from
the durable language object.

## Current evidence and pressure

The concrete NNG, blackboard, remote-worker, resolver, and CAS counterexamples
come from [`pi-bio-agent`](https://github.com/sounkou-bioinfo/pi-bio-agent), in
particular its concurrency, resource, and conceptual-design notes. Rho's current
conclusions are in [Current synthesis](../../docs/synthesis.md); the exercises
that may change them are in [Refinements](../../docs/refinements.md).
