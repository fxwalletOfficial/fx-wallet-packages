import 'dart:typed_data';

import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/xrpl_dart.dart';

import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Create a **xrp** wallet using mnemonic or private key,
/// with a signature algorithm of [EcdaSignature].
class XrpCoin extends WalletType {
  final _default = WalletSetting(bip44Path: XRP_PATH);
  WalletSetting? setting;
  XrpCoin({setting}) {
    this.setting = setting ?? _default;
  }

  static Future<XrpCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = XrpCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory XrpCoin.fromPrivateKey(dynamic privateKey, [WalletSetting? setting]) {
    final wallet = XrpCoin(setting: setting);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    return wallet;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    return HDWallet.bip32DerivePath(mnemonic, setting!.bip44Path);
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    final wallet = privateKeyToWallet(privateKey);
    final publicKey = wallet.getPublic().toBytes();
    return Uint8List.fromList(publicKey);
  }

  @override
  String publicKeyToAddress(Uint8List publicKey) {
    final pubKey = XRPPublicKey.fromBytes(publicKey);
    return pubKey.toAddress().toString();
  }

  @override
  String sign(String message) {
    // XrpTxData txData
    final wallet = privateKeyToWallet(privateKey);
    return wallet.sign(message);
  }

  @override
  bool verify(String signature, String message) {
    final pubKey = XRPPublicKey.fromBytes(publicKey);
    return pubKey.verifySignature(message, signature);
  }

  XRPPrivateKey privateKeyToWallet(Uint8List privateKey) {
    var key = dynamicToString(privateKey);
    final keyPrefix = key.substring(0, 2);
    if (keyPrefix != '00') key = '00$key'; // Handle private key
    return XRPPrivateKey.fromHex(key);
  }
}
