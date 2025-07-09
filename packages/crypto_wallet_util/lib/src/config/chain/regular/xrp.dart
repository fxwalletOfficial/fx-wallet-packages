import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **xrp**, address type is [AddressType.REGULAR], bip44 path is [XRP_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [XrpCoin].
class XRPChain extends ConfChain {
  XRPChain()
      : super(
            name: 'xrp',
            mainnet: WalletSetting(
                bip44Path: XRP_PATH,
                addressType: AddressType.REGULAR,
                regExp: XRP_ADDRESS_REG),
            testnet: WalletSetting(
                bip44Path: XRP_PATH,
                addressType: AddressType.REGULAR,
                regExp: XRP_ADDRESS_REG));
}
