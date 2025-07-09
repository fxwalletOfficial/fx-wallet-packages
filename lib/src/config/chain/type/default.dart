import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default chain setting, address type is [AddressType.NONE], bip44 path is [BTC_PATH].  
/// Testnet and mainnet share the same setting.
class DefaultChain extends ConfChain {
  DefaultChain()
      : super(
            name: 'default',
            mainnet: WalletSetting(
              bip44Path: BTC_PATH,
              addressType: AddressType.NONE,
            ),
            testnet: WalletSetting(
              bip44Path: BTC_PATH,
              addressType: AddressType.NONE,
            ));
}
