# rho.coding 0.0.1.9001

- Advances with the synchronized monorepo package release so dependent Rho
  packages resolve matching internal dependencies.
- Adds a worker-backed JSONL `SessionJournal` implementation with locked
  compare-and-append, restart replay, strict torn-tail detection, and a
  lossless codec derived from the reachable S7 session classes.

# rho.coding 0.0.1.9000

- Adds experimental file, Bash, isolated-worker R, and explicitly stateful
  current-session R tools with declared execution semantics.
- Requires an actual Bash executable on every platform; absence is a typed
  shell-unavailable value rather than silent substitution with another shell.
