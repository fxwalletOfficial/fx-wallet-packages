import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';
import 'package:test/test.dart';

void main() {
  group('CryptoKeypath source fingerprint', () {
    test('默认 big-endian encode 为 0x12345678', () {
      final kp = CryptoKeypath(
        sourceFingerprint: Uint8List.fromList([0x12, 0x34, 0x56, 0x78]),
      );
      final decoded = cbor.decode(kp.toCBOR()) as CborMap;

      expect(
        (decoded[CborSmallInt(2)] as CborInt).toInt(),
        equals(0x12345678),
      );
    });

    test('显式 little-endian legacy golden 为 0x78563412', () {
      final kp = CryptoKeypath(
        sourceFingerprint: Uint8List.fromList([0x12, 0x34, 0x56, 0x78]),
        sourceFingerprintEndian: Endian.little,
      );
      final decoded = cbor.decode(kp.toCBOR()) as CborMap;

      expect(
        (decoded[CborSmallInt(2)] as CborInt).toInt(),
        equals(0x78563412),
      );
    });

    test('big-endian round-trip 保持 bytes', () {
      final bytes = Uint8List.fromList([0xAB, 0xCD, 0xEF, 0x01]);
      final back = CryptoKeypath.fromCBOR(
        CryptoKeypath(sourceFingerprint: bytes).toCBOR(),
      );

      expect(back.getSourceFingerprint(), equals(bytes));
    });

    test('little-endian round-trip 保持 bytes', () {
      final bytes = Uint8List.fromList([0xAB, 0xCD, 0xEF, 0x01]);
      final encoded = CryptoKeypath(
        sourceFingerprint: bytes,
        sourceFingerprintEndian: Endian.little,
      ).toCBOR();
      final back = CryptoKeypath.fromCBOR(
        encoded,
        sourceFingerprintEndian: Endian.little,
      );

      expect(back.getSourceFingerprint(), equals(bytes));
    });

    test('length != 4 时 encode 抛错', () {
      final kp = CryptoKeypath(
        sourceFingerprint: Uint8List.fromList([1, 2, 3]),
      );

      expect(() => kp.toCBOR(), throwsArgumentError);
    });

    test('non-zero offset view 必须尊重 offset（回归 view-offset bug）', () {
      final backing = Uint8List.fromList([
        0x00,
        0x00,
        0x12,
        0x34,
        0x56,
        0x78,
      ]);
      final view = Uint8List.view(backing.buffer, 2, 4);
      final kp = CryptoKeypath(sourceFingerprint: view);
      final decoded = cbor.decode(kp.toCBOR()) as CborMap;

      expect(
        (decoded[CborSmallInt(2)] as CborInt).toInt(),
        equals(0x12345678),
      );
    });

    test('decode 时 fingerprint 超 uint32 范围抛错', () {
      final map = CborMap({
        CborSmallInt(1): CborList([]),
        CborSmallInt(2): CborInt(BigInt.from(0x1FFFFFFFF)),
      }, tags: [
        304,
      ]);

      expect(
        () => CryptoKeypath.fromCBOR(Uint8List.fromList(cbor.encode(map))),
        throwsArgumentError,
      );
    });
  });

  group('CryptoKeypath depth uint8', () {
    test('depth = 0 合法', () {
      expect(
        CryptoKeypath.fromCBOR(CryptoKeypath(depth: 0).toCBOR()).getDepth(),
        equals(0),
      );
    });

    test('depth = 255 合法', () {
      expect(
        CryptoKeypath.fromCBOR(CryptoKeypath(depth: 255).toCBOR()).getDepth(),
        equals(255),
      );
    });

    test('depth = 256 encode 抛错', () {
      expect(() => CryptoKeypath(depth: 256).toCBOR(), throwsArgumentError);
    });

    test('decode 时 depth > 255 抛错', () {
      final map = CborMap({
        CborSmallInt(1): CborList([]),
        CborSmallInt(3): CborSmallInt(300),
      }, tags: [
        304,
      ]);

      expect(
        () => CryptoKeypath.fromCBOR(Uint8List.fromList(cbor.encode(map))),
        throwsArgumentError,
      );
    });
  });

  group('CryptoKeypath decode fail-closed', () {
    Uint8List payload(CborList components) => Uint8List.fromList(
          cbor.encode(
            CborMap({
              CborSmallInt(1): components,
            }, tags: [
              304,
            ]),
          ),
        );

    test('is-hardened 非 CborBool 抛错，不默认 false', () {
      expect(
        () => CryptoKeypath.fromCBOR(
          payload(CborList([CborSmallInt(44), CborSmallInt(0)])),
        ),
        throwsArgumentError,
      );
    });

    test('component 非 CborInt/非空 CborList 抛错', () {
      expect(
        () => CryptoKeypath.fromCBOR(
          payload(CborList([CborString('x'), CborBool(true)])),
        ),
        throwsArgumentError,
      );
    });

    test('非空 CborList 作为 component（伪 wildcard）抛错', () {
      expect(
        () => CryptoKeypath.fromCBOR(
          payload(CborList([
            CborList([CborSmallInt(1)]),
            CborBool(false),
          ])),
        ),
        throwsArgumentError,
      );
    });

    test('components 奇数长度抛错', () {
      expect(
        () => CryptoKeypath.fromCBOR(
          payload(CborList([
            CborSmallInt(44),
            CborBool(true),
            CborSmallInt(0),
          ])),
        ),
        throwsArgumentError,
      );
    });

    test('components 非 CborList 抛错', () {
      final map = CborMap({
        CborSmallInt(1): CborSmallInt(0),
      }, tags: [
        304,
      ]);

      expect(
        () => CryptoKeypath.fromCBOR(Uint8List.fromList(cbor.encode(map))),
        throwsArgumentError,
      );
    });

    test('index 负数抛错', () {
      expect(
        () => CryptoKeypath.fromCBOR(
          payload(CborList([CborInt(BigInt.from(-1)), CborBool(false)])),
        ),
        throwsArgumentError,
      );
    });

    test('index >= 0x80000000 抛错', () {
      expect(
        () => CryptoKeypath.fromCBOR(
          payload(CborList([
            CborInt(BigInt.from(0x80000000)),
            CborBool(false),
          ])),
        ),
        throwsArgumentError,
      );
    });

    test("合法 hardened + wildcard 正常解码 (m/44'/*)", () {
      final kp = CryptoKeypath.fromCBOR(
        payload(CborList([
          CborSmallInt(44),
          CborBool(true),
          CborList([]),
          CborBool(false),
        ])),
      );

      expect(kp.getPath(), equals("m/44'/*"));
    });

    test('SolSignRequest 嵌套 malformed keypath 时向上抛错', () {
      final malformedKeypath = CborMap({
        CborSmallInt(1): CborList([CborSmallInt(44), CborSmallInt(0)]),
      }, tags: [
        304,
      ]);
      final request = CborMap({
        CborSmallInt(SolSignRequestKeys.uuid.index): CborBytes(
          Uint8List.fromList(List<int>.filled(16, 1)),
        ),
        CborSmallInt(SolSignRequestKeys.signData.index): CborBytes(
          Uint8List.fromList([1, 2, 3]),
        ),
        CborSmallInt(SolSignRequestKeys.derivationPath.index): malformedKeypath,
        CborSmallInt(SolSignRequestKeys.signType.index): CborSmallInt(
          SignType.transaction.index,
        ),
      });

      expect(
        () => SolSignRequest.fromCBOR(
          Uint8List.fromList(cbor.encode(request)),
        ),
        throwsArgumentError,
      );
    });
  });
}
