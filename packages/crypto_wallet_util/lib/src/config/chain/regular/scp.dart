import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **scp**, address type is [AddressType.REGULAR], bip44 path is [BTC_PATH].
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate SiaCoin wallet.
class SCPChain extends ConfChain {
  SCPChain()
      : super(
            name: 'scp',
            mainnet: WalletSetting(
                bip44Path: BTC_PATH,
                addressType: AddressType.REGULAR,
                regExp: SC_ADDRESS_REG),
            testnet: WalletSetting(
                bip44Path: BTC_PATH,
                addressType: AddressType.REGULAR,
                regExp: SC_ADDRESS_REG));
}
