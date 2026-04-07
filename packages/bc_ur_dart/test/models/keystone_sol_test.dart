import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';
import 'package:test/test.dart';

void main() {
  const testPath = "m/44'/501'/0'/0'";
  const testXfp = '12345678';
  const testTxHex = 'deadbeef01020304';
  const testMsgHex = 'aabbccdd';
  const testOrigin = 'FxWallet';
  // 合法 Solana 地址（示例）
  const testAddress = '9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin';

  // ────────────────────────────────────────────────────────────────────
  // GoldShell 原有功能：完全不受影响
  // ────────────────────────────────────────────────────────────────────
  group('GoldShell SolSignRequest（原有功能，不受影响）', () {
    test('构造签名请求并编码', () {
      final ur = SolSignRequest.generateSignRequest(
        signData: testTxHex,
        signType: SignType.transaction,
        path: testPath,
        xfp: testXfp,
        origin: testOrigin,
      );

      expect(ur.type, equals('sol-sign-request'));
      final encoded = ur.encode();
      expect(encoded, startsWith('UR:SOL-SIGN-REQUEST/'));
    });

    test('解码后字段正确', () {
      final ur = SolSignRequest.generateSignRequest(
        signData: testTxHex,
        signType: SignType.transaction,
        path: testPath,
        xfp: testXfp,
        outputAddress: 'SomeAddress',
        origin: testOrigin,
      );

      // 原路解码：用 GoldShell 的 fromCBOR
      final decoded = SolSignRequest.fromCBOR(ur.payload);
      expect(decoded.signType, equals(SignType.transaction));
      expect(decoded.outputAddress, equals('SomeAddress'));
      expect(decoded.origin, equals(testOrigin));
    });

    test('GoldShell UR 传给 Keystone 解析器应抛出明确异常', () {
      // GoldShell 格式的 UR，key3=keypath(CborMap)，Keystone 期望 key3=dataType(int)
      // 这是错误用法，应该抛出有意义的异常，而不是静默解析出错误数据
      final goldshellUR = SolSignRequest.generateSignRequest(
        signData: testTxHex,
        signType: SignType.transaction,
        path: testPath,
        xfp: testXfp,
      );

      expect(
        () => KeystoneSolSignRequest.fromUR(goldshellUR),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('GoldShell'),
        )),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────
  // Keystone 新格式：独立工作
  // ────────────────────────────────────────────────────────────────────
  group('Keystone KeystoneSolSignRequest', () {
    test('构造 transaction 请求 — 字段顺序符合 Keystone spec', () {
      final ur = KeystoneSolSignRequest.buildTransactionRequest(
        txHex: testTxHex,
        path: testPath,
        xfp: testXfp,
        origin: testOrigin,
      );

      expect(ur.type, equals('sol-sign-request'));
      expect(ur.encode(), startsWith('UR:SOL-SIGN-REQUEST/'));

      // 解码验证字段
      final decoded = KeystoneSolSignRequest.fromUR(ur);
      expect(decoded.dataType, equals(SolDataType.transaction));
      expect(decoded.derivationPath.getPath(), equals(testPath));
      expect(decoded.origin, equals(testOrigin));
    });

    test('构造 message 请求', () {
      final ur = KeystoneSolSignRequest.buildMessageRequest(
        messageHex: testMsgHex,
        path: testPath,
        xfp: testXfp,
        dataType: SolDataType.message,
        origin: testOrigin,
      );

      final decoded = KeystoneSolSignRequest.fromUR(ur);
      expect(decoded.dataType, equals(SolDataType.message));
    });

    test('支持 offChainMessage（GoldShell 无此类型）', () {
      final ur = KeystoneSolSignRequest.buildMessageRequest(
        messageHex: testMsgHex,
        path: testPath,
        xfp: testXfp,
        dataType: SolDataType.offChainMessage,
      );

      final decoded = KeystoneSolSignRequest.fromUR(ur);
      expect(decoded.dataType, equals(SolDataType.offChainMessage));
    });

    test('带地址字段的请求', () {
      final ur = KeystoneSolSignRequest.buildTransactionRequest(
        txHex: testTxHex,
        path: testPath,
        xfp: testXfp,
        address: testAddress,
        origin: testOrigin,
      );

      final decoded = KeystoneSolSignRequest.fromUR(ur);
      expect(decoded.addressBytes, isNotNull);
      expect(decoded.addressBytes!.isNotEmpty, isTrue);
    });

    test('CBOR key 3 是 dataType(int)，不是 keypath', () {
      final req = KeystoneSolSignRequest(
        signData: Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]),
        dataType: SolDataType.transaction,
        derivationPath: CryptoKeypath(
          components: [
            PathComponent(index: 44, hardened: true),
            PathComponent(index: 501, hardened: true),
            PathComponent(index: 0, hardened: true),
            PathComponent(index: 0, hardened: true),
          ],
          sourceFingerprint: Uint8List.fromList([0x12, 0x34, 0x56, 0x78]),
        ),
      );

      final cborMap = req.toCborValue() as CborMap;
      // key 3 必须是 CborInt（dataType），而非 CborMap（keypath）
      final key3 = cborMap[CborSmallInt(3)];
      expect(key3, isA<CborInt>());
      expect((key3 as CborInt).toInt(), equals(SolDataType.transaction.index));

      // key 4 必须是 CborMap（derivationPath）
      final key4 = cborMap[CborSmallInt(4)];
      expect(key4, isA<CborMap>());
    });

    test('encode → decode 往返一致性', () {
      final original = KeystoneSolSignRequest.buildTransactionRequest(
        txHex: testTxHex,
        path: testPath,
        xfp: testXfp,
        origin: testOrigin,
      );

      final decoded = KeystoneSolSignRequest.fromUR(original);

      expect(decoded.dataType, equals(SolDataType.transaction));
      expect(decoded.derivationPath.getPath(), equals(testPath));
      expect(decoded.origin, equals(testOrigin));
    });
  });

  // ────────────────────────────────────────────────────────────────────
  // 两套格式并存：互不干扰
  // ────────────────────────────────────────────────────────────────────
  group('GoldShell 与 Keystone 并存测试', () {
    test('同一个 UR type 下两种格式独立解析', () {
      // GoldShell 路径
      final gsUR = SolSignRequest.generateSignRequest(
        signData: testTxHex,
        signType: SignType.transaction,
        path: testPath,
        xfp: testXfp,
      );

      // Keystone 路径
      final ksUR = KeystoneSolSignRequest.buildTransactionRequest(
        txHex: testTxHex,
        path: testPath,
        xfp: testXfp,
      );

      // 两者都是 sol-sign-request，但 CBOR 内容不同
      expect(gsUR.type, equals(ksUR.type));
      // payload 字节不同（字段顺序不同）
      expect(gsUR.payload, isNot(equals(ksUR.payload)));
    });

    test('调用方通过类型选择正确的解析器', () {
      // 模拟业务层：根据硬件钱包类型选择解析器
      UR mockScan(String walletType, String txHex) {
        if (walletType == 'keystone') {
          return KeystoneSolSignRequest.buildTransactionRequest(
            txHex: txHex,
            path: testPath,
            xfp: testXfp,
          );
        } else {
          return SolSignRequest.generateSignRequest(
            signData: txHex,
            signType: SignType.transaction,
            path: testPath,
            xfp: testXfp,
          );
        }
      }

      final ksResult = mockScan('keystone', testTxHex);
      final gsResult = mockScan('goldshell', testTxHex);

      // Keystone 用 Keystone 解析器
      final ksParsed = KeystoneSolSignRequest.fromUR(ksResult);
      expect(ksParsed.dataType, equals(SolDataType.transaction));

      // GoldShell 用原有解析器
      final gsParsed = SolSignRequest.fromCBOR(gsResult.payload);
      expect(gsParsed.signType, equals(SignType.transaction));
    });
  });
}
