import 'package:crypto_wallet_util/crypto_utils.dart';

/// Canonical BTCB2 chain identifier used by the transaction protocol.
const String BTCB2_CHAIN_NAME = 'btcb2';

/// Backwards-compatible ticker alias for [BTCB2_CHAIN_NAME].
const String XBT_CHAIN_NAME = 'xbt';

/// Provide the BTCB2 mainnet configuration.
///
/// BTCB2 uses Bitcoin mainnet address and key encodings, but remains a
/// distinct chain identity for transaction assembly and signing.
class BTCB2Chain extends ConfChain {
  BTCB2Chain()
    : super(
        name: BTCB2_CHAIN_NAME,
        mainnet: _mainnetSetting(),
        // ConfChain requires a testnet setting. BTCB2 testnet transaction
        // assembly is intentionally unsupported, so keep this as the
        // mainnet encoding rather than advertising an unimplemented network.
        testnet: _mainnetSetting(),
      );

  /// Returns whether [value] is the canonical name or a supported alias.
  static bool matchesName(String value) {
    final normalized = value.toLowerCase();
    return normalized == BTCB2_CHAIN_NAME || normalized == XBT_CHAIN_NAME;
  }
}

WalletSetting _mainnetSetting() => WalletSetting(
  bip44Path: BTC_PATH,
  addressType: AddressType.BTC,
  networkType: NetworkType(
    messagePrefix: '\u0018Bitcoin Signed Message:\n',
    bech32: 'bc',
    wif: 128,
    pubKeyHash: 0,
    scriptHash: 5,
    bip32: Bip32Type(public: 76067358, private: 76066276),
  ),
);
