import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **karlsen**, address type is [AddressType.KAS], bip44 path is [KLS_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [KasCoin].
class KLSChain extends ConfChain {
  KLSChain()
      : super(
          name: 'karlsen',
          mainnet: WalletSetting(
            bip44Path: KLS_PATH,
            prefix: KLS_PREFIX,
            addressType: AddressType.KAS,
          ),
          testnet: WalletSetting(
            bip44Path: KLS_PATH,
            prefix: KLS_PREFIX,
            addressType: AddressType.KAS,
          ),
        );
}
