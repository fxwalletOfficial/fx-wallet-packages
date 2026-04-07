import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:convert/convert.dart';

/// Keystone 官方 sol-sign-request 字段编号
/// 与 SolSignRequest（GoldShell 格式）不同，从第 3 字段起完全不同
///
/// Keystone spec:
///   1 = requestId  (bytes, tag:37)
///   2 = signData   (bytes)
///   3 = dataType   (int: 1=transaction, 2=message, 3=off-chain-message)
///   4 = derivationPath (crypto-keypath)
///   5 = address    (bytes, optional — Solana 地址的原始 32 字节)
///   6 = origin     (string, optional)
enum _KeystoneSolKeys {
  zero, // 0
  requestId, // 1
  signData, // 2
  dataType, // 3  ← 与 GoldShell 不同：这里是 dataType 而非 derivationPath
  derivationPath, // 4
  address, // 5  bytes，不是 string
  origin, // 6
}

/// Keystone 定义的 Solana 签名数据类型
/// 注意：从 1 开始（0 占位），与 SignType 不同的是多了 offChainMessage
enum SolDataType {
  zero, // 0  占位，不使用
  transaction, // 1  标准链上交易
  message, // 2  普通消息签名 (signMessage)
  offChainMessage, // 3  Solana off-chain message (新增, GoldShell 不支持)
}

/// Keystone 兼容的 Solana 签名请求
///
/// 设计原则：
///   - 继承 [SolSignRequest]，保留所有 GoldShell 字段作为内部存储
///   - 仅 override [toCborValue] 和 [decodeFromCbor]，输出/解析 Keystone 字段顺序
///   - 调用方通过类型区分用哪个硬件钱包：
///       GoldShell → SolSignRequest
///       Keystone  → KeystoneSolSignRequest
class KeystoneSolSignRequest extends SolSignRequest {
  /// Solana 地址的原始字节（32 bytes），Keystone 要求 bytes 而非 string
  final Uint8List? addressBytes;

  /// Keystone dataType，对应 [SolDataType]
  final SolDataType dataType;

  KeystoneSolSignRequest({
    super.uuid,
    required super.signData,
    required this.dataType,
    required super.derivationPath,
    this.addressBytes,
    super.origin,
  }) : super(
          signType: dataType == SolDataType.transaction ? SignType.transaction : SignType.message,
        );

  // ──────────────────────────────────────────────────────────────────────────
  // Encode：按 Keystone 字段顺序序列化
  // ──────────────────────────────────────────────────────────────────────────

  @override
  CborValue toCborValue() {
    final Map<CborValue, CborValue> map = {};

    // key 1: requestId (uuid bytes, tag:37)
    map[CborSmallInt(_KeystoneSolKeys.requestId.index)] = cborBytes(
      getRequestId(),
      tags: [RegistryType.UUID.tag],
    );

    // key 2: signData (raw transaction / message bytes)
    map[CborSmallInt(_KeystoneSolKeys.signData.index)] = cborBytes(signData);

    // key 3: dataType (int) ← Keystone 关键差异
    map[CborSmallInt(_KeystoneSolKeys.dataType.index)] = cborInt(dataType.index);

    // key 4: derivationPath (crypto-keypath)
    map[CborSmallInt(_KeystoneSolKeys.derivationPath.index)] = derivationPath.toCborValue();

    // key 5: address (bytes, optional)
    if (addressBytes != null && addressBytes!.isNotEmpty) {
      map[CborSmallInt(_KeystoneSolKeys.address.index)] = cborBytes(addressBytes!);
    }

    // key 6: origin (string, optional)
    if (origin != null && origin!.isNotEmpty) {
      map[CborSmallInt(_KeystoneSolKeys.origin.index)] = CborString(origin!);
    }

    return CborMap(map);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Decode：从 Keystone 设备扫回的 QR 数据解析
  // ──────────────────────────────────────────────────────────────────────────

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    // key3 必须是 int（dataType），如果是 CborMap 说明传入的是 GoldShell 格式的 UR
    final key3 = map[CborSmallInt(_KeystoneSolKeys.dataType.index)];
    if (key3 is! CborInt) {
      throw Exception(
        'KeystoneSolSignRequest: key 3 must be dataType (int), '
        'got ${key3?.runtimeType}. '
        'Did you pass a GoldShell SolSignRequest UR to a Keystone parser?',
      );
    }

    final dataTypeIndex = key3.toInt();

    // dataType 安全转换：超出枚举范围时退化为 transaction
    final dataType = dataTypeIndex >= 0 && dataTypeIndex < SolDataType.values.length ? SolDataType.values[dataTypeIndex] : SolDataType.transaction;

    return KeystoneSolSignRequest(
      uuid: RegistryItem.readOptionalBytes(map, _KeystoneSolKeys.requestId.index),
      signData: RegistryItem.readBytes(map, _KeystoneSolKeys.signData.index),
      dataType: dataType,
      derivationPath: RegistryItem.readKeypath(
        map,
        _KeystoneSolKeys.derivationPath.index,
      ),
      addressBytes: RegistryItem.readOptionalBytes(
        map,
        _KeystoneSolKeys.address.index,
      ),
      origin: RegistryItem.readOptionalText(map, _KeystoneSolKeys.origin.index),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 工厂：从 Keystone 扫回的 UR 字符串解析
  // ──────────────────────────────────────────────────────────────────────────

  /// 解析 Keystone 设备扫回的 sol-sign-request UR
  static KeystoneSolSignRequest fromUR(UR ur) {
    final payload = ur.payload;
    return RegistryItem.fromCBOR<KeystoneSolSignRequest>(
      payload,
      KeystoneSolSignRequest(
        signData: Uint8List(0),
        dataType: SolDataType.transaction,
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
      uuid: uuid,
      signData: fromHex(txHex),
      dataType: SolDataType.transaction,
      derivationPath: CryptoKeypath(
        components: parsePath(path).map((e) => PathComponent(index: e['index'], hardened: e['hardened'])).toList(),
        sourceFingerprint: fromHex(xfp),
      ),
      addressBytes: address != null ? _base58Decode(address) : null,
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
    SolDataType dataType = SolDataType.message,
    String? address,
    String? origin,
    Uint8List? uuid,
  }) {
    assert(
      dataType != SolDataType.transaction,
      'Use buildTransactionRequest for transactions',
    );

    return KeystoneSolSignRequest(
      uuid: uuid,
      signData: fromHex(messageHex),
      dataType: dataType,
      derivationPath: CryptoKeypath(
        components: parsePath(path).map((e) => PathComponent(index: e['index'], hardened: e['hardened'])).toList(),
        sourceFingerprint: fromHex(xfp),
      ),
      addressBytes: address != null ? _base58Decode(address) : null,
      origin: origin,
    ).toUR();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 辅助：Solana Base58 地址 → bytes
  // ──────────────────────────────────────────────────────────────────────────

  /// Solana 地址是 Base58Check（无校验版），直接 base58 decode 得到 32 字节公钥
  static Uint8List _base58Decode(String address) {
    const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    BigInt result = BigInt.zero;
    for (final char in address.split('')) {
      final digit = alphabet.indexOf(char);
      if (digit < 0) throw ArgumentError('Invalid Base58 character: $char');
      result = result * BigInt.from(58) + BigInt.from(digit);
    }

    // 转为 32 字节（Solana 公钥固定长度）
    final bytes = <int>[];
    var remaining = result;
    while (remaining > BigInt.zero) {
      bytes.insert(0, (remaining % BigInt.from(256)).toInt());
      remaining ~/= BigInt.from(256);
    }

    // 补前缀 0（Base58 开头的 '1'）
    int leadingOnes = 0;
    for (final char in address.split('')) {
      if (char == '1')
        leadingOnes++;
      else
        break;
    }
    return Uint8List.fromList([...List.filled(leadingOnes, 0), ...bytes]);
  }

  @override
  String toString() => '''
KeystoneSolSignRequest {
  dataType: $dataType,
  path: ${derivationPath.getPath()},
  origin: $origin,
  addressBytes: ${addressBytes != null ? hex.encode(addressBytes!) : null},
  signData: ${hex.encode(signData)},
}''';
}
