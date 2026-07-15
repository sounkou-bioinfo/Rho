# Model catalog sources

The installed catalog in `R/sysdata.rda` is generated. Do not edit it directly.
Its inputs have two different roles.

`models-dev-selected.json` is a derived, reviewable projection of
<https://models.dev/api.json>. It retains only providers and fields used by
Rho, together with the SHA-256 digest of the complete response from which it
was produced.

`model-overrides.json` is curated. It contains only facts that cannot be
derived from the selected models.dev fields:

- endpoint-specific corrections, such as a GitHub Copilot transport behavior;
- an offline supported model subset for an authenticated endpoint that is not
  represented as a distinct models.dev provider.

Model names, prices, limits, and capabilities belong in the derived snapshot
whenever models.dev supplies them. A profile override is not a convenient way
to replace derivation. If a source field can express the fact, extend
`update-models-dev.R` and derive it in `compile-model-catalog.R`.

## Refreshing derived data

From the repository root:

```sh
make update-models
make check-models
```

`make update-models` downloads models.dev through nanonext, rewrites the
selected snapshot, and compiles `R/sysdata.rda`. Review both the source
snapshot and the compiled behavioral changes. The refresh must remain
deterministic: a second `make models` must produce no diff.

## Adding curated data

Every object in `profile_overrides` and `records` must include:

- `reason`: why the fact cannot be derived from models.dev;
- `evidence.kind`: the kind of observation or upstream contract;
- `evidence.reference`: an immutable documentation, test, or source-code URL.

Prefer primary provider documentation or an authenticated endpoint fixture.
When Rho follows an upstream compatibility decision, link to an exact commit,
not a moving branch. Never put credentials, response headers, account
identifiers, or unredacted endpoint responses in catalog inputs.

After editing curated data:

```sh
make models
make check-models
Rscript scripts/purl-tests.R
make test
```

Add or update an Rmd fixture that observes the resulting S7 capability value
and request translation. Request builders must consume the compiled typed
capability; they must not repeat model-name tests.

## Hosted operation capabilities

The curated `web_search` field exists only in catalog input. The compiler maps
its values to runtime classes:

- OpenAI `text` and `text_and_image` become `OpenAIWebSearchText` and
  `OpenAIWebSearchTextAndImage`.
- Anthropic `basic`, `dynamic`, and `response_inclusion` become the versioned
  `AnthropicWebSearchProtocol` classes.
- An absent declaration becomes `RhoWebSearchUnavailable`.

Unknown values, duplicate profile keys, and profiles that match no compiled
model are compiler errors. Provider request code sees only the S7 capability;
it neither reads these strings nor tests model identifiers.

## Removing curated data

During each refresh, check whether models.dev now expresses a curated fact. If
it does, add the field to the selected projection when necessary, derive the
typed capability, remove the curated entry, and keep the behavioral fixture.

The Codex OAuth records are an offline supported subset, not a claim that the
endpoint exposes only those models. Login-time discovery may narrow or enrich
availability for an account, but it does not silently rewrite the package
catalog.
