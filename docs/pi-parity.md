# pi-mono parity ledger

Reference: `earendil-works/pi` commit `dcfe36c79702ec240b146c45f167ab75ecddd205`
from 2026-07-14. This file records behavioral contracts, not TypeScript shapes.

Status values are `missing`, `implemented`, and `verified`. Only an executable
fixture or integration test moves a row to `verified`.

| Area | Contract | Status |
|---|---|---|
| Provider stream | start, text, thinking, tool-call, done, and error events with partial messages | verified |
| Messages | user, assistant, and tool result content with text, image, thinking, and tools | verified |
| Usage | input, output, cache read/write, reasoning, totals, and component costs | verified |
| Models | API, provider, URL, input modes, context, output cap, costs, headers, and compatibility | verified |
| Providers | catalog, explicit refresh compiler, auth resolution, streaming, and completion | verified |
| Credentials | serialized read/modify/delete and refresh ownership | verified |
| Agent loop | repeated provider turns until no tools or queued messages remain | verified |
| Tool execution | validation, pre/post hooks, updates, parallel and sequential modes, source-order results | verified |
| Queues | steering and follow-up with all or one-at-a-time draining | verified |
| Cancellation | provider and tool propagation with aborted terminal messages | verified |
| Events | ordered lifecycle events with awaited stateful listeners | verified |
| State | transcript, partial message, pending calls, error, reset, continue, and idle barrier | verified |
| Provider-hosted operations | model-profiled binding, request translation, normalized content, and no local execution | verified |
| Session compaction | cut point, summary or provider binding, durable entry, overflow recovery, and lifecycle hooks | missing |

Live wire adapters are tracked separately from surface parity. An API family is
not called implemented merely because its identifier is accepted.

## Live provider probes

| Adapter | Contract | Fixture | External account | Status |
|---|---|---|---|---|
| OpenAI Codex | explicit OAuth credential import, auth resolution, Responses translation, decoding, and agent completion with `gpt-5.3-codex-spark` | `codex-agent` in `README.Rmd` | completed | verified |
| GitHub Copilot | device authorization, session-token refresh, opt-in model policy, account-scoped catalog, token-derived endpoint, dynamic headers, Responses translation, and agent completion with `gpt-5.3-codex` | `github-copilot.Rmd` | completed | verified |
| Z.ai | explicit API-key auth, Coding Plan and general endpoints, GLM-5.2 thinking preservation, tool-call streaming, and normalized Chat Completions events | `zai.Rmd` | pending | pending |
| OpenAI | explicit API-key auth, model catalog, typed Responses request composition, normalized streaming, and agent completion | `openai.Rmd` and `openai-provider-loop.Rmd` | pending | pending |
| Anthropic | API-key and Claude Pro/Max OAuth auth, capability-profiled Messages requests, signed thinking, cache controls, normalized streaming, GitHub Copilot dialect reuse, and agent tool turns | `anthropic.Rmd` and `anthropic-provider-loop.Rmd` | organization disallows OAuth inference (HTTP 403) | pending |
| Ollama | OpenAI-compatible chat request translation, normalized SSE streaming, and agent completion | `ollama.Rmd` | completed with `gemma3:27b` | verified |
