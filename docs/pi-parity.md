# pi-mono parity ledger

Reference: `badlogic/pi-mono` commit `0e6909f050eeb15e8f6c05185511f3788357ddb3`
from 2026-07-13. This file records behavioral contracts, not TypeScript shapes.

Status values are `missing`, `implemented`, and `verified`. Only an executable
fixture or integration test moves a row to `verified`.

| Area | Contract | Status |
|---|---|---|
| Provider stream | start, text, thinking, tool-call, done, and error events with partial messages | implemented |
| Messages | user, assistant, and tool result content with text, image, thinking, and tools | verified |
| Usage | input, output, cache read/write, reasoning, totals, and component costs | missing |
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
| OpenAI Codex | explicit OAuth credential import, auth resolution, Responses translation, decoding, and agent completion with `gpt-5.3-codex-spark` | verified by `scripts/smoke-openai-codex.R` |
| OpenAI | Chat Completions request translation and normalized SSE decoding fixtures | implemented |
| Anthropic | Messages request translation and normalized SSE decoding fixtures | implemented |
| Ollama | chat request translation and normalized response decoding fixtures | implemented |
