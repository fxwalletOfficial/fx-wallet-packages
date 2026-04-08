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
  const testAddressHex = '0x00112233445566778899aabbccddeeff';

  group('GoldShell SolSignRequest', () {
    test('keeps existing transaction encoding behavior', () {
      final ur = SolSignRequest.generateSignRequest(
        signData: testTxHex,
        signType: SignType.transaction,
        path: testPath,
        xfp: testXfp,
        origin: testOrigin,
      );

      expect(ur.type, equals('sol-sign-request'));
      expect(ur.encode(), startsWith('UR:SOL-SIGN-REQUEST/'));
    });

    test('still decodes its own payload', () {
      final ur = SolSignRequest.generateSignRequest(
        signData: testTxHex,
        signType: SignType.transaction,
        path: testPath,
        xfp: testXfp,
        outputAddress: 'SomeAddress',
        origin: testOrigin,
      );

      final decoded = SolSignRequest.fromCBOR(ur.payload);
      expect(decoded.signType, equals(SignType.transaction));
      expect(decoded.outputAddress, equals('SomeAddress'));
      expect(decoded.origin, equals(testOrigin));
    });
  });

  group('KeystoneSolSignRequest', () {
    test('builds transaction requests with official signType layout', () {
      final ur = KeystoneSolSignRequest.buildTransactionRequest(
        txHex: testTxHex,
        path: testPath,
        xfp: testXfp,
        origin: testOrigin,
      );

      final decoded = KeystoneSolSignRequest.fromUR(ur);
      expect(ur.type, equals('sol-sign-request'));
      expect(decoded.signType, equals(SignType.transaction));
      expect(decoded.derivationPath.getPath(), equals(testPath));
      expect(decoded.origin, equals(testOrigin));
    });

    test('builds message requests with official signType layout', () {
      final ur = KeystoneSolSignRequest.buildMessageRequest(
        messageHex: testMsgHex,
        path: testPath,
        xfp: testXfp,
        origin: testOrigin,
      );

      final decoded = KeystoneSolSignRequest.fromUR(ur);
      expect(decoded.signType, equals(SignType.message));
      expect(decoded.derivationPath.getPath(), equals(testPath));
    });

    test('encodes address at key 4 when provided', () {
      final ur = KeystoneSolSignRequest.buildTransactionRequest(
        txHex: testTxHex,
        path: testPath,
        xfp: testXfp,
        address: testAddressHex,
      );

      final decoded = KeystoneSolSignRequest.fromUR(ur);
      expect(decoded.addressBytes, equals(fromHex(testAddressHex.substring(2))));
    });

    test('uses official cbor key ordering', () {
      final request = KeystoneSolSignRequest(
        signData: Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]),
        signType: SignType.transaction,
        derivationPath: CryptoKeypath(
          components: [
            PathComponent(index: 44, hardened: true),
            PathComponent(index: 501, hardened: true),
            PathComponent(index: 0, hardened: true),
            PathComponent(index: 0, hardened: true),
          ],
          sourceFingerprint: Uint8List.fromList([0x12, 0x34, 0x56, 0x78]),
        ),
        origin: testOrigin,
      );

      final cborMap = request.toCborValue() as CborMap;

      expect(cborMap[CborSmallInt(3)], isA<CborMap>());
      expect(cborMap[CborSmallInt(4)], isNull);
      expect(cborMap[CborSmallInt(5)], isA<CborString>());
      expect(cborMap[CborSmallInt(6)], isA<CborInt>());
      expect((cborMap[CborSmallInt(6)] as CborInt).toInt(), equals(SignType.transaction.index));
    });

    test('can parse overlapping GoldShell payloads with shared core fields', () {
      final goldshellUR = SolSignRequest.generateSignRequest(
        signData: testTxHex,
        signType: SignType.transaction,
        path: testPath,
        xfp: testXfp,
      );

      final decoded = KeystoneSolSignRequest.fromUR(goldshellUR);
      expect(decoded.signType, equals(SignType.transaction));
      expect(decoded.derivationPath.getPath(), equals(testPath));
      expect(decoded.origin, isNull);
      expect(decoded.addressBytes, isNull);
    });
  });

  group('GoldShell and Keystone stay separate', () {
    test('share type but not payload layout', () {
      final goldshellUR = SolSignRequest.generateSignRequest(
        signData: testTxHex,
        signType: SignType.transaction,
        path: testPath,
        xfp: testXfp,
      );
      final keystoneUR = KeystoneSolSignRequest.buildTransactionRequest(
        txHex: testTxHex,
        path: testPath,
        xfp: testXfp,
      );

      expect(goldshellUR.type, equals(keystoneUR.type));
      expect(goldshellUR.payload, isNot(equals(keystoneUR.payload)));
    });

    test('both payloads still preserve request semantics', () {
      final keystoneUR = KeystoneSolSignRequest.buildTransactionRequest(
        txHex: testTxHex,
        path: testPath,
        xfp: testXfp,
      );
      final goldshellUR = SolSignRequest.generateSignRequest(
        signData: testTxHex,
        signType: SignType.transaction,
        path: testPath,
        xfp: testXfp,
      );

      final keystoneParsed = KeystoneSolSignRequest.fromUR(keystoneUR);
      final goldshellParsed = SolSignRequest.fromCBOR(goldshellUR.payload);

      expect(keystoneParsed.signType, equals(SignType.transaction));
      expect(goldshellParsed.signType, equals(SignType.transaction));
    });

    test('GoldShell outputAddress does not map to Keystone address bytes', () {
      final goldshellUR = SolSignRequest.generateSignRequest(
        signData: testTxHex,
        signType: SignType.transaction,
        path: testPath,
        xfp: testXfp,
        outputAddress: 'SomeAddress',
      );

      expect(() => KeystoneSolSignRequest.fromUR(goldshellUR), throwsA(isA<ArgumentError>()));
    });
  });
}
