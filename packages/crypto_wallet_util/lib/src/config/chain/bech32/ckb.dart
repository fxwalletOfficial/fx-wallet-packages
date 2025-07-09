import 'package:crypto_wallet_util/crypto_utils.dart';

/// Provide default config for **ckb**, address type is [AddressType.BECH32], bip44 path is [CKB_PATH].  
/// Testnet and mainnet share the same setting. Use [mainnet] to instantiate [CkbCoin].
class CKBChain extends ConfChain {
  CKBChain()
      : super(
            name: 'ckb',
            mainnet: WalletSetting(
              bip44Path: CKB_PATH,
              addressType: AddressType.BECH32,
              bech32Length: 42,
              prefix: CKB_PREFIX,
            ),
            testnet: WalletSetting(
              bip44Path: CKB_PATH,
              addressType: AddressType.BECH32,
              bech32Length: 42,
              prefix: CKB_PREFIX,
            ));
}
