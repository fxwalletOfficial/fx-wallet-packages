import 'package:flutter/widgets.dart';

import 'package:web3_webview_demo/data/chains.dart';

/// Pre-generated demo wallet identity.
///
/// The EVM keys are the first three accounts of the well-known
/// `"test test test test test test test test test test test junk"`
/// mnemonic — i.e. the default Hardhat / Anvil accounts whose private keys
/// are printed on every local-node boot and published all over the
/// internet. They are used here precisely *because* they are public: the
/// demo can sign real secp256k1 signatures without ever holding a secret
/// that matters.
@immutable
class DemoAccount {
  /// Display name shown in pickers ("Account 1", "Account 2", …).
  final String label;

  /// 0x-prefixed checksummed EVM address.
  final String evmAddress;

  /// 0x-prefixed secp256k1 private key for [evmAddress]. **Public test
  /// key** (see the class doc) — never reuse for anything with value.
  final String evmPrivateKey;

  /// base58 Solana public key. The matching ed25519 secret key is wired in
  /// Phase 5 alongside the Solana signer.
  final String solanaAddress;

  /// BIP-44 derivation index (0, 1, 2 …).
  final int derivationIndex;

  const DemoAccount({
    required this.label,
    required this.evmAddress,
    required this.evmPrivateKey,
    required this.solanaAddress,
    required this.derivationIndex,
  });
}

/// The fixed set of demo identities. Three accounts is enough to exercise
/// the `accountsChanged` / `accountChanged` event flows without making the
/// picker noisy.
///
/// **DO NOT** use these keys for anything other than the demo.** They are
/// the default Hardhat / Anvil accounts derived from the openly-known
/// `"test test test test test test test test test test test junk"` phrase;
/// any funds sent to these addresses are immediately drained by bots that
/// scan for them.
///
///   * EVM uses BIP-44 path `m/44'/60'/0'/0/<index>` (keys below).
///   * Solana uses BIP-44 path `m/44'/501'/<index>'/0'` (Phase 5).
const List<DemoAccount> kDemoAccounts = <DemoAccount>[
  DemoAccount(
    label: 'Account 1',
    evmAddress: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
    evmPrivateKey:
        '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
    solanaAddress: '5ZWj7a1f8tWkjBESHKgrLmZhGh7yBR8Cmjw6aQGhRTMQ',
    derivationIndex: 0,
  ),
  DemoAccount(
    label: 'Account 2',
    evmAddress: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    evmPrivateKey:
        '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
    solanaAddress: 'GwHH8ciFhR8vejWCqmg8FWZUCNtubPY2esALvy5tBvji',
    derivationIndex: 1,
  ),
  DemoAccount(
    label: 'Account 3',
    evmAddress: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
    evmPrivateKey:
        '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a',
    solanaAddress: 'FN5sV1iyrnUMtSdaXbq5o24WnTcyJ4MEArytfSe6gE2c',
    derivationIndex: 2,
  ),
];

/// Mutable state shared across the demo (active account, active chain,
/// approval / broadcast preferences). Surfaces via `ChangeNotifier` so the
/// UI can rebuild via [InheritedNotifier] — keeps the dependency footprint
/// at zero third-party state-management packages.
class WalletState extends ChangeNotifier {
  WalletState({
    int evmAccountIndex = 0,
    int solanaAccountIndex = 0,
    int evmChainId = 1,
    String solanaClusterId = 'mainnet-beta',
    bool autoApproveReadMethods = true,
    bool realBroadcast = false,
  })  : _evmAccountIndex = evmAccountIndex,
        _solanaAccountIndex = solanaAccountIndex,
        _evmChainId = evmChainId,
        _solanaClusterId = solanaClusterId,
        _autoApproveReadMethods = autoApproveReadMethods,
        _realBroadcast = realBroadcast;

  int _evmAccountIndex;
  int _solanaAccountIndex;
  int _evmChainId;
  String _solanaClusterId;
  bool _autoApproveReadMethods;
  bool _realBroadcast;

  /// Currently selected EVM account.
  DemoAccount get evmAccount => kDemoAccounts[_evmAccountIndex];

  /// Currently selected Solana account. The demo lets the user switch the
  /// EVM and Solana accounts independently so the bridge log can show
  /// `accountsChanged` (EIP-1193) and `accountChanged` (wallet-standard)
  /// events firing on their own schedules.
  DemoAccount get solanaAccount => kDemoAccounts[_solanaAccountIndex];

  int get evmAccountIndex => _evmAccountIndex;
  int get solanaAccountIndex => _solanaAccountIndex;

  /// Active EVM chain id (decimal).
  int get evmChainId => _evmChainId;

  EvmChain get evmChain => evmChainById(_evmChainId);

  /// Active Solana cluster id (`mainnet-beta`, `devnet`, …).
  String get solanaClusterId => _solanaClusterId;

  SolanaCluster get solanaCluster => solanaClusterById(_solanaClusterId);

  /// When true, read-only RPC methods (`eth_accounts`, `eth_chainId`,
  /// `solana_account`) resolve immediately from this state without an
  /// approval dialog. Signing / sending / chain-switch requests always
  /// require manual confirmation regardless.
  bool get autoApproveReadMethods => _autoApproveReadMethods;

  /// When true, `eth_sendTransaction` and `solana_signAndSendTransaction`
  /// broadcast through the configured RPC endpoint instead of returning a
  /// mock tx hash. Only ever flipped on for testnets in the Phase 4/5
  /// settings UI — gating logic lives there so this flag stays a simple
  /// boolean.
  bool get realBroadcast => _realBroadcast;

  set evmAccountIndex(int value) {
    if (value < 0 || value >= kDemoAccounts.length) return;
    if (value == _evmAccountIndex) return;
    _evmAccountIndex = value;
    notifyListeners();
  }

  set solanaAccountIndex(int value) {
    if (value < 0 || value >= kDemoAccounts.length) return;
    if (value == _solanaAccountIndex) return;
    _solanaAccountIndex = value;
    notifyListeners();
  }

  set evmChainId(int value) {
    if (value == _evmChainId) return;
    _evmChainId = value;
    notifyListeners();
  }

  set solanaClusterId(String value) {
    if (value == _solanaClusterId) return;
    _solanaClusterId = value;
    notifyListeners();
  }

  set autoApproveReadMethods(bool value) {
    if (value == _autoApproveReadMethods) return;
    _autoApproveReadMethods = value;
    notifyListeners();
  }

  set realBroadcast(bool value) {
    if (value == _realBroadcast) return;
    _realBroadcast = value;
    notifyListeners();
  }
}

/// Inherited handle for [WalletState]. Pages call
/// `WalletStateScope.of(context)` to read the current state (and trigger
/// rebuilds), or `WalletStateScope.read(context)` for one-shot reads that
/// should *not* re-subscribe.
class WalletStateScope extends InheritedNotifier<WalletState> {
  const WalletStateScope({
    super.key,
    required WalletState super.notifier,
    required super.child,
  });

  /// Subscribing read: the calling widget rebuilds whenever
  /// [WalletState] notifies. Throws in debug if no scope is in the tree.
  static WalletState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<WalletStateScope>();
    assert(scope != null, 'WalletStateScope missing in widget tree');
    return scope!.notifier!;
  }

  /// Non-subscribing read for one-shot lookups inside callbacks / async
  /// handlers where re-running on every change would be wrong.
  static WalletState read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<WalletStateScope>();
    assert(scope != null, 'WalletStateScope missing in widget tree');
    return scope!.notifier!;
  }
}
