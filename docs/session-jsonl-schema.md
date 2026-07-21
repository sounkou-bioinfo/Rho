# Rho JSONL session schema

Rho JSONL is a coding-host implementation of `SessionJournal`. It is neither
the agent contract nor a general R object serializer.

## File framing

The file begins with one session record and continues with committed entry
records. Every record ends with LF.

```json
{"schema":"rho.session.jsonl","type":"session","id":"...","parent_id":""}
```

Entry records add a committed `position` and an `entry` semantic document.
Atomic values and lists retain their R storage mode, names, and missing
positions through the JSON value codec.

## Semantic records

A semantic record has a stable `type` and declared `fields`. It does
not contain an R package name, S7 class name, or reflected property list.

`RhoJsonSemanticAdapter` maps:

- a stable wire tag;
- stable wire-field names;
- the current S7 value class;
- each wire field to one current S7 property.

The two names may differ. This permits an R property rename without changing
stored records.

An extension registers an adapter explicitly:

```r
adapter <- rho_json_semantic_adapter(
  "example.result",
  ExampleResult,
  c(value = "current_value")
)
codec <- rho_json_session_codec(adapters = list(adapter))
```

Unknown S7 values resolve to `RhoSessionCodecErrorValue`. They are never granted
a durable representation by namespace discovery or property reflection.

## Change discipline

There is no released reader or stored consumer, so the current schema has no
invented migration history. Its tags and fields state the format Rho writes
now. Once a real consumer exists, an incompatible change must be explicit and
tested against that consumer's fixture.

Pi, training, DuckDB, and other representations are import/export codecs. They
do not add conditionals to this journal.
