import 'dart:typed_data';

import 'package:ss58/ss58.dart';

import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Select dot signature algorithm.
enum DotScheme { sr25519, ed25519 }

/// Create a **Dot** wallet using mnemonic or private key,
/// with a signature algorithm of [SR25519] or [ED25519].
class DotCoin extends WalletType {
  final PREFIX_LIST = [0, 2, 42];
  DotScheme _scheme = DotScheme.sr25519;
  final _default = WalletSetting(bip44Path: DOT_PATH);
  WalletSetting? setting;

  DotCoin({setting, bool setEd = false}) {
    this.setting = setting ?? _default;
    if (setEd) setEd25519();
  }

  static Future<DotCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = DotCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory DotCoin.fromPrivateKey(dynamic privateKey, [WalletSetting? setting]) {
    final wallet = DotCoin(setting: setting);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    return wallet;
  }

  ///  set dot address prefix
  ///  polkadot  (Prefix: 0) : 15rRgsWxz4H5LTnNGcCFsszfXD8oeAFd8QRsR6MbQE2f6XFF; //default address
  ///  kusama    (Prefix: 2) : HRkCrbmke2XeabJ5fxJdgXWpBRPkXWfWHY8eTeCKwDdf4k6;
  ///  rococo    (Prefix: 42): 5Gv8YYFu8H1btvmrJy9FjjAWfb99wrhV3uhPFoNEr918utyR;
  String get kusamaAddress => publicKeyToAddress(publicKey, prefix: 2);
  String get rococoAddress => publicKeyToAddress(publicKey, prefix: 42);
  /// set signature schemes, support sr25519 and ed25519.
  void setSr25519() {
    _scheme = DotScheme.sr25519;
  }

  void setEd25519() {
    _scheme = DotScheme.ed25519;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    switch (_scheme) {
      case DotScheme.sr25519:
        return HDWallet.substrateBip39(mnemonic);
      case DotScheme.ed25519:
        return HDWallet.hdLedger(mnemonic, setting!.bip44Path);
    }
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    switch (_scheme) {
      case DotScheme.sr25519:
        return SR25519.privateKeyToPublicKey(privateKey);
      case DotScheme.ed25519:
        return ED25519.privateKeyToPublicKey(privateKey);
    }
  }

  @override
  String publicKeyToAddress(Uint8List publicKey, {int prefix = 0}) {
    return Address(prefix: prefix, pubkey: publicKey).encode();
  }

  @override
  String sign(String message) {
    final msg = processMessage(message);
    switch (_scheme) {
      case DotScheme.sr25519:
        final signature = SR25519.sign(privateKey, msg);
        return dynamicToString(signature);
      case DotScheme.ed25519:
        final signature = ED25519.sign(privateKey, msg);
        return dynamicToString(signature);
    }
  }

  @override
  bool verify(String signature, String message) {
    switch (_scheme) {
      case DotScheme.sr25519:
        return SR25519.verify(publicKey, signature, message);
      case DotScheme.ed25519:
        return ED25519.verify(publicKey, signature, message);
    }
  }
}

/// delete message prefix 0x9c
Uint8List processMessage(dynamic message) {
  final Uint8List msg = dynamicToUint8List(message);
  // delete prefix 9c
  if (msg[0] == 156) return msg.sublist(1);
  return msg;
}
