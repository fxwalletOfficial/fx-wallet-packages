import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:convert/convert.dart';

/// Official Keystone-compatible `sol-sign-request`.
///
/// This model intentionally stays separate from [SolSignRequest], which is
/// retained for the existing GoldShell flow.
enum _KeystoneSolKeys {
  zero,
  requestId,
  signData,
  derivationPath,
  address,
  origin,
  signType,
}

class KeystoneSolSignRequest extends RegistryItem {
  Uint8List? requestId;
  final Uint8List signData;
  final SignType signType;
  final CryptoKeypath derivationPath;
  final Uint8List? addressBytes;
  final String? origin;

  KeystoneSolSignRequest({
    this.requestId,
    required this.signData,
    required this.signType,
    required this.derivationPath,
    this.addressBytes,
    this.origin,
  });

  Uint8List getRequestId() => requestId ??= generateUuid();

  @override
  RegistryType getRegistryType() => RegistryType.SOL_SIGN_REQUEST;

  @override
  CborValue toCborValue() {
    final Map<CborValue, CborValue> map = {};

    // key 1: requestId (uuid bytes, tag:37)
    map[CborSmallInt(_KeystoneSolKeys.requestId.index)] = cborBytes(
      getRequestId(),
      tags: [RegistryType.UUID.tag],
    );
    map[CborSmallInt(_KeystoneSolKeys.signData.index)] = cborBytes(signData);
    map[CborSmallInt(_KeystoneSolKeys.derivationPath.index)] = derivationPath.toCborValue();
    map[CborSmallInt(_KeystoneSolKeys.signType.index)] = cborInt(signType.index);

    if (addressBytes != null && addressBytes!.isNotEmpty) {
      map[CborSmallInt(_KeystoneSolKeys.address.index)] = cborBytes(addressBytes!);
    }
    if (origin != null && origin!.isNotEmpty) {
      map[CborSmallInt(_KeystoneSolKeys.origin.index)] = CborString(origin!);
    }

    return CborMap(map);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    final signTypeIndex = RegistryItem.readInt(map, _KeystoneSolKeys.signType.index);

    return KeystoneSolSignRequest(
      requestId: RegistryItem.readOptionalBytes(map, _KeystoneSolKeys.requestId.index),
      signData: RegistryItem.readBytes(map, _KeystoneSolKeys.signData.index),
      signType: SignType.values[signTypeIndex],
      derivationPath: RegistryItem.readKeypath(map, _KeystoneSolKeys.derivationPath.index),
      addressBytes: RegistryItem.readOptionalBytes(map, _KeystoneSolKeys.address.index),
      origin: RegistryItem.readOptionalText(map, _KeystoneSolKeys.origin.index),
    );
  }

  /// 解析 Keystone 设备扫回的 sol-sign-request UR
  static KeystoneSolSignRequest fromUR(UR ur) {
    if (ur.type.toLowerCase() != RegistryType.SOL_SIGN_REQUEST.type) {
      throw ArgumentError('Invalid UR type for KeystoneSolSignRequest: ${ur.type}');
    }

    return RegistryItem.fromCBOR<KeystoneSolSignRequest>(
      ur.payload,
      KeystoneSolSignRequest(
        signData: Uint8List(0),
        signType: SignType.transaction,
        derivationPath: CryptoKeypath(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 工厂：热钱包构造签名请求发给 Keystone
  // ──────────────────────────────────────────────────────────────────────────

  /// 构造一笔链上交易签名请求 QR，显示给 Keystone 扫描
  ///
  /// [txHex]    : 序列化后的交易原始字节（hex 字符串）
  /// [path]     : 派生路径，例如 "m/44'/501'/0'/0'"
  /// [xfp]      : 主密钥指纹（hex，4 字节），例如 "12345678"
  /// [address]  : Solana 地址（Base58 字符串），可选，用于 Keystone 显示确认
  /// [origin]   : 来源标识，例如应用名，可选
  static UR buildTransactionRequest({
    required String txHex,
    required String path,
    required String xfp,
    String? address,
    String? origin,
    Uint8List? uuid,
  }) {
    return KeystoneSolSignRequest(
      requestId: uuid,
      signData: fromHex(txHex),
      signType: SignType.transaction,
      derivationPath: _buildKeypath(path, xfp),
      addressBytes: _decodeAddress(address),
      origin: origin,
    ).toUR();
  }

  /// 构造消息签名请求 QR，显示给 Keystone 扫描
  ///
  /// [messageHex] : 消息原始字节（hex 字符串）
  /// [dataType]   : [SolDataType.message] 或 [SolDataType.offChainMessage]
  static UR buildMessageRequest({
    required String messageHex,
    required String path,
    required String xfp,
    String? address,
    String? origin,
    Uint8List? uuid,
  }) {
    return KeystoneSolSignRequest(
      requestId: uuid,
      signData: fromHex(messageHex),
      signType: SignType.message,
      derivationPath: _buildKeypath(path, xfp),
      addressBytes: _decodeAddress(address),
      origin: origin,
    ).toUR();
  }

  static CryptoKeypath _buildKeypath(String path, String xfp) {
    return CryptoKeypath(
      components: parsePath(path).map((e) => PathComponent(index: e['index'], hardened: e['hardened'])).toList(),
      sourceFingerprint: fromHex(xfp),
    );
  }

  /// Follows the current Keystone npm implementation, which treats `address`
  /// as optional raw hex bytes and strips a leading `0x` if present.
  static Uint8List? _decodeAddress(String? address) {
    if (address == null || address.isEmpty) return null;
    final normalized = address.startsWith('0x') ? address.substring(2) : address;
    return fromHex(normalized);
  }

  @override
  String toString() => '''
KeystoneSolSignRequest {
  signType: $signType,
  path: ${derivationPath.getPath()},
  origin: $origin,
  addressBytes: ${addressBytes != null ? hex.encode(addressBytes!) : null},
  signData: ${hex.encode(signData)},
}''';
}
