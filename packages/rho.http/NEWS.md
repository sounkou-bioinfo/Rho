# rho.http 0.0.1.9000

- Adds the experimental typed HTTP and SSE contracts backed by nanonext,
  including incremental response streaming.
- Preserves a configurable, bounded response body on non-success stream status
  values so provider adapters can decode structured errors asynchronously.
