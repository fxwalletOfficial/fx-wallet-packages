import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:test/test.dart';

/// 锁定"非优先链"malformed 解码的统一错误契约：
/// 之前这些链会抛出零散的 ArgumentError / RangeError / Exception / cast error，
/// 现在统一走 URException 家族（InvalidTypeURException / InvalidCborURException），
/// 使调用方可以在 `on URException` 一处收口所有 UR 解析失败。
void main() {
  // 顶层不是 CborMap 的合法 CBOR（这里编码成一个整数），用于触发收敛点包装。
  final nonMapPayload = Uint8List.fromList(cbor.encode(CborSmallInt(1)));

  group('Group A: RegistryItem.fromCBOR 收敛点统一为 InvalidCborURException', () {
    test('SolSignRequest.fromCBOR 顶层非 map', () {
      expect(() => SolSignRequest.fromCBOR(nonMapPayload), throwsA(isA<InvalidCborURException>()));
    });

    test('CosmosSignRequest.fromCBOR 顶层非 map', () {
      expect(() => CosmosSignRequest.fromCBOR(nonMapPayload), throwsA(isA<InvalidCborURException>()));
    });

    test('AlphSignRequest.fromCBOR 顶层非 map', () {
      expect(() => AlphSignRequest.fromCBOR(nonMapPayload), throwsA(isA<InvalidCborURException>()));
    });

    test('ScSignRequest.fromCBOR 顶层非 map', () {
      expect(() => ScSignRequest.fromCBOR(nonMapPayload), throwsA(isA<InvalidCborURException>()));
    });

    test('TronSignRequest.fromCBOR 顶层非 map', () {
      expect(() => TronSignRequest.fromCBOR(nonMapPayload), throwsA(isA<InvalidCborURException>()));
    });

    test('缺失必填字段（signData）时向上抛 InvalidCborURException', () {
      // 只放 uuid，缺 signData / signType，走 readBytes 的 ArgumentError → 收敛点翻译。
      final missingRequired = Uint8List.fromList(cbor.encode(CborMap({
        CborSmallInt(1): CborBytes(Uint8List.fromList(List<int>.filled(16, 1))),
      })));
      expect(() => SolSignRequest.fromCBOR(missingRequired), throwsA(isA<InvalidCborURException>()));
    });
  });

  group('Group B: fromUR 类型/结构校验统一为 URException', () {
    test('BchSignRequestUR.fromUR 错误 UR 类型 → InvalidTypeURException', () {
      final wrongType = UR(type: 'eth-sign-request', payload: Uint8List(4));
      expect(() => BchSignRequestUR.fromUR(ur: wrongType), throwsA(isA<InvalidTypeURException>()));
    });

    test('BchSignatureUR.fromUR 错误 UR 类型 → InvalidTypeURException', () {
      final wrongType = UR(type: 'eth-signature', payload: Uint8List(4));
      expect(() => BchSignatureUR.fromUR(ur: wrongType), throwsA(isA<InvalidTypeURException>()));
    });

    test('KeystoneXrpAccountBytes.fromUR 错误 UR 类型 → InvalidTypeURException', () {
      final wrongType = UR(type: 'eth-sign-request', payload: Uint8List(4));
      expect(() => KeystoneXrpAccountBytes.fromUR(wrongType), throwsA(isA<InvalidTypeURException>()));
    });

    test('KeystoneXrpSignRequestBytes.fromUR 顶层非 bytes → InvalidCborURException', () {
      final ur = UR.fromCBOR(type: RegistryType.BYTES.type, value: CborMap({}));
      expect(() => KeystoneXrpSignRequestBytes.fromUR(ur), throwsA(isA<InvalidCborURException>()));
    });

    test('ScSignRequest.fromUR 错误 UR 类型 → InvalidTypeURException', () {
      final wrongType = UR(type: 'eth-sign-request', payload: Uint8List(4));
      expect(() => ScSignRequest.fromUR(wrongType), throwsA(isA<InvalidTypeURException>()));
    });

    test('ScSignature.fromUR 错误 UR 类型 → InvalidTypeURException', () {
      final wrongType = UR(type: 'eth-signature', payload: Uint8List(4));
      expect(() => ScSignature.fromUR(wrongType), throwsA(isA<InvalidTypeURException>()));
    });

    test('KeystoneTronSignRequest.fromUR 错误 UR 类型 → InvalidTypeURException', () {
      final wrongType = UR(type: 'eth-sign-request', payload: Uint8List(4));
      expect(() => KeystoneTronSignRequest.fromUR(wrongType), throwsA(isA<InvalidTypeURException>()));
    });

    test('KeystoneTronSignResult.fromUR 错误 UR 类型 → InvalidTypeURException', () {
      final wrongType = UR(type: 'eth-signature', payload: Uint8List(4));
      expect(() => KeystoneTronSignResult.fromUR(wrongType), throwsA(isA<InvalidTypeURException>()));
    });
  });

  group('问题 3: optional best-effort vs required fail-closed', () {
    // 合法 keypath：components = [44, hardened]
    final keypath = CborMap({CborSmallInt(1): CborList([CborSmallInt(44), CborBool(true)])}, tags: [304]);

    CborMap solMap({required CborValue signData, CborValue? fee, CborValue? origin}) {
      return CborMap({
        CborSmallInt(1): CborBytes(Uint8List.fromList(List<int>.filled(16, 1))), // uuid (required bytes)
        CborSmallInt(2): signData, // signData (required bytes)
        CborSmallInt(3): keypath, // derivationPath (required)
        CborSmallInt(6): CborSmallInt(SignType.transaction.index), // signType (required)
        if (origin != null) CborSmallInt(5): origin, // origin (optional text)
        if (fee != null) CborSmallInt(8): fee, // fee (optional int)
      });
    }

    test('optional 字段类型不符 → 跳过（返回 null），不抛错', () {
      final map = solMap(
        signData: CborBytes(Uint8List.fromList([1, 2, 3])),
        fee: CborString('not-an-int'), // 期望 int，给了 string
        origin: CborSmallInt(999), // 期望 text，给了 int
      );
      final decoded = SolSignRequest.fromCBOR(Uint8List.fromList(cbor.encode(map)));
      expect(decoded.fee, isNull);
      expect(decoded.origin, isNull);
      expect(decoded.signData, equals(Uint8List.fromList([1, 2, 3])));
    });

    test('required 字段类型不符 → fail-closed 抛 InvalidCborURException', () {
      final map = solMap(signData: CborString('should-be-bytes')); // signData 期望 bytes
      expect(
        () => SolSignRequest.fromCBOR(Uint8List.fromList(cbor.encode(map))),
        throwsA(isA<InvalidCborURException>()),
      );
    });
  });
}
