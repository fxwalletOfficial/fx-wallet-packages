import 'dart:typed_data';

import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Create a **eth** wallet using mnemonic or private key,
/// with a signature algorithm of [EcdaSignature] and an address type of eth.
class EthCoin extends WalletType {
  final _default = WalletSetting(bip44Path: ETH_PATH);
  WalletSetting? setting;

  EthCoin({setting}) {
    this.setting = setting ?? _default;
  }

  static Future<EthCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = EthCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory EthCoin.fromPrivateKey(dynamic privateKey, [WalletSetting? setting]) {
    final wallet = EthCoin(setting: setting);
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
    final Uint8List compressPublicKey =
        EcdaSignature.privateKeyToPublicKey(privateKey, compress: false);
    final Uint8List addressBytes = getKeccakDigest(compressPublicKey);
    return addressBytes.sublist(12).toHex();
  }

  @override
  String sign(String message) {
    return EcdaSignature.sign(message, privateKey).getSignature();
  }

  String signForSponsor(String message) {
    return EcdaSignature.signForEth(message.toUint8List(), privateKey)
        .getSignature();
  }

  @override
  bool verify(String signature, String message) {
    return EcdaSignature.verify(message, publicKey, signature);
  }
}
