// On-device/simulator acceptance suite (PR6 spec §9). Builds the app with the
// bundled AleoRust.framework / libaleo_rust.so, then at runtime dlopens it and
// exercises it. Run with:
//   flutter test integration_test/load_test.dart -d <simulator-or-device>

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aleo_flutter/aleo_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Canonical bip39 test mnemonic — demo only, never a real wallet.
  const mnemonic = 'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon about';

  test('loads the bundled aleo_rust library and derives an address', () {
    // Validates ffi_abi_version at load (throws IncompatibleNativeLibraryException
    // on a stale/mismatched library).
    final lib = AleoFlutter.load();

    final account = AleoAccount(lib, 'mainnet');
    final address = account.mnemonicToAddress(mnemonic);

    expect(address, startsWith('aleo1'));
    expect(address.length, greaterThan(50));
  });

  // Offline operations (nice-to-have §9). A full account + sign/verify roundtrip
  // with NO network: AleoFlutter.load() is a dlopen (no download) and these APIs
  // are pure local compute over the bundled library, so they work in airplane
  // mode — i.e. there is no runtime download. (Toggling OS-level airplane mode is
  // a manual device step; this exercises the offline code paths themselves.)
  test('runs offline account + sign/verify operations (no runtime download)',
      () {
    final lib = AleoFlutter.load();
    final account = AleoAccount(lib, 'mainnet');

    final privateKey = account.mnemonicToPrivateKey(mnemonic);
    final address = account.mnemonicToAddress(mnemonic);
    final viewKey = account.mnemonicToViewKey(mnemonic);
    expect(privateKey, startsWith('APrivateKey1'));
    expect(address, startsWith('aleo1'));
    expect(viewKey, startsWith('AViewKey1'));

    final message =
        Uint8List.fromList(utf8.encode('aleo_flutter offline test'));
    final signature = account.sign(privateKey, message);
    expect(account.isValidSignature(address, signature, message), isTrue);

    // A tampered message must NOT verify against the same signature.
    final tampered =
        Uint8List.fromList(utf8.encode('aleo_flutter offline tesT'));
    expect(account.isValidSignature(address, signature, tampered), isFalse);
  });

  // ABI guard (nice-to-have §9). A library whose ffi_abi_version does not match
  // what this package expects must be rejected at load
  // (IncompatibleNativeLibraryException), not silently mis-bound. Simulated by
  // validating the real, loaded library against a deliberately wrong expected
  // version — the same code path a genuinely mismatched artifact would hit.
  test(
      'rejects an ABI-mismatched library with IncompatibleNativeLibraryException',
      () {
    final lib = AleoFlutter.load(); // the real library (its version matches)
    expect(
      () => AleoLib.fromDynamicLibrary(
        lib.dyLib,
        expected: AleoLib.expectedAbiVersion + 1,
      ),
      throwsA(isA<IncompatibleNativeLibraryException>()),
    );
  });
}
