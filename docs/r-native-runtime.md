# R-native interaction and secure storage

Rho keeps scheduling, presentation, and storage as separate protocols. nanonext
owns asynchronous I/O, mirai owns worker evaluation, and S7 generics connect
optional interactive or storage implementations. A graphics window, terminal
renderer, or credential cipher must not become an implicit event loop.

Several packages by [Mike Cheng](https://github.com/coolbutuseless) provide useful
implementations and, equally importantly, sharp examples of how those
responsibilities should be separated.

## Component decisions

| Project | Useful capability | Place in Rho |
|---|---|---|
| [nara](https://github.com/coolbutuseless/nara) | Fast, in-place drawing and image operations on `nativeRaster` values | Optional in-memory graphics surface. Ownership must be explicit because drawing mutates the raster. Durable output remains a declared `RhoGraphicArtifact`. |
| [tigerfb](https://github.com/coolbutuseless/tigerfb) | Cross-platform framebuffer window with keyboard, mouse, capture, and update operations | Optional graphics-preview presenter. It presents pixels and emits input state; it does not schedule provider or agent work. |
| [eventloop](https://github.com/coolbutuseless/eventloop) | Typed mouse, keyboard, frame, and device state around R graphics event handlers | Design reference only. Its X11 graphics-device loop is blocking and platform-specific, so it is not Rho's event substrate. |
| [devoutansi](https://github.com/coolbutuseless/devoutansi) and [miniansi](https://github.com/coolbutuseless/miniansi) | ANSI graphics-device output | Optional terminal graphic renderer. ANSI image output is distinct from terminal input, layout, focus, and accessibility; these packages do not constitute a TUI. |
| [tickle](https://github.com/coolbutuseless/tickle) | Tcl/Tk widgets, event bindings, canvas operations, and scheduled idle callbacks | Possible downstream desktop UI extension. Tcl/Tk lifecycle remains inside that extension. |
| [rmonocypher](https://github.com/coolbutuseless/rmonocypher) | XChaCha20-Poly1305 authenticated encryption and Argon2id | Implements Rho's encrypted `CredentialStore` envelope through raw AEAD operations, not arbitrary R-object encryption. |
| [cryptorng](https://github.com/coolbutuseless/cryptorng) | Operating-system cryptographic random bytes | No core dependency. `nanonext::random(convert = FALSE)` already supplies cryptographic bytes from its bundled Mbed TLS implementation. |
| [cryogenic](https://github.com/coolbutuseless/cryogenic) | Capture, inspect, modify, and later evaluate R calls | No dependency required. Rho model and compute specifications already use language objects directly and attach contracts with S7 classes. |
| [zstdlite](https://github.com/coolbutuseless/zstdlite) | Zstandard compression for raw data and R serialization | Possible artifact compression adapter. Compression and its parameters must be part of artifact metadata. |
| [serializer](https://github.com/coolbutuseless/serializer) and [zap](https://github.com/coolbutuseless/zap) | C-level R serialization and compact R-specific encodings | Useful implementation references, not durable interchange formats. CAS identities and credential envelopes must not depend on an opaque R serialization layout. |
| [rconnection](https://github.com/coolbutuseless/rconnection) | Custom R connections and composable connection filters | Design reference while the relevant R connection API remains experimental. Rho streams stay typed async streams rather than masquerading as blocking connections. |
| [priorityqueue](https://github.com/coolbutuseless/priorityqueue) and [governor](https://github.com/coolbutuseless/governor) | Priority ordering and frame-rate control | No scheduler dependency. Agent ordering is semantic, and waiting belongs to nanonext condition variables or an owning UI loop. |

No package is imported merely because its implementation is attractive. Each
adapter first needs a typed Rho contract, supported-platform checks, cancellation
semantics, and an executable integration example.

## Interactive safe points

The opt-in `rho.async` task-callback bridge uses `base::taskCallbackManager()` to
drain work that is already ready in the `later` loop after a top-level R
expression.

```text
nanonext Aio completion ──> RhoTask / RhoStream ──> promises/later notification
                                                        │
top-level R expression completed ──> non-blocking pump ─┘
```

The bridge has deliberately narrow semantics:

- registration and removal are explicit task-returning effects;
- the callback calls `later::run_now(timeoutSecs = 0)` and never waits;
- pump outcomes are typed values;
- registration is not performed from `.onLoad()`;
- lack of another top-level expression means lack of another safe point;
- a UI adapter remains responsible for its own native event lifecycle.

This improves interactive progress without creating a second scheduler beside
nanonext and mirai.

## Graphics presentation

`rho.graphics` continues to render archival PNG, SVG, and PDF artifacts on
declared devices. Interactive presentation is a separate operation. A future
presenter generic can dispatch on both artifact or raster type and presentation
target:

```text
RhoGraphicSpec ──render──> RhoGraphicArtifact
                              │
                              ├── present in a tigerfb window
                              ├── encode with an ANSI graphics device
                              └── attach to a desktop or web UI
```

`nara` is suitable for fast transient raster work before presentation.
`tigerfb` is suitable for a cross-platform preview window. Neither changes the
artifact's content identity or provenance. Window captures become new artifacts
rather than mutations of the original artifact record.

Terminal UI work needs a separate terminal capability contract covering raw
input, resize, cursor control, color depth, focus, and cleanup. ANSI graphics
alone does not satisfy that contract.

## Encrypted credential storage

`rho.ai` preserves the existing `CredentialStore` interface for encrypted
storage and keeps key acquisition explicit. Its on-disk envelope has a versioned
schema containing:

- envelope and credential schema versions;
- cipher and key-derivation identifiers with their parameters;
- a fresh random salt for password-derived keys;
- the AEAD nonce, authentication tag, and ciphertext;
- authenticated provider and credential-type metadata.

The payload is JSON for the typed credential fields, not
`serialize(..., xdr = FALSE)` output. Encryption and decryption failures resolve
to typed values, and filesystem reads, writes, and replacement remain
asynchronous effects.

Rho uses `rmonocypher::encrypt_raw()` and `decrypt_raw()`, generates salts with
`nanonext::random(convert = FALSE)`, and supplies explicit additional
authenticated data. A passphrase uses Argon2id with the stored random salt; an
automated caller can instead supply an explicit 32-byte key. Secret keys should
cross as little R code as possible; measured key-handling or envelope work can
move to C without moving the public S7 protocol out of R.

`rho_keychain_credential_store()` is the alternative for systems with a native
credential service. It deliberately rejects keyring's environment and file
backends, so a caller cannot silently exchange OS-backed storage for a process
variable or another unencrypted file.

Compression, when useful, happens before encryption and is declared in the
envelope. It is not required for the small credential documents expected here.
