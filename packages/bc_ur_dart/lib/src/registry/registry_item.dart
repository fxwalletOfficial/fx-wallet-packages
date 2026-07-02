import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';
import 'package:bc_ur_dart/src/utils/cbor_value.dart';

abstract class RegistryItem {
  RegistryType getRegistryType();

  CborValue toCborValue();

  RegistryItem decodeFromCbor(CborMap map);

  // =========================
  // encode helpers
  // =========================

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
    return cborBytesOrNull(map[CborSmallInt(key)]) ?? (throw ArgumentError("Invalid bytes at key $key"));
  }

  /// 读取普通整数，CborSmallInt 是 CborInt 子类，一个 if 覆盖两种情况
  static int readInt(CborMap map, int key) {
    return cborIntOrNull(map[CborSmallInt(key)]) ?? (throw ArgumentError("Invalid int at key $key"));
  }

  /// 读取大整数，用于 chain-id / 余额等超大数字场景
  /// 典型场景：ETH chain-id、ERC-20 token 数量（wei）
  static BigInt readBigInt(CborMap map, int key) {
    return cborBigIntOrNull(map[CborSmallInt(key)]) ?? (throw ArgumentError("Invalid bigint at key $key"));
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
    return cborTextOrNull(map[CborSmallInt(key)]) ?? (throw ArgumentError("Invalid text at key $key"));
  }

  static String readText(CborMap map, int key) {
    return readOptionalText(map, key) ?? (throw ArgumentError("Missing text at key $key"));
  }

  static Uint8List jsonBytes(Object? value) {
    return Uint8List.fromList(utf8.encode(jsonEncode(value)));
  }

  static dynamic readJson(CborMap map, int key) {
    final bytes = readBytes(map, key);
    return jsonDecode(utf8.decode(bytes));
  }

  static Map<String, dynamic> readJsonMap(CborMap map, int key) {
    final value = readJson(map, key);
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ArgumentError('Invalid json map at key $key');
  }

  static List<dynamic>? readOptionalJsonList(CborMap map, int key) {
    if (!hasKey(map, key)) return null;
    final value = readJson(map, key);
    if (value is List<dynamic>) return value;
    throw ArgumentError('Invalid json list at key $key');
  }

  static bool hasKey(CborMap map, int key) {
    return map.containsKey(CborSmallInt(key));
  }

  static CryptoKeypath readKeypath(
    CborMap map,
    int key, {
    Endian sourceFingerprintEndian = Endian.big,
    String? model,
    String? field,
  }) {
    try {
      final value = map[CborSmallInt(key)];

      if (value is CborMap) {
        // 标准路径：tagged CborMap 内联嵌套
        return CryptoKeypath(sourceFingerprintEndian: sourceFingerprintEndian).decodeFromCbor(value) as CryptoKeypath;
      }

      if (value is CborBytes) {
        // 防御路径：兼容旧版 CborBytes 格式
        return CryptoKeypath.fromCBOR(Uint8List.fromList(value.bytes), sourceFingerprintEndian: sourceFingerprintEndian);
      }

      throw ArgumentError(
        'Invalid keypath at key $key: '
        'expected CborMap or CborBytes, got ${value?.runtimeType}',
      );
    } on ArgumentError catch (error) {
      // 模型工厂传入 model 时，把 CryptoKeypath 的 ArgumentError（Plan A 保留的 registry
      // primitive 错误）在公共模型边界转成 InvalidCborURException；未传 model 的内部调用保持旧行为。
      if (model == null) rethrow;
      throw InvalidCborURException(model: model, field: field ?? 'field[$key]', reason: error.message.toString(), cause: error);
    }
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

mixin RegistryMapEncoding on RegistryItem {
  Map<int, CborValue> buildCborFields();

  @override
  CborValue toCborValue() {
    final raw = buildCborFields();
    final result = <CborValue, CborValue>{};
    raw.forEach((key, value) {
      result[_key(key)] = value;
    });
    return CborMap(result);
  }

  CborSmallInt _key(int index) {
    if (index < 0) {
      throw ArgumentError("Registry key must be >= 0, got: $index");
    }
    return CborSmallInt(index);
  }
}
