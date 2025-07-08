import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:web3dart/crypto.dart';

class GsplTxData {
  final List<GsplItem> inputs;
  final GsplItem? change;
  final String hex;
  final BtcSignDataType dataType;

  GsplTxData({required this.inputs, required this.hex, this.change, required this.dataType});

  CborMap toCbor() {
    final cborData = CborMap({
      CborSmallInt(1): CborBytes(fromHex(hex)),
      CborSmallInt(2): CborSmallInt(dataType.index),
      CborSmallInt(3): CborList(inputs.map((e) => e.toCbor()).toList())
    }, tags: [6111]);
    if (change != null) cborData[CborSmallInt(4)] = change!.toCbor(change: true);

    return cborData;
  }

  factory GsplTxData.fromCbor({required CborMap data}) {
    final hex = Uint8List.fromList((data[CborSmallInt(1)] as CborBytes).bytes);
    List<GsplItem>? inputs = (data[CborSmallInt(3)] as CborList).map((e) => GsplItem.fromCbor(data: e as CborMap)).toList();
    GsplItem? change = data[CborSmallInt(4)] == null ? null : GsplItem.fromCbor(data: data[CborSmallInt(4)] as CborMap);

    return GsplTxData(inputs: inputs, hex: bytesToHex(hex), dataType: BtcSignDataType.TRANSACTION, change: change);
  }
}

class GsplItem {
  final String? path;
  final String? address;
  final int? amount;
  final int? signHashType;
  final Uint8List? signature;
  GsplItem({this.path, this.amount, this.signature, this.address, this.signHashType});

  CborValue toCbor({bool change = false}) {
    final cborData = CborMap({}, tags: [6110]);
    if (path != null) cborData[CborSmallInt(1)] = CborList(getPath(path!));
    if (amount != null) cborData[CborSmallInt(2)] = CborInt(BigInt.from(amount!));
    if (signature != null) cborData[CborSmallInt(3)] = CborBytes(signature!);
    if (address != null) cborData[CborSmallInt(4)] = CborString(address!);

    return cborData;
  }

  factory GsplItem.fromCbor({required CborMap data}) {
    final amount = (data[CborSmallInt(2)] as CborInt).toInt();
    final signature = data[CborSmallInt(3)] != null ? Uint8List.fromList((data[CborSmallInt(3)] as CborBytes).bytes) : null;
    final signHashType = data[CborSmallInt(4)] != null ? (data[CborSmallInt(4)] as CborInt).toInt() : null;
    final address = data[CborSmallInt(5)] != null ? (data[CborSmallInt(5)] as CborString).toString() : null;

    return GsplItem(
      address: address,
      amount: amount,
      signHashType: signHashType,
      signature: signature
    );
  }

  Map<String, dynamic> toJson() => {
    'amount': amount.toString(),
    'address': address
  };
}
