# Changelog

## [Unreleased]

### Fixed

- CI: `dart analyze` no longer fails the pipeline. Manual demo / integration
  scripts under `test/` (which depend on a live node and/or the gitignored
  `test/local/config.dart`) are excluded from static analysis.
- CI: FFI-backed tests now skip gracefully via `tryLoadAleoLib()` when the
  native `aleo_rust` library is unavailable (e.g. on CI), instead of failing at
  load time. Tests that broadcast real transactions are marked as manual
  integration tests.

## [1.0.0]

- Initial release in the fx-wallet-packages monorepo.
- Imported from the standalone aleo_dart repository with full git history.
- Aleo account / record / transaction APIs via FFI to the `aleo_rust` native library.
- `dart run aleo_dart:setup` fetches a prebuilt dynamic library for the host platform.
