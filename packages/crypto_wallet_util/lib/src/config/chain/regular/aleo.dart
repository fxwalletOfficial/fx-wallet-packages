import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **aleo**, address type is [AddressType.REGULAR], bip44 path is [BTC_PATH].  
/// Testnet and mainnet share the same setting. 
class ALEOChain extends ConfChain {
  ALEOChain()
      : super(
          name: 'aleo',
          mainnet: WalletSetting(
              bip44Path: BTC_PATH,
              addressType: AddressType.REGULAR,
              regExp: ALEO_REG),
          testnet: WalletSetting(
              bip44Path: BTC_PATH,
              addressType: AddressType.REGULAR,
              regExp: ALEO_REG),
        );
}
