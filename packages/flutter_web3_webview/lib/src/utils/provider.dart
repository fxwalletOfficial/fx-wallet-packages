import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:uuid/uuid.dart';

import 'package:flutter_web3_webview/src/config/params.dart';
import 'package:flutter_web3_webview/src/models/settings.dart';

class Providers {
  final String uuid;
  final Web3Settings? settings;
  Providers({this.settings}) : uuid = const Uuid().v4();

  static String _js = '';
  static Future<void>? _initializing;
  static String get js => _js;

  static Future<void> init({AssetBundle? bundle}) async {
    if (_js.isNotEmpty) return;
    if (_initializing != null) return _initializing;

    _initializing = _load(bundle ?? rootBundle);
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _js = '';
    _initializing = null;
  }

  static Future<void> _load(AssetBundle bundle) async {
    try {
      _js = await bundle
          .loadString('packages/flutter_web3_webview/js/provider.min.js');
    } catch (_) {
      return;
    }
  }

  String getInitJs() {
    final walletName = jsonEncode(settings?.name ?? WALLET_NAME);
    final solanaIcon = jsonEncode(settings?.sol?.icon ?? WALLET_ICON);
    final ethereumIcon = jsonEncode(settings?.eth?.icon ?? '');
    final rdns = jsonEncode(settings?.eth?.rdns ?? '');
    final providerUuid = jsonEncode(uuid);
    final overwriteMetamask = settings?.eth?.overwriteMetamask ?? false;

    // NOTE on the config shape: `EthereumProvider` / `SolanaProvider` read
    // their options from the *top level* of this object (`config.chainId`,
    // `config.overwriteMetamask`, `config.isFxWallet`, …). The nested
    // `ethereum` / `solana` blocks below are legacy from the pre-rebuild
    // fork and are NOT read by the vendored providers — they are kept only
    // for backwards-compatibility with anything that might inspect them.
    // Anything that must actually reach a provider has to be a top-level
    // field, which is why `overwriteMetamask` lives here and not under
    // `ethereum`. (`chainId` / `cluster` are intentionally NOT promoted:
    // chain id is served by the Dart `ethChainId` callback, and promoting
    // `cluster: 'mainnet-beta'` would make SolanaProvider construct a
    // `Connection('mainnet-beta')` against an invalid RPC URL.)
    return '''
      (function() {
        if (window.ethereum != null) return;

        const config = {
          overwriteMetamask: $overwriteMetamask,
          ethereum: {
            chainId: ${settings?.eth?.chainId ?? 1}
          },
          solana: {
            cluster: 'mainnet-beta',
            icon: $solanaIcon,
            name: $walletName
          },
          isDebug: false
        };

        fxwallet.ethereum = new fxwallet.Provider(config);
        fxwallet.solana = new window.fxwallet.SolanaProvider(config);
        window.ethereum = fxwallet.ethereum;

        const event = new CustomEvent('eip6963:announceProvider', {
          detail: {
            info: {
              uuid: $providerUuid,
              name: $walletName,
              icon: $ethereumIcon,
              rdns: $rdns
            },
            provider: fxwallet.ethereum
          }
        });
        window.dispatchEvent(event);
        window.addEventListener('eip6963:requestProvider', () => {
          window.dispatchEvent(event);
        });
      })();
    ''';
  }
}
