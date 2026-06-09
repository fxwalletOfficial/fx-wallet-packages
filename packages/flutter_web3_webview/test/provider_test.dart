import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/src/config/params.dart';
import 'package:flutter_web3_webview/src/models/settings.dart';
import 'package:flutter_web3_webview/src/utils/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Providers.resetForTesting);

  group('Providers.init', () {
    test('loads the bundled provider JavaScript', () async {
      await Providers.init();

      expect(Providers.js, isNotEmpty);
      expect(Providers.js, contains('FxWalletHandler'));
    });

    test('loads provider JavaScript from an injected asset bundle', () async {
      final bundle = _TestAssetBundle(
        loadString: (_) async => 'custom-provider-js',
      );

      await Providers.init(bundle: bundle);

      expect(Providers.js, 'custom-provider-js');
      expect(bundle.loadCount, 1);
    });

    test('does not reload provider JavaScript after initialization', () async {
      final bundle = _TestAssetBundle(
        loadString: (_) async => 'cached-provider-js',
      );

      await Providers.init(bundle: bundle);
      await Providers.init(bundle: bundle);

      expect(Providers.js, 'cached-provider-js');
      expect(bundle.loadCount, 1);
    });

    test('shares a single load across concurrent initialization calls',
        () async {
      final completer = Completer<String>();
      final bundle = _TestAssetBundle(loadString: (_) => completer.future);

      final first = Providers.init(bundle: bundle);
      final second = Providers.init(bundle: bundle);
      completer.complete('concurrently-loaded-js');
      await Future.wait([first, second]);

      expect(Providers.js, 'concurrently-loaded-js');
      expect(bundle.loadCount, 1);
    });

    test('leaves provider JavaScript empty when loading fails', () async {
      final bundle = _TestAssetBundle(
        loadString: (_) => Future<String>.error(Exception('load failed')),
      );

      await Providers.init(bundle: bundle);

      expect(Providers.js, isEmpty);
      expect(bundle.loadCount, 1);
    });

    test('allows initialization to retry after loading fails', () async {
      final failingBundle = _TestAssetBundle(
        loadString: (_) => Future<String>.error(Exception('load failed')),
      );
      final successfulBundle = _TestAssetBundle(
        loadString: (_) async => 'recovered-provider-js',
      );

      await Providers.init(bundle: failingBundle);
      await Providers.init(bundle: successfulBundle);

      expect(Providers.js, 'recovered-provider-js');
      expect(failingBundle.loadCount, 1);
      expect(successfulBundle.loadCount, 1);
    });
  });

  group('Providers.getInitJs', () {
    test('creates unique provider UUIDs', () {
      final first = Providers();
      final second = Providers();

      expect(first.uuid, isNotEmpty);
      expect(first.uuid, isNot(second.uuid));
    });

    test('uses default wallet configuration', () {
      final provider = Providers();
      final script = provider.getInitJs();

      expect(script, contains('chainId: 1'));
      expect(script, contains('icon: ${jsonEncode(WALLET_ICON)}'));
      expect(script, contains('name: ${jsonEncode(WALLET_NAME)}'));
      expect(script, contains('uuid: ${jsonEncode(provider.uuid)}'));
      expect(script, contains('icon: ""'));
      expect(script, contains('rdns: ""'));
      expect(script, contains("new CustomEvent('eip6963:announceProvider'"));
      expect(script,
          contains("window.addEventListener('eip6963:requestProvider'"));
    });

    test('emits overwriteMetamask at the top level of the config', () {
      // The vendored EthereumProvider reads `config.overwriteMetamask`
      // (top level), not a nested `ethereum.isMetamask`, so the flag must
      // be a top-level field for `window.ethereum.isMetaMask` to take it.
      expect(Providers().getInitJs(),
          contains('overwriteMetamask: false'));

      final impersonating = Providers(
        settings: Web3Settings(eth: Web3EthSettings(overwriteMetamask: true)),
      );
      expect(impersonating.getInitJs(),
          contains('overwriteMetamask: true'));
    });

    test('uses custom EVM and Solana configuration', () {
      final provider = Providers(
        settings: Web3Settings(
          name: 'Custom Wallet',
          eth: Web3EthSettings(
            chainId: 137,
            icon: 'eth-icon',
            rdns: 'com.example.wallet',
          ),
          sol: Web3SolSettings(icon: 'sol-icon'),
        ),
      );

      final script = provider.getInitJs();

      expect(script, contains('chainId: 137'));
      expect(script, contains('name: "Custom Wallet"'));
      expect(script, contains('icon: "sol-icon"'));
      expect(script, contains('icon: "eth-icon"'));
      expect(script, contains('rdns: "com.example.wallet"'));
    });

    test('JSON-encodes user-controlled strings before JavaScript injection',
        () {
      const unsafeValue = "wallet';\nwindow.compromised = true;//";
      final provider = Providers(
        settings: Web3Settings(
          name: unsafeValue,
          eth: Web3EthSettings(icon: unsafeValue, rdns: unsafeValue),
          sol: Web3SolSettings(icon: unsafeValue),
        ),
      );

      final script = provider.getInitJs();
      final encodedValue = jsonEncode(unsafeValue);

      expect(script, contains('name: $encodedValue'));
      expect(script, contains('icon: $encodedValue'));
      expect(script, contains('rdns: $encodedValue'));
      expect(script, isNot(contains("name: '$unsafeValue'")));
    });
  });
}

class _TestAssetBundle extends AssetBundle {
  final Future<String> Function(String key) _loadString;
  int loadCount = 0;

  _TestAssetBundle({required Future<String> Function(String key) loadString})
      : _loadString = loadString;

  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError();
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    loadCount++;
    return _loadString(key);
  }
}
