import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:test/test.dart';

void main() {
  group('GsplSignRequestUR', () {
    test('rejects missing tx data with explicit CBOR error', () {
      final ur = UR.fromCBOR(
        type: BTC_SIGN_REQUEST,
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
        () => GsplSignRequestUR.fromUR(ur: ur),
        throwsA(
          isA<InvalidCborURException>().having((e) => e.message, 'message', contains('btc-sign-request.gspl')),
        ),
      );
    });
  });
}
