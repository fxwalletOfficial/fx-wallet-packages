import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart';

/// Provide default config for **ltc**, address type is [AddressType.BTC], bip44 path is [LTC_PATH].  
/// Testnet and mainnet share the same setting. Use [HDWallet] to to instantiate wallet.
class LTCChain extends ConfChain {
  LTCChain()
      : super(
            name: 'ltc',
            mainnet: WalletSetting(
              bip44Path: LTC_PATH,
              addressType: AddressType.BTC,
              networkType: NetworkType(
                  messagePrefix: '\x19Litecoin Signed Message:\n',
                  bech32: 'ltc',
                  wif: 0xb0,
                  pubKeyHash: 0x30,
                  scriptHash: 0x32,
                  bip32: Bip32Type(public: 0x019da462, private: 0x019d9cfe)),
            ),
            testnet: WalletSetting(
              bip44Path: LTC_PATH,
              addressType: AddressType.BTC,
              networkType: NetworkType(
                  messagePrefix: '\x19Litecoin Signed Message:\n',
                  bech32: 'ltc',
                  wif: 0xb0,
                  pubKeyHash: 0x30,
                  scriptHash: 0x32,
                  bip32: Bip32Type(public: 0x019da462, private: 0x019d9cfe)),
            ));
}
