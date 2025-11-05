import 'dart:typed_data';

import 'package:secp256k1_ecdsa/secp256k1.dart';

import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Create a **filecoin** wallet using mnemonic or private key,
/// with a signature algorithm of [secp256k1].
class FileCoin extends WalletType {
  final _default =
      WalletSetting(bip44Path: FILECOIN_PATH, prefix: FILECOIN_PREFIX_MAINNET);
  WalletSetting? setting;

  FileCoin({setting}) {
    this.setting = setting ?? _default;
  }

  static Future<FileCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = FileCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory FileCoin.fromPrivateKey(dynamic privateKey,
      [WalletSetting? setting]) {
    final wallet = FileCoin(setting: setting);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    return wallet;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    final privateKey =
        await HDWallet.bip32DerivePath(mnemonic, setting!.bip44Path);
    return Uint8List.fromList(privateKey);
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    return EcdaSignature.getUnCompressedPublicKey(privateKey);
  }

  @override
  String publicKeyToAddress(Uint8List publicKey) {
    final payload = Blake2b.getBlake2bHash(publicKey, size: 20);
    final checkSum =
        Blake2b.getBlake2bHash(Uint8List.fromList([1, ...payload]), size: 4);
    final address = Base32.encode(Uint8List.fromList([...payload, ...checkSum]),
        type: Base32Type.RFC4648);
    return setting!.prefix + address;
  }

  /// get F410 address from evm address, default filecoin mainnet prefix [FILECOIN_PREFIX_EVM].
  static String getF410Address(String address,
      {String prefix = FILECOIN_PREFIX_EVM}) {
    final bytes = address.toUint8List();
    final payload = Uint8List.fromList([4, 10, ...bytes]);
    final checkSum = Blake2b.getBlake2bHash(payload, size: 4);
    return '${prefix}f${Base32.encode([
          ...bytes,
          ...checkSum
        ], type: Base32Type.RFC4648)}';
  }

  @override
  String sign(String message) {
    final signer = PrivateKey.fromHex(privateKey.toStr());
    final signature = signer.sign(message.toUint8List());
    final signatureBytes = Uint8List.fromList(
        [...signature.toCompactRawBytes(), signature.recovery!]);
    return dynamicToString(signatureBytes);
  }

  @override
  bool verify(String signature, String message) {
    final compressedPubKey =
        EcdaSignature.privateKeyToPublicKey(privateKey).toStr();
    final signedMessage = Signature.fromCompactBytes(signature.toUint8List());
    final pubKey = PublicKey.fromHex(compressedPubKey);
    return pubKey.verify(signedMessage, message.toUint8List());
  }
}
