# Current synthesis

Rho is exploring one idea: an agent runtime should close over explicit
capabilities without fixing where the model, worker, session, or scientific
data lives. The current synthesis is not a frozen API. It is the smallest set
of distinctions that has survived the provider implementations in Rho and the
local, remote, recursive, and multi-agent compositions exercised by
`pi-bio-agent`.

## The distinctions that remain

Five decisions are independent:

1. A session journal orders typed entries and records identity, lineage, and
   committed progress. Its authority is logical, not necessarily a local file.
2. A resolver turns a serializable virtual resource into a typed handle and a
   receipt. The binding that performs the effect is injected by the host.
3. Content-addressed storage retains immutable bytes. It establishes byte
   identity, not freshness, truth, scheduling, or ownership of mutable state.
4. A coordination surface carries changing facts such as jobs, leases,
   blackboard notes, and observations. An environment, SQL connection, or NNG
   service may implement it.
5. An execution binding decides where work runs. The current R session, a
   mirai worker, a persistent process, a recursive agent, an embedded model,
   and a remote NNG endpoint are placements of work rather than different
   agent loops.

These ports are expressed as ordinary S7 generics and methods. A consuming
package may collect the generics it needs into a small structural `s7contract`
interface. The interface does not become a backend superclass, and an explicit
trait is introduced only when opt-in conformance, shared defaults, or associated
metadata has a concrete consumer. Field invariants remain S7 properties rather
than helper predicates that reopen an already validated object.

These capabilities may be composed in one process or distributed across
machines:

```text
agent or sub-agent
  -> session journal
  -> resolver -> resource handle + receipt
  -> execution binding -> task or stream
  -> CAS references for immutable payloads
  -> blackboard or observation port for shared changing state
```

No arrow requires a filesystem. A coding host may use JSONL for its journal,
an R process may use environments and condition variables, a remote deployment
may put journal and coordination ownership behind NNG, and a scientific
extension may project committed entries into DuckDB. These are topology
profiles over the same contracts.

## A file store is one result, not the premise

The first durability thesis was an append-only JSONL session owned by
`rho.coding`. It is useful because it is inspectable and replayable. It shares
append-only JSONL framing with Pi, but not Pi's version-3 header and ID-linked
entry-tree schema. It is not sufficient as the architecture.

`pi-bio-agent` supplies the counterexample. Its injected `SqlConn` may be local
or owned by a ducknng service. Independent processes and remote workers share
state through that owner without sharing a file or a DuckDB instance. Its
blackboard examples also let autonomous workers discover an execution order
through shared notes rather than through one coordinator.

The synthesis is an open session-journal capability. A session handle supports
committed append, ordered reading, a cursor or watermark, and explicit
close/flush behavior. A JSONL adapter, an in-memory adapter, and an NNG-owned
adapter may implement it. Extensions receive the handle and committed
watermark, not a path. A full snapshot is an operation a journal may provide,
not the only way to consume it.

The first executable slice keeps the interface narrower than that destination:
compare-and-append and full snapshot are the methods pulled by the current
agent and tests. The in-memory and JSONL implementations return typed commit
positions and reject stale positions before mutation. Session nodes retain
parent identity; explicit leaf movements select a branch; trajectory projection
reconstructs one root-to-leaf conversation. JSONL replay rebuilds that
projection after restart from semantic records, independent of S7
package and class names, and rejects a partial final record rather than guessing
at recovery. An assistant partial remains in the active turn until its
terminal value commits, and reset appends a typed entry rather than erasing
history. Storage synchronization, subscription, and remote cursors enter only
with their corresponding topology fixtures.

Large immutable entry payloads may move to CAS while the journal retains their
typed references. The journal itself is not CAS: ordering, branching,
compaction, cancellation, and shutdown are mutable lifecycle facts.

The journal is also not authored memory. A memory write appends a temporal,
attributed observation through an explicit coordination or observation port;
the session records the tool call and its receipt. Prompt-time memory is a
bounded projection of those observations. The host's base system prompt,
extension orientation, a memory-index layer, and a recalled note have different
authority and lifecycles and must not collapse into one mutable string. Full
note bodies enter context through explicit recall, while a dynamic index layer
records its as-of instant and source-revision digest. The agent-policy generic
is the current composition point; memory storage and retrieval policy remain
downstream.

The prompt order is least volatile first: base prompt, stable extension
orientation, then a memory index pinned to an explicit revision set. Rendering
of that prefix is canonical and excludes changing receipts or timestamps.
Agent-authored writes become visible at an explicit refresh rather than
rewriting the active run's prefix. Recalled note bodies appear late as tool
results. Provider methods may lower this structure to automatic prefix caching
or explicit cache-control blocks without changing which memory is visible.

## Lazy resources without hidden effects

A virtual resource is a recipe, not its materialized value. This fits R's lazy
evaluation directly: a promise can retain the resource specification and its
explicit resolution context until a consumer needs the handle. The effect of
forcing it must still be visible. Resolution returns `RhoTask`; an active
binding must not silently wait for network, compute, or storage.

The durable side remains data. A resource specification, quoted call, or
declarative R expression can be inspected, validated, hashed, and replayed.
The executable resolver is a closure or S7 method carrying injected HTTP, SQL,
CAS, credentials, and compute capabilities. Arbitrary captured environments do
not become durable resource identity.

Per-resolution memoization and content identity are also different. A promise
may avoid repeating work in one R context. CAS may identify bytes across
contexts. Source version, ETag, release, or another receipt decides whether a
previous materialization is current.

## Multi-agent and recursive execution

Sub-agents do not require a second agent substrate. A worker binding may invoke
another Rho agent, an embedded model, a mirai process, or a remote service. The
invocation carries typed parentage, budget, cancellation lineage, and a bounded
access list. Its result is an ordinary task whose durable products are handles,
receipts, notes, and CAS references.

The Fugu-shaped composition in `pi-bio-agent` is the important constraint:
each worker receives only the upstream notes and resources named by its access
list. Workers may all start concurrently, await their dependencies on a shared
blackboard, and publish their own results. Topological order then emerges from
the data dependencies. Rho should be able to express both this decentralized
shape and a central scaffold executor without making either one the agent
loop.

A recursive model call follows the same rule. Recursion is an execution
binding, not permission to copy an unbounded parent transcript into another
context. The host chooses the model, stopping rule, budget, placement, and
shared capabilities.

## What this does not resolve

- It does not select JSONL, DuckDB, or an NNG service as the universal session
  implementation.
- It does not turn CAS into a queue, lease service, blackboard, or freshness
  oracle.
- It does not add a multi-agent scheduler to `rho.agent`.
- It does not duplicate `targets`. A `targets` or `crew` adapter may implement
  deterministic build and worker placement where those semantics fit. Dynamic
  conversation, leases, and shared observations remain separate concerns.
- It does not place bioinformatics policy in Rho core. `rho.bio.agent` remains
  a consumer that may combine resolvers, CAS, DuckDB, NNG, and agent lifecycle.

## The next contradictions to push

1. Exercise the journal contract through an NNG-owned service, then run the same
   lifecycle fixture against memory, JSONL, and NNG before choosing its final
   method set.
2. Express a bounded recursive Rho worker and a blackboard-driven diamond with
   the same execution and resource handles.
3. Make resolver forcing lazy within R while keeping every effect asynchronous
   and cancellation-aware.
4. Put a large tool result in CAS, retain only its typed reference in the
   journal, and rebuild a downstream DuckDB projection from committed entries.
5. Compare a `targets`/`crew` execution binding with the native task and remote
   NNG bindings on one reproducible scientific operation.

An abstraction enters core only after these exercises require the same motion.
While every consumer is in the monorepo, change them together and retain only
the clearer form.

## Sources of pressure

- [`pi-bio-agent` concurrency and remote-store topologies](https://github.com/sounkou-bioinfo/pi-bio-agent/blob/main/docs/concurrency.md)
- [`pi-bio-agent` resource and resolver model](https://github.com/sounkou-bioinfo/pi-bio-agent/blob/main/docs/resources-and-tool-specs.md)
- [`pi-bio-agent` conceptual architecture](https://github.com/sounkou-bioinfo/pi-bio-agent/blob/main/docs/design.md)
- [`pi-bio-agent` refinement ledger](https://github.com/sounkou-bioinfo/pi-bio-agent/blob/main/docs/refinments.md)
