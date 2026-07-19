# rho.http.httr2 0.0.1.9001

- Gives the worker transport contract a finite 20-second cold-worker deadline
  in place of a CI-sensitive five-second deadline, with an explicit scoped
  mirai worker pool rather than an implicit ephemeral worker.

# rho.http.httr2 0.0.1.9000

- Implements the `rho.http` client contract with worker-owned httr2
  connections and typed NNG response messages.
- Keeps response-head waits and body reads outside the calling R process while
  preserving incremental delivery, backpressure, timeout, close, and
  cancellation semantics.
- Drains body bytes already buffered by curl before waiting on file descriptors,
  preserving one-byte reads and other small chunk sizes.
- Applies request timeout to complete requests while stream opening and each
  body receive retain their separate task deadlines; a long-lived stream no
  longer inherits the response-head deadline as its total lifetime.
- Preserves response-header names when removing the `httr2_headers` class.
- Passes the shared raw-peer checks for close-delimited bodies and truncated
  `Content-Length` responses.
