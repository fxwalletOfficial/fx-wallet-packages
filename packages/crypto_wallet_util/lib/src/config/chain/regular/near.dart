import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **near**, address type is [AddressType.REGULAR], bip44 path is [NEAR_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [NearCoin].
class NEARChain extends ConfChain {
  NEARChain()
      : super(
            name: 'near',
            mainnet: WalletSetting(
                bip44Path: NEAR_PATH,
                addressType: AddressType.REGULAR,
                regExp: NEAR_ADDRESS_REG),
            testnet: WalletSetting(
                bip44Path: NEAR_PATH,
                addressType: AddressType.REGULAR,
                regExp: NEAR_ADDRESS_REG));
}
