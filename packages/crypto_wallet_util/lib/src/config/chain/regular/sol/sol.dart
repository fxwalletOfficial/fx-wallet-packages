import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **sol**, address type is [AddressType.REGULAR], bip44 path is [SOL_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [SolCoin].
class SOLChain extends ConfChain {
  SOLChain()
      : super(
          name: 'sol',
          mainnet: WalletSetting(
              regExp: SOL_ADDRESS_REG,
              bip44Path: SOL_PATH,
              addressType: AddressType.REGULAR),
          testnet: WalletSetting(
              regExp: SOL_ADDRESS_REG,
              bip44Path: SOL_PATH,
              addressType: AddressType.REGULAR),
        );
}
