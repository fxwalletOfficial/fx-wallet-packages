import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart';

/// Provide default config for **btc**, address type is [AddressType.BTC], bip44 path is [BTC_PATH].
/// Testnet uses distinct version bytes, WIF, and bech32 HRP from mainnet. Use [HDWallet] to instantiate wallet.
class BTCChain extends ConfChain {
  BTCChain()
      : super(
            name: 'btc',
            mainnet: WalletSetting(
              bip44Path: BTC_PATH,
              addressType: AddressType.BTC,
              networkType: NetworkType(
                  messagePrefix: '\u0018Bitcoin Signed Message:\n',
                  bech32: 'bc',
                  wif: 128,
                  pubKeyHash: 0,
                  scriptHash: 5,
                  bip32: Bip32Type(public: 76067358, private: 76066276)),
            ),
            testnet: WalletSetting(
              bip44Path: BTC_PATH,
              addressType: AddressType.BTC,
              networkType: NetworkType(
                  messagePrefix: '\u0018Bitcoin Signed Message:\n',
                  bech32: 'tb',
                  wif: 239,
                  pubKeyHash: 0x6f,
                  scriptHash: 0xc4,
                  bip32: Bip32Type(public: 70617704, private: 70615956)),
            ));
}
