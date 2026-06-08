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
