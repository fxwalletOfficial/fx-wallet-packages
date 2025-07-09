import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Create a **sol** wallet using mnemonic or private key, 
/// with a signature algorithm of [ED25519].
class SolCoin extends WalletType {
  final _default = WalletSetting(bip44Path: SOL_PATH);
  WalletSetting? setting;

  SolCoin({setting}) {
    this.setting = setting ?? _default;
  }

  static Future<SolCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = SolCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory SolCoin.fromPrivateKey(dynamic privateKey, [WalletSetting? setting]) {
    final wallet = SolCoin(setting: setting);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    return wallet;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    return HDWallet.bip44DerivePath(mnemonic, setting!.bip44Path);
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    return ED25519.privateKeyToPublicKey(privateKey);
  }

  @override
  String publicKeyToAddress(Uint8List publicKey) {
    return base58.encode(publicKey);
  }

  @override
  String sign(String message) {
    final signedMessage = ED25519.sign(privateKey, dynamicToUint8List(message));
    return dynamicToString(signedMessage);
  }

  @override
  bool verify(String signature, String message) {
    return ED25519.verify(publicKey, signature, message);
  }
}
