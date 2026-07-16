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
- Derives GitHub Copilot provider protocols and transport capabilities from a
  sanitized `/models` endpoint snapshot. Catalog compilation no longer routes
  Copilot models from model-name patterns.
