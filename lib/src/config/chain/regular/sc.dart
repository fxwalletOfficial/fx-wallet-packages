import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **sc**, address type is [AddressType.REGULAR], bip44 path is [BTC_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [SiaCoin].
class SCChain extends ConfChain {
  SCChain()
      : super(
            name: 'sc',
            mainnet: WalletSetting(
                bip44Path: BTC_PATH,
                addressType: AddressType.REGULAR,
                regExp: SC_ADDRESS_REG),
            testnet: WalletSetting(
                bip44Path: BTC_PATH,
                addressType: AddressType.REGULAR,
                regExp: SC_ADDRESS_REG));
}
