import 'dart:ffi';
import 'dart:io';

import 'package:aleo_dart/aleo.dart';

/// Reason shown when FFI-backed tests are skipped because the native
/// `aleo_rust` library could not be loaded (e.g. on CI where it is neither
/// prebuilt nor compiled from source).
const nativeLibMissingReason =
    'native libaleo_rust not available; set ALEO_NEW_LIB to a built library, '
    'or fetch a prebuilt copy with `dart run aleo_dart:setup` '
    '(loaded via DyLib.getDyLibFromGit)';

/// Attempts to load the native `aleo_rust` dynamic library for tests.
///
/// An `ALEO_NEW_LIB` path takes priority and fails loudly when unloadable (CI
/// sets it to the freshly built cdylib, and a typo there should not silently
/// skip the suite). Otherwise tries the local cargo build, then a prebuilt
/// copy fetched by `dart run aleo_dart:setup`, and returns `null` when none
/// is available so that suites can [skip] gracefully instead of crashing at
/// load time.
DynamicLibrary? tryLoadAleoLib() {
  final override = Platform.environment['ALEO_NEW_LIB'];
  if (override != null && override.isNotEmpty) {
    return DynamicLibrary.open(override);
  }
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
