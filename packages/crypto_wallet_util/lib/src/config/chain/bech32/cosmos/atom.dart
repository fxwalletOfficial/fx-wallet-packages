import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **cosmos**, address type is [AddressType.BECH32], bip44 path is [ATOM_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [Cosmos].
class ATOMChain extends ConfChain {
  ATOMChain()
      : super(
            name: 'atom',
            mainnet: WalletSetting(
              bip44Path: ATOM_PATH,
              addressType: AddressType.BECH32,
              bech32Length: 38,
              prefix: ATOM_PREFIX,
            ),
            testnet: WalletSetting(
              bip44Path: ATOM_PATH,
              addressType: AddressType.BECH32,
              bech32Length: 38,
              prefix: ATOM_PREFIX,
            ));
}
