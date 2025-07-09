import 'package:bc_ur_dart/src/models/eth/eth_sign_request.dart';
import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  group('EthSignRequestUR', () {
    test('should create from message correctly', () {
      final request = EthSignRequestUR.fromMessage(
        dataType: EthSignDataType.ETH_TRANSACTION_DATA,
        address: '0x742d35cc6634c0532925a3b8d4c9db96c4b4d8b6',
        path: "m/44'/60'/0'/0/0",
        origin: 'https://example.com',
        xfp: '12345678',
        signData: '0x1234567890abcdef',
        chainId: 1,
      );

      expect(request, isNotNull);
      expect(request.address.hex, '0x742d35cc6634c0532925a3b8d4c9db96c4b4d8b6');
      expect(request.origin, 'https://example.com');
      expect(request.chainId, 1);
    });

    test('should create from typed transaction correctly', () {
      final tx = Eip1559TxData(
        data: EthTxDataRaw(
          nonce: 0,
          gasLimit: 21000,
          value: BigInt.from(1000000000000000), // 0.001 ETH
        ),
        network: TxNetwork(chainId: 1),
      );

      final request = EthSignRequestUR.fromTypedTransaction(
        tx: tx,
        address: '0x742d35cc6634c0532925a3b8d4c9db96c4b4d8b6',
        path: "m/44'/60'/0'/0/0",
        origin: 'https://example.com',
        xfp: '12345678',
      );

      expect(request, isNotNull);
      expect(request.txType, EthTxType.eip1559);
      expect(request.chainId, 1);
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

      final urString = request.encode();

      expect(urString, startsWith('UR:ETH-SIGN-REQUEST/'));
      expect(urString, isNotEmpty);
    });

    test('should decode transaction data correctly', () {
      final request = EthSignRequestUR.fromMessage(
        dataType: EthSignDataType.ETH_TRANSACTION_DATA,
        address: '0x742d35cc6634c0532925a3b8d4c9db96c4b4d8b6',
        path: "m/44'/60'/0'/0/0",
        origin: 'https://example.com',
        xfp: '12345678',
        signData: '0x1234567890abcdef',
        chainId: 1,
      );

      expect(request.value, isNotNull);
      expect(request.to, isNotNull);
    });
  });
}