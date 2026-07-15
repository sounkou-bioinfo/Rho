# Rho Agent Instructions

Rho architecture rules:

1. Public behavior enters through S7 generics.
2. Implementations are S7 methods.
3. Stateful runtime objects are S7 classes with environment properties.
4. All mutation goes through named functions/generics.
5. Protocol bundles use `s7contract` interfaces/traits.
6. Effectful public APIs return `RhoTask`, `RhoStream`, or `RhoDuplex`.
7. Blocking is allowed only in `rho_await()`, CLI boundaries, and test helpers.
8. HTTP, SSE, WebSocket, provider calls, tools, extension hooks, compute, DuckDB, bio resolvers, graphics, CAS, and ledger writes are async.
9. Provider packages must use `rho.http`; no ad hoc HTTP clients.
10. Worker execution goes through `rho.compute`; no hidden `parallel`, `future`, or direct `mirai` calls in higher packages.
11. Graphics are first-class artifacts, not console side effects.
12. Graphics render in declared devices with metadata and content digests.
13. `recordedplot` may be used for ephemeral preview, never durable provenance.
14. `rho.bio` must not import `rho.agent` or `rho.ext`.
15. `rho.agent` must not contain coding or bio tools.
16. Extensions register capabilities; they do not patch globals.
17. Missing providers, resolvers, tools, compute backends, or SQL connections fail closed.
18. New workflows enter as extensions, manifests, or provider packages, not core helpers.
19. Rmd files in `inst/tinytest/rmd/` are the authored tests; generated `inst/tinytest/test-*.R` files are not edited by hand.
20. Every async test must have an explicit timeout.
21. Do not create dot-prefixed functions, properties, constants, or pseudo-private helpers. R package namespaces already provide encapsulation; use descriptive `rho_*` names for ordinary package code. Standard R package hooks such as `.onLoad()` are the required exception.
22. A reusable constraint on an S7 field is an S7 property with its own validator and is attached directly to that class property. Do not re-check that constraint later with ad hoc `is_*` helper functions.
23. Behavior that varies by class enters through an S7 generic and methods. Keep a plain function only for a non-dispatched algorithm with a single meaning.
24. Rho targets R 4.4.0 or newer. Use modern base-R facilities directly; do not carry compatibility shims or redefine base operators such as `%||%`.
25. TLS belongs to nanonext and its bundled mbedTLS. Use `nanonext::tls_config()` for an in-memory configuration and pass PEM material as `c(ca_chain, revocation_list)` when peer authentication is required. Package code must not search platform CA paths.
26. Do not use “fallback” as a substitute for semantics. Name the concrete behavior, encode its observable consequences in the returned value, and include the reason that behavior was selected.
27. A semantically complete alternative is a successful typed result, not an error. For example, full active-tool advertisement remains successful when native deferred loading is unavailable; it records that the prompt prefix may be replaced. Return a typed unsupported/error value only when the requested operation was not performed.
28. Protocol polling lives only in `rho.async` combinators. Callers return typed poll decisions; delay uses nanonext condition-variable deadlines, never `Sys.sleep()` or an ad hoc timed loop.
29. Parallel scheduling and parallel execution are separate contracts. `rho.agent` starts and joins tasks while preserving source order. A tool definition declares whether calls may overlap and chooses the backend that realizes its returned task.
30. A tool that needs an R worker calls `rho.compute`; it does not call `mirai` directly. The agent package never imports `mirai` and never silently moves a tool to a worker.
31. Shell tools preserve declared shell semantics across platforms. A Bash tool resolves Bash on Windows instead of translating model-generated Bash into `cmd.exe` or PowerShell. The selected executable and the reason for selecting it are typed, inspectable values.
32. R evaluation names its state semantics. Current-session evaluation receives an explicit environment and requires exclusive scheduling. Ordinary mirai evaluation is isolated and must not be described as a persistent REPL.
33. Keep the GitHub repository private until the parity ledger, package checks, live provider checks, documentation, and secret scan are green. Only then make it public and add it to `sounkou-bioinfo/sounkou-bioinfo.r-universe.dev`.
34. Air is the repository formatter. Run `make format` after editing authored R code and require `make check-format` in CI. Generated tinytest files are excluded because their Rmd sources are authoritative.
35. Every package that defines S7 methods calls `S7::methods_register()` from `.onLoad()`. This is required for methods on generics owned by another package and harmless for locally owned generics.
36. Contributions to nanonext follow nanonext's surrounding C and R conventions. Reuse its Aio, error-value, TLS, request-header, registration, ownership, and finalizer patterns; use NNG synchronization for state shared with callbacks; and keep the R wrapper as thin as adjacent nanonext wrappers.
37. Provider request bodies are composed from typed policy or section values. Do not assemble optional wire fields with long `if`/`else` chains or use provider strings as internal state. S7 methods translate typed values to strings only at the wire boundary, and the final body builder reduces the resulting named sections.
38. Model metadata is derived from the pinned models.dev projection whenever its source fields can express the fact. Every curated profile correction or offline record declares why derivation is impossible and links immutable evidence; request code consumes the compiled typed capability and never repeats model-name tests.
39. S7 properties and class validators own field validation and its messages. Constructors do not repeat a property's type or value checks. Signal `rho_contract_violation` only for a programmer error involving call structure or relationships that no single S7 value can represent.
40. Operational failures are typed values. Installable package code does not use a package-local `rho_abort()` wrapper or bare `stop()` for transport, provider, tool, compute, graphics, SQL, cancellation, or timeout outcomes. `rho_await()` may re-signal an explicitly rejected task at the declared blocking boundary; build scripts and tests may stop their process.
41. A `ToolSpec` is executable host code. A `RhoOperation` is a semantic request that may be bound to a provider, an extension, a local evaluator, or a remote backend. Provider-hosted activity never enters the local tool registry and never masquerades as a `ToolCall`.
42. Operation selection is explicit. `rho_plan_operations()` produces typed bindings that record the selected handler and the reason; provider request translation rejects an unbound semantic operation instead of dropping it. A caller or extension may supply a narrower binding deliberately.
43. Provider-hosted capabilities are typed model compatibility values. Catalog input strings are confined to the catalog compiler; runtime request code dispatches on capability classes and does not infer support from ordinary tool calling or model-name comparisons.
