import 'dart:ffi';
import 'dart:io';

import 'package:aleo_dart/aleo.dart';

/// Reason shown when FFI-backed tests are skipped because the native
/// `aleo_rust` library could not be loaded (e.g. on CI before it is built).
const nativeLibMissingReason =
    'native libaleo_rust not available; set ALEO_NEW_LIB to a freshly built '
    'library, or build it from source (`cargo build --release` in rust/aleo_ffi)';

/// Attempts to load the native `aleo_rust` dynamic library for tests, returning
/// only an **ABI-compatible** library (or null).
///
/// `ALEO_NEW_LIB` takes priority and fails loudly: a bad path or an ABI mismatch
/// is a misconfiguration the suite must not silently skip (CI sets it to the
/// freshly built cdylib). Otherwise the local cargo build is used *only if it is
/// present and ABI-compatible*; anything else returns null so suites [skip]
/// gracefully instead of throwing at construction mid-test.
///
/// The deprecated `dart run aleo_dart:setup` download path is intentionally NOT a
/// fallback: a previously-downloaded GPL-era library is ABI-incompatible and would
/// be rejected by the `ffi_abi_version` guard anyway — returning it here would turn
/// a graceful skip into a mid-test `IncompatibleNativeLibraryException`.
DynamicLibrary? tryLoadAleoLib() {
  final override = Platform.environment['ALEO_NEW_LIB'];
  if (override != null && override.isNotEmpty) {
    final lib = DynamicLibrary.open(override);
    AleoLib.fromDynamicLibrary(lib); // throws on an ABI mismatch (loud, by design)
    return lib;
  }
  try {
    final lib = DyLib.getDyLibFromCargo();
    AleoLib.fromDynamicLibrary(lib); // reject a not-rebuilt / incompatible local lib
    return lib;
  } catch (_) {
    return null; // not built or incompatible → suites skip gracefully
  }
}
