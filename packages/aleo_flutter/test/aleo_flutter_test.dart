// Pure-Dart unit tests for the artifact manifest (the integrity anchor). These
// run without the native library — the on-device load + API acceptance is the
// example app's job (spec §9).

import 'package:flutter_test/flutter_test.dart';
import 'package:aleo_dart/aleo.dart';

import 'package:aleo_flutter/src/artifact_manifest.dart';

void main() {
  group('artifact manifest', () {
    test('manifest ABI version matches the aleo_dart loader guard', () {
      // If these drift, the bundled library would be rejected at load. Bump them
      // together with the Rust ffi_abi_version.
      expect(aleoFfiAbiVersion, AleoLib.expectedAbiVersion);
    });

    test('release tag is namespaced and is referenced by both asset URLs', () {
      expect(aleoFfiReleaseTag, startsWith('aleo_ffi-v'));
      expect(aleoIosArtifactUrl, contains(aleoFfiReleaseTag));
      expect(aleoAndroidArtifactUrl, contains(aleoFfiReleaseTag));
    });

    test('asset URLs are GitHub Release download URLs', () {
      const prefix =
          'https://github.com/fxwalletOfficial/fx-wallet-packages/releases/download/';
      expect(aleoIosArtifactUrl, startsWith(prefix));
      expect(aleoAndroidArtifactUrl, startsWith(prefix));
    });

    test('SHA-256 fields are 64 lowercase hex chars', () {
      final hex64 = RegExp(r'^[0-9a-f]{64}$');
      expect(hex64.hasMatch(aleoIosArtifactSha256), isTrue);
      expect(hex64.hasMatch(aleoAndroidArtifactSha256), isTrue);
    });
  });
}
