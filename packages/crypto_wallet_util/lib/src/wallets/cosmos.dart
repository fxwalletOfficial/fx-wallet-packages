import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Create a **cosmos** wallet using mnemonic or private key, 
/// with a signature algorithm of [EcdaSignature] and an address type of [bech32].
/// Default create atom wallet.
class Cosmos extends WalletType {
  final _default = WalletSetting(bip44Path: ATOM_PATH, prefix: ATOM_PREFIX);
  WalletSetting? setting;

  Cosmos({setting}) {
    this.setting = setting ?? _default;
  }

  static Future<Cosmos> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = Cosmos(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory Cosmos.fromPrivateKey(dynamic privateKey, [WalletSetting? setting]) {
    final wallet = Cosmos(setting: setting);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    return wallet;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    return HDWallet.bip32DerivePath(mnemonic, setting!.bip44Path);
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    return EcdaSignature.privateKeyToPublicKey(privateKey);
  }

  @override
  String publicKeyToAddress(Uint8List publicKey) {
    final sha256Digest = getSHA256Digest(publicKey);
    final address = getRIPEMD160Digest(sha256Digest);
    final digest = toUint5Array(dynamicToUint8List(address));
    return bech32.encode(Bech32(setting!.prefix, digest));
  }

  @override
  String sign(String message) {
    final digest =
        dynamicToString(getSHA256Digest(dynamicToUint8List(message)));
    return EcdaSignature.sign(digest, privateKey).getSignature();
  }

  @override
  bool verify(String signature, String message) {
    final digest = getSHA256Digest(dynamicToUint8List(message));
    return EcdaSignature.verify(dynamicToString(digest), publicKey, signature);
  }
}
