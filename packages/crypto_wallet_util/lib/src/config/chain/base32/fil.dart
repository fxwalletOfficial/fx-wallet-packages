import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **filecoin**, address type is [AddressType.FIL], bip44 path is [FILECOIN_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [AlphCoin].
class FILChain extends ConfChain {
  FILChain()
      : super(
            name: 'fil',
            mainnet: WalletSetting(
                addressType: AddressType.FIL,
                prefix: FILECOIN_PREFIX_MAINNET,
                bip44Path: FILECOIN_PATH,
                regExp: FILECOIN_MAINNET_REG),
            testnet: WalletSetting(
                addressType: AddressType.FIL,
                prefix: FILECOIN_PREFIX_TESTNET,
                bip44Path: FILECOIN_PATH,
                regExp: FILECOIN_TESTNET_REG));
}
