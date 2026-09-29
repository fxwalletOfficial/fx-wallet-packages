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

  group('EthSignRequestUR calldata classification', () {
    const token = '0xdac17f958d2ee523a2206206994597c13d831ec7';
    const recipient = '742d35cc6634c0532925a3b8d4c9db96c4b4d8b6';
    const zeroPad = '000000000000000000000000';
    const amountWord = '00000000000000000000000000000000000000000000000000000000000f4240'; // 1_000_000

    String call(String selector, {String pad = zeroPad, String address = recipient, String word = amountWord}) => '0x$selector$pad$address$word';

    EthSignRequestUR roundTrip(EthTxData tx) {
      final request = EthSignRequestUR.fromTypedTransaction(tx: tx, address: '0x$recipient', path: "m/44'/60'/0'/0/0", origin: '', xfp: '12345678');
      return EthSignRequestUR.fromUR(ur: UR.decode(request.encode()));
    }

    EthSignRequestUR eip1559({String to = token, String data = '', BigInt? value}) => roundTrip(Eip1559TxData(
          data: EthTxDataRaw(nonce: 1, gasLimit: 60000, maxFeePerGas: 2, maxPriorityFeePerGas: 1, to: to, value: value ?? BigInt.zero, data: data),
          network: TxNetwork(chainId: 1),
        ));

    test('native transfer keeps tx recipient and value', () {
      final parsed = eip1559(to: '0x$recipient', value: BigInt.from(1000));

      expect(parsed.callKind, EthCallKind.nativeTransfer);
      expect(parsed.selector, '');
      expect(parsed.to, '0x$recipient');
      expect(parsed.token, '');
      expect(parsed.value, BigInt.from(1000));
    });

    test('ERC-20 transfer decodes recipient, token and amount', () {
      final parsed = eip1559(data: call(ERC20_TRANSFER_SELECTOR));

      expect(parsed.callKind, EthCallKind.erc20Transfer);
      expect(parsed.selector, ERC20_TRANSFER_SELECTOR);
      expect(parsed.to, '0x$recipient');
      expect(parsed.token, token);
      expect(parsed.value, BigInt.from(1000000));
    });

    test('legacy ERC-20 transfer decodes the same way', () {
      final parsed = roundTrip(LegacyTxData(
        data: EthTxDataRaw(nonce: 1, gasLimit: 60000, gasPrice: 1, to: token, value: BigInt.zero, data: call(ERC20_TRANSFER_SELECTOR)),
        network: TxNetwork(chainId: 1),
      ));

      expect(parsed.callKind, EthCallKind.erc20Transfer);
      expect(parsed.to, '0x$recipient');
      expect(parsed.token, token);
      expect(parsed.value, BigInt.from(1000000));
    });

    // approve / increaseAllowance / decreaseAllowance 与 transfer 同为 68 字节。
    for (final selector in ['095ea7b3', '39509351', 'a457c2d7', 'deadbeef']) {
      test('68-byte call with selector $selector is a contract call, not a transfer', () {
        final parsed = eip1559(data: call(selector), value: BigInt.from(7));

        expect(parsed.callKind, EthCallKind.contractCall);
        expect(parsed.selector, selector);
        expect(parsed.to, token);
        expect(parsed.token, '');
        expect(parsed.value, BigInt.from(7));
      });
    }

    test('transfer selector with dirty address padding is a contract call', () {
      final parsed = eip1559(data: call(ERC20_TRANSFER_SELECTOR, pad: '000000000000000000000001'));

      expect(parsed.callKind, EthCallKind.contractCall);
      expect(parsed.to, token);
      expect(parsed.token, '');
      expect(parsed.value, BigInt.zero);
    });

    test('transfer selector with extra trailing bytes is a contract call', () {
      final parsed = eip1559(data: '${call(ERC20_TRANSFER_SELECTOR)}00');

      expect(parsed.callKind, EthCallKind.contractCall);
      expect(parsed.to, token);
      expect(parsed.token, '');
    });

    test('non-68-byte call is a contract call', () {
      final parsed = eip1559(data: '0x12345678');

      expect(parsed.callKind, EthCallKind.contractCall);
      expect(parsed.selector, '12345678');
      expect(parsed.to, token);
      expect(parsed.token, '');
    });

    test('message requests have no call kind', () {
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

      expect(parsed.callKind, isNull);
      expect(parsed.selector, '');
    });
  });
}
