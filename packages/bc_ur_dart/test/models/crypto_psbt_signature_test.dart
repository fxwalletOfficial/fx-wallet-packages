import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BtcSignature', () {
    test('rejects non-bytes payload with explicit CBOR error', () {
      final ur = UR.fromCBOR(
        type: RegistryType.CRYPTO_PSBT.type,
        value: CborString('not-psbt-bytes'),
      );

      expect(
        () => BtcSignature.fromUR(ur: ur),
        throwsA(isA<InvalidCborURException>()),
      );
    });

    test('wraps an undecodable CBOR payload in a URException', () {
      // A truncated CBOR stream (0x18 = "uint8 follows" with no trailing byte)
      // must surface as the URException contract, not the cbor library's own
      // exception, so callers can catch it via `on URException`.
      final ur = UR(
        type: RegistryType.CRYPTO_PSBT.type,
        payload: Uint8List.fromList([0x18]),
      );

      expect(
        () => BtcSignature.fromUR(ur: ur),
        throwsA(isA<URException>()),
      );
    });

    test('rejects a wrong UR type', () {
      final ur = UR.fromCBOR(
        type: RegistryType.BYTES.type,
        value: CborBytes([1, 2, 3]),
      );

      expect(
        () => BtcSignature.fromUR(ur: ur),
        throwsA(isA<InvalidTypeURException>()),
      );
    });
  });
}
