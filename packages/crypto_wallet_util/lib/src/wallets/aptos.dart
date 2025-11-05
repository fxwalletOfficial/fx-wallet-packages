import 'dart:typed_data';

import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Create a **aptos** wallet using mnemonic or private key,
/// with a signature algorithm of [ED25519].
class AptosCoin extends WalletType {
  static final ED25519_SCHEME = 0;
  final _default = WalletSetting(bip44Path: APTOS_PATH);
  WalletSetting? setting;

  AptosCoin({setting}) {
    this.setting = setting ?? _default;
  }

  static Future<AptosCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = AptosCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory AptosCoin.fromPrivateKey(dynamic privateKey,
      [WalletSetting? setting]) {
    final wallet = AptosCoin(setting: setting);
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
    final bytes = Uint8List(publicKey.length + 1);
    bytes.setAll(0, publicKey);
    bytes.setAll(publicKey.length, [ED25519_SCHEME]);
    final sha3Hash = getSHA3Digest(bytes);
    return dynamicToHex(sha3Hash);
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
