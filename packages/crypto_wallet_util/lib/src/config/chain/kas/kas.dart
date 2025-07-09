import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **kaspa**, address type is [AddressType.KAS], bip44 path is [KAS_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [KasCoin].
class KASChain extends ConfChain {
  KASChain()
      : super(
            name: 'kaspa',
            mainnet: WalletSetting(
              bip44Path: KAS_PATH,
              prefix: KAS_PREFIX,
              addressType: AddressType.KAS,
            ),
            testnet: WalletSetting(
              bip44Path: KAS_PATH,
              prefix: KAS_PREFIX,
              addressType: AddressType.KAS,
            ));
}
