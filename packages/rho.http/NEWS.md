# rho.http 0.0.1.9000

- Adds the experimental typed HTTP and SSE contracts backed by nanonext,
  including incremental response streaming.
- Separates the `HttpClient` and `RhoHttpBodyStream` contracts from the built-in
  nanonext classes so another transport can implement the same generics without
  changing provider or SSE code.
- Preserves a configurable, bounded response body on non-success stream status
  values so provider adapters can decode structured errors asynchronously.
- Exercises cancellation from an SSE receive task through the nanonext HTTP
  stream and closes the connection with typed task semantics.
- Adds `rho_http_open_execution()` and typed Aio, worker, and caller-process
  values so a task cannot conceal where response-head opening runs.
- Installs one HTTP client contract exercised by both built-in implementations,
  covering fixed and chunked bodies, one-byte reads, repeated end-of-stream,
  opening and receive cancellation, timeout, bounded error bodies, and repeated
  close.
- Extends that contract with a raw HTTP peer: close-delimited bodies end
  normally, while a connection ending before the declared `Content-Length`
  yields a typed transport error without losing bytes already delivered.
