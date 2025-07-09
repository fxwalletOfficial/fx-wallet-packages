import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **icp**, address type is [AddressType.REGULAR], bip44 path is [ICP_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [IcpCoin].
class ICPChain extends ConfChain {
  ICPChain()
      : super(
            name: 'icp',
            mainnet: WalletSetting(
                bip44Path: ICP_PATH,
                addressType: AddressType.REGULAR,
                regExp: ICP_ADDRESS_REG),
            testnet: WalletSetting(
                bip44Path: ICP_PATH,
                addressType: AddressType.REGULAR,
                regExp: ICP_ADDRESS_REG));
}
