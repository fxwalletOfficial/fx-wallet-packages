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
