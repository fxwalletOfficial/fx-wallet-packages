import 'dart:typed_data';

import 'package:bc_ur_dart/src/utils/utils.dart' show getPath, fromHex, cborPathToString;
import 'package:cbor/cbor.dart';
import 'package:crypto_wallet_util/transaction.dart' show GsplTxData, GsplItem, BtcSignDataType;
import 'package:web3dart/crypto.dart' show bytesToHex;

extension GsplTxDataWithCbor on GsplTxData {
  CborMap toCbor() {
    final cborData = CborMap({
      CborSmallInt(1): CborBytes(fromHex(hex)),
      CborSmallInt(2): CborSmallInt(dataType.index),
      CborSmallInt(3): CborList(inputs.map((e) => e.toCbor()).toList())
    }, tags: [6111]);
    if (change != null) cborData[CborSmallInt(4)] = change!.toCbor(change: true);

    return cborData;
  }
}

extension GsplItemWithCbor on GsplItem {
  CborValue toCbor({bool change = false}) {
    final cborData = CborMap({}, tags: [6110]);
    if (path != null) cborData[CborSmallInt(1)] = CborList(getPath(path!));
    if (amount != null) cborData[CborSmallInt(2)] = CborInt(BigInt.from(amount!));
    if (signature != null) cborData[CborSmallInt(3)] = CborBytes(signature!);
    if (address != null) cborData[CborSmallInt(4)] = CborString(address!);

    return cborData;
  }
}

GsplTxData getGsplTxDataFromCbor({required CborMap data}) {
  final hex = Uint8List.fromList((data[CborSmallInt(1)] as CborBytes).bytes);
  List<GsplItem>? inputs = (data[CborSmallInt(3)] as CborList).map((e) => getGsplItemFromCbor(data: e as CborMap)).toList();
  GsplItem? change = data[CborSmallInt(4)] == null ? null : getGsplItemFromCbor(data: data[CborSmallInt(4)] as CborMap);

  return GsplTxData(inputs: inputs, hex: bytesToHex(hex), dataType: BtcSignDataType.TRANSACTION, change: change);
}

GsplItem getGsplItemFromCbor({required CborMap data}) {
  final pathList = data[CborSmallInt(1)] != null ? (data[CborSmallInt(1)] as CborList) : null;
  final path = cborPathToString(pathList);
  final amount = (data[CborSmallInt(2)] as CborInt).toInt();
  final signature = data[CborSmallInt(3)] != null ? Uint8List.fromList((data[CborSmallInt(3)] as CborBytes).bytes) : null;
  final address = data[CborSmallInt(4)] != null ? (data[CborSmallInt(4)] as CborString).toString() : null;
  int? signHashType;
  try {
    signHashType = data[CborSmallInt(5)] != null ? int.parse((data[CborSmallInt(5)] as CborString).toString()) : null;
  } catch (_) {
    signHashType = null;
  }

  return GsplItem(
    path: path,
    address: address,
    amount: amount,
    signHashType: signHashType,
    signature: signature
  );
}
