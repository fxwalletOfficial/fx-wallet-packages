import 'dart:io';

/// `dart run aleo_dart:setup` is removed in v1. The old runtime download targeted
/// a stale, GPL-era, ABI-incompatible native library (`pzhun/aleo_dart`). The
/// library is now built from source (desktop/CI) or bundled by the aleo_flutter
/// plugin (mobile). This entry point fails fast with guidance instead of
/// downloading.
void main() {
  stderr.writeln(
    'aleo_dart:setup is removed in v1 — it used to download a stale, GPL-era, '
    'ABI-incompatible native library, which the ffi_abi_version load guard would '
    'reject anyway.\n'
    '\n'
    'Get the native library instead by:\n'
    '  - Flutter apps: depend on the aleo_flutter plugin (it bundles libaleo_rust\n'
    '    at build time; no runtime download).\n'
    '  - Desktop / CI: build from source -- `cargo build --release` in rust/aleo_ffi,\n'
    '    loaded via DyLib.getDyLibFromCargo().\n'
    '\n'
    'See packages/aleo_dart/README.md.',
  );
  exit(1);
}
