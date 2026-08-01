import 'dart:typed_data';

import 'package:crypto_wallet_util/src/config/chain/btc/ltc.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/src/payments/p2pkh.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_base_hd/src/crypto/keypair/ec_private.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Create a **ltc** wallet using mnemonic or private key,
/// with a signature algorithm of [EcdaSignature] or [Schnorr] and an address type of [ltc]

class LtcCoin extends WalletType {
  final _defaultWalletSetting = LTCChain().mainnet;
  final _taproot = WalletSetting(bip44Path: LTC_TAPROOT_PATH, networkType: LTCChain().mainnet.networkType, addressType: LTCChain().mainnet.addressType);
  final bool isTaproot;
  late WalletSetting setting;
  LtcCoin({setting, this.isTaproot = false}) {
    this.setting = setting ?? (isTaproot ? _taproot : _defaultWalletSetting);
  }

  static Future<LtcCoin> fromMnemonic(String mnemonic, [WalletSetting? setting, bool isTaproot = false]) async {
    final wallet = LtcCoin(setting: setting, isTaproot: isTaproot);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory LtcCoin.fromPrivateKey(dynamic privateKey, [WalletSetting? setting, bool isTaproot = false]) {
    final wallet = LtcCoin(setting: setting, isTaproot: isTaproot);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    return wallet;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    return HDWallet.bip32DerivePath(mnemonic, setting.bip44Path);
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    return EcdaSignature.privateKeyToPublicKey(privateKey);
  }

  @override
  String publicKeyToAddress(Uint8List publicKey) {
    if (isTaproot) {
      // Taproot P2TR address, bech32m encoded, starts with ltc1p
      return P2PKH.getTaprootAddress(publicKey, 'ltc');
    } else {
      final addressBytes = sha160fromByte(publicKey);
      Uint8List versionedHash = Uint8List(21);
      versionedHash[0] = setting.networkType!.pubKeyHash;
      versionedHash.setRange(1, 21, addressBytes);
      return getBase58Address(versionedHash);
    }
  }

  @override
  String sign(String message) {
    final ecPrivateKey = ECPrivate.fromBytes(privateKey);
    if (isTaproot) {
      // Schnorr signature
      return ecPrivateKey.signTapRoot(message.toUint8List()).toHex();
    } else {
      return ecPrivateKey.signInput(message.toUint8List()).toHex();
    }
  }

  /// Sign with an explicit sighash type, keeping the digest's committed
  /// hashType consistent with the hashType byte the caller will embed in
  /// the final signature (GSPL callers compute both from the same value).
  String signWithHashType(String message, int hashType) {
    final ecPrivateKey = ECPrivate.fromBytes(privateKey);
    if (isTaproot) {
      // Keep the signer/serializer boundary unambiguous: return the raw
      // 64-byte Schnorr signature here. The GSPL transaction serializer is
      // the single place that appends a non-default sighash byte to witness.
      return ecPrivateKey.signTapRoot(message.toUint8List()).toHex();
    } else {
      return ecPrivateKey
          .signInput(message.toUint8List(), sigHash: hashType)
          .toHex();
    }
  }

  @override
  bool verify(String signature, String message) {
    if (isTaproot) {
      // A key-path signature verifies against the tweaked output key
      // committed to by the P2TR address, not the untweaked public key.
      final outputKey = P2PKH.getTaprootOutputKey(publicKey);
      return Schnorr.verify(
          Uint8List.fromList(outputKey), signature, message);
    } else {
      // Non-Taproot sign() returns DER + a trailing sighash byte, not raw
      // 64-byte r||s.
      return EcdaSignature.verifyDerWithHashType(message, publicKey, signature);
    }
  }
}
