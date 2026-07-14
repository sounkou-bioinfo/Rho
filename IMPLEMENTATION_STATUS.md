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
- OpenAI Responses/Codex wire events have a typed decoder and the root README
  exercises an agent with Spark. Anthropic and Ollama request surfaces still need
  live streaming fixtures before their adapters can be called verified.
- `rho.http::rho_sse_connect()` opens the response with the pinned nanonext
  `ncurl_stream_aio()` fork and incrementally decodes arbitrary body chunks. The
  transport remains pinned until the primitive is available from an upstream
  nanonext release.
- `rho.duckdb` has a conservative read-only SQL guard; production hardening should add a parser-backed guard before enabling untrusted SQL.
- The Bash tool currently returns complete combined output. Pi-equivalent
  incremental output updates, bounded tail retention, and persisted full-output
  artifacts remain explicit coding-agent parity work.
- `RhoMiraiExpressionEvaluator` gives isolated worker evaluation.
  `RhoCurrentSessionREvaluator` preserves state only in the environment supplied
  by its caller and requires exclusive execution.

The repository stays private until the parity ledger, package checks, live
provider checks, generated documentation, and secret scan pass. Public
release is followed by registration in
`sounkou-bioinfo/sounkou-bioinfo.r-universe.dev`.
