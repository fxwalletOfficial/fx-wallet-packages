import 'dart:typed_data';

import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/src/payments/p2pkh.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_base_hd/src/crypto/keypair/ec_private.dart';

/// Create a **btc** wallet using mnemonic or private key,
/// with a signature algorithm of [EcdaSignature] or [Schnorr] and an address type of [btc]
class BtcCoin extends WalletType {
  final _default = WalletSetting(bip44Path: BTC_PATH);
  final _taproot = WalletSetting(bip44Path: TAPROOT_PATH);
  final isTaproot;
  WalletSetting? setting;
  BtcCoin({setting, this.isTaproot = false}) {
    this.setting = setting ?? (isTaproot ? _taproot : _default);
  }

  static Future<BtcCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting, bool isTaproot = false]) async {
    final wallet = BtcCoin(setting: setting, isTaproot: isTaproot);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory BtcCoin.fromPrivateKey(dynamic privateKey,
      [WalletSetting? setting, bool isTaproot = false]) {
    final wallet = BtcCoin(setting: setting, isTaproot: isTaproot);
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
    if (isTaproot) {
      return P2PKH.getTaprootAddress(publicKey, 'bc');
    } else {
      final addressBytes = sha160fromByte(publicKey);
      Uint8List versionedHash = Uint8List(21);
      versionedHash[0] = 0x00;
      versionedHash.setRange(1, 21, addressBytes);
      return getBase58Address(versionedHash);
    }
  }

  @override
  String sign(String message) {
    final ecPrivateKey = ECPrivate.fromBytes(privateKey);

    if (isTaproot) {
      return ecPrivateKey.signTapRoot(message.toUint8List()).toHex();
    } else {
      return ecPrivateKey.signInput(message.toUint8List()).toHex();
    }
  }

  @override
  bool verify(String signature, String message) {
    // if (isTaproot) {
    //   return Schnorr.verify(publicKey, signature, message);
    // } else {
    //   return EcdaSignature.verify(message, publicKey, signature);
    // }
    return true;
  }
}
