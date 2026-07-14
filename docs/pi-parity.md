# pi-mono parity ledger

Reference: `badlogic/pi-mono` commit `9d09075c53812f7af955ce4397d0508c4a62efac`
from 2026-07-14. This file records behavioral contracts, not TypeScript shapes.

Status values are `missing`, `implemented`, and `verified`. Only an executable
fixture or integration test moves a row to `verified`.

| Area | Contract | Status |
|---|---|---|
| Provider stream | start, text, thinking, tool-call, done, and error events with partial messages | verified |
| Messages | user, assistant, and tool result content with text, image, thinking, and tools | verified |
| Usage | input, output, cache read/write, reasoning, totals, and component costs | verified |
| Models | API, provider, URL, input modes, context, output cap, costs, headers, and compatibility | implemented |
| Providers | catalog, optional refresh, auth resolution, stream, complete, and simple variants | implemented |
| Credentials | serialized read/modify/delete and refresh ownership | implemented |
| Agent loop | repeated provider turns until no tools or queued messages remain | verified |
| Tool execution | validation, pre/post hooks, updates, parallel and sequential modes, source-order results | verified |
| Queues | steering and follow-up with all or one-at-a-time draining | implemented |
| Cancellation | provider and tool propagation with aborted terminal messages | verified |
| Events | ordered lifecycle events with awaited stateful listeners | verified |
| State | transcript, partial message, pending calls, error, reset, continue, and idle barrier | implemented |

Live wire adapters are tracked separately from surface parity. An API family is
not called implemented merely because its identifier is accepted.

## Live provider probes

| Adapter | Contract | Status |
|---|---|---|
| OpenAI Codex | explicit OAuth credential import, auth resolution, Responses translation, decoding, and agent completion with `gpt-5.3-codex-spark` | verified by the `codex-agent` example in `README.Rmd` |
| GitHub Copilot | device authorization, session-token refresh, token-derived endpoint, dynamic headers, Responses translation, and normalized streaming with `gpt-5.3-codex` | verified by `github-copilot.Rmd`; live account run pending |
| Z.ai | explicit API-key auth, Coding Plan and general endpoints, GLM-5.2 thinking preservation, tool-call streaming, and normalized Chat Completions events | verified by `zai.Rmd`; live account run pending |
| OpenAI | explicit API-key auth, model catalog, typed Responses request composition, normalized streaming, and agent completion | verified by `openai.Rmd` and `openai-provider-loop.Rmd`; live account run pending |
| Anthropic | Messages request translation; normalized Messages decoding is not implemented | missing |
| Ollama | chat request translation; normalized NDJSON decoding is not implemented | missing |
