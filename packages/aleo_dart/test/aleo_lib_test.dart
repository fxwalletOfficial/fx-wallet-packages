import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

import 'support/test_dylib.dart';

/// A real, loadable native library that does NOT export `ffi_abi_version`, opened
/// as its own handle so the lookup is scoped to it (not the globally-loaded aleo
/// library). Used as the "stale / pre-guard library" fixture.
ffi.DynamicLibrary? _guardlessLibrary() {
  if (Platform.isMacOS) {
    return ffi.DynamicLibrary.open('/usr/lib/libSystem.B.dylib');
  }
  if (Platform.isLinux) {
    return ffi.DynamicLibrary.open('libc.so.6');
  }
  return null; // no portable fixture on this platform
}

/// The load-time ABI guard (PR4a §4). These cases use explicit fixtures rather
/// than the prebuilt fallback, so a stale-but-loadable library can never mask a
/// regression:
///   - a fresh library (ALEO_NEW_LIB) validates and exposes ffi_abi_version == 1;
///   - a library without the symbol (the Dart executable) is rejected;
///   - a version mismatch (via the injectable `expected` seam) is rejected before
///     any business lookup.
void main() {
  final dyLib = tryLoadAleoLib();

  test('fresh library validates and is wrapped', () {
    if (dyLib == null) {
      markTestSkipped(nativeLibMissingReason);
      return;
    }
    final lib = AleoLib.fromDynamicLibrary(dyLib);
    expect(lib.dyLib, same(dyLib));
    // coerce passes an AleoLib through and validates a bare DynamicLibrary.
    expect(AleoLib.coerce(lib), same(lib));
    expect(AleoLib.coerce(dyLib).dyLib, same(dyLib));
  });

  test('missing ffi_abi_version symbol is rejected', () {
    final guardless = _guardlessLibrary();
    if (guardless == null) {
      markTestSkipped('no portable guardless-library fixture on this platform');
      return;
    }
    // The system library does not export ffi_abi_version, so the lookup throws
    // ArgumentError, which the loader maps to IncompatibleNativeLibraryException.
    expect(
      () => AleoLib.fromDynamicLibrary(guardless),
      throwsA(isA<IncompatibleNativeLibraryException>()),
    );
  });

  test('ABI version mismatch is rejected before any business lookup', () {
    if (dyLib == null) {
      markTestSkipped(nativeLibMissingReason);
      return;
    }
    // The library reports version 1; demanding a different version must fail.
    expect(
      () => AleoLib.fromDynamicLibrary(dyLib, expected: 2),
      throwsA(isA<IncompatibleNativeLibraryException>()),
    );
  });

  test('coerce rejects a non-library argument', () {
    expect(() => AleoLib.coerce('not a library'), throwsArgumentError);
  });
}
