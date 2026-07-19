# rho.agent 0.0.1.9001

- Uses only counted usage observations when projecting context usage; an
  unavailable provider observation is estimated from message content instead.

# rho.agent 0.0.1.9000

- Gives the provider-operation agent-loop fixture enough time on slower build
  hosts while retaining an explicit test timeout.

- Adds the experimental asynchronous multi-turn agent loop, ordered lifecycle
  events, tool scheduling, queues, cancellation, and policy generics.
- Adds append-only session entries, projected provider context, semantic
  compaction, typed skip and failure outcomes, threshold compaction, and one
  provider-input recovery attempt selected by an open S7 generic.
