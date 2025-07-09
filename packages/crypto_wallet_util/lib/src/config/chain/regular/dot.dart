import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **dot**, address type is [AddressType.REGULAR], bip44 path is [DOT_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [DotCoin].
class DOTChain extends ConfChain {
  DOTChain()
      : super(
            name: 'dot',
            mainnet: WalletSetting(
              regExp: DOT_ADDRESS_REG,
              bip44Path: DOT_PATH,
              addressType: AddressType.REGULAR,
            ),
            testnet: WalletSetting(
              regExp: DOT_ADDRESS_REG,
              bip44Path: DOT_PATH,
              addressType: AddressType.REGULAR,
            ));
}
