import 'dart:typed_data';

import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:crypto_wallet_util/src/utils/bip32/bip32.dart' show NetworkType;
import 'package:crypto_wallet_util/src/utils/bip32/src/utils/base58.dart';
import 'package:crypto_wallet_util/src/utils/bip32/src/utils/constants.dart';
import 'package:crypto_wallet_util/src/utils/bip32/src/utils/extended_key.dart';
import 'package:pointycastle/export.dart';

import '../../../utils/bech32/bech32.dart';
import '../src/models/networks.dart';
import '../src/payments/index.dart' show PaymentData;
import '../src/payments/p2pkh.dart';
import '../src/payments/p2sh.dart';
import '../src/utils/constants/op.dart';
import '../src/utils/script.dart';

class Address {
  static bool validateAddress(String address, [NetworkType? nw]) {
    try {
      addressToOutputScript(address, nw);
      return true;
    } catch (err) {
      return false;
    }
  }

  static Uint8List? addressToOutputScript(String address, [NetworkType? nw]) {
    final network = nw ?? bitcoin;
    bool flag = false;
    final parts = address.split(':');
    if (parts.length == 2) {
      final cashAddressPrefix = network.prefix;
      if (cashAddressPrefix == null ||
          !validateCashAddress(address, cashAddressPrefix)) {
        throw ArgumentError('Invalid CashAddr prefix or checksum');
      }
      address = bchToLegacy(address, prefix: cashAddressPrefix);
    }

    try {
      final decodeBase58 = bs58check.decode(address);
      if (decodeBase58[0] == network.pubKeyHash)
        return P2PKH(
          data: PaymentData(address: address),
          network: network,
        ).data.output;
      if (decodeBase58[0] == network.scriptHash)
        return P2SH(
          data: PaymentData(address: address),
          network: network,
        ).data.output;

      throw ArgumentError('Invalid version or Network mismatch');
    } catch (e) {
      flag = true;
    }

    try {
      final decodeBech32 = bech32.decode(address);
      if (network.bech32 != decodeBech32.hrp)
        throw ArgumentError('Invalid prefix or Network mismatch');
      if (decodeBech32.data.isEmpty || decodeBech32.data.first != 0) {
        throw ArgumentError('Unsupported witness version');
      }
      final program = Uint8List.fromList(
        convertBits(decodeBech32.data.sublist(1), 5, 8, strictMode: true),
      );
      if (program.length != 20 && program.length != 32) {
        throw ArgumentError('Invalid SegWit v0 witness program');
      }
      return compile([OPS['OP_0'], program]);
    } catch (e) {
      flag = true;
    }

    try {
      final decodeBech32m = bech32.decode(address, encoding: 'bech32m');
      if (network.bech32 != decodeBech32m.hrp)
        throw ArgumentError('Invalid prefix or Network mismatch');
      if (decodeBech32m.data.isEmpty || decodeBech32m.data.first != 1) {
        throw ArgumentError('Unsupported witness version');
      }

      final hash = Uint8List.fromList(
        convertBits(decodeBech32m.data.sublist(1), 5, 8, strictMode: true),
      );
      if (hash.length != 32) {
        throw ArgumentError('Invalid Taproot witness program');
      }
      return compile([OPS['OP_1'], hash]);
    } catch (e) {
      flag = true;
    }

    if (flag) throw ArgumentError('$address has no matching Script');
  }

  static String createExtendedAddress(
    Uint8List seed, {
    String? path,
    List<int>? prefix,
  }) {
    path ??= "m/44'/195'/0'/0/0";
    prefix ??= xprv;

    final root = ExtendedPrivateKey.master(seed, prefix);
    final r = root.forPath(path);
    return extendedFromPrivateKey((r as ExtendedPrivateKey).key);
  }

  static String extendedFromPrivateKey(BigInt privateKey) {
    final q = secp256k1.G * privateKey;

    final publicParams = ECPublicKey(q, secp256k1);
    final pk = publicParams.Q!.getEncoded(false);

    final input = Uint8List.fromList(pk.skip(1).toList());

    final digest = KeccakDigest(256);
    final result = Uint8List(digest.digestSize);
    digest.update(input, 0, input.length);
    digest.doFinal(result, 0);

    final addr = result.skip(result.length - 20).toList();
    return Base58CheckCodec.bitcoin().encode(Base58CheckPayload(0x41, addr));
  }

  static bool validateCashAddress(String address, String prefix) {
    try {
      if (address.toLowerCase() != address &&
          address.toUpperCase() != address) {
        return false;
      }

      final normalizedAddress = address.toLowerCase();
      final normalizedPrefix = prefix.toLowerCase();
      final parts = normalizedAddress.split(':');
      if (parts.length != 2 ||
          parts[0] != normalizedPrefix ||
          parts[1].isEmpty) {
        return false;
      }

      final payload = base32Decode(parts[1]);
      if (payload.length <= 8 || payload.any((value) => value < 0)) {
        return false;
      }

      final checksumData = prefixToUint5Array(normalizedPrefix) + [0] + payload;
      if (polymod(checksumData) != BigInt.zero) {
        return false;
      }

      final payloadData = payload.sublist(0, payload.length - 8);
      final decoded = convertBits(payloadData, 5, 8, strictMode: true);
      if (decoded.isEmpty ||
          convertBits(decoded, 8, 5).join(',') != payloadData.join(',')) {
        return false;
      }

      final version = decoded.first;
      if ((version & 0x80) != 0 ||
          (version & 0x78) != 0 && (version & 0x78) != 8) {
        return false;
      }

      const hashSizes = [20, 24, 28, 32, 40, 48, 56, 64];
      return decoded.length - 1 == hashSizes[version & 0x07];
    } catch (_) {
      return false;
    }
  }

  static String bchToLegacy(String addr, {String? prefix}) {
    final parts = addr.split(':');
    final cashAddressPrefix = (prefix ?? parts.first).toLowerCase();
    if (parts.length != 2 || !validateCashAddress(addr, cashAddressPrefix)) {
      throw ArgumentError('Invalid CashAddr');
    }
    final payload = base32Decode(parts[1]);
    final decoded = convertBits(
      payload.sublist(0, payload.length - 8),
      5,
      8,
      strictMode: true,
    );
    final isScriptHash = decoded.first & 0x78 == 8;
    final isMainnet = cashAddressPrefix == 'bitcoincash';
    final legacyVersion = isMainnet
        ? (isScriptHash ? 0x05 : 0x00)
        : (isScriptHash ? 0xc4 : 0x6f);
    return bs58check.encode(
      Uint8List.fromList([legacyVersion, ...decoded.sublist(1)]),
    );
  }

  static String legacyToBch({required String address, required String prefix}) {
    final decode = bs58check.decode(address);
    final hash = decode.sublist(1);
    final normalizedPrefix = prefix.toLowerCase();
    final isMainnet = normalizedPrefix == 'bitcoincash';
    final pubKeyHashVersion = isMainnet ? 0x00 : 0x6f;
    final scriptHashVersion = isMainnet ? 0x05 : 0xc4;
    final type = decode.first == pubKeyHashVersion
        ? 'P2PKH'
        : decode.first == scriptHashVersion
        ? 'P2SH'
        : throw ArgumentError('Legacy address does not match CashAddr network');

    final prefixData = prefixToUint5Array(normalizedPrefix) + [0];
    final versionByte = getTypeBits(type) + getHashSizeBits(hash);
    final payloadData = convertBits([versionByte] + hash, 8, 5);
    final checksumData =
        prefixData + payloadData + List.generate(8, (index) => 0);
    final payload = payloadData + checksumToUint5Array(polymod(checksumData));

    return '$normalizedPrefix:${base32Encode(payload)}';
  }
}
