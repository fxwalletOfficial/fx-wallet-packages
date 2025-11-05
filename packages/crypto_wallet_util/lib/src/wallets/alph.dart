import 'dart:typed_data';

import 'package:bs58check/bs58check.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Create a **alph** wallet using mnemonic or private key,
/// with a signature algorithm of [EcdaSignature] and an address type of [base58].
class AlphCoin extends WalletType {
  final _default = WalletSetting(bip44Path: ALPH_PATH);
  WalletSetting? setting;

  AlphCoin({setting}) {
    this.setting = setting ?? _default;
  }

  static Future<AlphCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = AlphCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory AlphCoin.fromPrivateKey(dynamic privateKey,
      [WalletSetting? setting]) {
    final wallet = AlphCoin(setting: setting);
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
    final blake2bHash = Blake2b.getBlake2bHash(publicKey);
    final type = dynamicToUint8List([0]);
    final bytes = dynamicToUint8List([...type, ...blake2bHash]);
    return base58.encode(bytes);
  }

  @override
  String sign(String message) {
    return EcdaSignature.sign(message, privateKey).getSignature();
  }

  @override
  bool verify(String signature, String message) {
    return EcdaSignature.verify(message, publicKey, signature);
  }

  static getAlphAddress(Uint8List publicKey) {
    return AlphCoin().publicKeyToAddress(publicKey);
  }
}
