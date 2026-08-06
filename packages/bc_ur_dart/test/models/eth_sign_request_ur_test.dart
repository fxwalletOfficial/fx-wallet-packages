import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:crypto_wallet_util/utils.dart';
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
      expect(request.address.toHex(), '0x742d35cc6634c0532925a3b8d4c9db96c4b4d8b6');
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

    test('rejects missing required uuid with explicit CBOR error', () {
      final ur = UR.fromCBOR(
        type: ETH_SIGN_REQUEST,
        value: CborMap({
          CborSmallInt(2): CborBytes(Uint8List.fromList([1])),
          CborSmallInt(3): CborSmallInt(EthSignDataType.ETH_RAW_BYTES.index),
          CborSmallInt(4): CborSmallInt(1),
          CborSmallInt(5): CborMap({CborSmallInt(1): CborList(getPath("m/44'/60'/0'/0/0"))}, tags: [304]),
        }),
      );

      expect(
        () => EthSignRequestUR.fromUR(ur: ur),
        throwsA(
          isA<InvalidCborURException>().having((e) => e.message, 'message', contains('eth-sign-request.uuid')).having((e) => e.message, 'message', contains('missing required field 1')),
        ),
      );
    });

    test('rejects out-of-range data type with explicit CBOR error', () {
      final ur = EthSignRequestUR.fromMessage(
        dataType: EthSignDataType.ETH_RAW_BYTES,
        address: '',
        path: "m/44'/60'/0'/0/0",
        origin: '',
        xfp: '12345678',
        signData: '0x1234',
        chainId: 1,
      );
      final map = ur.decodeCBOR() as CborMap;
      map[CborSmallInt(3)] = CborSmallInt(99);
      final malformed = UR.fromCBOR(type: ETH_SIGN_REQUEST, value: map);

      expect(
        () => EthSignRequestUR.fromUR(ur: malformed),
        throwsA(
          isA<InvalidCborURException>().having((e) => e.message, 'message', contains('eth-sign-request.data_type')).having((e) => e.message, 'message', contains('out of range')),
        ),
      );
    });

    test('preserves canonical xfp value with default big-endian parsing', () {
      final request = EthSignRequestUR.fromMessage(
        dataType: EthSignDataType.ETH_RAW_BYTES,
        address: '',
        path: "m/44'/60'/0'/0/0",
        origin: '',
        xfp: '12345678',
        signData: '0x1234',
        chainId: 1,
      );

      final parsed = EthSignRequestUR.fromUR(ur: UR.decode(request.encode()));

      expect(parsed.xfp, '12345678');
    });

    test('preserves legacy reversed xfp value when bigEndian is false', () {
      final request = EthSignRequestUR.fromMessage(
        dataType: EthSignDataType.ETH_RAW_BYTES,
        address: '',
        path: "m/44'/60'/0'/0/0",
        origin: '',
        xfp: '12345678',
        signData: '0x1234',
        chainId: 1,
      );

      final parsed = EthSignRequestUR.fromUR(
        ur: UR.decode(request.encode()),
        bigEndian: false,
      );

      expect(parsed.xfp, '78563412');
    });

    test('rejects malformed derivation path instead of swallowing xfp parse errors', () {
      final ur = EthSignRequestUR.fromMessage(
        dataType: EthSignDataType.ETH_RAW_BYTES,
        address: '',
        path: "m/44'/60'/0'/0/0",
        origin: '',
        xfp: '12345678',
        signData: '0x1234',
        chainId: 1,
      );
      final map = ur.decodeCBOR() as CborMap;
      map[CborSmallInt(5)] = CborString('bad-keypath');
      final malformed = UR.fromCBOR(type: ETH_SIGN_REQUEST, value: map);

      expect(
        () => EthSignRequestUR.fromUR(ur: malformed),
        throwsA(isA<InvalidCborURException>()),
      );
    });
  });
}
