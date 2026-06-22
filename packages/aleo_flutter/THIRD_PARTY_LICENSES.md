# Third-party licenses

The native `libaleo_rust` library bundled by this plugin statically links the
components below. The **authoritative, complete** list is generated from the Rust
dependency graph in PR6b (e.g. `cargo about generate`) and shipped alongside the
release artifacts; this file describes what that generated list covers.

## Bundled native library

- **aleo_ffi** (this repository, `rust/aleo_ffi`) — Apache-2.0. Clean-room
  reimplementation; links no HTTP/TLS stack and carries no GPL code (Phase 4).
- **snarkVM** (Aleo) — Apache-2.0. Statically linked.
- **Transitive Rust crates** — predominantly MIT, Apache-2.0, BSD-3-Clause, and
  Unicode-DFS-2016.
- **r-efi** — `Apache-2.0 OR LGPL-2.1-or-later OR MIT`; this distribution elects
  **Apache-2.0 / MIT**.

## Note

This is attribution, not legal advice. The generated `THIRD_PARTY_LICENSES`
(PR6b) is the binding artifact; confirm licensing with whoever owns IP/legal
before public distribution.
