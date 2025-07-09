import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart';

/// Provide default config for **doge**, address type is [AddressType.BTC], bip44 path is [DOGE_PATH].  
/// Testnet and mainnet share the same setting. Use [HDWallet] to to instantiate wallet.
class DOGEChain extends ConfChain {
  DOGEChain()
      : super(
            name: 'doge',
            mainnet: WalletSetting(
              bip44Path: DOGE_PATH,
              addressType: AddressType.BTC,
              networkType: NetworkType(
                  messagePrefix: '\x19Dogecoin Signed Message:\n',
                  wif: 0x9e,
                  pubKeyHash: 0x1e,
                  scriptHash: 0x16,
                  bip32: Bip32Type(public: 0x02facafd, private: 0x02fac398)),
            ),
            testnet: WalletSetting(
              bip44Path: DOGE_PATH,
              addressType: AddressType.BTC,
              networkType: NetworkType(
                  messagePrefix: '\x19Dogecoin Signed Message:\n',
                  wif: 0x9e,
                  pubKeyHash: 0x1e,
                  scriptHash: 0x16,
                  bip32: Bip32Type(public: 0x02facafd, private: 0x02fac398)),
            ));
}
