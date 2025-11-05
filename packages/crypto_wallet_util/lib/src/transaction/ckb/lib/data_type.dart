import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto_wallet_util/src/utils/bech32/bech32.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

const CKB_HASH_PERSONALIZATION = 'ckb-default-hash';
const CKB_CODE_HASH =
    '9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8';
const SHORT_ID = 0;
const MAX_LENGTH = 1023;
const PREFIX = 'ckb';

enum AddressType { LONG, SHORT }

/// Provides data types required in [CkbTxData]
class CellDep {
  static const String Code = 'code';
  static const String DepGroup = 'dep_group';

  OutPoint? outPoint;
  String depType;

  CellDep({this.outPoint, this.depType = Code});

  factory CellDep.fromJson(Map<String, dynamic> json) {
    return CellDep(
        outPoint: OutPoint.fromJson(json['out_point']),
        depType: json['dep_type']);
  }

  String toJson() {
    return jsonEncode({
      'out_point': outPoint?.toJson(),
      'dep_type': depType,
    });
  }
}

class OutPoint {
  String? txHash;
  String? index;

  OutPoint({this.txHash, this.index});

  factory OutPoint.fromJson(Map<String, dynamic> json) {
    return OutPoint(txHash: json['tx_hash'], index: json['index']);
  }

  String toJson() {
    return jsonEncode({
      'tx_hash': txHash,
      'index': index,
    });
  }
}

class CellInput {
  OutPoint? previousOutput;
  String? since;

  CellInput({this.previousOutput, this.since});

  factory CellInput.fromJson(Map<String, dynamic> json) {
    return CellInput(
        previousOutput: OutPoint.fromJson(json['previous_output']),
        since: json['since']);
  }

  String toJson() {
    return jsonEncode({
      'previous_output': previousOutput?.toJson(),
      'since': since,
    });
  }
}

class CellOutput {
  String? capacity;
  Script? lock;
  Script? type;

  CellOutput({this.capacity, this.lock, this.type});

  factory CellOutput.fromJson(Map<String, dynamic> json) {
    return CellOutput(
        capacity: json['capacity'],
        lock: Script.fromJson(json['lock']),
        type: json['type'] == null ? null : Script.fromJson(json['type']));
  }

  String toJson() {
    return jsonEncode(
        {'capacity': capacity, 'lock': lock?.toJson(), 'type': type?.toJson()});
  }
}

class Script {
  static const String Data = 'data';
  static const String Type = 'type';

  String? codeHash;
  String? args;
  String hashType;

  Script({this.codeHash, this.args, this.hashType = Data});

  factory Script.fromJson(Map<String, dynamic> json) {
    return Script(
        codeHash: json['code_hash'],
        args: json['args'],
        hashType: json['hash_type']);
  }

  String toJson() {
    return jsonEncode(
        {'code_hash': codeHash, 'args': args, 'hash_type': hashType});
  }

  factory Script.fromAddress(address, AddressType addressType) {
    switch (addressType) {
      case AddressType.LONG:
        // 1,32,1,20
        final bechDecode =
            bech32.decode(address, maxLength: MAX_LENGTH, encoding: 'bech32m');
        final data = convertBits(bechDecode.data, 5, 8);
        final codeHash = dynamicToString(data.sublist(1, 33));
        if (bechDecode.hrp != PREFIX || codeHash != CKB_CODE_HASH) {
          throw ArgumentError('address error');
        }
        final hashType = codeToHashType(data.sublist(33, 34).first);
        final arg = dynamicToString(data.sublist(34, 54));
        return Script(hashType: hashType, args: arg, codeHash: codeHash);
      case AddressType.SHORT:
        // 1,1,20
        final bechDecode = bech32.decode(address, maxLength: MAX_LENGTH);
        final data = convertBits(bechDecode.data, 5, 8);
        if (bechDecode.hrp != PREFIX || data[1] != SHORT_ID) {
          throw ArgumentError('address error');
        }
        final arg = dynamicToString(data.sublist(2, 22));
        return Script(
            hashType: Script.Type, args: arg, codeHash: CKB_CODE_HASH);
    }
  }
}

int hashTypeToCode(String hashType) {
  if (hashType == 'data') return 0;
  if (hashType == 'type') return 1;
  if (hashType == 'data1') return 2;
  throw ArgumentError('Unsupported hash type');
}

String codeToHashType(int code) {
  if (code == 0) return 'data';
  if (code == 1) return 'type';
  if (code == 2) return 'data1';
  throw ArgumentError('Unsupported hash type');
}

class Witness {
  static final String SIGNATURE_PLACEHOLDER = '0' * 130;

  String? lock;
  String? inputType;
  String? outputType;

  Witness({this.lock, this.inputType, this.outputType});
}

class ScriptGroup {
  List<int> inputIndexes;

  ScriptGroup(this.inputIndexes);
}

abstract class SerializeType<T> {
  Uint8List toBytes();
  T getValue();
  int getLength();
}

abstract class FixedType<T> implements SerializeType<T> {}

abstract class DynType<T> implements SerializeType<T> {}

class Byte1 extends FixedType<Uint8List> {
  Uint8List _value;

  Byte1(this._value);

  factory Byte1.fromHex(String hex) {
    return Byte1(dynamicToUint8List(hex));
  }

  @override
  int getLength() {
    return 1;
  }

  @override
  Uint8List getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    return _value;
  }
}

class Byte32 extends FixedType<Uint8List> {
  Uint8List? _value;

  Byte32(Uint8List value) {
    if (value.length != 32) {
      throw ('Byte32 length error');
    }
    _value = value;
  }

  factory Byte32.fromHex(String hex) {
    var list = dynamicToUint8List(hex);
    if (list.length > 32) {
      throw ('Byte32 length error');
    } else if (list.length < 32) {
      var bytes = Uint8List(32);
      for (var i = 0; i < list.length; i++) {
        bytes[i] = list[i];
      }
      return Byte32(bytes);
    }
    return Byte32(list);
  }

  @override
  int getLength() {
    return 32;
  }

  @override
  Uint8List getValue() {
    return _value!;
  }

  @override
  Uint8List toBytes() {
    return _value!;
  }
}

class Empty extends FixedType {
  @override
  int getLength() {
    return 0;
  }

  @override
  void getValue() {
    return;
  }

  @override
  Uint8List toBytes() {
    return Uint8List.fromList(<int>[]);
  }
}

class EmptySerializeType implements SerializeType<dynamic> {
  @override
  int getLength() {
    return 0;
  }

  @override
  void getValue() {
    return;
  }

  @override
  Uint8List toBytes() {
    return Uint8List.fromList(<int>[]);
  }
}

class Fixed<T extends FixedType> implements SerializeType<List<T>> {
  final List<T> _value;

  Fixed(this._value);

  @override
  int getLength() {
    var length = UInt32.byteSize;
    for (SerializeType type in _value) {
      length += type.getLength();
    }
    return length;
  }

  @override
  List<T> getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    var dest = [...UInt32(_value.length).toBytes()];
    for (var type in _value) {
      dest.addAll(type.toBytes());
    }
    return Uint8List.fromList(dest);
  }
}

class Struct extends FixedType<List<SerializeType>> {
  final List<SerializeType> _value;

  Struct(this._value);

  @override
  int getLength() {
    var length = 0;
    for (var type in _value) {
      length += type.getLength();
    }
    return length;
  }

  @override
  List<SerializeType> getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    var dest = <int>[];
    for (var type in _value) {
      dest.addAll(type.toBytes());
    }
    return Uint8List.fromList(dest);
  }
}

class UInt32 extends FixedType<int> {
  static final int byteSize = 4;

  int _value;

  UInt32(this._value);

  factory UInt32.fromHex(String hex) =>
      UInt32(BigInt.parse(dynamicToString(hex), radix: 16).toInt());

  // generate int value from little endian bytes
  factory UInt32.fromBytes(Uint8List bytes) {
    var result = 0;
    for (var i = 3; i >= 0; i--) {
      result += (bytes[i] & 0xff) << 8 * i;
    }
    return UInt32(result);
  }

  @override
  int getLength() {
    return byteSize;
  }

  @override
  int getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    return Uint8List.fromList(
        <int>[_value, _value >> 8, _value >> 16, _value >> 24]);
  }
}

class UInt64 extends FixedType<BigInt> {
  BigInt _value;

  UInt64(this._value);

  factory UInt64.fromInt(int value) {
    return UInt64(BigInt.from(value));
  }

  factory UInt64.fromHex(String hex) {
    try {
      return UInt64(BigInt.parse(dynamicToString(hex), radix: 16));
    } catch (error) {
      return UInt64(BigInt.from(0));
    }
  }

  // generate int value from little endian bytes
  factory UInt64.fromBytes(Uint8List bytes) {
    var result = 0;
    for (var i = 7; i >= 0; i--) {
      result += (bytes[i] & 0xff) << 8 * i;
    }
    return UInt64.fromInt(result);
  }

  @override
  int getLength() {
    return 8;
  }

  @override
  BigInt getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    return Uint8List.fromList([
      _value.toInt(),
      (_value >> 8).toInt(),
      (_value >> 16).toInt(),
      (_value >> 24).toInt(),
      (_value >> 32).toInt(),
      (_value >> 40).toInt(),
      (_value >> 48).toInt(),
      (_value >> 56).toInt()
    ]);
  }
}

class Table extends SerializeType<List<SerializeType>> {
  final List<SerializeType> _value;

  Table(this._value);

  @override
  int getLength() {
    var length = (1 + _value.length) * UInt32.byteSize;
    for (var type in _value) {
      length += type.getLength();
    }
    return length;
  }

  @override
  List<SerializeType> getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    var dest = [...UInt32(getLength()).toBytes()];

    var typeOffset = UInt32.byteSize * (1 + _value.length);

    for (var type in _value) {
      dest.addAll(UInt32(typeOffset).toBytes());
      typeOffset += type.getLength();
    }

    for (var type in _value) {
      dest.addAll(type.toBytes());
    }

    return Uint8List.fromList(dest);
  }
}

class Option extends DynType<SerializeType> {
  final SerializeType _value;

  Option(this._value);

  @override
  int getLength() {
    return _value.getLength();
  }

  @override
  SerializeType getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    return _value.toBytes();
  }
}

class Dynamic<T extends SerializeType> implements SerializeType<List<T>> {
  final List<T> _value;

  Dynamic(this._value);

  @override
  int getLength() {
    var length = (1 + _value.length) * UInt32.byteSize;
    for (SerializeType type in _value) {
      length += type.getLength();
    }
    return length;
  }

  @override
  List<T> getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    var dest = [...UInt32(getLength()).toBytes()];

    var typeOffset = UInt32.byteSize * (1 + _value.length);

    for (var type in _value) {
      dest.addAll(UInt32(typeOffset).toBytes());
      typeOffset += type.getLength();
    }

    for (var type in _value) {
      dest.addAll(type.toBytes());
    }

    return Uint8List.fromList(dest);
  }
}

class Bytes extends DynType<Uint8List> {
  Uint8List _value;

  Bytes(this._value);

  factory Bytes.fromHex(String hex) => Bytes(dynamicToUint8List(hex));

  @override
  int getLength() {
    return _value.length + UInt32.byteSize;
  }

  @override
  Uint8List getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    return Uint8List.fromList([...UInt32(_value.length).toBytes(), ..._value]);
  }
}

List<int> regionToList(int start, int length) {
  var integers = <int>[];
  for (var i = start; i < (start + length); i++) {
    integers.add(i);
  }
  return integers;
}
