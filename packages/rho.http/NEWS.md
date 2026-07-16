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
