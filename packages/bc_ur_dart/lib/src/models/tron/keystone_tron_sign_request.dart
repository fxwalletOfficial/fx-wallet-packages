import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bc_ur_dart/src/gen/keystone/base.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/chains/tron_transaction.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/payload.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/transaction.pb.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';
import 'package:cbor/cbor.dart';
import 'package:convert/convert.dart';
import 'package:fixnum/fixnum.dart';

class KeystoneTronTokenInfo {
  final String name;
  final String symbol;
  final int decimals;

  const KeystoneTronTokenInfo({
    required this.name,
    required this.symbol,
    required this.decimals,
  });
}

class KeystoneTronSignRequest {
  final String requestId;
  final String path;
  final String xfp;
  final TronTx tronTx;
  final String? origin;

  const KeystoneTronSignRequest({
    required this.requestId,
    required this.path,
    required this.xfp,
    required this.tronTx,
    this.origin,
  });

  static UR buildUR({
    required String requestId,
    required String signDataHex,
    required String path,
    required String xfp,
    KeystoneTronTokenInfo? tokenInfo,
    String? origin,
  }) {
    final tronTx = _TronRawDataParser.parse(
      signData: fromHex(signDataHex),
      tokenInfo: tokenInfo,
    );

    final signTx = SignTransaction(
      coinCode: 'TRON',
      signId: requestId,
      hdPath: path,
      timestamp: Int64(DateTime.now().millisecondsSinceEpoch),
      decimal: 6,
      tronTx: tronTx,
    );

    final payload = Payload(
      type: Payload_Type.TYPE_SIGN_TX,
      xfp: xfp,
      signTx: signTx,
    );

    final base = Base(
      version: 2,
      description: 'QrCode Protocol',
      deviceType: '',
      payloadData: payload,
    );

    final signData = Uint8List.fromList(GZipCodec().encode(base.writeToBuffer()));

    return UR.fromCBOR(
      type: RegistryType.KEYSTONE_SIGN_REQUEST.type,
      value: CborMap({
        CborSmallInt(1): CborBytes(signData),
        if (origin != null && origin.isNotEmpty) CborSmallInt(2): CborString(origin),
      }),
    );
  }

  static KeystoneTronSignRequest fromUR(UR ur) {
    if (ur.type.toLowerCase() != RegistryType.KEYSTONE_SIGN_REQUEST.type) {
      throw ArgumentError('Invalid UR type for KeystoneTronSignRequest: ${ur.type}');
    }

    final decoded = ur.decodeCBOR();
    if (decoded is! CborMap) {
      throw ArgumentError('Invalid Keystone TRON request payload');
    }

    final signDataValue = decoded[CborSmallInt(1)];
    if (signDataValue is! CborBytes) {
      throw ArgumentError('Invalid Keystone TRON signData payload');
    }

    final base = Base.fromBuffer(
      GZipCodec().decode(Uint8List.fromList(signDataValue.bytes)),
    );
    final payload = base.payloadData;
    final signTx = payload.signTx;
    if (signTx.whichTransaction() != SignTransaction_Transaction.tronTx) {
      throw ArgumentError('Invalid Keystone TRON transaction payload');
    }

    final originValue = decoded[CborSmallInt(2)];
    return KeystoneTronSignRequest(
      requestId: signTx.signId,
      path: signTx.hdPath,
      xfp: payload.xfp,
      tronTx: signTx.tronTx,
      origin: originValue is CborString ? originValue.toString() : null,
    );
  }
}

class _TronRawDataParser {
  static const _transferContractType = 1;
  static const _transferAssetContractType = 2;
  static const _triggerSmartContractType = 31;

  static TronTx parse({
    required Uint8List signData,
    KeystoneTronTokenInfo? tokenInfo,
  }) {
    final raw = _parseTransactionRaw(signData);
    final override = tokenInfo == null
        ? null
        : Override(
            tokenShortName: tokenInfo.symbol,
            tokenFullName: tokenInfo.name,
            decimals: tokenInfo.decimals,
          );

    final latestBlock = LatestBlock(
      hash: hex.encode([
        ...Uint8List(8),
        ...raw.refBlockHash,
        ...Uint8List(16),
      ]),
      number: raw.refBlockBytes.length >= 2 ? int.parse(hex.encode(raw.refBlockBytes.sublist(0, 2)), radix: 16) : 0,
      timestamp: Int64(raw.timestamp),
    );
    final memo = raw.data.isEmpty ? '' : utf8.decode(raw.data);

    switch (raw.contract.type) {
      case _transferContractType:
        final contract = _parseTransferContract(raw.contract.value);
        return TronTx(
          fee: raw.feeLimit,
          from: _TronAddressCodec.toBase58(contract.ownerAddress),
          latestBlock: latestBlock,
          memo: memo,
          to: _TronAddressCodec.toBase58(contract.toAddress),
          token: 'TRX',
          value: contract.amount.toString(),
        );
      case _transferAssetContractType:
        if (override == null) {
          throw ArgumentError('tokenInfo is required for TRC10 transfer');
        }
        final contract = _parseTransferAssetContract(raw.contract.value);
        return TronTx(
          fee: raw.feeLimit,
          from: _TronAddressCodec.toBase58(contract.ownerAddress),
          latestBlock: latestBlock,
          memo: memo,
          override: override,
          to: _TronAddressCodec.toBase58(contract.toAddress),
          token: utf8.decode(contract.assetName),
          value: contract.amount.toString(),
        );
      case _triggerSmartContractType:
        if (override == null) {
          throw ArgumentError('tokenInfo is required for TRC20 transfer');
        }
        final contract = _parseTriggerSmartContract(raw.contract.value);
        if (contract.data.length < 68) {
          throw ArgumentError('TRC20 call data is invalid');
        }
        final toAddress = Uint8List.fromList([
          0x41,
          ...contract.data.sublist(16, 36),
        ]);
        final amount = byteToBigInt(contract.data.sublist(36, 68)).toString();
        return TronTx(
          contractAddress: _TronAddressCodec.toBase58(contract.contractAddress),
          fee: raw.feeLimit,
          from: _TronAddressCodec.toBase58(contract.ownerAddress),
          latestBlock: latestBlock,
          memo: memo,
          override: override,
          to: _TronAddressCodec.toBase58(toAddress),
          value: amount,
        );
      default:
        throw ArgumentError('Unsupported TRON contract type: ${raw.contract.type}');
    }
  }

  static _TransactionRaw _parseTransactionRaw(Uint8List data) {
    final reader = _ProtoReader(data);
    Uint8List refBlockBytes = Uint8List(0);
    Uint8List refBlockHash = Uint8List(0);
    Uint8List txData = Uint8List(0);
    int expiration = 0;
    int timestamp = 0;
    int feeLimit = 0;
    Uint8List? contractBytes;

    while (reader.hasMore()) {
      final tag = reader.readVarint();
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;

      switch (fieldNumber) {
        case 1:
          refBlockBytes = reader.readLengthDelimited();
          break;
        case 4:
          refBlockHash = reader.readLengthDelimited();
          break;
        case 8:
          expiration = reader.readVarint();
          break;
        case 10:
          txData = reader.readLengthDelimited();
          break;
        case 11:
          contractBytes = reader.readLengthDelimited();
          break;
        case 14:
          timestamp = reader.readVarint();
          break;
        case 18:
          feeLimit = reader.readVarint();
          break;
        default:
          reader.skipField(wireType);
      }
    }

    if (contractBytes == null) {
      throw ArgumentError('TRON signData is missing contract');
    }

    return _TransactionRaw(
      refBlockBytes: refBlockBytes,
      refBlockHash: refBlockHash,
      expiration: expiration,
      timestamp: timestamp,
      data: txData,
      feeLimit: feeLimit,
      contract: _parseContract(contractBytes),
    );
  }

  static _ContractEnvelope _parseContract(Uint8List data) {
    final reader = _ProtoReader(data);
    int type = 0;
    Uint8List? parameterBytes;

    while (reader.hasMore()) {
      final tag = reader.readVarint();
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;

      switch (fieldNumber) {
        case 1:
          type = reader.readVarint();
          break;
        case 2:
          parameterBytes = reader.readLengthDelimited();
          break;
        default:
          reader.skipField(wireType);
      }
    }

    if (parameterBytes == null) {
      throw ArgumentError('TRON contract parameter is missing');
    }

    return _ContractEnvelope(
      type: type,
      value: _unwrapAnyValue(parameterBytes),
    );
  }

  static Uint8List _unwrapAnyValue(Uint8List parameterBytes) {
    try {
      final reader = _ProtoReader(parameterBytes);
      while (reader.hasMore()) {
        final tag = reader.readVarint();
        final fieldNumber = tag >> 3;
        final wireType = tag & 0x7;

        switch (fieldNumber) {
          case 1:
            if (wireType != 2) return parameterBytes;
            reader.readLengthDelimited();
            break;
          case 2:
            if (wireType != 2) return parameterBytes;
            return reader.readLengthDelimited();
          default:
            reader.skipField(wireType);
        }
      }
    } catch (_) {
      return parameterBytes;
    }

    return parameterBytes;
  }

  static _TransferContract _parseTransferContract(Uint8List data) {
    final reader = _ProtoReader(data);
    Uint8List ownerAddress = Uint8List(0);
    Uint8List toAddress = Uint8List(0);
    int amount = 0;

    while (reader.hasMore()) {
      final tag = reader.readVarint();
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;

      switch (fieldNumber) {
        case 1:
          ownerAddress = reader.readLengthDelimited();
          break;
        case 2:
          toAddress = reader.readLengthDelimited();
          break;
        case 3:
          amount = reader.readVarint();
          break;
        default:
          reader.skipField(wireType);
      }
    }

    return _TransferContract(
      ownerAddress: ownerAddress,
      toAddress: toAddress,
      amount: amount,
    );
  }

  static _TransferAssetContract _parseTransferAssetContract(Uint8List data) {
    final reader = _ProtoReader(data);
    Uint8List assetName = Uint8List(0);
    Uint8List ownerAddress = Uint8List(0);
    Uint8List toAddress = Uint8List(0);
    int amount = 0;

    while (reader.hasMore()) {
      final tag = reader.readVarint();
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;

      switch (fieldNumber) {
        case 1:
          assetName = reader.readLengthDelimited();
          break;
        case 2:
          ownerAddress = reader.readLengthDelimited();
          break;
        case 3:
          toAddress = reader.readLengthDelimited();
          break;
        case 4:
          amount = reader.readVarint();
          break;
        default:
          reader.skipField(wireType);
      }
    }

    return _TransferAssetContract(
      assetName: assetName,
      ownerAddress: ownerAddress,
      toAddress: toAddress,
      amount: amount,
    );
  }

  static _TriggerSmartContract _parseTriggerSmartContract(Uint8List data) {
    final reader = _ProtoReader(data);
    Uint8List ownerAddress = Uint8List(0);
    Uint8List contractAddress = Uint8List(0);
    Uint8List callData = Uint8List(0);

    while (reader.hasMore()) {
      final tag = reader.readVarint();
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;

      switch (fieldNumber) {
        case 1:
          ownerAddress = reader.readLengthDelimited();
          break;
        case 2:
          contractAddress = reader.readLengthDelimited();
          break;
        case 4:
          callData = reader.readLengthDelimited();
          break;
        default:
          reader.skipField(wireType);
      }
    }

    return _TriggerSmartContract(
      ownerAddress: ownerAddress,
      contractAddress: contractAddress,
      data: callData,
    );
  }
}

class _TransactionRaw {
  final Uint8List refBlockBytes;
  final Uint8List refBlockHash;
  final int expiration;
  final int timestamp;
  final Uint8List data;
  final int feeLimit;
  final _ContractEnvelope contract;

  const _TransactionRaw({
    required this.refBlockBytes,
    required this.refBlockHash,
    required this.expiration,
    required this.timestamp,
    required this.data,
    required this.feeLimit,
    required this.contract,
  });
}

class _ContractEnvelope {
  final int type;
  final Uint8List value;

  const _ContractEnvelope({
    required this.type,
    required this.value,
  });
}

class _TransferContract {
  final Uint8List ownerAddress;
  final Uint8List toAddress;
  final int amount;

  const _TransferContract({
    required this.ownerAddress,
    required this.toAddress,
    required this.amount,
  });
}

class _TransferAssetContract {
  final Uint8List assetName;
  final Uint8List ownerAddress;
  final Uint8List toAddress;
  final int amount;

  const _TransferAssetContract({
    required this.assetName,
    required this.ownerAddress,
    required this.toAddress,
    required this.amount,
  });
}

class _TriggerSmartContract {
  final Uint8List ownerAddress;
  final Uint8List contractAddress;
  final Uint8List data;

  const _TriggerSmartContract({
    required this.ownerAddress,
    required this.contractAddress,
    required this.data,
  });
}

class _ProtoReader {
  final Uint8List _data;
  int _offset = 0;

  _ProtoReader(this._data);

  bool hasMore() => _offset < _data.length;

  int readVarint() {
    var result = 0;
    var shift = 0;
    while (true) {
      final value = _data[_offset++];
      result |= (value & 0x7f) << shift;
      if ((value & 0x80) == 0) return result;
      shift += 7;
    }
  }

  Uint8List readLengthDelimited() {
    final length = readVarint();
    final bytes = _data.sublist(_offset, _offset + length);
    _offset += length;
    return Uint8List.fromList(bytes);
  }

  void skipField(int wireType) {
    switch (wireType) {
      case 0:
        readVarint();
        return;
      case 1:
        _offset += 8;
        return;
      case 2:
        _offset += readVarint();
        return;
      case 5:
        _offset += 4;
        return;
      default:
        throw ArgumentError('Unknown protobuf wireType: $wireType');
    }
  }
}

class _TronAddressCodec {
  static const _alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  static String toBase58(Uint8List addressBytes) {
    final payload = addressBytes.length == 21 && addressBytes.first == 0x41 ? addressBytes : Uint8List.fromList([0x41, ...addressBytes]);
    final checksum = sha256(sha256(payload)).sublist(0, 4);
    return _base58Encode(Uint8List.fromList([...payload, ...checksum]));
  }

  static String _base58Encode(Uint8List data) {
    var leadingZeros = 0;
    for (final value in data) {
      if (value == 0) {
        leadingZeros++;
      } else {
        break;
      }
    }

    var number = BigInt.zero;
    for (final value in data) {
      number = (number << 8) | BigInt.from(value);
    }

    final buffer = StringBuffer();
    final base = BigInt.from(58);
    while (number > BigInt.zero) {
      final mod = number % base;
      number ~/= base;
      buffer.write(_alphabet[mod.toInt()]);
    }

    for (var index = 0; index < leadingZeros; index++) {
      buffer.write('1');
    }

    return buffer.toString().split('').reversed.join();
  }
}
