import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart';

/// Provide default config for **btc**, address type is [AddressType.BTC], bip44 path is [BTC_PATH].  
/// Testnet and mainnet share the same setting. Use [HDWallet] to to instantiate wallet.
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
                  bech32: 'bc',
                  wif: 128,
                  pubKeyHash: 0,
                  scriptHash: 5,
                  bip32: Bip32Type(public: 76067358, private: 76066276)),
            ));
}
