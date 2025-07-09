import 'package:bc_ur_dart/src/models/eth/eth_signature.dart';
import 'package:bc_ur_dart/src/models/eth/eth_sign_request.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:test/test.dart';

void main() {
  group('EthSignatureUR', () {
    test('should create from message signed correctly', () {
      final request = EthSignRequestUR.fromMessage(
        dataType: EthSignDataType.ETH_TRANSACTION_DATA,
        address: '0x742d35cc6634c0532925a3b8d4c9db96c4b4d8b6',
        path: "m/44'/60'/0'/0/0",
        origin: 'https://example.com',
        xfp: '12345678',
        signData: '0x1234567890abcdef',
        chainId: 1,
      );

      final signature = EthSignatureUR.fromMessageSigned(
        request: request,
        signature: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1b',
      );

      expect(signature, isNotNull);
      expect(signature.uuid, equals(request.uuid));
    });

    test('should create from signature components correctly', () {
      final request = EthSignRequestUR.fromMessage(
        dataType: EthSignDataType.ETH_TRANSACTION_DATA,
        address: '0x742d35cc6634c0532925a3b8d4c9db96c4b4d8b6',
        path: "m/44'/60'/0'/0/0",
        origin: 'https://example.com',
        xfp: '12345678',
        signData: '0x1234567890abcdef',
        chainId: 1,
      );

      final signature = EthSignatureUR.fromSignature(
        request: request,
        r: BigInt.parse('1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef', radix: 16),
        s: BigInt.parse('abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890', radix: 16),
        v: 27,
      );

      expect(signature, isNotNull);
      expect(signature.v, 0); // handleV converts 27 to 0
    });

    test('should encode to UR correctly', () {
      final request = EthSignRequestUR.fromMessage(
        dataType: EthSignDataType.ETH_TRANSACTION_DATA,
        address: '0x742d35cc6634c0532925a3b8d4c9db96c4b4d8b6',
        path: "m/44'/60'/0'/0/0",
        origin: 'https://example.com',
        xfp: '12345678',
        signData: '0x1234567890abcdef',
        chainId: 1,
      );

      final signature = EthSignatureUR.fromMessageSigned(
        request: request,
        signature: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1b',
      );

      final urString = signature.encode();

      expect(urString, startsWith('UR:ETH-SIGNATURE/'));
      expect(urString, isNotEmpty);
    });

    test('should handle v value conversion correctly', () {
      expect(EthSignatureUR.handleV(27), 0);
      expect(EthSignatureUR.handleV(28), 1);
      expect(EthSignatureUR.handleV(0), 0);
      expect(EthSignatureUR.handleV(1), 1);
    });
  });
}