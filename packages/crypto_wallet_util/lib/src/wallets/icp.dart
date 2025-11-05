import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:secp256k1_ecdsa/secp256k1.dart';
import 'package:pointycastle/asn1.dart';

import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';
import 'package:crypto_wallet_util/src/config/constants/icp_constants.dart';

/// Create a **icp** wallet using mnemonic or private key,
/// with a signature algorithm of [EcdaSignature] and an address type of [base58].

enum IcpWalletType {
  /// type for plug wallet (default)
  plug,

  /// type for stoic
  stoic
}

class IcpCoin extends WalletType {
  final _default = WalletSetting(bip44Path: ICP_PATH);
  final IcpWalletType _defaultType = IcpWalletType.plug;

  WalletSetting? setting;
  Principal? principal;
  IcpWalletType? icpWalletType;

  IcpCoin({setting, walletType}) {
    this.setting = setting ?? _default;
    icpWalletType = walletType ?? _defaultType;
  }

  initPrincipal() {
    principal = Principal.fromPublicKey(publicKey, icpWalletType);
  }

  static Future<IcpCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = IcpCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    wallet.initPrincipal();
    return wallet;
  }

  factory IcpCoin.fromPrivateKey(dynamic privateKey,
      [WalletSetting? setting, IcpWalletType? walletType]) {
    final wallet = IcpCoin(setting: setting, walletType: walletType);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    wallet.initPrincipal();
    return wallet;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    return HDWallet.bip32DerivePath(mnemonic, setting!.bip44Path);
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    switch (icpWalletType) {
      case IcpWalletType.stoic:
        return ED25519.privateKeyToPublicKey(privateKey);
      default:
        return EcdaSignature.getUnCompressedPublicKey(privateKey);
    }
  }

  @override
  String publicKeyToAddress(Uint8List publicKey) {
    final padding = asciiStringToByteArray("\x0Aaccount-id");
    final hash = getSha244Digest(Uint8List.fromList(
        [...padding, ...principal!.bytes, ...subAccountFromID(0)]));

    // Prepend the checksum of the hash and convert to a hex string
    final checksum = bigEndianCrc32(hash);
    final accountIdentifier = Uint8List.fromList([...checksum, ...hash]);
    final address = accountIdentifier.toStr();
    return address;
  }

  @override
  String sign(String message) {
    switch (icpWalletType) {
      case IcpWalletType.stoic:
        return ED25519.sign(privateKey, message).toStr();
      default:
        final signer = PrivateKey.fromHex(privateKey.toStr());
        final signature = signer.sign(message.toUint8List());
        final signatureBytes = signature.toCompactRawBytes();
        return dynamicToString(signatureBytes);
    }
  }

  @override
  bool verify(String signature, String message) {
    switch (icpWalletType) {
      case IcpWalletType.stoic:
        return ED25519.verify(publicKey, signature, message);
      default:
        final compressedPubKey =
            EcdaSignature.privateKeyToPublicKey(privateKey).toStr();
        final signedMessage =
            Signature.fromCompactBytes(signature.toUint8List());
        final pubKey = PublicKey.fromHex(compressedPubKey);
        return pubKey.verify(signedMessage, message.toUint8List());
    }
  }

  Uint8List bigEndianCrc32(Uint8List bytes) {
    final checksum = getCrc32(bytes);
    final buffer = ByteData(4);
    buffer.setUint32(0, checksum, Endian.big);
    return buffer.buffer.asUint8List();
  }

  Uint8List subAccountFromID(int id) {
    if (id < 0) throw ArgumentError("Number cannot be negative");

    if (id > 0x1FFFFFFFFFFFFFFF)
      throw ArgumentError("Number is too large to fit in 32 bytes.");

    final buffer = ByteData(32);
    if (id >= 0) {
      final high = (id >> 32) & 0xFFFFFFFF;
      final low = id & 0xFFFFFFFF;

      buffer.setUint32(24, high);
      buffer.setUint32(28, low);
    }
    return buffer.buffer.asUint8List();
  }
}

getCrc32(Uint8List buf) {
  final b = buf;
  int crc = 0xffffffff;
  for (int i = 0; i < b.length; i++) {
    final byte = b[i];
    final t = (byte ^ crc) & 0xff;
    crc = lookUpTable[t] ^ (crc >>> 8);
  }
  return ~crc & 0xffffffff;
}

class Principal {
  final Uint8List bytes;
  Principal(this.bytes);

  factory Principal.fromPublicKey(Uint8List publicKey,
      [IcpWalletType? walletType]) {
    final Uint8List OID =
        walletType == IcpWalletType.stoic ? ED25519_OID : SECP256K1_OID;
    final Uint8List publicKey_der = wrapDER(publicKey, OID);
    final sha224Hash = getSha244Digest(publicKey_der);
    final Uint8List principal =
        Uint8List.fromList([...sha224Hash, SELF_AUTHENTICATING_SUFFIX]);
    return Principal(principal);
  }

  static getRawPublicKey(Uint8List publicKey, [IcpWalletType? walletType]) {
    final Uint8List OID =
        walletType == IcpWalletType.stoic ? ED25519_OID : SECP256K1_OID;
    final Uint8List publicKey_der = wrapDER(publicKey, OID);
    return publicKey_der.toStr();
  }

  String toText() {
    final checksumArrayBuf = Uint8List(4)
      ..buffer.asByteData().setUint32(0, getCrc32(bytes));
    final checksum = checksumArrayBuf.sublist(0, 4);
    final data = Uint8List.fromList(bytes);
    final array = Uint8List.fromList([...checksum, ...data]);
    final result = Base32.encode(array, type: Base32Type.RFC4648);
    return splitStringIntoGroups(result.replaceAll('=', ''));
  }

  static String splitStringIntoGroups(String input) {
    List<String> groups = [];

    for (int i = 0; i < input.length; i += 5) {
      String group =
          input.substring(i, i + 5 > input.length ? input.length : i + 5);
      groups.add(group);
    }

    return groups.join('-');
  }

  static Uint8List wrapDER(Uint8List payload, Uint8List oid) {
    // The Bit String header needs to include the unused bit count byte in its length
    final bitStringHeaderLength = 2 + encodeLenBytes(payload.length + 1);
    final len = oid.length + bitStringHeaderLength + payload.length;
    int offset = 0;
    final int bufLength = 1 + encodeLenBytes(len) + len;
    final buf = Uint8List(bufLength);
    // Sequence
    buf[offset++] = 0x30;
    // Sequence Length
    offset += encodeLen(buf, offset, len);

    // OID
    buf.setAll(offset, oid);
    offset += oid.length;

    // Bit String Header
    buf[offset++] = 0x03;
    offset += encodeLen(buf, offset, payload.length + 1);
    // 0 padding
    buf[offset++] = 0x00;
    buf.setRange(offset, offset + payload.length, payload);

    return buf;
  }

  static int encodeLenBytes(len) {
    if (len <= 0x7f) {
      return 1;
    } else if (len <= 0xff) {
      return 2;
    } else if (len <= 0xffff) {
      return 3;
    } else if (len <= 0xffffff) {
      return 4;
    } else {
      throw Exception("Length too long (> 4 bytes)");
    }
  }

  static int encodeLen(buf, offset, len) {
    if (len <= 0x7f) {
      buf[offset] = len;
      return 1;
    } else if (len <= 0xff) {
      buf[offset] = 0x81;
      buf[offset + 1] = len;
      return 2;
    } else if (len <= 0xffff) {
      buf[offset] = 0x82;
      buf[offset + 1] = len >> 8;
      buf[offset + 2] = len;
      return 3;
    } else if (len <= 0xffffff) {
      buf[offset] = 0x83;
      buf[offset + 1] = len >> 16;
      buf[offset + 2] = len >> 8;
      buf[offset + 3] = len;
      return 4;
    } else {
      throw Exception("Length too long (> 4 bytes)");
    }
  }
}

class IcpPem {
  final String EcParameters;
  final String EcPrivateKey;

  IcpPem(this.EcParameters, this.EcPrivateKey);

  static Future<IcpPem> readPemFile(String path) async {
    File pemFile = File(path);
    if (!await pemFile.exists()) {
      throw Exception('PEM file does not exist at the specified path.');
    }

    String content = await pemFile.readAsString();
    final List<String> result = content
        .split('\n')
        .where((line) => line.isNotEmpty && !line.startsWith('-'))
        .toList();

    return IcpPem(result[0], result[1]);
  }

  Uint8List getEcPrivateKey() {
    final privateKeyBytes = base64.decode(EcPrivateKey);

    ASN1Parser keyParser = ASN1Parser(privateKeyBytes);
    final ASN1Object privateKeyObject = keyParser.nextObject();

    var sequence = privateKeyObject as ASN1Sequence;
    final ASN1Object privateKey = sequence.elements![1];

    return privateKey.valueBytes!;
  }
}
