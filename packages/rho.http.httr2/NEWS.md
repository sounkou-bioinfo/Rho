# rho.http.httr2 0.0.1.9000

- Implements the `rho.http` client contract with worker-owned httr2
  connections and typed NNG response messages.
- Keeps response-head waits and body reads outside the calling R process while
  preserving incremental delivery, backpressure, timeout, close, and
  cancellation semantics.
