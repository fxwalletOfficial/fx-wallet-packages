import 'dart:typed_data';

import 'package:bc_ur_dart/src/models/btc/gspl_tx_data.dart';
import 'package:bc_ur_dart/src/models/btc/gspl_sign_request.dart';
import 'package:bc_ur_dart/src/registry/cbor_field_reader.dart';
import 'package:cbor/cbor.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:crypto_wallet_util/transaction.dart' show GsplTxData;

const String BTC_SIGNATURE = 'BTC-SIGNATURE';

class GsplSignatureUR extends UR {
  final Uint8List uuid;
  final GsplTxData gspl;

  GsplSignatureUR({required this.uuid, required this.gspl, super.type, super.payload});

  factory GsplSignatureUR.fromUR({required UR ur}) {
    final reader = CborFieldReader.fromUr(ur, model: 'btc-signature', expectedType: BTC_SIGNATURE);
    final uuid = reader.requiredBytes(1, field: 'uuid', length: 16);
    final gspl = getGsplTxDataFromCbor(data: reader.requiredMap(2, field: 'gspl'));

    return GsplSignatureUR(uuid: uuid, gspl: gspl, type: ur.type, payload: ur.payload);
  }

  factory GsplSignatureUR.fromSignature({required GsplSignRequestUR request, required GsplTxData gspl}) {
    final ur = UR.fromCBOR(
        type: BTC_SIGNATURE,
        value: CborMap({
          CborSmallInt(1): CborBytes(request.uuid, tags: [37]),
          CborSmallInt(2): gspl.toCbor(),
        }));
    return GsplSignatureUR(uuid: request.uuid, gspl: gspl, type: ur.type, payload: ur.payload);
  }
}
