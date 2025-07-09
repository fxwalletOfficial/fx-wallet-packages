import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **kava**, address type is [AddressType.BECH32], bip44 path is [KAVA_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [Cosmos].
class KAVAChain extends ConfChain {
  KAVAChain()
      : super(
            name: 'kava',
            mainnet: WalletSetting(
              bip44Path: KAVA_PATH,
              addressType: AddressType.BECH32,
              bech32Length: 38,
              prefix: KAVA_PREFIX,
            ),
            testnet: WalletSetting(
              bip44Path: KAVA_PATH,
              addressType: AddressType.BECH32,
              bech32Length: 38,
              prefix: KAVA_PREFIX,
            ));
}
