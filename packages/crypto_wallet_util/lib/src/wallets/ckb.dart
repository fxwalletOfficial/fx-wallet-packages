import 'dart:typed_data';

import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/transaction/ckb/lib/ckb_lib.dart' as ckb;
import 'package:crypto_wallet_util/src/utils/bech32/bech32.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Create a **ckb** wallet using mnemonic or private key,
/// with a signature algorithm of [EcdaSignature] and an address type of [bech32]
class CkbCoin extends WalletType {
  final _default = WalletSetting(bip44Path: CKB_PATH);
  WalletSetting? setting;
  CkbCoin({setting}) {
    this.setting = setting ?? _default;
  }

  static Future<CkbCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = CkbCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory CkbCoin.fromPrivateKey(dynamic privateKey, [WalletSetting? setting]) {
    final wallet = CkbCoin(setting: setting);
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
    final hash = pubKeyToArg(publicKey);
    return argToAddress(hash);
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

  String toLongAddress() {
    final script = ckb.Script.fromAddress(address, ckb.AddressType.SHORT);
    return argToAddress(dynamicToUint8List(script.args),
        addressType: ckb.AddressType.LONG);
  }

  Uint8List pubKeyToArg(Uint8List publicKey) {
    final hash = Blake2b.getBlake2bHash(publicKey,
        personalization: ckb.CKB_HASH_PERSONALIZATION);
    return hash.sublist(0, 20);
  }

  String argToAddress(Uint8List hash,
      {String hashType = ckb.Script.Type,
      ckb.AddressType addressType = ckb.AddressType.SHORT}) {
    List<int> data = [];
    switch (addressType) {
      case ckb.AddressType.LONG:
        data.add(0x00);
        data.addAll(dynamicToUint8List(ckb.CKB_CODE_HASH));
        data.add(ckb.hashTypeToCode(hashType));
        data.addAll(hash);
        final words = toUint5Array(data);
        return bech32.encode(Bech32(CKB_PREFIX, words),
            maxLength: ckb.MAX_LENGTH, encoding: 'bech32m');
      case ckb.AddressType.SHORT:
        data.add(0x01);
        data.add(ckb.SHORT_ID);
        data.addAll(hash);
        final words = toUint5Array(data);
        return bech32.encode(Bech32(CKB_PREFIX, words),
            maxLength: ckb.MAX_LENGTH);
    }
  }
}
