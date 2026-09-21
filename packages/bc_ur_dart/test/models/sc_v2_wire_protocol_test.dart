import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:test/test.dart';

void main() {
  const requestId = '123e4567-e89b-12d3-a456-426614174000';
  final requestIdBytes = Uint8List.fromList(uuidParse(requestId));
  final fingerprint = Uint8List.fromList(<int>[0xa1, 0xb2, 0xc3, 0xd4]);
  final signerAddress = Uint8List.fromList(List<int>.generate(32, (index) => index));

  ScV2SignRequest request({ScV2Profile profile = ScV2Profile.sc, Uint8List? semanticTransaction}) {
    return ScV2SignRequest(
      requestId: requestIdBytes,
      profile: profile,
      masterFingerprint: fingerprint,
      signerCoreAddress: signerAddress,
      semanticTransaction: semanticTransaction ?? Uint8List.fromList(<int>[0x00, 0x7f, 0x80, 0xff]),
    );
  }

  group('SC V2 sign request', () {
    test('round trips deterministic opaque bytes for both profiles', () {
      for (final profile in ScV2Profile.values) {
        final original = request(profile: profile);
        final first = original.toCBOR();
        final second = request(profile: profile).toCBOR();
        final decoded = ScV2SignRequest.fromCBOR(first);

        expect(first, second);
        expect(decoded.toCBOR(), first);
        expect(decoded.protocolVersion, 2);
        expect(decoded.requestIdString, requestId);
        expect(decoded.profile, profile);
        expect(decoded.masterFingerprint, fingerprint);
        expect(decoded.signerCoreAddress, signerAddress);
        expect(decoded.semanticTransaction, <int>[0x00, 0x7f, 0x80, 0xff]);
        expect(decoded.toUR().type, 'sc-v2-sign-request');
      }
    });

    test('buildUR uses the independent V2 registry type', () {
      final ur = ScV2SignRequest.buildUR(
        requestId: requestId,
        profile: ScV2Profile.scp,
        masterFingerprint: fingerprint,
        signerCoreAddress: signerAddress,
        semanticTransaction: Uint8List.fromList(<int>[1, 2, 3]),
      );

      expect(ur.type, RegistryType.SC_V2_SIGN_REQUEST.type);
      expect(ScV2SignRequest.fromUR(ur).profile, ScV2Profile.scp);
      expect(() => ScSignRequest.fromUR(ur), throwsA(isA<InvalidTypeURException>()));
    });

    test('rejects unknown version and profile', () {
      final valid = request().toCBOR();

      expect(() => ScV2SignRequest.fromCBOR(_replace(valid, 1, const CborSmallInt(3))), throwsA(_invalidField('protocolVersion', 'unsupported version 3')));
      expect(() => ScV2SignRequest.fromCBOR(_replace(valid, 3, const CborSmallInt(2))), throwsA(_invalidField('profile', 'unsupported profile 2')));
    });

    test('rejects malformed fixed-length fields', () {
      final valid = request().toCBOR();

      for (final malformed in <({int key, int length, String field})>[
        (key: 2, length: 15, field: 'requestId'),
        (key: 4, length: 3, field: 'masterFingerprint'),
        (key: 5, length: 31, field: 'signerCoreAddress'),
      ]) {
        final tags = malformed.key == 2 ? const <int>[37] : const <int>[];
        expect(() => ScV2SignRequest.fromCBOR(_replace(valid, malformed.key, CborBytes(Uint8List(malformed.length), tags: tags))), throwsA(_invalidField(malformed.field, 'expected')));
      }
    });

    test('rejects missing, unknown, duplicate, and non-canonical keys', () {
      final valid = request().toCBOR();
      final missingMap = cbor.decode(valid) as CborMap..remove(const CborSmallInt(6));
      final unknownMap = cbor.decode(valid) as CborMap..[const CborSmallInt(7)] = CborBytes(<int>[1]);
      final duplicate = Uint8List.fromList(<int>[0xa7, ...valid.sublist(1), 0x01, 0x02]);
      final reversed = CborMap.fromEntries((cbor.decode(valid) as CborMap).entries.toList().reversed, type: CborLengthType.definite);

      expect(() => ScV2SignRequest.fromCBOR(Uint8List.fromList(cbor.encode(missingMap))), throwsA(isA<InvalidCborURException>()));
      expect(() => ScV2SignRequest.fromCBOR(Uint8List.fromList(cbor.encode(unknownMap))), throwsA(isA<InvalidCborURException>()));
      expect(() => ScV2SignRequest.fromCBOR(duplicate), throwsA(isA<InvalidCborURException>()));
      expect(() => ScV2SignRequest.fromCBOR(Uint8List.fromList(cbor.encode(reversed))), throwsA(isA<InvalidCborURException>()));
    });

    test('accepts the semantic payload boundary and rejects larger payloads', () {
      final boundary = request(semanticTransaction: Uint8List(ScV2SignRequest.maxSemanticTransactionBytes));
      expect(boundary.toCBOR(), hasLength(ScV2SignRequest.maxCborPayloadBytes));
      expect(ScV2SignRequest.fromCBOR(boundary.toCBOR()).semanticTransaction, hasLength(ScV2SignRequest.maxSemanticTransactionBytes));

      expect(() => request(semanticTransaction: Uint8List(ScV2SignRequest.maxSemanticTransactionBytes + 1)), throwsArgumentError);

      final oversizedMap = cbor.decode(request().toCBOR()) as CborMap..[const CborSmallInt(6)] = CborBytes(Uint8List(ScV2SignRequest.maxSemanticTransactionBytes + 1));
      expect(() => ScV2SignRequest.fromCBOR(Uint8List.fromList(cbor.encode(oversizedMap))), throwsA(isA<InvalidCborURException>()));
      expect(() => ScV2SignRequest.fromCBOR(Uint8List(ScV2SignRequest.maxCborPayloadBytes + 1)), throwsA(isA<InvalidCborURException>()));
    });

    test('matches the two-output formula payload fragment budget at maxLength 80', () {
      for (final sample in <({int inputs, int expectedPayloadBytes, int expectedFragments})>[
        (inputs: 1, expectedPayloadBytes: 293, expectedFragments: 4),
        (inputs: 167, expectedPayloadBytes: 5606, expectedFragments: 71),
        (inputs: 1000, expectedPayloadBytes: 32262, expectedFragments: 404),
      ]) {
        // Canonical semantic fixture formula: 192 fixed bytes for two outputs,
        // plus one 32-byte input reference per input.
        final semanticBytes = Uint8List(192 + sample.inputs * 32);
        final ur = request(semanticTransaction: semanticBytes).toUR();

        expect(ur.payload, hasLength(sample.expectedPayloadBytes));
        expect(_fragmentCount(ur, maxLength: 80), sample.expectedFragments, reason: '${sample.inputs} input(s), payload=${ur.payload.length}');
      }
    });
  });

  group('SC V2 signature', () {
    test('round trips UUID and raw Ed25519 signature deterministically', () {
      final signatureBytes = Uint8List.fromList(List<int>.generate(64, (index) => 255 - index));
      final original = ScV2Signature(requestId: requestIdBytes, signature: signatureBytes);
      final encoded = original.toCBOR();
      final decoded = ScV2Signature.fromCBOR(encoded);

      expect(decoded.toCBOR(), encoded);
      expect(decoded.protocolVersion, 2);
      expect(decoded.requestIdString, requestId);
      expect(decoded.signature, signatureBytes);
      expect(decoded.toUR().type, 'sc-v2-signature');
      expect(_fragmentCount(decoded.toUR(), maxLength: 100), 1);
      expect(decoded.toUR().payload, hasLength(90));
    });

    test('fromRequest preserves the correlation UUID', () {
      final ur = ScV2Signature.fromRequest(request: request(), signature: Uint8List(64));

      expect(ScV2Signature.fromUR(ur).requestIdString, requestId);
    });

    test('rejects unknown version, malformed lengths, and unknown field', () {
      final valid = ScV2Signature(requestId: requestIdBytes, signature: Uint8List(64)).toCBOR();
      final unknownMap = cbor.decode(valid) as CborMap..[const CborSmallInt(4)] = const CborSmallInt(0);

      expect(() => ScV2Signature.fromCBOR(_replace(valid, 1, const CborSmallInt(3))), throwsA(_invalidField('protocolVersion', 'unsupported version 3')));
      expect(() => ScV2Signature.fromCBOR(_replace(valid, 2, CborBytes(Uint8List(15), tags: const <int>[37]))), throwsA(_invalidField('requestId', 'expected 16 bytes')));
      expect(() => ScV2Signature.fromCBOR(_replace(valid, 3, CborBytes(Uint8List(63)))), throwsA(_invalidField('signature', 'expected 64 bytes')));
      expect(() => ScV2Signature.fromCBOR(Uint8List.fromList(cbor.encode(unknownMap))), throwsA(isA<InvalidCborURException>()));
    });
  });

  test('legacy SC registry types remain independently decodable', () {
    final legacyRequest = ScSignRequest.buildUR(
      requestId: requestId,
      xfp: 'A1B2C3D4',
      path: '',
      address: 'legacy-address',
      publicKey: 'legacy-public-key',
      signingPayloadData: const <String, dynamic>{'siacoinInputs': <dynamic>[]},
    );
    final legacySignature = ScSignature.buildUR(requestId: requestId, broadcastTx: const <String, dynamic>{'transactions': <dynamic>[]});

    expect(ScSignRequest.fromUR(legacyRequest).address, 'legacy-address');
    expect(ScSignature.fromUR(legacySignature).broadcastTx['transactions'], isEmpty);
    expect(() => ScV2SignRequest.fromUR(legacyRequest), throwsA(isA<InvalidTypeURException>()));
    expect(() => ScV2Signature.fromUR(legacySignature), throwsA(isA<InvalidTypeURException>()));
  });
}

Uint8List _replace(Uint8List payload, int key, CborValue value) {
  final map = cbor.decode(payload) as CborMap;
  map[CborSmallInt(key)] = value;
  return Uint8List.fromList(cbor.encode(map));
}

Matcher _invalidField(String field, String reason) {
  return isA<InvalidCborURException>().having((error) => error.field, 'field', field).having((error) => error.message, 'message', contains(reason));
}

int _fragmentCount(UR ur, {required int maxLength}) {
  ur.maxLength = maxLength;
  final first = UR.decode(ur.next());
  return first.isFragment ? first.seq.length : 1;
}
