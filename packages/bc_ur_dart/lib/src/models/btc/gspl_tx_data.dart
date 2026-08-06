import 'package:bc_ur_dart/src/registry/cbor_field_reader.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:bc_ur_dart/src/utils/utils.dart' show getPath, fromHex, cborPathToString;
import 'package:cbor/cbor.dart';
import 'package:crypto_wallet_util/transaction.dart' show GsplTxData, GsplItem, BtcSignDataType;
import 'package:crypto_wallet_util/utils.dart' hide fromHex;

extension GsplTxDataWithCbor on GsplTxData {
  CborMap toCbor() {
    final cborData = CborMap({
      CborSmallInt(1): CborBytes(fromHex(hex)),
      CborSmallInt(2): CborSmallInt(dataType.index),
      CborSmallInt(3): CborList(inputs.map((e) => e.toCbor()).toList()),
    }, tags: [
      6111
    ]);
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
  final reader = CborFieldReader(data, model: 'gspl-tx-data');
  final txBytes = reader.requiredBytes(1, field: 'hex');
  final inputsRaw = reader.requiredList(3, field: 'inputs');

  final inputs = <GsplItem>[];
  for (var i = 0; i < inputsRaw.length; i++) {
    final item = inputsRaw[i];
    if (item is! CborMap) {
      throw InvalidCborURException(model: 'gspl-tx-data', field: 'inputs[$i]', reason: 'expected CborMap, got ${item.runtimeType}');
    }
    inputs.add(getGsplItemFromCbor(data: item));
  }

  final changeRaw = reader.optionalMap(4, field: 'change');

  return GsplTxData(inputs: inputs, hex: txBytes.toHex(), dataType: BtcSignDataType.TRANSACTION, change: changeRaw == null ? null : getGsplItemFromCbor(data: changeRaw));
}

GsplItem getGsplItemFromCbor({required CborMap data}) {
  final reader = CborFieldReader(data, model: 'gspl-item');

  final pathValue = reader.optionalValue(1);
  if (pathValue != null && pathValue is! CborList) {
    throw InvalidCborURException(model: 'gspl-item', field: 'path', reason: 'expected CborList, got ${pathValue.runtimeType}');
  }
  final path = cborPathToString(pathValue as CborList?);

  final amount = reader.optionalInt(2, field: 'amount');
  final signature = reader.optionalBytes(3, field: 'signature');
  final address = reader.optionalText(4, field: 'address');

  int? signHashType;
  final signHashTypeValue = reader.optionalValue(5);
  if (signHashTypeValue is CborInt) {
    signHashType = signHashTypeValue.toInt();
  } else if (signHashTypeValue is CborString) {
    signHashType = int.tryParse(signHashTypeValue.toString());
  } else if (signHashTypeValue != null) {
    throw InvalidCborURException(model: 'gspl-item', field: 'signHashType', reason: 'expected CborInt or CborString, got ${signHashTypeValue.runtimeType}');
  }

  return GsplItem(path: path, address: address, amount: amount, signHashType: signHashType, signature: signature);
}
