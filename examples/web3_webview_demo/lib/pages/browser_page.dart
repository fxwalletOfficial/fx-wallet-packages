import 'package:flutter/material.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';

import 'package:web3_webview_demo/services/wallet_state.dart';

/// Navigation argument carried by the `/browser` route.
@immutable
class BrowserPageArgs {
  final String url;
  final String title;

  const BrowserPageArgs({required this.url, required this.title});
}

/// In-WebView dApp page.
///
/// Phase 1 only wires the read-only callbacks (`ethAccounts`, `ethChainId`,
/// `walletSwitchEthereumChain`) end-to-end so the existing `app.uniswap.org`
/// flow keeps working after the skeleton refactor. The signing / send /
/// Solana / approval-sheet behaviour ships in Phase 3+.
class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key, required this.args});

  final BrowserPageArgs args;

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  String _title = '';

  @override
  void initState() {
    super.initState();
    _title = widget.args.title;
  }

  @override
  Widget build(BuildContext context) {
    final wallet = WalletStateScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          _ChainChip(chainId: wallet.evmChainId),
          const SizedBox(width: 8),
          _AccountChip(address: wallet.evmAccount.evmAddress),
          const SizedBox(width: 8),
        ],
      ),
      body: Web3Webview(
        initialUrlRequest: URLRequest(url: WebUri(widget.args.url)),
        settings: Web3Settings(
          eth: Web3EthSettings(
            chainId: wallet.evmChainId,
            rdns: 'com.fxfi.fxwallet',
          ),
        ),
        shouldOverrideUrlLoading: (_, __) async =>
            NavigationActionPolicy.ALLOW,
        onTitleChanged: _onTitleChanged,
        ethAccounts: () async => [wallet.evmAccount.evmAddress],
        ethChainId: () async => wallet.evmChainId,
        walletSwitchEthereumChain: (JsAddEthereumChain data) async {
          final hex = (data.chainId ?? '').replaceFirst('0x', '');
          if (hex.isEmpty) return false;
          wallet.evmChainId = int.parse(hex, radix: 16);
          return true;
        },
      ),
    );
  }

  void _onTitleChanged(InAppWebViewController _, String? value) {
    if (value == null || value.isEmpty || value == _title) return;
    setState(() => _title = value);
  }
}

class _ChainChip extends StatelessWidget {
  const _ChainChip({required this.chainId});

  final int chainId;

  @override
  Widget build(BuildContext context) {
    final wallet = WalletStateScope.of(context);
    final chain = wallet.evmChain;
    return Chip(
      avatar: Icon(chain.icon, color: chain.color, size: 18),
      label: Text(chain.symbol),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final short = address.length <= 10
        ? address
        : '${address.substring(0, 6)}…${address.substring(address.length - 4)}';
    return Chip(
      avatar: const Icon(Icons.account_circle_outlined, size: 18),
      label: Text(short),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
