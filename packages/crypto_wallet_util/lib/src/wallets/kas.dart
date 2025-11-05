import 'dart:typed_data';

import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/bech32/bech32.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Prefix of kas address.
final KAS_DECODE = [11, 1, 19, 16, 1, 0];

/// Prefix of kls address.
final KLS_DECODE = [11, 1, 18, 12, 19, 5, 14, 0];

/// Create a **kas** wallet using mnemonic or private key,
/// with a signature algorithm of [EcdaSignature] and an address type of [bech32]
/// Default create kas wallet.
class KasCoin extends WalletType {
  final _default = WalletSetting(bip44Path: KAS_PATH, prefix: KAS_PREFIX);
  WalletSetting? setting;
  String? prefix;
  KasCoin({setting}) {
    this.setting = setting ?? _default;
    prefix = this.setting!.prefix;
  }

  static Future<KasCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = KasCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory KasCoin.fromPrivateKey(dynamic privateKey, [WalletSetting? setting]) {
    final wallet = KasCoin(setting: setting);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    return wallet;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    switch (prefix) {
      case KAS_PREFIX:
        return HDWallet.bip32DerivePath(mnemonic, setting!.bip44Path);
      case KLS_PREFIX:
        final keyPair = HDWallet.bip32HdWallet(mnemonic, setting!.bip44Path);
        final wallet4 = HDLedger.deriveChild(keyPair.chainCode,
            keyPair.privateKey!, keyPair.publicKey.sublist(1));
        final Wallet5 = HDLedger.deriveChild(wallet4.chainCode,
            wallet4.privateKey!, wallet4.publicKey.sublist(1));
        return dynamicToUint8List(Wallet5.privateKey!);
      default:
        return HDWallet.bip32DerivePath(mnemonic, setting!.bip44Path);
    }
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    switch (prefix) {
      case KAS_PREFIX:
        return EcdaSignature.privateKeyToPublicKey(privateKey);
      case KLS_PREFIX:
        return EcdaSignature.privateKeyToPublicKey(privateKey, compress: false)
            .sublist(0, 32);
      default:
        return EcdaSignature.privateKeyToPublicKey(privateKey);
    }
  }

  @override
  String publicKeyToAddress(Uint8List publicKey) {
    switch (prefix) {
      case KAS_PREFIX:
        return getKasAddress(publicKey);
      case KLS_PREFIX:
        return getKlsAddress(publicKey);
      default:
        return getKasAddress(publicKey);
    }
  }

  @override
  String sign(String message) {
    return Schnorr.sign(privateKey, message);
  }

  @override
  bool verify(String signature, String message) {
    switch (prefix) {
      case KAS_PREFIX:
        return Schnorr.verify(publicKey.sublist(1), signature, message);
      case KLS_PREFIX:
        return Schnorr.verify(publicKey, signature, message);
      default:
        return Schnorr.verify(publicKey.sublist(1), signature, message);
    }
  }

  static getKasAddress(Uint8List publicKey) {
    final eight0 = [0, 0, 0, 0, 0, 0, 0, 0];
    final versionByte = [0];
    final data = [...versionByte, ...publicKey.sublist(1)];
    final payloadData = toUint5Array(data);
    final checksumData = [...KAS_DECODE, ...payloadData, ...eight0];
    final polymodData = checksumToArray(polymod(checksumData));
    final addressBytes = [...payloadData, ...polymodData];
    return "$KAS_PREFIX:${Base32.encode(addressBytes)}";
  }

  static getKlsAddress(Uint8List publicKey) {
    final eight0 = [0, 0, 0, 0, 0, 0, 0, 0];
    final versionByte = [0];
    final data = [...versionByte, ...publicKey];
    final payloadData = toUint5Array(data);
    final checksumData = [...KLS_DECODE, ...payloadData, ...eight0];
    final polymodData = checksumToArray(polymod(checksumData));
    final addressBytes = [...payloadData, ...polymodData];
    return "$KLS_PREFIX:${Base32.encode(addressBytes)}";
  }
}

int polymod(List<int> data) {
  const GENERATOR1 = [0x98, 0x79, 0xf3, 0xae, 0x1e];
  const GENERATOR2 = [
    0xf2bc8e61,
    0xb76d99e2,
    0x3e5fb3c4,
    0x2eabe2a8,
    0x4f43e470
  ];
  int c0 = 0;
  int c1 = 1;
  int C = 0;

  for (int j = 0; j < data.length; j++) {
    C = c0 >> 3;
    c0 &= 0x07;
    c0 <<= 5;
    c0 |= c1 >> 27;
    c1 &= 0x07ffffff;
    c1 <<= 5;
    c1 ^= data[j];

    for (int i = 0; i < GENERATOR1.length; ++i) {
      if ((C & (1 << i)) != 0) {
        c0 ^= GENERATOR1[i];
        c1 ^= GENERATOR2[i];
      }
    }
  }

  c1 ^= 1;

  if (c1 < 0) {
    c1 ^= 1 << 31;
    c1 += (1 << 30) * 2;
  }

  return c0 * (1 << 30) * 4 + c1;
}

List<int> checksumToArray(int checksum) {
  List<int> result = [];
  for (int i = 0; i < 8; ++i) {
    result.add(checksum & 31);
    checksum ~/= 32;
  }
  return result.reversed.toList();
}
