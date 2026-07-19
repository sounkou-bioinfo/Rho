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
