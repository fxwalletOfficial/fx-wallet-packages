import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **trx**, address type is [AddressType.REGULAR], bip44 path is [TRX_PATH].  
/// Testnet and mainnet share the same setting.
class TRXChain extends ConfChain {
  TRXChain()
      : super(
            name: 'trx',
            mainnet: WalletSetting(
                bip44Path: TRX_PATH,
                addressType: AddressType.REGULAR,
                regExp: TRX_ADDRESS_REG),
            testnet: WalletSetting(
                bip44Path: TRX_PATH,
                addressType: AddressType.REGULAR,
                regExp: TRX_ADDRESS_REG));
}
