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
    final keypath = CborMap({
      CborSmallInt(1): CborList([CborSmallInt(44), CborBool(true)])
    }, tags: [
      304
    ]);

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

  group('问题 2: 裸模型新增类型门 fromUR(UR)', () {
    final wrongType = UR(type: 'eth-sign-request', payload: Uint8List(4));

    test('8 个 fromUR 对错误 UR 类型均抛 InvalidTypeURException', () {
      expect(() => SolSignRequest.fromUR(wrongType), throwsA(isA<InvalidTypeURException>()));
      expect(() => SolSignature.fromUR(wrongType), throwsA(isA<InvalidTypeURException>()));
      expect(() => CosmosSignRequest.fromUR(wrongType), throwsA(isA<InvalidTypeURException>()));
      expect(() => CosmosSignature.fromUR(wrongType), throwsA(isA<InvalidTypeURException>()));
      expect(() => AlphSignRequest.fromUR(wrongType), throwsA(isA<InvalidTypeURException>()));
      expect(() => AlphSignature.fromUR(wrongType), throwsA(isA<InvalidTypeURException>()));
      expect(() => TronSignRequest.fromUR(wrongType), throwsA(isA<InvalidTypeURException>()));
      expect(() => TronSignature.fromUR(wrongType), throwsA(isA<InvalidTypeURException>()));
    });

    test('fromUR 正确类型时委托 fromCBOR 正常解码（Sol round-trip）', () {
      final ur = SolSignRequest.generateSignRequest(
        signData: 'deadbeef',
        signType: SignType.transaction,
        path: "m/44'/501'/0'/0'",
        xfp: '12345678',
      );
      final decoded = SolSignRequest.fromUR(ur);
      expect(decoded.signData, equals(Uint8List.fromList([0xde, 0xad, 0xbe, 0xef])));
      expect(decoded.signType, equals(SignType.transaction));
    });
  });

  group('issue #88: 列表字段中的畸形项必须失败，不得静默过滤', () {
    // 以合法请求为底，替换指定 key 的值后重新编码，模拟被篡改/畸形的 payload。
    Uint8List replaceKey(Uint8List payload, int key, CborValue value) {
      final map = Map<CborValue, CborValue>.from(cbor.decode(payload) as CborMap);
      map[CborSmallInt(key)] = value;
      return Uint8List.fromList(cbor.encode(CborMap(map)));
    }

    CborMap decodeMap(Uint8List payload) => cbor.decode(payload) as CborMap;

    final alphPayload = AlphSignRequest.generateSignRequest(
      signData: 'deadbeef',
      path: "m/44'/1234'/0'/0/0",
      xfp: '12345678',
      outputs: [
        {'address': 'addr-1', 'amount': '1000'},
        {'address': 'addr-2', 'amount': '2000'},
      ],
    ).payload;

    final cosmosPayload = KeystoneCosmosSignRequest.constructCosmosRequest(
      signDataHex: 'deadbeef',
      dataType: CosmosDataType.amino,
      paths: ["m/44'/118'/0'/0/0", "m/44'/118'/0'/0/1"],
      xfps: ['12345678', '12345678'],
      addresses: ['cosmos1a', 'cosmos1b'],
    ).payload;

    test('ALPH 合法 outputs 仍按顺序完整解码', () {
      final decoded = AlphSignRequest.fromCBOR(alphPayload);
      expect(parseTxOutputs(decoded.outputs), [
        {'address': 'addr-1', 'amount': '1000'},
        {'address': 'addr-2', 'amount': '2000'},
      ]);
    });

    test('ALPH outputs 中混入非 CborMap 项 → InvalidCborURException', () {
      final outputs = (decodeMap(alphPayload)[CborSmallInt(4)] as CborList).toList();
      final tampered = replaceKey(alphPayload, 4, CborList([CborSmallInt(1), ...outputs]));
      expect(() => AlphSignRequest.fromCBOR(tampered), throwsA(isA<InvalidCborURException>()));
    });

    test('ALPH outputs 不是 CborList → InvalidCborURException', () {
      final tampered = replaceKey(alphPayload, 4, CborString('not-a-list'));
      expect(() => AlphSignRequest.fromCBOR(tampered), throwsA(isA<InvalidCborURException>()));
    });

    test('Cosmos 合法 derivationPaths / addresses 仍完整解码', () {
      final decoded = KeystoneCosmosSignRequest.fromUR(UR(type: RegistryType.COSMOS_SIGN_REQUEST.type, payload: cosmosPayload));
      expect(decoded.getDerivationPaths(), ["m/44'/118'/0'/0/0", "m/44'/118'/0'/0/1"]);
      expect(decoded.addresses, ['cosmos1a', 'cosmos1b']);
    });

    UR cosmosUR(Uint8List payload) => UR(type: RegistryType.COSMOS_SIGN_REQUEST.type, payload: payload);

    test('Cosmos derivationPaths 中混入非 CborMap 项 → InvalidCborURException', () {
      final paths = (decodeMap(cosmosPayload)[CborSmallInt(4)] as CborList).toList();
      final tampered = replaceKey(cosmosPayload, 4, CborList([CborSmallInt(1), ...paths]));
      expect(() => KeystoneCosmosSignRequest.fromUR(cosmosUR(tampered)), throwsA(isA<InvalidCborURException>()));
    });

    test('Cosmos derivationPaths 不是 CborList → InvalidCborURException', () {
      final tampered = replaceKey(cosmosPayload, 4, CborString('not-a-list'));
      expect(() => KeystoneCosmosSignRequest.fromUR(cosmosUR(tampered)), throwsA(isA<InvalidCborURException>()));
    });

    test('Cosmos derivationPaths 为空 → InvalidCborURException', () {
      final tampered = replaceKey(cosmosPayload, 4, CborList([]));
      expect(() => KeystoneCosmosSignRequest.fromUR(cosmosUR(tampered)), throwsA(isA<InvalidCborURException>()));
    });

    test('Cosmos addresses 中混入非 CborString 项 → InvalidCborURException', () {
      final tampered = replaceKey(cosmosPayload, 5, CborList([CborSmallInt(1), CborString('cosmos1a'), CborString('cosmos1b')]));
      expect(() => KeystoneCosmosSignRequest.fromUR(cosmosUR(tampered)), throwsA(isA<InvalidCborURException>()));
    });

    test('Cosmos addresses 不是 CborList → InvalidCborURException', () {
      final tampered = replaceKey(cosmosPayload, 5, CborString('cosmos1a'));
      expect(() => KeystoneCosmosSignRequest.fromUR(cosmosUR(tampered)), throwsA(isA<InvalidCborURException>()));
    });
  });

  group('issue #88: bigIntToBytes 拒绝负数和非法输入', () {
    test('合法非负整数按大端编码', () {
      expect(bigIntToBytes('0'), isEmpty);
      expect(bigIntToBytes('255'), [0xff]);
      expect(bigIntToBytes('256'), [0x01, 0x00]);
    });

    test('负数 → URException(invalidParams)', () {
      expect(
        () => bigIntToBytes('-1'),
        throwsA(isA<URException>().having((e) => e.type, 'type', URExceptionType.invalidParams)),
      );
    });

    test('非数字字符串 → URException(invalidParams)', () {
      for (final input in ['', 'abc', '1.5', '12a']) {
        expect(
          () => bigIntToBytes(input),
          throwsA(isA<URException>().having((e) => e.type, 'type', URExceptionType.invalidParams)),
          reason: input,
        );
      }
    });

    test('ALPH 构造请求时负数 amount 失败而不是编码成错误的正数', () {
      expect(
        () => AlphSignRequest.generateSignRequest(
          signData: 'deadbeef',
          path: "m/44'/1234'/0'/0/0",
          xfp: '12345678',
          outputs: [
            {'address': 'addr-1', 'amount': '-1000'},
          ],
        ),
        throwsA(isA<URException>()),
      );
    });
  });
}
