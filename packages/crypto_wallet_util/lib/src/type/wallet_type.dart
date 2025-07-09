import 'package:crypto_wallet_util/src/config/config.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart'
    as bitcoin;
import 'package:crypto_wallet_util/src/utils/utils.dart';

class WalletSetting {
  /// [WalletSetting] stores the essential information required for wallet generation.
  /// [bip44Path]     m/44'/60'/0'/0/0
  /// [prefix]        ckb, kaspa...
  /// [addressType]   bech32, base58.. For further details, refer to [AddressType].
  /// [networkType]   default bitcoin type. 
  /// [bech32Length]  Employed for bech32 address verification.
  /// [regExp]        A regular expression for addresses, utilized in address verification.
  ///
  final String bip44Path;
  String prefix;
  AddressType addressType;
  bitcoin.NetworkType? networkType;
  int bech32Length;
  String regExp;
  WalletSetting(
      {required this.bip44Path,
      this.prefix = '',
      this.networkType,
      this.bech32Length = 38,
      this.regExp = COMMON_REG,
      this.addressType = AddressType.NONE});
}

abstract class WalletType {
  /// [privateKey] and [publicKey] key are always [Uint8List];
  /// [mnemonic] and [address] are always String
  late final String? mnemonic;
  late final Uint8List privateKey;
  WalletType();

  Uint8List get publicKey => privateKeyToPublicKey(privateKey);
  String get address => publicKeyToAddress(publicKey);

  Future<void> initFromMnemonic(String mnemonic) async {
    this.mnemonic = mnemonic;
    privateKey = await mnemonicToPrivateKey(mnemonic);
  }

  void initFromPrivateKey(Uint8List privateKey) {
    this.privateKey = privateKey;
  }

  Future<String> mnemonicToAddress(String mnemonic) async {
    final privateKey = await mnemonicToPrivateKey(mnemonic);
    final publicKey = privateKeyToPublicKey(privateKey);
    return publicKeyToAddress(publicKey);
  }

  Future<Uint8List> mnemonicToPrivateKey(String mnemonic);
  Uint8List privateKeyToPublicKey(Uint8List privateKey);
  String publicKeyToAddress(Uint8List publicKey);
  String sign(String message);
  bool verify(String signature, String message);
}
