import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **ton**, address type is [AddressType.REGULAR], bip44 path is [SOL_PATH].  
/// Testnet and mainnet share the same setting. 
class TONChain extends ConfChain {
  TONChain()
      : super(
            name: 'ton',
            mainnet: WalletSetting(
                bip44Path: SOL_PATH, addressType: AddressType.TON),
            testnet: WalletSetting(
                bip44Path: SOL_PATH, addressType: AddressType.TON));
}
