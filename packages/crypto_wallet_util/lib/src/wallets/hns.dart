import 'dart:typed_data';

import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/bech32/bech32.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Create a **hns** wallet using mnemonic or private key,
/// with a signature algorithm of [EcdaSignature] and an address type of [bech32]
class HnsCoin extends WalletType {
  final _default = WalletSetting(bip44Path: HNS_PATH, prefix: HNS_PREFIX);
  WalletSetting? setting;

  HnsCoin({setting, String? prefix}) {
    this.setting = setting ?? _default;
  }

  static Future<HnsCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = HnsCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory HnsCoin.fromPrivateKey(dynamic privateKey, [WalletSetting? setting]) {
    final wallet = HnsCoin(setting: setting);
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
    final blake2bHash = Blake2b.getBlake2bHash(publicKey, size: 20);
    final digest = convertBit(blake2bHash);
    return bech32.encode(Bech32(setting!.prefix, digest));
  }

  @override
  String sign(String message) {
    final signature = EcdaSignature.sign(message, privateKey);
    return dynamicToHex(signature.getSignatureWithRecId());
  }

  @override
  bool verify(String signature, String message) {
    return EcdaSignature.verify(message, publicKey, signature);
  }
}
