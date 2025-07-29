import 'dart:typed_data';

import 'package:bc_ur_dart/src/models/btc/gspl_tx_data.dart';
import 'package:bc_ur_dart/src/models/btc/gspl_sign_request.dart';
import 'package:cbor/cbor.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:crypto_wallet_util/transaction.dart' show GsplTxData;

const String BTC_SIGNATURE = 'BTC-SIGNATURE';

class GsplSignatureUR extends UR {
  final Uint8List uuid;
  final GsplTxData gspl;

  GsplSignatureUR({required this.uuid, required this.gspl, super.type, super.payload});

  factory GsplSignatureUR.fromUR({required UR ur}) {
    if (ur.type.toUpperCase() != BTC_SIGNATURE) throw Exception('Invalid type: ${ur.type}');

    final data = ur.decodeCBOR() as CborMap;

    final uuid = Uint8List.fromList((data[CborSmallInt(1)] as CborBytes).bytes);
    final gspl = getGsplTxDataFromCbor(data: data[CborSmallInt(2)] as CborMap);

    return GsplSignatureUR(uuid: uuid, gspl: gspl, type: ur.type, payload: ur.payload);
  }

  factory GsplSignatureUR.fromSignature({required GsplSignRequestUR request, required GsplTxData gspl}) {
    final ur = UR.fromCBOR(
      type: BTC_SIGNATURE,
      value: CborMap({
        CborSmallInt(1): CborBytes(request.uuid, tags: [37]),
        CborSmallInt(2): gspl.toCbor(),
      })
    );
    return GsplSignatureUR(uuid: request.uuid, gspl: gspl, type: ur.type, payload: ur.payload);
  }
}
