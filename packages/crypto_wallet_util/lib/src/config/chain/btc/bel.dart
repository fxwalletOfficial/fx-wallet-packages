import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart';

/// Provide default config for **bel**, address type is [AddressType.BTC].
/// Testnet and mainnet share the same setting. Use [HDWallet] to to instantiate wallet.
class BELChain extends ConfChain {
  BELChain()
      : super(
            name: 'bells',
            mainnet: WalletSetting(
              bip44Path: '',
              addressType: AddressType.BTC,
              networkType: NetworkType(
                  messagePrefix: '\x18Bells Signed Message:\n',
                  bip32: Bip32Type(
                    public: 0x0488b21e,
                    private: 0x0488ade4,
                  ),
                  pubKeyHash: 0x19,
                  scriptHash: 0x24,
                  wif: 0x99),
            ),
            testnet: WalletSetting(
              bip44Path: '',
              addressType: AddressType.BTC,
              networkType: NetworkType(
                  messagePrefix: '\x18Bells Signed Message:\n',
                  bip32: Bip32Type(
                    public: 0x0488b21e,
                    private: 0x0488ade4,
                  ),
                  pubKeyHash: 0x19,
                  scriptHash: 0x24,
                  wif: 0x99),
            ));
}
