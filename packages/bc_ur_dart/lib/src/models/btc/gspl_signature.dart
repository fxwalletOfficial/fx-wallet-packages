import 'dart:typed_data';

import 'package:bc_ur_dart/src/models/btc/gspl_tx_data.dart';
import 'package:cbor/cbor.dart';
import 'package:bc_ur_dart/src/ur.dart';

const String BTC_SIGNATURE = 'BTC-SIGNATURE';

class GsplSignatureUR extends UR {
  final Uint8List uuid;
  final GsplTxData gspl;

  GsplSignatureUR({required this.uuid, required this.gspl, super.type, super.payload});

  factory GsplSignatureUR.fromUR({required UR ur}) {
    if (ur.type.toUpperCase() != BTC_SIGNATURE) throw Exception('Invalid type: ${ur.type}');

    final data = ur.decodeCBOR() as CborMap;

    final uuid = Uint8List.fromList((data[CborSmallInt(1)] as CborBytes).bytes);
    final gspl = GsplTxData.fromCbor(data: data[CborSmallInt(2)] as CborMap);

    return GsplSignatureUR(uuid: uuid, gspl: gspl, type: ur.type, payload: ur.payload);
  }
}
