import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/gen/keystone/base.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/payload.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/payload.pbenum.dart';
import 'package:bc_ur_dart/src/gen/keystone/sign_transaction_result.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/transaction.pb.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

void main() {
  const testPath = "m/44'/195'/0'";
  const testXfp = '21d0ae26';
  const testRequestId = 'trx-request-id';
  const testOrigin = 'FxWallet';
  const ownerHex = '41a9569efd62152d36adbd577a9bc6deab09d0d462';
  const toHex = '412a4d2fe3ce100a12b1626aa5aab8393d2e60a13c';
  const contractHex = '4199c3d3d7f2b9a4f6a07e2d5d3df2b9a4f6a07e2d';
  const rawTrxTransferHex =
      '0a0232202208dd448d6e1f3946c540c8d2f9f082315a67080112630a2d747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e5472616e73666572436f6e747261637412320a1541a9569efd62152d36adbd577a9bc6deab09d0d4621215412a4d2fe3ce100a12b1626aa5aab8393d2e60a13c18c0843d70fe96f6f08231';
  const signedRawTx = '0xdeadbeefcafe';
  const signedTxId = '0x1234abcd';

  group('KeystoneTronSignRequest', () {
    test('builds Keystone TRX request for native TRX transfer', () {
      final ur = KeystoneTronSignRequest.buildUR(
        requestId: testRequestId,
        signDataHex: rawTrxTransferHex,
        path: testPath,
        xfp: testXfp,
        origin: testOrigin,
      );

      expect(ur.type, equals(RegistryType.KEYSTONE_SIGN_REQUEST.type));

      final decoded = KeystoneTronSignRequest.fromUR(ur);
      expect(decoded.requestId, equals(testRequestId));
      expect(decoded.path, equals(testPath));
      expect(decoded.xfp, equals(testXfp));
      expect(decoded.origin, equals(testOrigin));

      final SignTransaction signTx = _decodeKeystoneSignTx(ur);
      expect(signTx.coinCode, equals('TRON'));
      expect(signTx.signId, equals(testRequestId));
      expect(signTx.hdPath, equals(testPath));
      expect(signTx.decimal, equals(6));
      expect(signTx.whichTransaction(), equals(SignTransaction_Transaction.tronTx));

      final tronTx = signTx.tronTx;
      expect(tronTx.token, equals('TRX'));
      expect(tronTx.contractAddress, isEmpty);
      expect(tronTx.from, equals(_tronBase58(ownerHex)));
      expect(tronTx.to, equals(_tronBase58(toHex)));
      expect(tronTx.value, equals('1000000'));
      expect(tronTx.fee, equals(0));
      expect(tronTx.latestBlock.hash, equals('0000000000000000dd448d6e1f3946c500000000000000000000000000000000'));
      expect(tronTx.latestBlock.number, equals(0x3220));
      expect(tronTx.latestBlock.timestamp.toInt(), equals(1684397925000));
      expect(tronTx.hasOverride(), isFalse);
    });

    test('builds Keystone TRX request for TRC10 transfer with override token info', () {
      final rawDataHex = _buildTransferAssetRawDataHex(
        ownerHex: ownerHex,
        toHex: toHex,
        assetName: '1001090',
        amount: 42,
        expiration: 1684400925000,
        timestamp: 1684400868222,
      );

      final ur = KeystoneTronSignRequest.buildUR(
        requestId: testRequestId,
        signDataHex: rawDataHex,
        path: testPath,
        xfp: testXfp,
        tokenInfo: const KeystoneTronTokenInfo(
          name: 'TRONONE',
          symbol: 'TONE',
          decimals: 2,
        ),
      );

      final tronTx = _decodeKeystoneSignTx(ur).tronTx;
      expect(tronTx.token, equals('1001090'));
      expect(tronTx.from, equals(_tronBase58(ownerHex)));
      expect(tronTx.to, equals(_tronBase58(toHex)));
      expect(tronTx.value, equals('42'));
      expect(tronTx.override.tokenFullName, equals('TRONONE'));
      expect(tronTx.override.tokenShortName, equals('TONE'));
      expect(tronTx.override.decimals, equals(2));
    });

    test('builds Keystone TRX request for TRC20 transfer with contract address', () {
      final rawDataHex = _buildTriggerSmartContractRawDataHex(
        ownerHex: ownerHex,
        contractHex: contractHex,
        toHex: toHex,
        amount: BigInt.from(1234567),
        expiration: 1684400925000,
        timestamp: 1684400868222,
        feeLimit: 150000000,
      );

      final ur = KeystoneTronSignRequest.buildUR(
        requestId: testRequestId,
        signDataHex: rawDataHex,
        path: testPath,
        xfp: testXfp,
        tokenInfo: const KeystoneTronTokenInfo(
          name: 'Tether USD',
          symbol: 'USDT',
          decimals: 6,
        ),
      );

      final tronTx = _decodeKeystoneSignTx(ur).tronTx;
      expect(tronTx.token, isEmpty);
      expect(tronTx.contractAddress, equals(_tronBase58(contractHex)));
      expect(tronTx.from, equals(_tronBase58(ownerHex)));
      expect(tronTx.to, equals(_tronBase58(toHex)));
      expect(tronTx.value, equals('1234567'));
      expect(tronTx.fee, equals(150000000));
      expect(tronTx.override.tokenFullName, equals('Tether USD'));
      expect(tronTx.override.tokenShortName, equals('USDT'));
      expect(tronTx.override.decimals, equals(6));
    });
  });

  group('KeystoneTronSignResult', () {
    test('parses official keystone-sign-result with rawTx and txId', () {
      final resultPayload = SignTransactionResult(
        signId: testRequestId,
        txId: signedTxId,
        rawTx: signedRawTx,
      );
      final ur = _buildKeystoneResultUr(resultPayload);

      final decoded = KeystoneTronSignResult.fromUR(ur);

      expect(decoded.requestId, equals(testRequestId));
      expect(decoded.txId, equals(signedTxId));
      expect(decoded.rawTx, equals(signedRawTx));
    });
  });
}

SignTransaction _decodeKeystoneSignTx(UR ur) {
  final cborMap = cbor.decode(ur.payload) as CborMap;
  final signData = (cborMap[CborSmallInt(1)] as CborBytes).bytes;
  final decompressed = GZipCodec().decode(signData);
  final base = Base.fromBuffer(decompressed);
  return base.payloadData.signTx;
}

UR _buildKeystoneResultUr(SignTransactionResult result) {
  final payload = Payload()
    ..type = Payload_Type.TYPE_SIGN_TX_RESULT
    ..signTxResult = result;

  final base = Base()
    ..version = 2
    ..description = 'QrCode Protocol'
    ..payloadData = payload;

  final compressed = Uint8List.fromList(GZipCodec().encode(base.writeToBuffer()));
  return UR.fromCBOR(
    type: RegistryType.KEYSTONE_SIGNATURE.type,
    value: CborMap({
      CborSmallInt(1): CborBytes(compressed),
    }),
  );
}

String _buildTransferAssetRawDataHex({
  required String ownerHex,
  required String toHex,
  required String assetName,
  required int amount,
  required int expiration,
  required int timestamp,
}) {
  final contractValue = _message([
    _bytesField(1, utf8.encode(assetName)),
    _bytesField(2, fromHex(ownerHex)),
    _bytesField(3, fromHex(toHex)),
    _varintField(4, amount),
  ]);

  return _buildTransactionRawHex(
    contractType: 2,
    typeUrl: 'type.googleapis.com/protocol.TransferAssetContract',
    contractValue: contractValue,
    expiration: expiration,
    timestamp: timestamp,
  );
}

String _buildTriggerSmartContractRawDataHex({
  required String ownerHex,
  required String contractHex,
  required String toHex,
  required BigInt amount,
  required int expiration,
  required int timestamp,
  required int feeLimit,
}) {
  final selector = fromHex('a9059cbb');
  final paddedTo = Uint8List.fromList([
    ...Uint8List(12),
    ...fromHex(toHex.substring(2)),
  ]);
  final amountBytes = _bigIntToFixedBytes(amount, 32);
  final callData = Uint8List.fromList([
    ...selector,
    ...paddedTo,
    ...amountBytes,
  ]);

  final contractValue = _message([
    _bytesField(1, fromHex(ownerHex)),
    _bytesField(2, fromHex(contractHex)),
    _varintField(3, 0),
    _bytesField(4, callData),
  ]);

  return _buildTransactionRawHex(
    contractType: 31,
    typeUrl: 'type.googleapis.com/protocol.TriggerSmartContract',
    contractValue: contractValue,
    expiration: expiration,
    timestamp: timestamp,
    feeLimit: feeLimit,
  );
}

String _buildTransactionRawHex({
  required int contractType,
  required String typeUrl,
  required Uint8List contractValue,
  required int expiration,
  required int timestamp,
  int feeLimit = 0,
}) {
  final any = _message([
    _bytesField(1, utf8.encode(typeUrl)),
    _bytesField(2, contractValue),
  ]);
  final contract = _message([
    _varintField(1, contractType),
    _bytesField(2, any),
  ]);
  final raw = _message([
    _bytesField(1, fromHex('3220')),
    _bytesField(4, fromHex('dd448d6e1f3946c5')),
    _varintField(8, expiration),
    _bytesField(11, contract),
    _varintField(18, timestamp),
    _varintField(20, feeLimit),
  ]);
  return hex.encode(raw);
}

Uint8List _message(List<Uint8List> fields) {
  return Uint8List.fromList(fields.expand((field) => field).toList());
}

Uint8List _varintField(int fieldNumber, int value) {
  return Uint8List.fromList([
    ..._encodeVarint((fieldNumber << 3) | 0),
    ..._encodeVarint(value),
  ]);
}

Uint8List _bytesField(int fieldNumber, List<int> value) {
  return Uint8List.fromList([
    ..._encodeVarint((fieldNumber << 3) | 2),
    ..._encodeVarint(value.length),
    ...value,
  ]);
}

List<int> _encodeVarint(int value) {
  final result = <int>[];
  var current = value;
  while (true) {
    if ((current & ~0x7f) == 0) {
      result.add(current);
      return result;
    }
    result.add((current & 0x7f) | 0x80);
    current >>= 7;
  }
}

Uint8List _bigIntToFixedBytes(BigInt value, int length) {
  final result = Uint8List(length);
  var current = value;
  for (var i = length - 1; i >= 0; i--) {
    result[i] = (current & BigInt.from(0xff)).toInt();
    current >>= 8;
  }
  return result;
}

String _tronBase58(String hexAddress) {
  final payload = fromHex(hexAddress);
  final digest = crypto.sha256.convert(crypto.sha256.convert(payload).bytes).bytes;
  final full = Uint8List.fromList([...payload, ...digest.take(4)]);
  return _base58Encode(full);
}

String _base58Encode(Uint8List bytes) {
  const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  var leadingZeroes = 0;
  for (final byte in bytes) {
    if (byte == 0) {
      leadingZeroes++;
      continue;
    }
    break;
  }

  var value = BigInt.zero;
  for (final byte in bytes) {
    value = (value << 8) | BigInt.from(byte);
  }

  final buffer = StringBuffer();
  final base = BigInt.from(58);
  while (value > BigInt.zero) {
    final mod = value % base;
    value ~/= base;
    buffer.write(alphabet[mod.toInt()]);
  }
  for (var i = 0; i < leadingZeroes; i++) {
    buffer.write('1');
  }
  return buffer.toString().split('').reversed.join();
}
