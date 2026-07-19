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
| Session compaction | cut point, semantic summary, in-memory entry, provider-input recovery, and lifecycle hooks | verified |

Live wire adapters are tracked separately from surface parity. An API family is
not called implemented merely because its identifier is accepted.

The external-account column records the account state observed while exercising
the adapter. Paid entitlement is not an implementation requirement. A provider
may be verified by its executable wire fixture when authentication, request
translation, streaming, and terminal behavior are covered. An entitlement
rejection is useful evidence only when it arrives as the expected typed provider
value after the real authentication path.

## Live provider probes

| Adapter | Contract | Fixture | External account | Status |
|---|---|---|---|---|
| OpenAI Codex | explicit OAuth credential import, auth resolution, Responses translation, SSE and one-shot `response.create` WebSocket decoding, and agent completion with `gpt-5.3-codex-spark` | `codex-agent` in `README.Rmd` and `openai-codex-websocket.Rmd` | completed | verified |
| GitHub Copilot | device authorization, session-token refresh, opt-in model policy, account-scoped catalog, token-derived endpoint, dynamic headers, Responses translation, and agent completion with `gpt-5.3-codex` | `github-copilot.Rmd` | completed | verified |
| Z.ai | explicit API-key auth, Coding Plan and general endpoints, GLM-5.2 thinking preservation, tool-call streaming, and normalized Chat Completions events | `zai.Rmd` | no paid entitlement; [Z.ai documents API-key/JWT auth](https://docs.z.ai/guides/develop/http/introduction) and no device grant | verified |
| OpenAI | explicit API-key auth, model catalog, typed Responses request composition, normalized streaming, structured input-limit recovery, and agent completion | `openai.Rmd` and `openai-provider-loop.Rmd` | API-key account not supplied; executable HTTP fixtures cover the wire contract | verified |
| Anthropic | API-key and Claude Pro/Max OAuth auth, capability-profiled Messages requests, signed thinking, cache controls, normalized streaming, GitHub Copilot dialect reuse, and agent tool turns | `anthropic.Rmd` and `anthropic-provider-loop.Rmd` | expired subscription returns the expected typed HTTP 403 after OAuth authorization | verified |
| Kimi Code | explicit subscription key and OAuth device authorization, refresh ownership, adaptive Anthropic Messages translation, image input, and normalized events | `kimi.Rmd` | account not supplied; local OAuth and wire fixtures cover authorization and refresh | verified |
| Kimi Platform | explicit API-key auth, distinct global and China catalogs, Kimi thinking controls, image input, completion limits, and normalized Chat Completions usage | `kimi.Rmd` | API-key account not supplied; executable request and event fixtures cover the advertised surface | verified |
| Ollama | OpenAI-compatible chat request translation, normalized SSE streaming, and agent completion | `ollama.Rmd` | completed with `gemma3:27b` | verified |
