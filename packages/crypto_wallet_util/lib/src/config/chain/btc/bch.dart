import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **bch**, address type is [AddressType.BTC], bip44 path is [BCH_PATH].
/// Testnet uses the bchtest CashAddr prefix and Bitcoin testnet version bytes.
class BCHChain extends ConfChain {
  BCHChain()
    : super(
        name: 'bch',
        mainnet: WalletSetting(
          bip44Path: BCH_PATH,
          addressType: AddressType.BTC,
          prefix: BITCOINCASH_PREFIX,
          networkType: NetworkType(
            messagePrefix: '\u0019BitcoinCash Signed Message:\n',
            wif: 128,
            pubKeyHash: 0,
            scriptHash: 5,
            prefix: BITCOINCASH_PREFIX,
            bip32: Bip32Type(public: 76067358, private: 76066276),
          ),
        ),
        testnet: WalletSetting(
          bip44Path: BCH_PATH,
          addressType: AddressType.BTC,
          prefix: BITCOINCASH_TESTNET_PREFIX,
          networkType: NetworkType(
            messagePrefix: '\u0019BitcoinCash Signed Message:\n',
            wif: 239,
            pubKeyHash: 0x6f,
            scriptHash: 0xc4,
            prefix: BITCOINCASH_TESTNET_PREFIX,
            bip32: Bip32Type(public: 70617704, private: 70615956),
          ),
        ),
      );
}
