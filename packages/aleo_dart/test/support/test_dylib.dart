import 'dart:ffi';

import 'package:aleo_dart/aleo.dart';

/// Reason shown when FFI-backed tests are skipped because the native
/// `aleo_rust` library could not be loaded (e.g. on CI where it is neither
/// prebuilt nor compiled from source).
const nativeLibMissingReason =
    'native libaleo_rust not available; fetch a prebuilt copy with '
    '`dart run aleo_dart:setup` (loaded via DyLib.getDyLibFromGit)';

/// Attempts to load the native `aleo_rust` dynamic library for tests.
///
/// Tries the local cargo build first, then a prebuilt copy fetched by
/// `dart run aleo_dart:setup`. Returns `null` when none is available so that
/// suites can [skip] gracefully instead of crashing at load time.
DynamicLibrary? tryLoadAleoLib() {
  for (final loader in <DynamicLibrary Function()>[
    DyLib.getDyLibFromCargo,
    DyLib.getDyLibFromGit,
  ]) {
    try {
      return loader();
    } catch (_) {
      // Try the next loader.
    }
  }
  return null;
}
