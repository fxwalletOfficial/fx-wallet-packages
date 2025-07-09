import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **filecoin**, address type is [AddressType.REGULAR], bip44 path is [ALGO_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [AlphCoin].
class ALGOChain extends ConfChain {
  ALGOChain()
      : super(
            name: 'algo',
            mainnet: WalletSetting(
                addressType: AddressType.ALGO,
                bip44Path: ALGO_PATH,
                regExp: ALGO_REG),
            testnet: WalletSetting(
                addressType: AddressType.ALGO,
                bip44Path: ALGO_PATH,
                regExp: ALGO_REG));
}
