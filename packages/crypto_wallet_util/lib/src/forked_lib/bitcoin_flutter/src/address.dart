import 'dart:typed_data';

import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:pointycastle/export.dart';

import '../src/base58.dart';
import '../src/bech32/bech32.dart';
import '../src/bip32/bip32.dart';
import '../src/models/networks.dart';
import '../src/payments/index.dart' show PaymentData;
import '../src/payments/p2pkh.dart';
import '../src/payments/p2sh.dart';
import '../src/payments/p2wpkh.dart';
import '../src/utils/constants/constants.dart';
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
    if(parts.length == 2 && parts[0] == 'bitcoincash'){
      final reAddress = bchToLegacy(address);
      address = reAddress;
    }

    try {
      final decodeBase58 = bs58check.decode(address);
      if (decodeBase58[0] == network.pubKeyHash) return P2PKH(data: PaymentData(address: address), network: network).data.output;
      if (decodeBase58[0] == network.scriptHash) return P2SH(data: PaymentData(address: address), network: network).data.output;

      throw ArgumentError('Invalid version or Network mismatch');
    } catch (e) {
      flag = true;
    }

    try {
      final decodeBech32 = bech32.decode(address);
      if (network.bech32 != decodeBech32.hrp) throw ArgumentError('Invalid prefix or Network mismatch');

      final p2wpkh = P2WPKH(data: PaymentData(address: address), network: network);
      return p2wpkh.data.output;
    } catch (e) {
      flag = true;
    }

    try {
      final decodeBech32m = bech32.decode(address, encoding: 'bech32m');
      if (network.bech32 != decodeBech32m.hrp) throw ArgumentError('Invalid prefix or Network mismatch');

      final hash = Uint8List.fromList(convertBits(decodeBech32m.data.sublist(1), 5, 8, strictMode: true));
      return compile([OPS['OP_1'], hash]);
    } catch (e) {
      flag = true;
    }
    
    if(flag) throw ArgumentError('$address has no matching Script');
  }

  static String createExtendedAddress(Uint8List seed, {String? path, List<int>? prefix}) {
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

  static String bchToLegacy(String addr) {
    if(addr.split(':').length == 1) return '';
    final payload = base32Decode(addr.split(':')[1]);
    final hash = convertBits(payload.sublist(0, 34), 5, 8, strictMode: true);
    return bs58check.encode(Uint8List.fromList(hash));
  }

  static String legacyToBch({required String address, required String prefix}) {
    final decode = bs58check.decode(address);
    final hash = decode.sublist(1);
    final type = 'P2PKH';

    final prefixData = prefixToUint5Array(prefix) + [0];
    final versionByte = getTypeBits(type) + getHashSizeBits(hash);
    final payloadData = convertBits([versionByte] + hash, 8, 5);
    final checksumData = prefixData + payloadData + List.generate(8, (index) => 0);
    final payload = payloadData + checksumToUint5Array(polymod(checksumData));

    return '${prefix}:${base32Encode(payload)}';
  }
}
