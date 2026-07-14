# Implementation status

This workspace contains package code, S7 classes and generics, async task and
stream contracts, nanonext HTTP adapters, mirai task adapters, graphics artifact
rendering, Rmd-driven tinytest specs, and provider request builders. Package API
documentation and namespaces are generated from roxygen2 tags. Air is the
authoritative formatter; the local verified version is 0.10.0.

All twelve source packages build from tarballs and report `Status: OK` under
`R CMD check --no-manual` with R 4.6.0 on Linux. The check driver treats every
NOTE, WARNING, or ERROR as a failed monorepo gate. This establishes package
health; it does not claim provider or Pi behavioral parity.

Verified executable behavior now includes typed assistant events, repeated agent
turns, awaited listeners, steering/follow-up machinery, cancellation, typed
per-tool overlap requirements, concurrent task joining with source-order
results, real parallel mirai workers, cross-platform Bash resolution, shell
execution in mirai workers, isolated R expression evaluation, and an opt-in
stateful current-session R evaluator. Provider request builders require explicit
resolved `RhoModelAuth`; they do not read API keys from process-global
environment variables. JSON parsing and serialization use `yyjsonr` throughout.

Known boundaries that are deliberately explicit rather than faked:

- `rho.ai::rho_faux_provider()` is the deterministic provider used by tests.
- OpenAI Responses/Codex wire events have a typed decoder and a live Spark smoke
  test has succeeded locally. Anthropic and Ollama request surfaces still need
  live streaming fixtures before their adapters can be called verified.
- `rho.http::rho_sse_connect()` currently resolves an HTTP response body into an SSE event stream using nanonext `ncurl_aio`; it is correct for complete SSE bodies and test fixtures. A chunk-by-chunk client stream backend should be added when nanonext exposes or Rho implements that transport cleanly.
- `rho.duckdb` has a conservative read-only SQL guard; production hardening should add a parser-backed guard before enabling untrusted SQL.
- The Bash tool currently returns complete combined output. Pi-equivalent
  incremental output updates, bounded tail retention, and persisted full-output
  artifacts remain explicit coding-agent parity work.
- `RhoMiraiExpressionEvaluator` is isolated. Persistent daemon-global R state is
  not exposed as a REPL until routing and lifetime are represented explicitly.

The repository stays private until the parity ledger, package checks, live
provider smoke tests, generated documentation, and secret scan pass. Public
release is followed by registration in
`sounkou-bioinfo/sounkou-bioinfo.r-universe.dev`.
