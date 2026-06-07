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

    return '''
      (function() {
        if (window.ethereum != null) return;

        const config = {
          ethereum: {
            chainId: ${settings?.eth?.chainId ?? 1},
            isMetamask: false
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
