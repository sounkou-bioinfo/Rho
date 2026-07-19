# Refinements

This is a pressure ledger, not a feature queue. A refinement enters the Rho
substrate only when a current provider, host, extension, or downstream
application cannot express the behavior through S7 dispatch, explicit
capabilities, tasks and streams, resolvers, execution bindings, session
journals, CAS references, or a coordination port.

## Current pressure

### Session ownership across topologies

The agent now closes over the structural `SessionJournal` interface. The
in-memory implementation proves compare-and-append, full snapshots, typed
journal failure, terminal-only assistant entries, and reset as an append-only
entry. An idle agent can asynchronously synchronize an existing snapshot. Its
committed process-local projection then drives context and compaction.

Compare-and-append supplies the first concurrency rule: a writer presents its
known committed position, and the journal rejects a stale position before
mutation. This prevents a process-local agent from discovering divergence only
after an external journal has already accepted its entry. Branch lineage,
incremental cursors, and durable recovery remain unproven.

A future JSONL adapter can prove local recovery but cannot by itself prove
remote ownership, concurrent readers, or sub-agent composition.

Do not make a path part of the agent contract. First exercise committed append,
ordered read, cursor/watermark, branch lineage, flush, and close through an
in-memory adapter, a JSONL adapter, and an NNG-owned adapter. Extension delivery
must carry session identity and committed position rather than inviting an
extension to inspect a file.

Evidence required: restart and torn-write fixtures for JSONL; disconnect,
duplicate-delivery, cancellation, and resumed-cursor fixtures for NNG; the same
agent and extension tests against all adapters.

Current evidence: the
[`SessionJournal` interface](https://github.com/sounkou-bioinfo/Rho/blob/main/packages/rho.agent/R/04-interfaces.R),
[in-memory implementation](https://github.com/sounkou-bioinfo/Rho/blob/main/packages/rho.agent/R/06-session.R),
and [authored journal fixture](https://github.com/sounkou-bioinfo/Rho/blob/main/packages/rho.agent/inst/tinytest/rmd/agent-loop.Rmd).

### Immutable content versus changing state

Tool output, graphics, model attachments, resource snapshots, and session
snapshots may be large immutable byte products. They fit CAS. Session ordering,
job status, leases, compaction, blackboard notes, and observation revisions do
not.

Keep CAS references in typed session or run entries. Put mutable coordination
behind its own port. Shared CAS reuse needs explicit roots or leases before
garbage collection can be claimed safe.

Evidence required: oversized tool-result round trip; downstream projection
rebuilt from journal entries and CAS bytes; concurrent read versus collection
fixture for any shared CAS implementation.

### Lazy resolver forcing

R promises and active bindings can make virtual resources natural to use, but
they can also conceal blocking I/O. A virtual resource must retain a
serializable specification and an explicit resolution context. Forcing begins
or returns a `RhoTask`; only a declared wait operation obtains the value.

The executable resolver may be an S7 method or closure over injected
capabilities. Its captured environment is not durable identity. Memoization in
one R process is not evidence that a cached materialization is current.

Evidence required: a resource referenced twice resolves once in one context;
cancellation propagates during forcing; a changed source receipt prevents stale
CAS reuse; no active binding calls `rho_await()`.

### Remote and recursive execution

Current-session R and mirai workers cover two placements. The same operation
shape should admit a persistent R kernel, a remote NNG worker, an embedded
model, or a recursively invoked Rho agent without a type switch in the agent
loop.

Recursive calls require explicit parentage, budgets, cancellation, and bounded
resource access. They do not inherit ambient credentials, files, transcript,
or stores. Remote handles need stable status and collection semantics after the
originating task object disappears.

Evidence required: local and remote execution of one quoted R operation with
the same receipt; cancellation before and after remote admission; one bounded
recursive call whose parent receives only its declared result.

### Decentralized sub-agent coordination

A central scheduler is not the only useful topology. In the `pi-bio-agent`
blackboard proof, workers start independently, wait for access-list
dependencies, and publish notes. A diamond order emerges from shared state.

Rho needs only the smallest coordination protocol demonstrated by both an
environment/condition-variable implementation and a remote SQL or NNG
implementation. Do not promote Fugu prompts, a scaffold schema, or a universal
multi-agent scheduler into core.

Evidence required: a four-worker diamond with no central topological loop;
bounded worker context; deterministic dependency receipts; failure and
cancellation propagation.

### `targets` and `crew` composition

Deterministic scientific invalidation, durable dynamic agent coordination, and
provider streaming are not one problem. Before adding a Rho scheduler or
action cache, bind one resolver or operation to `targets`/`crew` and identify
which semantics are already supplied.

Promote only a missing common contract. A target graph may own reproducible
materialization while Rho owns conversation lifecycle; mirai may serve both
through separate policies.

Evidence required: one scientific operation executed directly and through the
adapter with matching result and provenance; a written account of invalidation,
cancellation, resumption, and remote placement that names the remaining gap.

## Closed constraints

Do not reopen these without contradictory executable evidence:

- providers and the agent loop receive credentials and effects explicitly;
- effectful public APIs return tasks, streams, or typed error values;
- provider transport, model behavior, and execution placement remain separate
  dispatch questions;
- CAS identifies immutable bytes but does not establish freshness or truth;
- bioinformatics remains downstream of provider and agent semantics;
- a file-backed adapter does not make the filesystem part of an open protocol;
- recursive and multi-agent arrangements are host compositions over the same
  agent, resource, execution, and coordination contracts.

The abstractions that currently survive these pressures are summarized in
[Current synthesis](synthesis.html). Concrete delivery order remains in the
[roadmap](https://github.com/sounkou-bioinfo/Rho/blob/main/ROADMAP.md).
