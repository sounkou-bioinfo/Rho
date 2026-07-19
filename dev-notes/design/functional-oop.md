# Functional OOP in R

Rho uses functional OOP in the literal R sense: generic functions state open
questions, S7 classes carry semantic values, and methods supply answers for
particular combinations of values. The function remains the public verb. The
object does not become a mutable manager with a private method vocabulary.

[`s7contract`](https://github.com/sounkou-bioinfo/s7contract) describes the
shape expected by a consumer without moving dispatch out of ordinary S7
generics and methods. Its interfaces and traits are runtime R contracts, not
claims of Go or Rust compile-time typing.

## Dispatch removes accidental representation

Use a class when a value changes behavior. Use a property class when a field has
a reusable constraint. Use a generic when an operation has more than one
meaning across classes. This removes three common sources of duplication:

- class names encoded as strings;
- repeated `if`/`else` tests over those strings;
- validation helpers that restate a class property's contract.

A request section, provider transport, model capability, operation binding,
tool placement, error value, resource handle, and execution placement are all
values on which R can dispatch. Their wire spellings are produced only by the
method that crosses the wire.

If a constraint belongs to a field, make it the field's property:

```r
rho_non_empty_string <- S7::new_property(
  S7::class_character,
  validator = function(value) {
    if (length(value) != 1L || !nzchar(value)) {
      "must be one non-empty string"
    }
  }
)

ResourceId <- S7::new_class(
  "ResourceId",
  properties = list(value = rho_non_empty_string)
)
```

Do not follow this with `rho_is_valid_resource_id()` that reads `x@value` and
repeats the same test. Construction has already established the invariant and
S7 owns its error message. A predicate is justified only at a genuinely
untyped boundary or when it asks a different semantic question.

Not every function is a generic. A deterministic algorithm with one meaning is
an ordinary named function. Package namespaces provide privacy, so an initial
dot does not add a useful access boundary.

## Default methods are part of the design

A generic's default method expresses a complete common case. Narrower methods
specialize only the behavior that truly differs. This is the synthesis point
between a lowest-common-denominator interface and provider-specific branches:
shared semantics remain shared, while a specialized value can preserve a
capability the common method cannot express.

A default is not a place to silently discard a request. A semantically complete
alternative returns a successful typed result and records what it did and why.
An operation that could not be performed returns a typed unsupported or error
value.

## Structural interfaces belong to consumers

An interface is a small named set of required S7 generics. Define concrete
classes and their methods normally. Then define the interface where consuming
code needs several behaviors to travel together.

Rho already uses this shape:

- `HttpClient` requires request, stream-opening, execution-placement, and close
  generics without requiring one HTTP base class;
- `Provider` requires canonical streaming regardless of whether execution is
  SSE, WebSocket, embedded, or remote;
- `Tool`, `CredentialStore`, `AgentPolicy`, `RhoTaskQueue`, and
  `ProviderRequestTranslator` collect the operations their consumers need.

This is structural conformance. A class satisfies the interface when S7 can
find its required methods. `s7contract::assert_implements()` belongs at a
capability-admission boundary, such as agent construction or provider binding.
It should not be repeated before every generic call after admission.

Define the interface from the consumer's needs, not by listing everything an
implementation happens to provide. Prefer several coherent interfaces to one
root `RhoBackend` interface that every implementation must pretend to satisfy.
Parent interfaces are appropriate only for a real requirement relation.

## Traits are explicit and rarer

A `s7contract` trait requires `impl_trait()`. Use that stronger declaration
when opt-in conformance matters or the contract carries default methods or
associated metadata. Do not use a trait merely to restate structural method
availability. Rho currently prefers interfaces; the first trait must be pulled
by a concrete consumer that needs explicit implementation or associated
metadata.

Trait defaults follow the same rule as generic defaults: they implement a
complete shared semantic case, never a silent no-op.

## Progressive call contracts

`interface_requirement()` may declare argument and return specifications.
`with(interface, expression)` and `%::%` apply those checks to generic calls in
a contract mask. Use them progressively at boundaries where a bad result would
otherwise travel asynchronously or across packages:

- provider streams must return `RhoStream`;
- tool execution and operation execution must return `RhoTask`;
- request sections must encode to named lists;
- agent policy hooks must return the declared decision or task value.

Do not wrap every internal expression in a contract mask. S7 property
validation, method dispatch, and focused interface tests already cover most
ordinary calls. Progressive checks are runtime evidence at selected seams, not
an imitation of a static type checker.

## State and effects

Stateful S7 objects use explicit environment properties when identity and
mutation are real. Named generics perform mutation. Callers should not reach
inside an environment and modify fields as an accidental second API.

Closures are capability bindings. They may close over an explicitly supplied
credential store, SQL connection, evaluator, or resolver implementation. That
captured environment is runtime behavior, not a durable specification.

Language objects are data when kept within a constrained contract. A quoted
call can be inspected with base R and `codetools`, validated, hashed, and sent
to a worker with explicit arguments. Arbitrary closures and environments are
not serialized merely because R permits it.

## Lazy evaluation

Promises fit virtual resources and deferred computations, but laziness must not
hide waiting. Forcing a resource may start or return a `RhoTask`; it must not
call `rho_await()` inside an active binding. Per-context promise memoization,
cross-context content identity, and source freshness are separate contracts.

## Native code

Keep the semantic protocol in R. Move a bounded operation to C when profiling,
threading, ABI access, byte framing, or object lifetime requires it. The C entry
point should receive validated values and implement one narrow operation, not a
second class hierarchy or provider policy engine.

## Mechanical requirements

- Class validators own relationship checks local to one value.
- A constructor does not repeat its property validators.
- A helper does not repeat a class property's validator by inspecting its slot.
- Structural interfaces are defined at the consuming boundary and remain
  smaller than the implementation.
- `assert_implements()` is an admission check, not per-call ceremony.
- Traits require a demonstrated need for explicit conformance, defaults, or
  associated metadata.
- Cross-value call-shape errors may use `rho_contract_violation`.
- Operational failures are typed values.
- Packages defining methods call `S7::methods_register()` during `.onLoad()`.
- `s7contract` interfaces describe protocol bundles when several generics must
  travel together.
