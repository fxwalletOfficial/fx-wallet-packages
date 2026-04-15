import 'dart:io';
import 'dart:typed_data';

import 'package:bc_ur_dart/src/gen/keystone/base.pb.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:cbor/cbor.dart';

class KeystoneTronSignResult {
  final String requestId;
  final String txId;
  final String rawTx;

  const KeystoneTronSignResult({
    required this.requestId,
    required this.txId,
    required this.rawTx,
  });

  static KeystoneTronSignResult fromUR(UR ur) {
    if (ur.type.toLowerCase() != RegistryType.KEYSTONE_SIGNATURE.type) {
      throw ArgumentError('Invalid UR type for KeystoneTronSignResult: ${ur.type}');
    }

    final decoded = ur.decodeCBOR();
    if (decoded is! CborMap) {
      throw ArgumentError('Invalid Keystone TRON result payload');
    }

    final signResultValue = decoded[CborSmallInt(1)];
    if (signResultValue is! CborBytes) {
      throw ArgumentError('Invalid Keystone TRON signResult payload');
    }

    final base = Base.fromBuffer(
      GZipCodec().decode(Uint8List.fromList(signResultValue.bytes)),
    );
    final result = base.payloadData.signTxResult;

    return KeystoneTronSignResult(
      requestId: result.signId,
      txId: result.txId,
      rawTx: result.rawTx,
    );
  }
}
