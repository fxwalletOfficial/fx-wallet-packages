import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:crypto_wallet_util/src/utils/bip39/src/bip39_base.dart';
import "package:ed25519_hd_key/ed25519_hd_key.dart";
import 'package:substrate_bip39/substrate_bip39.dart';

import 'package:crypto_wallet_util/src/utils/bip32/bip32.dart' show BIP32, NetworkType, Bip32Type;
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Provide various methods to generate a hd wallet.
///  Include [BIP32], [BIP39], [ED25519_HD_KEY].
class HDWallet {
  static final HARDENED_OFFSET = 0x80000000;
  static final _BITCOIN = NetworkType(
    messagePrefix: '\u0018Bitcoin Signed Message:\n',
    bech32: 'bc',
    wif: 128,
    pubKeyHash: 0,
    scriptHash: 5,
    bip32: Bip32Type(public: 76067358, private: 76066276)
  );

  static Uint8List mnemonicToSeed(String mnemonic) {
    return BIP39.mnemonicToSeed(mnemonic);
  }

  static Uint8List mnemonicToEntropy(String mnemonic) {
    return dynamicToUint8List(BIP39.mnemonicToEntropy(mnemonic));
  }

  static Uint8List bip32DerivePath(String mnemonic, String path,
      [NetworkType? networkType]) {
    final seed = mnemonicToSeed(mnemonic);
    NetworkType network = networkType ?? _BITCOIN;
    final keyChain = BIP32.fromSeed(seed, network);
    final keyPair = keyChain.derivePath(path);
    return dynamicToUint8List(keyPair.privateKey!);
  }

  static BIP32 bip32HdWallet(String mnemonic, String path,
      [NetworkType? networkType]) {
    final seed = mnemonicToSeed(mnemonic);
    NetworkType network = networkType ?? _BITCOIN;
    final keyChain = BIP32.fromSeed(seed, network);
    return keyChain.derivePath(path);
  }

  static BIP32 getBip32Node(String mnemonic,
      [NetworkType? networkType]) {
    NetworkType network = networkType ?? _BITCOIN;
    final seed = mnemonicToSeed(mnemonic);
    return BIP32.fromSeed(seed, network);
  }

  static BIP32 getBip32Signer(String mnemonic, String path,
      [NetworkType? networkType]) {
    final node = getBip32Node(mnemonic, networkType);
    return node.derivePath(path);
  }

  static Future<Uint8List> bip44DerivePath(String mnemonic, String path) async {
    final seed = mnemonicToSeed(mnemonic);
    final keyData = await ED25519_HD_KEY.derivePath(path, seed);
    return Uint8List.fromList(keyData.key);
  }

  static Future<Uint8List> substrateBip39(String mnemonic) async {
    final seed = await SubstrateBip39.ed25519.seedFromUri(mnemonic);
    return Uint8List.fromList(seed);
  }

  static Uint8List hdLedger(String mnemonic, String path) {
    final seed = mnemonicToSeed(mnemonic);
    return HDLedger.ledgerMaster(seed, path);
  }
}

class HDLedger {
  static final ED25519_CRYPTO = 'ed25519 seed';

  /// derive path for dot ed25519.
  static Uint8List ledgerMaster(Uint8List seed, String path) {
    final chainCode = Hmac(sha256, utf8.encode(ED25519_CRYPTO))
        .convert(Uint8List.fromList([1, ...seed]))
        .bytes;
    List<int> priv = [];
    while (priv.length == 0 || (priv[31] & 32) != 0) {
      List<int> convertBytes = priv;
      if (priv.length == 0) {
        convertBytes = seed;
      }
      priv =
          Hmac(sha512, utf8.encode(ED25519_CRYPTO)).convert(convertBytes).bytes;
    }
    priv[0] &= 248;
    priv[31] &= 127;
    priv[31] |= 64;
    var result = Uint8List.fromList([...priv, ...chainCode]);

    List<String> segments = path.split('/');
    segments = segments.sublist(1);
    for (String segment in segments) {
      int index = int.parse(segment.replaceAll("'", ""));
      result = _ledgerDerivePrivate(result, index);
    }
    return dynamicToUint8List(result.sublist(0, 32));
  }

  static BIP32 deriveChild(
      Uint8List chainCode, Uint8List privateKey, Uint8List publicKey) {
    final data = Uint8List.fromList([...publicKey, 0, 0, 0, 0]);
    final I = _hmacShaAsU8a(chainCode, data, 512);
    final IL = I.sublist(0, 32);
    final IR = I.sublist(32);
    final ki = EcdaSignature.privateAdd(privateKey, IL);
    BIP32 hd = BIP32.fromPrivateKey(ki, IR);
    return hd;
  }

  static Uint8List _ledgerDerivePrivate(Uint8List xprv, int index) {
    final kl = xprv.sublist(0, 32);
    final kr = xprv.sublist(32, 64);
    final cc = xprv.sublist(64, 96);
    final offset = bnToU8a(BigInt.from(index + HARDENED_OFFSET));
    final data = Uint8List.fromList([0, ...kl, ...kr, ...offset]);
    final z = _hmacShaAsU8a(cc, data, 512);
    data[0] = 0x01;

    final klBn = u8aToBn(kl);
    final z28 = u8aToBn(z.sublist(0, 28));
    final resultBn1 = klBn + (z28 * BigInt.from(8));
    final resultBytes1 = bnToU8a(resultBn1);
    final part1 = resultBytes1.sublist(0, 32);

    final krBn = u8aToBn(kr);
    final z32_64 = u8aToBn(z.sublist(32, 64));
    final resultBn2 = krBn + z32_64;
    final resultBytes2 = bnToU8a(resultBn2);
    final part2 = resultBytes2.sublist(0, 32);

    final part3 = _hmacShaAsU8a(cc, data, 512).sublist(32, 64);
    return Uint8List.fromList([...part1, ...part2, ...part3]);
  }

  static Uint8List _hmacShaAsU8a(Uint8List key, Uint8List data, int bits) {
    final hmac = Hmac(sha512, key);
    final digest = hmac.convert(data);
    final bytes = digest.bytes;
    final result = Uint8List.fromList(bytes.sublist(0, bits ~/ 8));
    return result;
  }
}
