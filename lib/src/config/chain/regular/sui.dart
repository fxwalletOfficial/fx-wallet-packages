import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **sui**, address type is [AddressType.REGULAR], bip44 path is [SUI_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [SuiCoin].
class SUIChain extends ConfChain {
  SUIChain()
      : super(
            name: 'sui',
            mainnet: WalletSetting(
                bip44Path: SUI_PATH,
                addressType: AddressType.REGULAR,
                regExp: SUI_ADDRESS_REG),
            testnet: WalletSetting(
                bip44Path: SUI_PATH,
                addressType: AddressType.REGULAR,
                regExp: SUI_ADDRESS_REG));
}
