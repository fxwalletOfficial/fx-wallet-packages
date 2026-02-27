import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';

abstract class RegistryItem {
  RegistryType getRegistryType();

  RegistryItem decodeFromCbor(CborMap map);

  // =========================
  // encode 两条路径
  // =========================

  /// 路径 A（扁平结构推荐）：
  /// override buildCbor() 填入字段
  /// 基类 toCborValue() 自动组装成 CborMap
  ///
  /// 路径 B（含嵌套 RegistryItem 时使用）：
  /// override toCborValue() 完全自定义编码
  /// buildCbor() 不需要 override
  ///
  /// 两条路径选其一，不需要同时 override
  Map<int, CborValue> buildCbor() => {};

  // =========================
  // encode helpers
  // =========================

  CborSmallInt _key(int index) {
    if (index < 0) {
      throw ArgumentError("Registry key must be >= 0, got: $index");
    }
    return CborSmallInt(index);
  }

  CborValue cborInt(int value) {
    if (value >= 0 && value <= 23) {
      return CborSmallInt(value);
    }
    return CborInt(BigInt.from(value));
  }

  /// 支持 BigInt 编码（用于 chain-id 等大整数场景）
  CborValue cborBigInt(BigInt value) {
    if (value.isValidInt) {
      return cborInt(value.toInt());
    }
    return CborInt(value);
  }

  CborBytes cborBytes(Uint8List data, {List<int>? tags}) {
    return CborBytes(data, tags: tags ?? const []);
  }

  /// 统一编码入口
  ///
  /// 两种路径：
  ///   1. 子类 override toCborValue() — 完全自定义编码（用于需要兼容的老格式）
  ///      例如：CryptoKeypath、CosmosSignRequest（使用 CborValue(Dart Map) 推断类型）
  ///
  ///   2. 子类 override buildCbor() — 走基类统一编码（用于新格式）
  ///      例如：GsSignature、SolSignRequest 等
  ///
  /// 返回类型改为 CborValue（而不是 CborMap），兼容子类返回 CborValue 的情况
  CborValue toCborValue() {
    final raw = buildCbor();
    final Map<CborValue, CborValue> result = {};
    raw.forEach((k, v) {
      result[_key(k)] = v;
    });
    return CborMap(result);
  }

  Uint8List toCBOR() {
    return Uint8List.fromList(cbor.encode(toCborValue()));
  }

  UR toUR() {
    return UR(
      type: getRegistryType().type,
      payload: toCBOR(),
    );
  }

  // =========================
  // decode helpers
  // =========================

  static Uint8List readBytes(CborMap map, int key) {
    final v = map[CborSmallInt(key)];
    if (v is CborBytes) {
      return Uint8List.fromList(v.bytes);
    }
    throw ArgumentError("Invalid bytes at key $key");
  }

  /// 读取普通整数，CborSmallInt 是 CborInt 子类，一个 if 覆盖两种情况
  static int readInt(CborMap map, int key) {
    final v = map[CborSmallInt(key)];
    if (v is CborInt) {
      return v.toInt();
    }
    throw ArgumentError("Invalid int at key $key");
  }

  /// 读取大整数，用于 chain-id / 余额等超大数字场景
  /// 典型场景：ETH chain-id、ERC-20 token 数量（wei）
  static BigInt readBigInt(CborMap map, int key) {
    final v = map[CborSmallInt(key)];
    if (v is CborInt) {
      return v.toBigInt();
    }
    throw ArgumentError("Invalid bigint at key $key");
  }

  /// 读取可选字段，Keystone 很多字段是 optional
  static int? readOptionalInt(CborMap map, int key) {
    if (!hasKey(map, key)) return null;
    return readInt(map, key);
  }

  static Uint8List? readOptionalBytes(CborMap map, int key) {
    if (!hasKey(map, key)) return null;
    return readBytes(map, key);
  }

  static String? readOptionalText(CborMap map, int key) {
    if (!hasKey(map, key)) return null;
    final v = map[CborSmallInt(key)];
    if (v is CborString) return v.toString();
    throw ArgumentError("Invalid text at key $key");
  }

  static bool hasKey(CborMap map, int key) {
    return map.containsKey(CborSmallInt(key));
  }

  static CryptoKeypath readKeypath(CborMap map, int key) {
    final value = map[CborSmallInt(key)];

    if (value is CborMap) {
      // 标准路径：tagged CborMap 内联嵌套
      return CryptoKeypath().decodeFromCbor(value) as CryptoKeypath;
    }

    if (value is CborBytes) {
      // 防御路径：兼容旧版 CborBytes 格式
      return CryptoKeypath.fromCBOR(Uint8List.fromList(value.bytes));
    }

    throw ArgumentError(
      'Invalid keypath at key $key: '
      'expected CborMap or CborBytes, got ${value?.runtimeType}',
    );
  }

  static T fromCBOR<T extends RegistryItem>(
    Uint8List payload,
    T emptyInstance,
  ) {
    final decoded = cbor.decode(payload);
    if (decoded is! CborMap) {
      throw ArgumentError("Invalid CBOR structure");
    }
    return emptyInstance.decodeFromCbor(decoded) as T;
  }
}
