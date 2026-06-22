/// aleo_flutter — a Flutter FFI plugin that bundles the prebuilt `aleo_rust`
/// native library (Android per-ABI `.so`, iOS static `xcframework`) at build
/// time and exposes the [aleo_dart](https://pub.dev/packages/aleo_dart) API on
/// device.
///
/// The native library is fetched once at **build** time — from a pinned GitHub
/// Release, verified against the SHA-256 in `src/artifact_manifest.dart`, or from
/// a local build during development (see `pr6a-impl-notes.md`) — and bundled into
/// the app. At **run** time [AleoFlutter.load] does no network or disk I/O beyond
/// `dlopen`: the library already lives inside the app, so it works offline.
library;

import 'package:aleo_dart/aleo.dart';

/// Re-export the full aleo_dart API so an app depends on (and imports) just
/// `aleo_flutter`.
export 'package:aleo_dart/aleo.dart';

/// Loads the build-time-bundled `aleo_rust` native library on Android and iOS.
abstract final class AleoFlutter {
  /// Returns the bundled native library, validated against the ABI version this
  /// package expects ([AleoLib.expectedAbiVersion]).
  ///
  /// Does no network or disk I/O beyond `dlopen` — the library is already inside
  /// the app (bundled at build time). Android opens the bundled
  /// `libaleo_rust.so`; iOS finds the statically-linked symbols via
  /// `DynamicLibrary.process()`.
  ///
  /// Throws [IncompatibleNativeLibraryException] if the bundled library's ABI
  /// does not match (for example a stale artifact), or an [Exception] on a
  /// platform other than Android/iOS.
  ///
  /// The result can be passed straight into the aleo_dart constructors, which
  /// also accept a bare `DynamicLibrary`:
  /// ```dart
  /// final lib = AleoFlutter.load();
  /// final account = AleoAccount(lib, 'mainnet');
  /// final address = account.mnemonicToAddress(mnemonic);
  /// ```
  static AleoLib load() => AleoLib.coerce(DyLib.getMobileDyLib());
}
