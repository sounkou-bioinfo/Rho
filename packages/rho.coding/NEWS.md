# rho.coding 0.0.1.9001

- Adds an open `MemoryStore` interface and typed `remember`, `recall`,
  `edit_memory`, `forget`, and history tools. The reference store retains
  attributed revisions and tombstones, rejects stale mutation, and records
  retracted links. Tool arguments are normalized into S7 command values before
  execution.
- Advances with the synchronized monorepo package release so dependent Rho
  packages resolve matching internal dependencies.
- Adds a worker-backed JSONL `SessionJournal` implementation with locked
  compare-and-append, restart replay, strict torn-tail detection, and a
  lossless semantic record codec. Stable tags and declared fields are
  mapped to current S7 values by explicit adapters; package names and reflected
  class properties are not persisted. File inspection, conflicts, lock
  failures, and commits cross the worker boundary as typed values rather than
  status strings.

# rho.coding 0.0.1.9000

- Adds experimental file, Bash, isolated-worker R, and explicitly stateful
  current-session R tools with declared execution semantics.
- Requires an actual Bash executable on every platform; absence is a typed
  shell-unavailable value rather than silent substitution with another shell.
