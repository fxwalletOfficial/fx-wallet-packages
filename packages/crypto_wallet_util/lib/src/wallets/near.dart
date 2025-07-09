import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Create a **near** wallet using mnemonic or private key, 
/// with a signature algorithm of [ED25519].
class NearCoin extends WalletType {
  final _default = WalletSetting(bip44Path: NEAR_PATH);
  WalletSetting? setting;

  NearCoin({setting}) {
    this.setting = setting ?? _default;
  }

  String get base58PrivateKey =>
      'ed25519:${base58.encode((privateKey + publicKey).toUint8List())}';

  String get base58PublicKey =>
      'ed25519:${base58.encode((publicKey).toUint8List())}';

  static Future<NearCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = NearCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory NearCoin.fromPrivateKey(dynamic privateKey,
      [WalletSetting? setting]) {
    final wallet = NearCoin(setting: setting);
    if (privateKey.runtimeType.toString() == 'String') {
      if (privateKey.startsWith('ed25519:')) {
        final data = privateKey.substring(8);
        final secretKey = base58.decode(data);
        wallet.initFromPrivateKey(dynamicToUint8List(secretKey.sublist(0, 32)));
      } else {
        wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
      }
    } else {
      throw Exception('Unsupported private key');
    }
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
    return dynamicToString(publicKey);
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
