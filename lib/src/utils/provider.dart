import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';

import 'package:flutter_web3_webview/src/config/params.dart';
import 'package:flutter_web3_webview/src/models/settings.dart';

class Providers {
  final String uuid;
  final Web3Settings? settings;
  Providers({this.settings}) : uuid = const Uuid().v4();

  static String _js = '';
  static String get js => _js;

  static Future<void> init() async {
    if (_js.isNotEmpty) return;

    try {
      _js = await rootBundle
          .loadString('packages/flutter_web3_webview/js/provider.min.js');
    } catch (e) {
      return;
    }
  }

  String getInitJs() {
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
            icon: '${settings?.sol?.icon ?? WALLET_ICON}',
            name: '${settings?.name ?? WALLET_NAME}'
          },
          isDebug: false
        };

        fxwallet.ethereum = new fxwallet.Provider(config);
        fxwallet.solana = new window.fxwallet.SolanaProvider(config);
        window.ethereum = fxwallet.ethereum;

        const event = new CustomEvent('eip6963:announceProvider', {
          detail: {
            info: {
              uuid: '$uuid',
              name: '${settings?.name ?? WALLET_NAME}',
              icon: '${settings?.eth?.icon ?? ''}',
              rdns: '${settings?.eth?.rdns ?? ''}'
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
