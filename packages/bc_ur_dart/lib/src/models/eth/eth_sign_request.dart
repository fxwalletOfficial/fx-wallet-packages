import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/cbor_field_reader.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:convert/convert.dart';
import 'package:crypto_wallet_util/utils.dart' hide fromHex;

const String ETH_SIGN_REQUEST = 'ETH-SIGN-REQUEST';

class EthSignRequestUR extends UR {
  final Uint8List uuid;
  final int chainId;
  final EthSignDataType dataType;
  final Uint8List data;

  final Uint8List address;
  final String origin;
  final String xfp;

  EthTxType get txType => _tx.txType;

  EthTxData _tx = Eip1559TxData(data: EthTxDataRaw(nonce: 0, gasLimit: 0, value: BigInt.zero), network: TxNetwork(chainId: 1));
  EthTxData get tx => _tx;

  EthSignRequestUR({required UR ur, required this.uuid, required this.chainId, required this.dataType, required this.data, required this.address, required this.xfp, this.origin = ''})
      : super(payload: ur.payload, type: ur.type);

  factory EthSignRequestUR.fromTypedTransaction(
      {required EthTxData tx, required String address, required String path, required String origin, required String xfp, bool xfpReverse = false, Uint8List? uuid}) {
    uuid ??= UR.generateUUid();
    final dataType = tx.txType == EthTxType.legacy ? EthSignDataType.ETH_TRANSACTION_DATA : EthSignDataType.ETH_TYPED_TRANSACTION;
    final addr = address.isEmpty ? Uint8List(0) : dynamicToUint8List(address);
    final msg = tx.serialize(sig: false);

    final ur = UR.fromCBOR(
        type: ETH_SIGN_REQUEST,
        value: CborMap({
          CborSmallInt(1): CborBytes(uuid, tags: [37]),
          CborSmallInt(2): CborBytes(msg),
          CborSmallInt(3): CborSmallInt(dataType.index),
          CborSmallInt(4): CborSmallInt(tx.network.chainId),
          CborSmallInt(5): CborMap({CborSmallInt(1): CborList(getPath(path)), if (xfp.isNotEmpty) CborSmallInt(2): CborInt(toXfpCode(xfp, reverseBytes: xfpReverse))}, tags: [304]),
          if (addr.isNotEmpty) CborSmallInt(6): CborBytes(addr),
          CborSmallInt(7): CborString(origin)
        }));

    final item = EthSignRequestUR(ur: ur, uuid: uuid, chainId: tx.network.chainId, dataType: dataType, data: msg, address: addr, origin: origin, xfp: xfp);

    item.setTx(tx);

    return item;
  }

  factory EthSignRequestUR.fromMessage(
      {required EthSignDataType dataType,
      required String address,
      required String path,
      required String origin,
      required String xfp,
      required String signData,
      required int chainId,
      bool xfpReverse = false,
      Uint8List? uuid}) {
    uuid ??= UR.generateUUid();
    final addr = address.isEmpty ? Uint8List(0) : dynamicToUint8List(address);
    final msg = fromHex(signData);

    final ur = UR.fromCBOR(
        type: ETH_SIGN_REQUEST,
        value: CborMap({
          CborSmallInt(1): CborBytes(uuid, tags: [37]),
          CborSmallInt(2): CborBytes(msg),
          CborSmallInt(3): CborSmallInt(dataType.index),
          CborSmallInt(4): CborSmallInt(chainId),
          CborSmallInt(5): CborMap({CborSmallInt(1): CborList(getPath(path)), if (xfp.isNotEmpty) CborSmallInt(2): CborInt(toXfpCode(xfp, reverseBytes: xfpReverse))}, tags: [304]),
          if (addr.isNotEmpty) CborSmallInt(6): CborBytes(addr),
          CborSmallInt(7): CborString(origin)
        }));

    return EthSignRequestUR(ur: ur, uuid: uuid, chainId: chainId, dataType: dataType, data: msg, address: addr, origin: origin, xfp: xfp);
  }

  factory EthSignRequestUR.fromUR({required UR ur, bool bigEndian = true}) {
    final reader = CborFieldReader.fromUr(ur, model: 'eth-sign-request', expectedType: ETH_SIGN_REQUEST);

    final uuid = reader.requiredBytes(1, field: 'uuid', length: 16);
    final msg = reader.requiredBytes(2, field: 'data');
    final dataType = EthSignDataType.values[reader.requiredEnumIndex(3, field: 'data_type', valuesLength: EthSignDataType.values.length)];
    final chainId = reader.requiredInt(4, field: 'chain_id', min: 0);
    final address = reader.optionalBytes(6, field: 'address') ?? Uint8List(0);
    final origin = reader.optionalText(7, field: 'origin') ?? '';

    // xfp 仍保留 bigEndian 兼容参数：canonical=big-endian，legacy=little-endian。
    // 走 CryptoKeypath.sourceFingerprint（而非旧的 getXfp 手解析），并由 value-preservation
    // golden 锁住 canonical(12345678)/legacy(78563412) 不变。malformed keypath 现在抛错而非吞掉。
    final keypath = RegistryItem.readKeypath(reader.map, 5, sourceFingerprintEndian: bigEndian ? Endian.big : Endian.little, model: 'eth-sign-request', field: 'derivation_path');
    final xfp = keypath.sourceFingerprint != null ? hex.encode(keypath.sourceFingerprint!) : '';

    final item = EthSignRequestUR(ur: ur, uuid: uuid, chainId: chainId, dataType: dataType, data: msg, address: address, origin: origin, xfp: xfp);

    try {
      switch (dataType) {
        case EthSignDataType.ETH_TRANSACTION_DATA:
        case EthSignDataType.ETH_TYPED_TRANSACTION:
          item.decodeTransaction();
          break;
        default:
          break;
      }
    } on Object catch (error) {
      throw InvalidCborURException(model: 'eth-sign-request', field: 'data', reason: 'invalid ETH transaction payload', cause: error);
    }

    return item;
  }

  void setTx(EthTxData item) => _tx = item;

  void decodeTransaction() {
    if (data.first == 2) {
      _tx = Eip1559TxData.deserialize(hex.encode(data));
    } else if (data.first == 4) {
      _tx = Eip7702TxData.deserialize(hex.encode(data));
    } else {
      _tx = LegacyTxData.deserialize(hex.encode(data), chainId: chainId);
    }

    _value = tx.data.value;
    _to = _tx.data.to;
    final input = stringToBytes(tx.data.data);
    if (input.length != 68) return;

    // Handle ERC-20 Simple token transfer information.
    _to = '0x${hex.encode(input.sublist(16, 36))}';
    _token = tx.data.to;
    _value = BigInt.parse(hex.encode(input.sublist(36)), radix: 16);
  }

  BigInt _value = BigInt.zero;
  BigInt get value => _value;

  String _to = '';
  String get to => _to;

  String _token = '';
  String get token => _token;
}

enum EthSignDataType { NONE, ETH_TRANSACTION_DATA, ETH_TYPED_DATA, ETH_RAW_BYTES, ETH_TYPED_TRANSACTION }
