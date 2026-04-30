import 'dart:convert';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Keystone XRP bytes helpers', () {
    test('parses account-export ur:bytes payload', () {
      final bytes = utf8.encode('{"address":"rAccount","pubkey":"02ABCD"}');
      final ur = UR.fromCBOR(type: RegistryType.BYTES.type, value: CborBytes(bytes));

      final account = KeystoneXrpAccountBytes.fromUR(ur);

      expect(account.address, 'rAccount');
      expect(account.publicKey, '02ABCD');
    });

    test('builds sign-request ur:bytes payload', () {
      final ur = KeystoneXrpSignRequestBytes.buildUR(transaction: {
        'Account': 'rSource',
        'TransactionType': 'Payment',
        'Destination': 'rDest',
        'Amount': '1000',
      });

      expect(ur.type, RegistryType.BYTES.type);

      final request = KeystoneXrpSignRequestBytes.fromUR(ur);
      expect(request.transaction['Account'], 'rSource');
      expect(request.transaction['TransactionType'], 'Payment');
    });

    test('parses signature-result ur:bytes payload', () {
      final bytes = utf8.encode('{"signature":"ABC123","publicKey":"02ABCD"}');
      final ur = UR.fromCBOR(type: RegistryType.BYTES.type, value: CborBytes(bytes));

      final signature = KeystoneXrpSignatureBytes.fromUR(ur);

      expect(signature.signature, 'ABC123');
      expect(signature.publicKey, '02ABCD');
      expect(signature.hasSignatureMaterial, isTrue);
    });

    test('parses nested signature-result ur:bytes payload', () {
      final bytes = utf8.encode('{"result":{"TxnSignature":"ABC123","SigningPubKey":"02ABCD"}}');
      final ur = UR.fromCBOR(type: RegistryType.BYTES.type, value: CborBytes(bytes));

      final signature = KeystoneXrpSignatureBytes.fromUR(ur);

      expect(signature.signature, 'ABC123');
      expect(signature.publicKey, '02ABCD');
      expect(signature.hasSignatureMaterial, isTrue);
    });

    test('treats plain hex blob text as signed blob', () {
      final bytes = utf8.encode('120000228000000024000000012E0000000C6140000000000003E868400000000000000C732102ABCDEF7446304402201234567890ABCDEF02201234567890ABCDEFE1F1');
      final ur = UR.fromCBOR(type: RegistryType.BYTES.type, value: CborBytes(bytes));

      final signature = KeystoneXrpSignatureBytes.fromUR(ur);

      expect(signature.signedBlob, isNotEmpty);
      expect(signature.signature, isEmpty);
      expect(signature.hasSignatureMaterial, isTrue);
    });

    test('rejects malformed account bytes payload', () {
      final bytes = utf8.encode('{"hello":"world"}');
      final ur = UR.fromCBOR(type: RegistryType.BYTES.type, value: CborBytes(bytes));

      expect(() => KeystoneXrpAccountBytes.fromUR(ur), throwsArgumentError);
    });

    test('does not treat non account bytes as account export', () {
      final bytes = utf8.encode('{"signature":"ABC123"}');
      final ur = UR.fromCBOR(type: RegistryType.BYTES.type, value: CborBytes(bytes));

      expect(() => KeystoneXrpAccountBytes.fromUR(ur), throwsArgumentError);
    });
  });
}
