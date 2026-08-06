import 'dart:typed_data';

import 'package:bc_ur_dart/src/models/btc/gspl_tx_data.dart';
import 'package:bc_ur_dart/src/registry/cbor_field_reader.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';
import 'package:cbor/cbor.dart';
import 'package:convert/convert.dart';
import 'package:crypto_wallet_util/transaction.dart' show GsplTxData, GsplItem, BtcSignDataType;

const String BTC_SIGN_REQUEST = 'BTC-SIGN-REQUEST';

class GsplSignRequestUR extends UR {
  final String path;
  final String xfp;
  final Uint8List uuid;
  final GsplTxData gsplTxData;

  GsplSignRequestUR({required UR ur, required this.uuid, required this.path, required this.gsplTxData, required this.xfp}) : super(payload: ur.payload, type: ur.type);

  factory GsplSignRequestUR.fromTypedTransaction(
      {required String hex, required String path, required String xfp, required String origin, required List<GsplItem> inputs, GsplItem? change, Uint8List? uuid, bool xfpReverse = false}) {
    uuid ??= UR.generateUUid();
    final gspl = GsplTxData(dataType: BtcSignDataType.TRANSACTION, inputs: inputs, change: change, hex: hex);

    final ur = UR.fromCBOR(
        type: BTC_SIGN_REQUEST,
        value: CborMap({
          CborSmallInt(1): CborBytes(uuid, tags: [37]),
          CborSmallInt(2): gspl.toCbor(),
          CborSmallInt(3): CborMap({CborSmallInt(1): CborList(getPath(path)), if (xfp.isNotEmpty) CborSmallInt(2): CborInt(toXfpCode(xfp, reverseBytes: xfpReverse))}, tags: [40304]),
          CborSmallInt(4): CborString(origin)
        }));

    final item = GsplSignRequestUR(ur: ur, uuid: uuid, gsplTxData: gspl, path: path, xfp: xfp);

    return item;
  }

  factory GsplSignRequestUR.fromUR({required UR ur, bool bigEndian = true}) {
    final reader = CborFieldReader.fromUr(ur, model: 'btc-sign-request', expectedType: BTC_SIGN_REQUEST);

    final uuid = reader.requiredBytes(1, field: 'uuid', length: 16);
    final gsplTxData = getGsplTxDataFromCbor(data: reader.requiredMap(2, field: 'gspl'));

    final keypath = RegistryItem.readKeypath(reader.map, 3, sourceFingerprintEndian: bigEndian ? Endian.big : Endian.little, model: 'btc-sign-request', field: 'derivation_path');
    final path = keypath.getPath() ?? 'm';
    final xfp = keypath.sourceFingerprint != null ? hex.encode(keypath.sourceFingerprint!) : '';

    return GsplSignRequestUR(ur: ur, uuid: uuid, path: path, gsplTxData: gsplTxData, xfp: xfp);
  }
}
