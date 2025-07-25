import 'dart:typed_data';
import 'package:bc_ur_dart/src/models/btc/gspl_tx_data.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:cbor/cbor.dart';

import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';
import 'package:crypto_wallet_util/transaction.dart' show GsplTxData, GsplItem, BtcSignDataType;

const String BTC_SIGN_REQUEST = 'BTC-SIGN-REQUEST';

class GsplSignRequestUR extends UR {
  final String path;
  final String xfp;
  final Uint8List uuid;
  final GsplTxData gsplTxData;

  GsplSignRequestUR({required UR ur, required this.uuid, required this.path, required this.gsplTxData, required this.xfp}) : super(payload: ur.payload, type: ur.type);

  factory GsplSignRequestUR.fromTypedTransaction({
    required String hex,
    required String path,
    required String xfp,
    required String origin,
    required List<GsplItem> inputs,
    GsplItem? change,
    Uint8List? uuid,
    bool xfpReverse = true
  }) {
    uuid ??= UR.generateUUid();
    final gspl = GsplTxData(dataType: BtcSignDataType.TRANSACTION, inputs: inputs, change: change, hex: hex);

    final ur = UR.fromCBOR(
      type: BTC_SIGN_REQUEST,
      value: CborMap({
        CborSmallInt(1): CborBytes(uuid, tags: [37]),
        CborSmallInt(2): gspl.toCbor(),
        CborSmallInt(3): CborMap({
          CborSmallInt(1): CborList(getPath(path)),
          if (xfpReverse) CborSmallInt(2): CborInt(toXfpCode(xfp, bigEndian: xfpReverse))
        }, tags: [40304]),
        CborSmallInt(4): CborString(origin)
      })
    );

    final item = GsplSignRequestUR(ur: ur, uuid: uuid, gsplTxData: gspl, path: path, xfp: xfp);

    return item;
  }

  factory GsplSignRequestUR.fromUR({required UR ur, bool bigEndian = true}) {
    if (ur.type.toUpperCase() != BTC_SIGN_REQUEST) throw Exception(URExceptionType.invalidType.toString());

    final data = ur.decodeCBOR() as CborMap;

    final uuid = Uint8List.fromList((data[CborSmallInt(1)] as CborBytes).bytes);
    final gsplTxData = getGsplTxDataFromCbor(data: data[CborSmallInt(2)] as CborMap);
    final components = (data[CborSmallInt(3)] as CborMap)[CborSmallInt(1)] as CborList;

    String path = 'm';
    for (final item in components) {
      if (item is CborSmallInt) path += '/${item.value}';
      if (item is CborBool && item.value) path += "'";
    }

    String xfp = '';
    try {
      xfp = getXfp(((data[CborSmallInt(3)] as CborMap)[CborSmallInt(2)] as CborInt).toBigInt(), bigEndian: bigEndian);
    } catch (e) {
      xfp = '';
    }

    return GsplSignRequestUR(ur: ur, uuid: uuid, path: path, gsplTxData: gsplTxData, xfp: xfp);
  }
}
