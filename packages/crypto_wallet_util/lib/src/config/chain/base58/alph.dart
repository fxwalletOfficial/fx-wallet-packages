import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **alph**, address type is [AddressType.BASE58], bip44 path is [ALPH_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [AlphCoin].
class ALPHChain extends ConfChain {
  ALPHChain()
      : super(
            name: 'alph',
            mainnet: WalletSetting(
                addressType: AddressType.BASE58,
                bip44Path: ALPH_PATH,
                regExp: ALPH_ADDRESS_REG),
            testnet: WalletSetting(
                addressType: AddressType.BASE58,
                bip44Path: ALPH_PATH,
                regExp: ALPH_ADDRESS_REG));
}
