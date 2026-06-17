# Vendored crates

## snarkvm-synthesizer 4.5.0 (Apache-2.0)

Verbatim copy of `snarkvm-synthesizer` 4.5.0 from crates.io with **one
2-line visibility change** (see `expose-raw.patch`): `VM::execute_authorization_raw`
and `VM::execute_fee_authorization_raw` are flipped from private to `pub`.

### Why

`aleo_rust`'s split-proof flow (`execute_proof` / `execute_fee_proof` /
`build_transaction_offline`) needs the bare `Execution` / `Fee` objects so the
proving step can run separately from transaction assembly. snarkVM's public
API (`execute_authorization`) only returns a fully assembled `Transaction`.
The original library was built against a (now lost) snarkVM fork exposing
these methods; without this patch the crate does not compile.

Consumed via `[patch.crates-io]` in `rust/aleo_rust/Cargo.toml`. The clean-room
`aleo_ffi` crate will use the same vendor for its program/proof group.

### Maintenance

- Upgrading snarkVM: download the new crate source (`crates.io` tarball),
  re-apply `expose-raw.patch`, replace this directory, refresh the lockfiles.
- Switching to a git fork later only means replacing the `path = ...` patch
  entry with a `git = ..., rev = ...` one; nothing else changes.

License note: snarkvm-synthesizer is Apache-2.0, so modifying and vendoring it
is permitted with attribution; its LICENSE.md is preserved in the directory.

## snarkvm-ledger-query 4.5.0 (Apache-2.0)

Verbatim copy of `snarkvm-ledger-query` 4.5.0 from crates.io with a **split-feature
change** (see `ledger-query-split-rest.patch`): the `ureq`-backed REST query is
moved out of the `query` feature into a new opt-in `rest = ["query", "dep:ureq"]`
feature. `default = ["query"]` (no `rest`). The REST surface in `src/query.rs`
(`mod rest`, the `Query::REST` variant + its match arms, `From<http::Uri>`, the
`FromStr` URL branch, `use ureq::http`) is gated behind `#[cfg(feature = "rest")]`.

### Why

`aleo_ffi` only ever uses `StaticQuery` (all node HTTP I/O now lives in the Dart
`AleoNode` — see `rust/aleo_ffi/docs/network-io-to-dart.md`). Upstream's `query`
feature unconditionally pulls `ureq` (and thus `rustls`), so the default build
links an HTTP stack it never calls. Splitting `ureq` into `rest` lets `aleo_ffi`
depend with `default-features = false, features = ["query"]` and drop the
transitive `ureq`/`rustls` entirely — Phase 4 workstream **B** (`docs/phase4-plan.md`).
This is a pure build-graph change: zero behavior change, the exported symbol set
is unchanged. (Removing `curl`/`openssl-sys`, pulled by `snarkvm-parameters`, is
the separate workstream **A**.)

Consumed via `[patch.crates-io]` in `rust/aleo_ffi/Cargo.toml`; the patch applies
tree-wide, so `snarkvm-synthesizer`/`-process` also resolve to this copy and no
longer pull `ureq` either.

### Maintenance

- Upgrading snarkVM: download the new crate source (`crates.io` tarball),
  re-apply `ledger-query-split-rest.patch`, replace this directory, refresh the
  lockfiles. Verify with `cargo tree -i ureq` / `-i rustls` (must be empty) from
  `rust/aleo_ffi`.
- The REST code is preserved (only feature-gated), so enabling `rest` restores
  upstream behavior verbatim. Feature combinations `query` (default), `rest`,
  `async`, and `async,rest` all compile; `--no-default-features` does not, which
  matches unpatched upstream (the crate needs at least `query`).

License note: snarkvm-ledger-query is Apache-2.0, so modifying and vendoring it
is permitted with attribution; its LICENSE.md is preserved in the directory.

## snarkvm-parameters 4.5.0 (Apache-2.0)

Verbatim copy of `snarkvm-parameters` 4.5.0 from crates.io with two fx-wallet
patches, applied in order:

1. **param-dir change** (`parameters-param-dir.patch`): a new
   `src/parameter_dir.rs` module plus a two-spot edit to `src/lib.rs` /
   `src/macros.rs`.
2. **no-remote-fetch change** (`parameters-no-remote-fetch.patch`, workstream A /
   PR3): removes the in-Rust curl downloader so the build links no HTTP/TLS stack.

### Why

snarkVM downloads/loads proving keys from a hard-wired `aleo_std::aleo_dir()`
(`~/.aleo`) with **no env/`ALEO_HOME` override**, and the read happens *inside*
this crate's load macro. To provision parameters into a mobile app sandbox, the
directory has to be overridable, and the override must be owned by the crate that
actually reads the files (so it can enforce the set-once rule against snarkVM's
static parameter cache). The patch adds:

- `parameter_dir.rs`: a process-global `set_parameter_dir(path)` /
  `parameter_dir_for_load()` / `effective_parameter_dir()` with a set-once
  contract (create-then-canonicalize, idempotent same-path, `Locked` on a
  different path or after loading has begun) — Phase 4 §8 Contract 2. "Choose a
  directory" and "begin loading" share **one mutex**, so a `set_parameter_dir` and
  the first load cannot interleave (no set-after-load-start TOCTOU).
- `macros.rs`: the `impl_load_bytes_logic_remote!` local-read path now reads from
  `parameter_dir_for_load()` (not `aleo_std::aleo_dir()`), which atomically freezes
  the directory and returns it.

The macro's **size + SHA-256 checksum guards are unchanged**, so a Dart-provisioned
parameter that is missing/corrupt is still rejected by this crate — the trust
boundary stays in Rust even once curl is removed.

### No remote fetch (workstream A, PR3)

The native download branch of `impl_load_bytes_logic_remote!` previously fetched a
missing parameter with `curl` (pulling in `openssl-sys`). The
`parameters-no-remote-fetch.patch` removes it: a parameter that is absent from the
param dir now **fails closed** with `ParameterError::RemoteFetchDisabled` instead
of being downloaded in-process. The Dart `ParameterProvisioner` provisions params
(download + verify + atomic rename) into the param dir before any prove. With the
downloader gone, the native `store_bytes` + curl `remote_fetch` and the
`From<curl::Error>` impl are deleted and the `curl` dependency is dropped, so
`cargo tree -i curl` / `-i openssl-sys` no longer resolve through this crate. The
size + checksum guards stay, so the trust boundary remains in Rust. (CI's "Verify
no HTTP/TLS stack" step asserts curl/openssl-sys/ureq/rustls/reqwest are all
absent; a Rust subprocess test asserts an absent remote param returns
`RemoteFetchDisabled`.)

Consumed via `[patch.crates-io]` in `rust/aleo_ffi/Cargo.toml` (applies tree-wide).

### Maintenance

- Upgrading snarkVM: re-extract the crate, re-apply `parameters-param-dir.patch`
  then `parameters-no-remote-fetch.patch`, re-add `src/parameter_dir.rs`, replace
  this directory, refresh lockfiles.
- The embedded `resources/*.metadata` (checksums/sizes) and the `impl_local!`
  base-SRS `.usrs` files (~6.3 MB, `include_bytes!`'d) are kept verbatim; only the
  downloadable (`impl_remote!`) keys are fetched at runtime into the param dir.

License note: snarkvm-parameters is Apache-2.0, so modifying and vendoring it is
permitted with attribution; its LICENSE.md is preserved in the directory.
