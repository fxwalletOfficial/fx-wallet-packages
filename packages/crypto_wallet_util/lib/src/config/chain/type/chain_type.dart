import 'package:crypto_wallet_util/src/type/wallet_type.dart';

/// To save config of chain, including [mainnet] wallet setting and [testnet] one. The [name] is a unique identification.
class ConfChain {
  /// Chain name for selected.
  final String name;

  /// Chain conf for mainnet.
  final WalletSetting mainnet;

  /// Chain conf for testnet.
  final WalletSetting testnet;

  ConfChain({
    required this.name,
    required this.mainnet,
    required this.testnet
  });
}