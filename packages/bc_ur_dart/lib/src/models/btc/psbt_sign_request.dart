import 'dart:typed_data';

import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:cbor/cbor.dart';

import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';
import 'package:crypto_wallet_util/utils.dart' show hexUint8List;

const String PSBT_SIGN_REQUEST = 'PSBT-SIGN-REQUEST';

class PsbtSignRequestUR extends UR {
  final Uint8List uuid;
  final BtcSignDataType dataType;
  final String psbt;
  final String path;
  final String xfp;

  PsbtSignRequestUR({required UR ur, required this.uuid, required this.dataType, required this.psbt, required this.path, required this.xfp}) : super(payload: ur.payload, type: ur.type);

  factory PsbtSignRequestUR.fromTypedTransaction({
    required String path,
    required String psbt,
    required String xfp,
    required String origin,
    Uint8List? uuid,
    bool xfpReverse = true
  }) {
    uuid ??= UR.generateUUid();
    final dataType = BtcSignDataType.TRANSACTION;

    final ur = UR.fromCBOR(
      type: PSBT_SIGN_REQUEST,
      value: CborMap({
        CborSmallInt(1): CborBytes(uuid, tags: [37]),
        CborSmallInt(2): CborBytes(fromHex(psbt), tags: [40310]),
        CborSmallInt(3): CborMap({
          CborSmallInt(1): CborList(getPath(path)),
          if (xfp.isNotEmpty) CborSmallInt(2): CborInt(toXfpCode(xfp, bigEndian: xfpReverse))
        }, tags: [40304]),
        CborSmallInt(4): CborString(origin)
      })
    );

    final item = PsbtSignRequestUR(ur: ur, uuid: uuid, path: path, psbt: psbt, dataType: dataType, xfp: xfp);

    return item;
  }

  factory PsbtSignRequestUR.fromUR({required UR ur, bool bigEndian = true}) {
    if (ur.type.toUpperCase() != PSBT_SIGN_REQUEST) throw Exception(URExceptionType.invalidType.toString());

    final data = ur.decodeCBOR() as CborMap;

    final uuid = Uint8List.fromList((data[CborSmallInt(1)] as CborBytes).bytes);
    final psbt = Uint8List.fromList((data[CborSmallInt(2)] as CborBytes).bytes);

    final components = (data[CborSmallInt(3)] as CborMap)[CborSmallInt(1)] as CborList;
    String path = 'm';
    for (final item in components) {
      if (item is CborSmallInt) path += '/${item.value}';
      if (item is CborBool && item.value) path += "'";
    }

    final xfp = (data[CborSmallInt(3)] as CborMap)[CborSmallInt(2)] == null ? '' : getXfp(((data[CborSmallInt(3)] as CborMap)[CborSmallInt(2)] as CborInt).toBigInt(), bigEndian: bigEndian);

    final item = PsbtSignRequestUR(ur: ur, uuid: uuid, path: path, psbt: psbt.toHex(), dataType: BtcSignDataType.TRANSACTION, xfp: xfp);
    return item;
  }
}

enum BtcSignDataType {
  ZERO,
  TRANSACTION,
  MESSAGE
}
