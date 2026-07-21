# rho.ai 0.0.1.9001

- Adds `UsageSummary` and open usage-observation traversal. Aggregates preserve
  provider-reported, estimated, unavailable, and unpriced observations while
  reporting disjoint tokens, cache-hit proportion, and nominal cost.
- Assistant messages can retain the request-context revision associated with a
  usage observation. Tool calls explicitly record whether host arguments have
  already been prepared.
- Adds explicit encrypted-file and native-keychain credential stores. Portable
  storage uses Argon2id and XChaCha20-Poly1305, authenticates metadata, and
  returns typed values for wrong secrets or altered envelopes. Keychain storage
  rejects environment and file backends.
- Replaces ambiguous zero-valued usage with typed provider-reported,
  explicitly estimated, and unavailable observations. Nominal API-equivalent
  pricing is distinct from a subscription charge.

# rho.ai 0.0.1.9000

- Adds experimental typed models, messages, credentials, provider operations,
  request translation, and normalized streaming adapters inspired by Pi.
- Adds typed provider input-limit values and exact structured-code translation
  for OpenAI-compatible context limits and Anthropic request-size limits.
- Preserves HTTP retry semantics when OpenAI-compatible status errors include a
  structured provider error body.
- Collects provider completions through task composition and serializes
  asynchronous credential updates without blocking the R event loop.
- Adds an explicit file-backed credential store so login and refresh results are
  persisted with serialized updates and owner-only file permissions.
- Adds typed provider-turn strategies and a default `rho_stream()` method so
  HTTP SSE, WebSocket, and embedded providers share the normalized event
  protocol without sharing a wire implementation.
- Adds executable embedded-provider values: an explicit executor can return a
  normalized stream or a task resolving to one, without inventing a provider
  class for each in-process model.
- Adds the OpenAI Codex `response.create` WebSocket transport when the selected
  HTTP client implements Rho's WebSocket client interface. Explicit WebSocket
  selection reports an unsupported transport instead of changing to SSE.
- Derives GitHub Copilot provider protocols and transport capabilities from a
  sanitized `/models` endpoint snapshot. Catalog compilation no longer routes
  Copilot models from model-name patterns.
- Compiles provider and protocol constructors from an executable R registry,
  validates endpoint declarations retained from models.dev, and exposes model
  catalogs through lazy read-only bindings.
- Adds Kimi Code subscription keys and OAuth device authorization, plus
  distinct global and China Kimi Platform API-key providers with Kimi thinking,
  image-input, token-limit, and streamed-usage semantics.
