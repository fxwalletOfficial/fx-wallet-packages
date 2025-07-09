import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Create a **algo** wallet using mnemonic or private key, 
/// with a signature algorithm of [ED25519].
class AlgoCoin extends WalletType {
  final _default = WalletSetting(bip44Path: ALGO_PATH);
  WalletSetting? setting;

  AlgoCoin({setting}) {
    this.setting = setting ?? _default;
  }

  static Future<AlgoCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = AlgoCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory AlgoCoin.fromPrivateKey(dynamic privateKey,
      [WalletSetting? setting]) {
    final wallet = AlgoCoin(setting: setting);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    return wallet;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    final privateKey =
        await HDWallet.bip44DerivePath(mnemonic, setting!.bip44Path);
    return Uint8List.fromList(privateKey);
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    return ED25519.privateKeyToPublicKey(privateKey);
  }

  @override
  String publicKeyToAddress(Uint8List publicKey) {
    final checkSum = getSHA512256(publicKey).sublist(28, 32);
    final address = Base32.encode(
        Uint8List.fromList([...publicKey, ...checkSum]),
        type: Base32Type.RFC4648);
    return address.replaceAll('=', '').toUpperCase();
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
