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
  });
}
