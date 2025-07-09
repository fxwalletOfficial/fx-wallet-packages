import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **aptos**, address type is [AddressType.REGULAR], bip44 path is [APTOS_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [AptosCoin].
class APTOSChain extends ConfChain {
  APTOSChain()
      : super(
            name: 'aptos',
            mainnet: WalletSetting(
                bip44Path: APTOS_PATH,
                addressType: AddressType.REGULAR,
                regExp: APTOS_ADDRESS_REG),
            testnet: WalletSetting(
                bip44Path: APTOS_PATH,
                addressType: AddressType.REGULAR,
                regExp: APTOS_ADDRESS_REG));
}
