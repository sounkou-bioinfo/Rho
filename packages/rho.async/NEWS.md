# rho.async 0.0.1.9000

- Adds experimental task, stream, cancellation, timeout, and composition
  contracts over nanonext asynchronous primitives.
- Propagates cancellation through task continuations to their source task.
- Adds cancellation-aware task groups, `rho_race()`, source-cancelling
  deadlines, global stream collection deadlines, and timeout propagation
  through derived streams.
- Adds a cancellable serial task queue whose queued entries do not cancel
  active work.
