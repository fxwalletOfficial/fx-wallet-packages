// On-device/simulator acceptance test (PR6 spec §9): load the build-time-bundled
// native library and run a cheap, offline API. This is the real gate — it builds
// the app with the bundled AleoRust.framework, then at runtime dlopens it and
// calls into it. Run with:
//   flutter test integration_test/load_test.dart -d <simulator-or-device>

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aleo_flutter/aleo_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('loads the bundled aleo_rust framework and derives an address offline',
      () {
    // Validates ffi_abi_version at load (throws IncompatibleNativeLibraryException
    // on a stale/mismatched library).
    final lib = AleoFlutter.load();

    final account = AleoAccount(lib, 'mainnet');
    final address = account.mnemonicToAddress(
      'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon about',
    );

    expect(address, startsWith('aleo1'));
    expect(address.length, greaterThan(50));
  });
}
