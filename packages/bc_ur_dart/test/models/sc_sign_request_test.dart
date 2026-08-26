import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:test/test.dart';

void main() {
  group('SC sign request UR', () {
    test('round trips request payload', () {
      final signingPayloadData = {
        'siacoinInputs': [
          {
            'parent': {
              'id': 'input-id',
              'siacoinOutput': {
                'value': '1000000000000000000000000',
                'address': 'sender-address',
              },
            },
            'satisfiedPolicy': {
              'policy': {'type': 'pk', 'key': 'ed25519-public-key'},
              'signatures': [],
            },
          }
        ],
        'siacoinOutputs': [
          {
            'value': '123456789012345678901234',
            'address': 'receiver-address',
          }
        ],
      };

      final ur = ScSignRequest.buildUR(
        requestId: '123e4567-e89b-12d3-a456-426614174000',
        xfp: 'A1B2C3D4',
        path: "m/44'/1991'/0'",
        address: 'sender-address',
        publicKey: 'ed25519-public-key',
        signingPayloadData: signingPayloadData,
        fee: '1000000000000000000000',
        outputs: [
          {'address': 'receiver-address', 'amount': '123456789012345678901234'}
        ],
        origin: 'fxwallet',
        chain: 'scp',
        crossChainFee: '0.3',
      );

      expect(ur.type, RegistryType.SC_SIGN_REQUEST.type);

      final request = ScSignRequest.fromUR(ur);
      expect(request.getRequestIdString(), '123e4567-e89b-12d3-a456-426614174000');
      expect(request.xfp, 'A1B2C3D4');
      expect(request.path, "m/44'/1991'/0'");
      expect(request.address, 'sender-address');
      expect(request.publicKey, 'ed25519-public-key');
      expect(request.signingPayloadData['siacoinOutputs'][0]['value'], '123456789012345678901234');
      expect(request.fee, '1000000000000000000000');
      expect(request.outputs?.first['amount'], '123456789012345678901234');
      expect(request.origin, 'fxwallet');
      expect(request.chain, 'scp');
      expect(request.crossChainFee, '0.3');
    });

    test('cross-chain fee is omitted when not provided', () {
      final ur = ScSignRequest.buildUR(
        xfp: 'A1B2C3D4',
        path: "m/44'/1991'/0'",
        address: 'sender-address',
        publicKey: 'ed25519-public-key',
        signingPayloadData: const {'siacoinInputs': []},
      );

      final request = ScSignRequest.fromUR(ur);
      expect(request.crossChainFee, isNull);
    });

    test('round trips deterministic zlib signing payload while preserving request fields', () {
      final signingPayloadData = <String, dynamic>{
        'siacoinInputs': List<Map<String, dynamic>>.generate(
          4,
          (index) => <String, dynamic>{
            'parent': <String, dynamic>{
              'id': 'input-$index',
              'stateElement': <String, dynamic>{'leafIndex': index, 'merkleProof': List<String>.filled(20, 'proof-$index')},
            },
            'satisfiedPolicy': <String, dynamic>{'policy': 'pk', 'signatures': <String>[]},
          },
        ),
        'siacoinOutputs': const <Map<String, dynamic>>[
          <String, dynamic>{'value': '1000', 'address': 'receiver-address'},
        ],
      };

      UR build() => ScSignRequest.buildUR(
            requestId: '123e4567-e89b-12d3-a456-426614174000',
            xfp: 'A1B2C3D4',
            path: "m/44'/1991'/0'",
            address: 'sender-address',
            publicKey: 'ed25519-public-key',
            signingPayloadData: signingPayloadData,
            signingPayloadEncoding: ScSigningPayloadEncoding.zlibJsonV1,
            chain: 'sc',
          );

      final first = build();
      final second = build();
      final request = ScSignRequest.fromUR(first);
      final map = cbor.decode(first.payload) as CborMap;
      final compressed = map[CborSmallInt(ScSignRequestKeys.signingPayloadData.index)]! as CborBytes;

      expect(first.payload, second.payload, reason: '固定输入的 SC zlib 请求必须逐字节确定');
      expect(request.signingPayloadEncoding, ScSigningPayloadEncoding.zlibJsonV1);
      expect(request.signingPayloadData, signingPayloadData);
      expect(ScSignRequest.fromCBOR(first.payload).signingPayloadData, signingPayloadData);
      expect(compressed.bytes.length, lessThan(utf8.encode(jsonEncode(signingPayloadData)).length));
      expect((map[CborSmallInt(ScSignRequestKeys.signingPayloadEncoding.index)]! as CborInt).toInt(), 1);
    });

    test('keeps legacy request bytes unchanged when compression is not selected', () {
      UR build(ScSigningPayloadEncoding encoding) => ScSignRequest.buildUR(
            requestId: '123e4567-e89b-12d3-a456-426614174000',
            xfp: 'A1B2C3D4',
            path: "m/44'/1991'/0'",
            address: 'sender-address',
            publicKey: 'ed25519-public-key',
            signingPayloadData: const <String, dynamic>{'siacoinInputs': <dynamic>[]},
            signingPayloadEncoding: encoding,
          );

      final defaultRequest = ScSignRequest.buildUR(
        requestId: '123e4567-e89b-12d3-a456-426614174000',
        xfp: 'A1B2C3D4',
        path: "m/44'/1991'/0'",
        address: 'sender-address',
        publicKey: 'ed25519-public-key',
        signingPayloadData: const <String, dynamic>{'siacoinInputs': <dynamic>[]},
      );
      final explicitLegacy = build(ScSigningPayloadEncoding.json);
      final map = cbor.decode(defaultRequest.payload) as CborMap;

      expect(defaultRequest.payload, explicitLegacy.payload);
      expect(map.containsKey(CborSmallInt(ScSignRequestKeys.signingPayloadEncoding.index)), isFalse);
      expect(ScSignRequest.fromUR(defaultRequest).signingPayloadEncoding, ScSigningPayloadEncoding.json);
    });

    test('rejects corrupted or unknown compressed signing payloads', () {
      final valid = ScSignRequest.buildUR(
        requestId: '123e4567-e89b-12d3-a456-426614174000',
        xfp: 'A1B2C3D4',
        path: "m/44'/1991'/0'",
        address: 'sender-address',
        publicKey: 'ed25519-public-key',
        signingPayloadData: const <String, dynamic>{'siacoinInputs': <dynamic>[]},
        signingPayloadEncoding: ScSigningPayloadEncoding.zlibJsonV1,
      );
      final damagedMap = cbor.decode(valid.payload) as CborMap;
      final fieldKey = CborSmallInt(ScSignRequestKeys.signingPayloadData.index);
      final damagedBytes = Uint8List.fromList((damagedMap[fieldKey]! as CborBytes).bytes)..[0] ^= 0xff;
      damagedMap[fieldKey] = CborBytes(damagedBytes);

      final unknownMap = cbor.decode(valid.payload) as CborMap;
      unknownMap[CborSmallInt(ScSignRequestKeys.signingPayloadEncoding.index)] = const CborSmallInt(99);

      expect(() => ScSignRequest.fromUR(_urFromMap(damagedMap)), throwsA(isA<InvalidCborURException>()));
      expect(() => ScSignRequest.fromUR(_urFromMap(unknownMap)), throwsA(isA<InvalidCborURException>()));
    });

    test('rejects compressed signing payload beyond the decompressed size limit', () {
      final oversized = Uint8List(ScSignRequest.maxSigningPayloadBytes + 1)..fillRange(0, ScSignRequest.maxSigningPayloadBytes + 1, 0x20);
      final map = cbor.decode(
        ScSignRequest.buildUR(
          requestId: '123e4567-e89b-12d3-a456-426614174000',
          xfp: 'A1B2C3D4',
          path: "m/44'/1991'/0'",
          address: 'sender-address',
          publicKey: 'ed25519-public-key',
          signingPayloadData: const <String, dynamic>{'siacoinInputs': <dynamic>[]},
        ).payload,
      ) as CborMap;
      map[CborSmallInt(ScSignRequestKeys.signingPayloadData.index)] = CborBytes(ZLibCodec(level: 6).encode(oversized));
      map[CborSmallInt(ScSignRequestKeys.signingPayloadEncoding.index)] = const CborSmallInt(1);

      expect(
        () => ScSignRequest.fromUR(_urFromMap(map)),
        throwsA(isA<InvalidCborURException>().having((error) => error.message, 'message', contains('exceeds'))),
      );
    });

    test('round trips signature payload', () {
      final ur = ScSignature.buildUR(
        requestId: '123e4567-e89b-12d3-a456-426614174000',
        broadcastTx: {
          'transactions': [
            {
              'siacoinInputs': [
                {
                  'satisfiedPolicy': {
                    'signatures': ['signature-bytes']
                  }
                }
              ],
              'siacoinOutputs': [
                {'value': '123456789012345678901234', 'address': 'receiver-address'}
              ],
            }
          ]
        },
        origin: 'fxwallet',
      );

      expect(ur.type, RegistryType.SC_SIGNATURE.type);

      final signature = ScSignature.fromUR(ur);
      expect(signature.getRequestIdString(), '123e4567-e89b-12d3-a456-426614174000');
      expect(signature.broadcastTx['transactions'][0]['siacoinOutputs'][0]['value'], '123456789012345678901234');
      expect(signature.origin, 'fxwallet');
    });

    test('builds signature from signed tx result', () {
      final request = ScSignRequest(
        uuid: Uint8List.fromList(uuidParse('123e4567-e89b-12d3-a456-426614174000')),
        xfp: 'A1B2C3D4',
        path: "m/44'/1991'/0'",
        address: 'sender-address',
        publicKey: 'ed25519-public-key',
        signingPayloadData: const {'siacoinInputs': []},
        origin: 'fxwallet',
      );

      final ur = ScSignature.fromSignedTx(
        request: request,
        broadcastTx: const {'transactions': []},
      );

      final signature = ScSignature.fromUR(ur);
      expect(signature.getRequestIdString(), request.getRequestIdString());
      expect(signature.broadcastTx['transactions'], isEmpty);
      expect(signature.origin, request.origin);
    });

    test('auto generates request id when omitted', () {
      final ur = ScSignRequest.buildUR(
        xfp: 'A1B2C3D4',
        path: "m/44'/1991'/0'",
        address: 'sender-address',
        publicKey: 'ed25519-public-key',
        signingPayloadData: const {'siacoinInputs': []},
      );

      final request = ScSignRequest.fromUR(ur);
      expect(request.getRequestId(), hasLength(16));
      expect(request.getRequestIdString(), isNotEmpty);
    });
  });
}

UR _urFromMap(CborMap map) {
  return UR(type: RegistryType.SC_SIGN_REQUEST.type, payload: Uint8List.fromList(cbor.encode(map)));
}
