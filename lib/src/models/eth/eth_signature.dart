import 'dart:typed_data';

import 'package:cbor/cbor.dart';

import 'package:bc_ur_dart/src/models/eth/eth_sign_request.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';

const String ETH_SIGNATURE = 'ETH-SIGNATURE';

class EthSignatureUR extends UR {
  final Uint8List uuid;
  final Uint8List signature;

  EthSignatureUR({required this.uuid, required this.signature, super.type, super.payload});

  factory EthSignatureUR.fromUR({required UR ur}) {
    if (ur.type.toUpperCase() != ETH_SIGNATURE) throw Exception('Invalid type: ${ur.type}');

    final data = ur.decodeCBOR() as CborMap;

    final uuid = Uint8List.fromList((data[CborSmallInt(1)] as CborBytes).bytes);
    final signature = Uint8List.fromList((data[CborSmallInt(2)] as CborBytes).bytes);

    return EthSignatureUR(uuid: uuid, signature: signature, type: ur.type, payload: ur.payload);
  }

  factory EthSignatureUR.fromMessageSigned({required EthSignRequestUR request, required String signature}) {
    final ur = UR.fromCBOR(
      type: ETH_SIGNATURE,
      value: CborMap({
        CborSmallInt(1): CborBytes(request.uuid, tags: [37]),
        CborSmallInt(2): CborBytes(fromHex(signature))
      })
    );
    return EthSignatureUR(uuid: request.uuid, signature: fromHex(signature), type: ETH_SIGNATURE, payload: ur.payload);
  }

  factory EthSignatureUR.fromSignature({required EthSignRequestUR request, required BigInt r, required BigInt s, required int v}) {
    int vData = handleV(v);
    final signature = Uint8List.fromList(bigIntToByte(r, 32) + bigIntToByte(s, 32) + [vData]);

    final ur = UR.fromCBOR(
      type: ETH_SIGNATURE,
      value: CborMap({
        CborSmallInt(1): CborBytes(request.uuid, tags: [37]),
        CborSmallInt(2): CborBytes(signature)
      })
    );

    return EthSignatureUR(uuid: request.uuid, signature: signature, type: ETH_SIGNATURE, payload: ur.payload);
  }

  static int handleV(int v) {
    if (v == 0 || v == 1) return v;
    if (v == 27 || v == 28) return v - 27;
    if (v > 35) return (v - 35) % 2;

    throw Exception('Invalid signature: v - $v');
  }

  BigInt get r => byteToBigInt(signature.sublist(0, 32));
  BigInt get s => byteToBigInt(signature.sublist(32, 64));
  int get v => signature[64];
}
