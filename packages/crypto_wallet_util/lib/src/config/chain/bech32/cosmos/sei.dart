import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **sei**, address type is [AddressType.BECH32], bip44 path is [ATOM_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [Cosmos].
class SEIChain extends ConfChain {
  SEIChain()
      : super(
            name: 'sei',
            mainnet: WalletSetting(
              bip44Path: ATOM_PATH,
              addressType: AddressType.BECH32,
              bech32Length: 38,
              prefix: SEI_PREFIX,
            ),
            testnet: WalletSetting(
              bip44Path: ATOM_PATH,
              addressType: AddressType.BECH32,
              bech32Length: 38,
              prefix: SEI_PREFIX,
            ));
}
