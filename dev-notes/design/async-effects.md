# Asynchronous effects

Rho is asynchronous at the effect boundary. The public result of networking,
provider execution, tools, hooks, worker evaluation, SQL, resource resolution,
graphics, credentials, and persistence is a task, stream, duplex channel, or a
typed operational value.

## Waiting and signalling

`rho_await()` is the visible synchronous boundary. CLI entry points and test
helpers may call it. Package logic does not poll with `Sys.sleep()` or grow
private timed loops. Protocol polling belongs in `rho.async`; adapters use
nanonext condition variables and deadlines.

Cancellation follows the task or stream handle into the selected backend.
Closing a stream, cancelling a pending receive, timing out an operation, and a
remote peer disappearing are distinct typed outcomes where their consequences
differ. An adapter must not turn them all into one thrown condition.

## Scheduling is not execution placement

`rho.agent` may identify independent tool calls, start their tasks, and retain
source-order results. This does not decide where R executes. The tool or
operation binding selects its evaluator:

- current-session R has an explicit environment and exclusive mutation;
- an ordinary mirai task is isolated and may execute in parallel;
- a persistent process has stated routing and lifetime;
- a remote NNG endpoint owns its process and connection lifecycle;
- an embedded provider may return a stream without HTTP.

Higher packages do not call mirai, `parallel`, or `future` directly. They submit
through `rho.compute`, which owns pool, placement, cancellation, serialization,
and receipt semantics.

## Transport responsibilities

nanonext owns NNG, asynchronous I/O, condition variables, and TLS. `rho.http`
owns request, response-head, body-stream, SSE, and WebSocket contracts. A
provider owns translation between its wire dialect and canonical assistant
events. These layers may have private parser values, but their public
boundaries do not leak transport-specific objects.

TLS configuration is an explicit nanonext value. Use its bundled mbedTLS and
in-memory certificate material; package code does not search platform CA-file
paths.

## Tests

Every asynchronous test has a finite timeout and proves the relevant order, not
only the final value. Transport fixtures cover incremental delivery, clean EOF,
malformed framing, cancellation, and connection loss. Remote execution fixtures
add admission, repeated delivery, disconnect, resumed collection, and verified
receipts.
