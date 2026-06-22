import 'dart:ffi' as ffi;
import 'dart:io';

/// Thrown when a native library's ABI does not match what this Dart package was
/// built against — either the `ffi_abi_version` symbol is missing (a library
/// predating the Phase-4 ABI guard) or its value differs. Surfacing this at load
/// time turns a silent ABI mismatch (a renamed symbol, a changed arity, a widened
/// integer) into a clear, loud failure instead of a later segfault or a bound
/// symbol reading the wrong bytes.
class IncompatibleNativeLibraryException implements Exception {
  final String message;
  IncompatibleNativeLibraryException(this.message);
  @override
  String toString() => 'IncompatibleNativeLibraryException: $message';
}

/// A native library validated against this package's expected ABI version.
///
/// Every public class that reaches the FFI (`AleoAccount`, `AleoRecord`,
/// `AleoProgram`, `ParameterProvisioner`) funnels its library through
/// [AleoLib.coerce], so there is no unvalidated path to the native code: a stale
/// or mismatched library is rejected at construction (before any call can bind a
/// renamed symbol or pass an argument into the wrong slot). The constructors keep
/// accepting a bare [ffi.DynamicLibrary] for source compatibility — they just
/// validate it now.
class AleoLib {
  final ffi.DynamicLibrary dyLib;
  const AleoLib._(this.dyLib);

  /// The ABI version this package is built against. Bump in lockstep with the
  /// Rust `ffi_abi_version` on every ABI-affecting change.
  static const int expectedAbiVersion = 1;

  /// Wraps an already-open [dyLib] after checking its ABI version.
  ///
  /// Throws [IncompatibleNativeLibraryException] if `ffi_abi_version` is absent
  /// (a pre-guard library — `lookup` throws `ArgumentError`) or returns a value
  /// other than [expected].
  factory AleoLib.fromDynamicLibrary(ffi.DynamicLibrary dyLib,
      {int expected = expectedAbiVersion}) {
    final int version;
    try {
      version = dyLib.lookupFunction<ffi.Uint32 Function(), int Function()>(
          'ffi_abi_version')();
    } on ArgumentError catch (e) {
      throw IncompatibleNativeLibraryException(
          'native library predates the ABI guard (no ffi_abi_version symbol); '
          'rebuild/redistribute it — $e');
    }
    if (version != expected) {
      throw IncompatibleNativeLibraryException(
          'native library ABI version $version, expected $expected; '
          'rebuild/redistribute the library in lockstep with this package');
    }
    return AleoLib._(dyLib);
  }

  /// Opens the library at [path] and validates it.
  factory AleoLib.open(String path, {int expected = expectedAbiVersion}) =>
      AleoLib.fromDynamicLibrary(ffi.DynamicLibrary.open(path),
          expected: expected);

  /// The single validation chokepoint the public constructors call: passes an
  /// already-validated [AleoLib] through, validates a bare [ffi.DynamicLibrary],
  /// and rejects anything else.
  static AleoLib coerce(Object lib, {int expected = expectedAbiVersion}) {
    if (lib is AleoLib) return lib;
    if (lib is ffi.DynamicLibrary) {
      return AleoLib.fromDynamicLibrary(lib, expected: expected);
    }
    throw ArgumentError(
        'expected an AleoLib or DynamicLibrary, got ${lib.runtimeType}');
  }
}

// Desktop dev / CI build-from-source paths, relative to the package directory
// (`packages/aleo_dart`). PR4b repointed these from the GPL `aleo_rust` crate to
// the clean-room `aleo_ffi` crate; the `[lib] name` is still `aleo_rust`, so the
// artifact filename is unchanged. `cargo build --release` in rust/aleo_ffi
// produces them. (Mobile does not use these — see getMobileDyLib.)
const DEFAULT_RUST_LIB_CARGO_SO =
    '../../rust/aleo_ffi/target/release/libaleo_rust.so'; // linux
const DEFAULT_RUST_LIB_CARGO_DLL =
    '../../rust/aleo_ffi/target/release/aleo_rust.dll'; // windows
const DEFAULT_RUST_LIB_CARGO_LIB =
    '../../rust/aleo_ffi/target/release/libaleo_rust.dylib'; // macOS

const DEFAULT_RUST_LIB_GIT_SO = '.dart_tool/dart_aleo/libaleo_rust.so';
const DEFAULT_RUST_LIB_GIT_DLL = '.dart_tool/dart_aleo/aleo_rust.dll';
const DEFAULT_RUST_LIB_GIT_LIB = '.dart_tool/dart_aleo/libaleo_rust.dylib';

class DyLib {
  static ffi.DynamicLibrary getDyLibByPosition(String position) {
    return ffi.DynamicLibrary.open(position);
  }

  static ffi.DynamicLibrary getLocalDyLib() {
    return ffi.DynamicLibrary.open('./aleo_rust.dll');
  }

  static ffi.DynamicLibrary getDyLibFromCargo() {
    if (Platform.isLinux) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_CARGO_SO);
    } else if (Platform.isMacOS) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_CARGO_LIB);
    } else if (Platform.isWindows) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_CARGO_DLL);
    } else {
      throw Exception("error platform");
    }
  }

  static ffi.DynamicLibrary getDyLibFromGit() {
    if (Platform.isLinux) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_GIT_SO);
    } else if (Platform.isMacOS) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_GIT_LIB);
    } else if (Platform.isWindows) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_GIT_DLL);
    } else {
      throw Exception("error platform");
    }
  }

  /// Loads the build-time-bundled native library on mobile (no runtime download).
  /// Android opens the per-ABI `libaleo_rust.so` the app bundles in its jniLibs
  /// (see `rust/build_android.sh`); iOS dlopens the embedded dynamic
  /// `AleoRust.framework` (see `rust/build_ios.sh`), whose exported symbols are
  /// intact (dynamic libraries are not dead-stripped).
  ///
  /// Wrap the result in `AleoLib.coerce` (the public constructors already do) so
  /// the ABI version is validated before any FFI call.
  static ffi.DynamicLibrary getMobileDyLib() {
    if (Platform.isAndroid) {
      return ffi.DynamicLibrary.open('libaleo_rust.so');
    } else if (Platform.isIOS) {
      // The dynamic AleoRust.framework is embedded in the app (see aleo_flutter);
      // dlopen it by name so it loads regardless of link-time dylib stripping. Its
      // exported symbols are intact — dynamic libraries are not dead-stripped.
      return ffi.DynamicLibrary.open('AleoRust.framework/AleoRust');
    } else {
      throw Exception('getMobileDyLib is for Android/iOS only');
    }
  }
}
