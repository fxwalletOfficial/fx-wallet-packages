import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:test/test.dart';

void main() {
  group('PsbtSignRequestUR', () {
    test('round-trips a valid PSBT sign request', () {
      final request = PsbtSignRequestUR.fromTypedTransaction(
        path: "m/84'/0'/0'/0/0",
        psbt: '70736274ff0100',
        xfp: '12345678',
        origin: 'test',
      );

      final parsed = PsbtSignRequestUR.fromUR(ur: UR.decode(request.encode()));

      expect(parsed.uuid, request.uuid);
      expect(parsed.path, "m/84'/0'/0'/0/0");
      expect(parsed.xfp, '12345678');
      // fromUR decodes psbt bytes via toHex(), which prefixes '0x' (pre-existing behavior).
      expect(parsed.psbt, '0x70736274ff0100');
    });

    test('rejects missing PSBT bytes with explicit CBOR error', () {
      final ur = UR.fromCBOR(
        type: PSBT_SIGN_REQUEST,
        value: CborMap({
          CborSmallInt(1): CborBytes(UR.generateUUid(), tags: [37]),
          CborSmallInt(3): CborMap({
            CborSmallInt(1): CborList(getPath("m/84'/0'/0'/0/0")),
          }, tags: [
            40304
          ]),
        }),
      );

      expect(
        () => PsbtSignRequestUR.fromUR(ur: ur),
        throwsA(
          isA<InvalidCborURException>().having((e) => e.message, 'message', contains('psbt-sign-request.psbt')),
        ),
      );
    });

    test('rejects malformed keypath with explicit CBOR error', () {
      final request = PsbtSignRequestUR.fromTypedTransaction(
        path: "m/84'/0'/0'/0/0",
        psbt: '70736274ff0100',
        xfp: '12345678',
        origin: 'test',
      );
      final map = request.decodeCBOR() as CborMap;
      map[CborSmallInt(3)] = CborString('bad-keypath');

      expect(
        () => PsbtSignRequestUR.fromUR(ur: UR.fromCBOR(type: PSBT_SIGN_REQUEST, value: map)),
        throwsA(isA<InvalidCborURException>()),
      );
    });
  });
}
