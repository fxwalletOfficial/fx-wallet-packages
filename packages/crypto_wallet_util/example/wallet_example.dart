// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

void main() async {
  /// prepare mnemonic
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';

  /// prepare private key
  const String privateKey =
      "14c9be0fc16ba5cbf0ac730a9419a2ec1541f7fbea1fc28b5ec429322bb564ce";

  /// test message
  const String message = "0000";

  /// get wallet
  final WalletType mnemonicWallet = await AlphCoin.fromMnemonic(mnemonic);
  final WalletType privateKeyWallet = await AlphCoin.fromPrivateKey(privateKey);

  /// generate address
  print(mnemonicWallet.address);
  print(privateKeyWallet.address);

  /// sign message
  final String signature = mnemonicWallet.sign(message);
  print(mnemonicWallet.verify(signature, message));

  /// common function to get wallet,
  final WalletType testWallet = await getMnemonicWallet('alph', mnemonic);
  print(testWallet.address);

  /// generate Non-default wallet
  final bip44Path = "m/44'/60'/0'/0/0";
  final Uint8List customPrivateKey =
      HDWallet.bip32DerivePath(mnemonic, bip44Path);
  final Uint8List customPublicKey =
      EcdaSignature.privateKeyToPublicKey(customPrivateKey);
  final Uint8List compressPublicKey =
      EcdaSignature.privateKeyToPublicKey(customPrivateKey, compress: false);
  final Uint8List addressBytes = getKeccakDigest(compressPublicKey);
  final String address = addressBytes.sublist(12).toHex();
  print(address);
  final customSignature =
      EcdaSignature.sign(message, customPrivateKey).getSignature();
  print(EcdaSignature.verify(message, customPublicKey, customSignature));
}
