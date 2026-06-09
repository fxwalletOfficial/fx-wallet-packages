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
    // EIP-6963 requires a valid data-URI icon and a reverse-DNS rdns, so we
    // default to the built-in icon / rdns when the host app doesn't supply
    // them — an empty string makes strict DApps ignore the announcement.
    final ethereumIcon = jsonEncode(settings?.eth?.icon ?? WALLET_ICON);
    final rdns = jsonEncode(settings?.eth?.rdns ?? WALLET_RDNS);
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
        const announce = function() {
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
        };

        if (fxwallet.ethereum == null) {
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

          // Only claim window.ethereum if nothing else already has, so a
          // coexisting wallet isn't clobbered — EIP-6963 announcement below
          // handles discovery either way.
          if (window.ethereum == null) {
            window.ethereum = fxwallet.ethereum;
          }

          window.addEventListener('eip6963:requestProvider', announce);
        }

        // Always announce over EIP-6963, regardless of window.ethereum —
        // multi-provider coexistence is the entire point of the standard,
        // so an existing window.ethereum must not suppress our announce.
        announce();
      })();
    ''';
  }
}
