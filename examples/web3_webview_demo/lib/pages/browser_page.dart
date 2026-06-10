import 'package:flutter/material.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';

import 'package:web3_webview_demo/data/chains.dart';
import 'package:web3_webview_demo/services/bridge_log.dart';
import 'package:web3_webview_demo/services/eth_signer.dart';
import 'package:web3_webview_demo/services/request_summary.dart';
import 'package:web3_webview_demo/services/sol_signer.dart';
import 'package:web3_webview_demo/services/wallet_state.dart';
import 'package:web3_webview_demo/widgets/approval_sheet.dart';
import 'package:web3_webview_demo/widgets/debug_panel.dart';

/// Navigation argument carried by the `/browser` route.
@immutable
class BrowserPageArgs {
  final String url;
  final String title;

  const BrowserPageArgs({required this.url, required this.title});
}

/// Thrown when the user rejects an approval sheet. Its [toString] is the
/// EIP-1193 `4001` JSON shape so the DApp sees the same rejection a real
/// wallet would surface through the bridge.
class UserRejectedException implements Exception {
  const UserRejectedException();

  @override
  String toString() => '{"code":4001,"message":"User rejected the request"}';
}

/// In-WebView dApp page with the full `flutter_web3_webview` callback set
/// wired through an approval sheet and a bridge log.
///
/// Read-only methods (`eth_accounts`, `eth_chainId`, `solana_account`)
/// resolve immediately when `autoApproveReadMethods` is on; everything
/// that signs / sends / switches chain always prompts. Every round-trip is
/// recorded in the [BridgeLog].
class BrowserPage extends StatefulWidget {
  const BrowserPage({
    super.key,
    required this.args,
    this.ethSigner = const MockEthSigner(),
    this.solSigner = const MockSolSigner(),
  });

  final BrowserPageArgs args;
  final EthSigner ethSigner;
  final SolSigner solSigner;

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  String _title = '';
  InAppWebViewController? _controller;

  // The WalletState this page is currently subscribed to, plus the last
  // values we pushed to the page, so we only emit an event when something
  // actually changed (e.g. the user switched account / chain in Settings
  // while this DApp stayed open in the background).
  WalletState? _boundWallet;
  int? _lastChainId;
  String? _lastEvmAddress;
  String? _lastSolAddress;

  @override
  void initState() {
    super.initState();
    _title = widget.args.title;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wallet = WalletStateScope.of(context);
    if (!identical(wallet, _boundWallet)) {
      _boundWallet?.removeListener(_onWalletChanged);
      _boundWallet = wallet;
      _boundWallet!.addListener(_onWalletChanged);
      _lastChainId = wallet.evmChainId;
      _lastEvmAddress = wallet.evmAccount.evmAddress;
      _lastSolAddress = wallet.solanaAccount.solanaAddress;
    }
  }

  @override
  void dispose() {
    _boundWallet?.removeListener(_onWalletChanged);
    super.dispose();
  }

  /// Push EIP-1193 / wallet-standard events into the page when the active
  /// identity changes out-of-band (i.e. not as the direct result of a DApp
  /// request). This is the demo's showcase of the *wallet → DApp*
  /// direction of the bridge.
  void _onWalletChanged() {
    final wallet = _boundWallet;
    final controller = _controller;
    if (wallet == null || controller == null) return;

    if (wallet.evmChainId != _lastChainId) {
      _lastChainId = wallet.evmChainId;
      final hex = '0x${wallet.evmChainId.toRadixString(16)}';
      _emit('window.ethereum.emitChainChanged("$hex")');
      _log.record(method: 'emitChainChanged', request: hex);
    }
    if (wallet.evmAccount.evmAddress != _lastEvmAddress) {
      _lastEvmAddress = wallet.evmAccount.evmAddress;
      _emit('window.ethereum.emitAccountsChanged('
          '["${wallet.evmAccount.evmAddress}"])');
      _log.record(
          method: 'emitAccountsChanged',
          request: [wallet.evmAccount.evmAddress]);
    }
    if (wallet.solanaAccount.solanaAddress != _lastSolAddress) {
      _lastSolAddress = wallet.solanaAccount.solanaAddress;
      _emit('window.fxwallet && window.fxwallet.solana && '
          'window.fxwallet.solana.emitAccountChanged()');
      _log.record(
          method: 'solana.emitAccountChanged',
          request: wallet.solanaAccount.solanaAddress);
    }
  }

  void _emit(String expression) {
    // Guard every emit so a page that hasn't injected the provider (or a
    // non-web3 page) never throws inside evaluateJavascript.
    _controller?.evaluateJavascript(
        source: 'try { $expression } catch (e) {}');
  }

  @override
  Widget build(BuildContext context) {
    final wallet = WalletStateScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          _ChainChip(),
          const SizedBox(width: 4),
          _AccountChip(address: wallet.evmAccount.evmAddress),
          IconButton(
            icon: const Icon(Icons.terminal),
            tooltip: 'Bridge log',
            onPressed: () =>
                DebugPanel.show(context, BridgeLogScope.read(context)),
          ),
        ],
      ),
      body: Web3Webview(
        initialUrlRequest: URLRequest(url: WebUri(widget.args.url)),
        settings: Web3Settings(
          eth: Web3EthSettings(
            chainId: wallet.evmChainId,
            rdns: 'com.fxfi.fxwallet',
            // Impersonate MetaMask so DApps that gate signing on
            // `isMetaMask` (e.g. the official MetaMask test dapp) expose
            // their full surface to the demo.
            overwriteMetamask: true,
          ),
        ),
        onWebViewCreated: (c) => _controller = c,
        shouldOverrideUrlLoading: (_, __) async =>
            NavigationActionPolicy.ALLOW,
        onTitleChanged: _onTitleChanged,
        // ── read-only ────────────────────────────────────────────────
        ethAccounts: () => _runRead<List<String>>(
          method: 'eth_accounts',
          action: () async => [_wallet.evmAccount.evmAddress],
        ),
        ethChainId: () => _runRead<int>(
          method: 'eth_chainId',
          action: () async => _wallet.evmChainId,
        ),
        solAccount: () => _runRead<String>(
          method: 'solana_account',
          action: () async => _wallet.solanaAccount.solanaAddress,
        ),
        // ── EVM signing ─────────────────────────────────────────────
        ethPersonalSign: (message) => _runApproved<String>(
          method: 'personal_sign',
          request: message,
          summary: RequestSummary.ethMessage(
            title: 'Sign message',
            account: _wallet.evmAccount.evmAddress,
            message: message,
          ),
          action: () => widget.ethSigner.personalSign(
            account: _wallet.evmAccount,
            message: message,
          ),
        ),
        ethSign: (message) => _runApproved<String>(
          method: 'eth_sign',
          request: message,
          summary: RequestSummary.ethMessage(
            title: 'Sign message (eth_sign)',
            account: _wallet.evmAccount.evmAddress,
            message: message,
          ),
          action: () => widget.ethSigner.ethSign(
            account: _wallet.evmAccount,
            message: message,
          ),
        ),
        ethSignTypedData: (payload) => _runApproved<String>(
          method: 'eth_signTypedData',
          request: payload,
          summary: RequestSummary.ethTypedData(
            account: _wallet.evmAccount.evmAddress,
            payload: payload,
          ),
          action: () => widget.ethSigner.signTypedData(
            account: _wallet.evmAccount,
            payload: payload,
          ),
        ),
        ethSendTransaction: (tx) => _runApproved<String>(
          method: 'eth_sendTransaction',
          request: tx.toJson(),
          summary: RequestSummary.ethTransaction(transaction: tx),
          dangerous: true,
          confirmLabel: 'Send',
          action: () => widget.ethSigner.sendTransaction(
            account: _wallet.evmAccount,
            transaction: tx,
            broadcast: _wallet.realBroadcast,
            rpcUrl: _wallet.evmChain.rpcUrl,
          ),
        ),
        walletSwitchEthereumChain: _switchChain,
        walletAddEthereumChain: _addChain,
        // ── Solana signing ──────────────────────────────────────────
        solSignMessage: (data) => _runApproved<String>(
          method: 'solana_signMessage',
          request: data.params,
          summary: RequestSummary.solMessage(
            account: _wallet.solanaAccount.solanaAddress,
            data: data,
          ),
          action: () => widget.solSigner.signMessage(
            account: _wallet.solanaAccount,
            data: data,
          ),
        ),
        solSignTransaction: (data) => _runApproved<String>(
          method: 'solana_signTransaction',
          request: data.params,
          summary: RequestSummary.solTransaction(
            account: _wallet.solanaAccount.solanaAddress,
            data: data,
          ),
          action: () => widget.solSigner.signTransaction(
            account: _wallet.solanaAccount,
            data: data,
          ),
        ),
        onDefaultCallback: (data) => _runUnknown(data),
      ),
    );
  }

  WalletState get _wallet => WalletStateScope.read(context);
  BridgeLog get _log => BridgeLogScope.read(context);

  void _onTitleChanged(InAppWebViewController _, String? value) {
    if (value == null || value.isEmpty || value == _title) return;
    setState(() => _title = value);
  }

  /// Read-only method runner: resolves immediately when auto-approve is on,
  /// otherwise prompts. Always records the round-trip.
  Future<T> _runRead<T>({
    required String method,
    required Future<T> Function() action,
  }) async {
    final log = _log;
    final id = log.begin(method: method, request: null);
    final sw = Stopwatch()..start();
    try {
      if (!_wallet.autoApproveReadMethods) {
        final approved = await _confirm(
          title: 'Connect request',
          method: method,
          rows: [
            MapEntry('Method', method),
            MapEntry('Account', _wallet.evmAccount.evmAddress),
          ],
        );
        if (!approved) throw const UserRejectedException();
      }
      final result = await action();
      sw.stop();
      log.resolve(id, response: result, elapsed: sw.elapsed);
      return result;
    } catch (e) {
      sw.stop();
      log.reject(id, error: e.toString(), elapsed: sw.elapsed);
      rethrow;
    }
  }

  /// Signing / sending runner: always prompts, runs [action] on approval.
  Future<T> _runApproved<T>({
    required String method,
    required Object? request,
    required RequestSummary summary,
    required Future<T> Function() action,
    bool dangerous = false,
    String confirmLabel = 'Approve',
  }) async {
    final log = _log;
    final id = log.begin(method: method, request: request);
    final sw = Stopwatch()..start();
    try {
      final approved = await _confirm(
        title: summary.title,
        method: method,
        rows: summary.rows,
        dangerous: dangerous,
        confirmLabel: confirmLabel,
      );
      if (!approved) throw const UserRejectedException();
      final result = await action();
      sw.stop();
      log.resolve(id, response: result, elapsed: sw.elapsed);
      return result;
    } catch (e) {
      sw.stop();
      log.reject(id, error: e.toString(), elapsed: sw.elapsed);
      rethrow;
    }
  }

  /// `wallet_switchEthereumChain` returns a bool — the dispatcher turns a
  /// `false` into the EIP-1193 rejection itself, so we don't throw here.
  Future<bool> _switchChain(JsAddEthereumChain data) async {
    final log = _log;
    final id = log.begin(
        method: 'wallet_switchEthereumChain', request: data.toJson());
    final sw = Stopwatch()..start();

    final hex = (data.chainId ?? '').replaceFirst('0x', '');
    if (hex.isEmpty) {
      sw.stop();
      log.reject(id, error: 'missing chainId', elapsed: sw.elapsed);
      return false;
    }
    final targetId = int.tryParse(hex, radix: 16);
    if (targetId == null) {
      sw.stop();
      log.reject(id, error: 'invalid chainId 0x$hex', elapsed: sw.elapsed);
      return false;
    }

    final target = evmChainById(targetId);
    final approved = await _confirm(
      title: 'Switch chain',
      method: 'wallet_switchEthereumChain',
      rows: [
        MapEntry('From', _wallet.evmChain.name),
        MapEntry('To', '${target.name} (chainId $targetId)'),
      ],
    );
    sw.stop();
    if (!approved) {
      log.reject(id, error: 'user rejected', elapsed: sw.elapsed);
      return false;
    }
    _wallet.evmChainId = targetId;
    log.resolve(id, response: '0x${targetId.toRadixString(16)}',
        elapsed: sw.elapsed);
    return true;
  }

  /// EIP-3085 `wallet_addEthereumChain`. The demo treats this as "register
  /// the chain": it shows an approval sheet and, on approval, returns true
  /// WITHOUT switching the active chain (that's `_switchChain`'s job). The
  /// package then resolves the DApp call with null; with no add handler wired
  /// it would instead reject with EIP-1193 `4200` (unsupported method).
  Future<bool> _addChain(JsAddEthereumChain data) async {
    final log = _log;
    final id =
        log.begin(method: 'wallet_addEthereumChain', request: data.toJson());
    final sw = Stopwatch()..start();

    final hex = (data.chainId ?? '').replaceFirst('0x', '');
    final targetId = int.tryParse(hex, radix: 16);
    if (targetId == null) {
      sw.stop();
      log.reject(id, error: 'invalid chainId', elapsed: sw.elapsed);
      return false;
    }

    final target = evmChainById(targetId);
    final approved = await _confirm(
      title: 'Add chain',
      method: 'wallet_addEthereumChain',
      rows: [
        MapEntry('Chain', '${target.name} (chainId $targetId)'),
        const MapEntry('Note', 'Adds the network without switching to it'),
      ],
    );
    sw.stop();
    if (!approved) {
      log.reject(id, error: 'user rejected', elapsed: sw.elapsed);
      return false;
    }
    // Intentionally does NOT change _wallet.evmChainId — add must not switch.
    log.resolve(id, response: 'added (resolves null)', elapsed: sw.elapsed);
    return true;
  }

  /// Anything the dispatcher didn't have a typed route for. We log it and
  /// reject so a DApp calling an unsupported method gets a clear error
  /// instead of a silent hang.
  Future<dynamic> _runUnknown(JsCallBackData data) async {
    _log.record(
      method: data.method.isEmpty ? '(unknown)' : data.method,
      request: data.params,
      error: 'No handler in demo wallet for "${data.method}"',
    );
    throw Exception('Unsupported method: ${data.method}');
  }

  Future<bool> _confirm({
    required String title,
    required String method,
    required List<MapEntry<String, String>> rows,
    bool dangerous = false,
    String confirmLabel = 'Approve',
  }) async {
    if (!mounted) return false;
    return ApprovalSheet.show(
      context,
      title: title,
      rows: rows,
      method: method,
      dangerous: dangerous,
      confirmLabel: confirmLabel,
    );
  }
}

class _ChainChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chain = WalletStateScope.of(context).evmChain;
    return Chip(
      avatar: Icon(chain.icon, color: chain.color, size: 18),
      label: Text(chain.symbol),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
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
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}
