import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **hns**, address type is [AddressType.BECH32], bip44 path is [HNS_PATH].
/// Testnet and mainnet share the different setting. Use [mainnet] to instantiate [HnsCoin].
class HNSChain extends ConfChain {
  HNSChain()
      : super(
            name: 'hns',
            mainnet: WalletSetting(
              bip44Path: HNS_PATH,
              addressType: AddressType.BECH32,
              bech32Length: 39,
              prefix: HNS_PREFIX,
              networkType: NetworkType(
                messagePrefix: '',
                bech32: HNS_PREFIX,
                wif: 0x80,
                pubKeyHash: 0,
                scriptHash: 5,
                bip32: Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
              ),
            ),
            testnet: WalletSetting(
              bip44Path: HNS_PATH,
              addressType: AddressType.BECH32,
              bech32Length: 39,
              prefix: 'rs',
              networkType: NetworkType(
                  messagePrefix: '',
                  bech32: 'rs',
                  wif: 0x5a,
                  pubKeyHash: 0,
                  scriptHash: 5,
                  bip32: Bip32Type(public: 0xeab4fa05, private: 0xeab404c7)),
            ));
}
