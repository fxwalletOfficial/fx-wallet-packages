import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **eth**, address type is [AddressType.ETH], bip44 path is [ETH_PATH].  
/// Testnet and mainnet share the same setting. Use **HDWallet** to to instantiate wallet.
class ETHChain extends ConfChain {
  ETHChain()
      : super(
          name: 'eth',
          mainnet:
              WalletSetting(bip44Path: ETH_PATH, addressType: AddressType.ETH),
          testnet:
              WalletSetting(bip44Path: ETH_PATH, addressType: AddressType.ETH),
        );
}
