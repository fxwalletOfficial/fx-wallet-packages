// ignore_for_file: unused_field

import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';

enum _KeystoneCosmosSignatureKeys {
  zero,
  requestId,
  signature,
  publicKey,
}

/// Official Keystone-compatible `cosmos-signature`.
class KeystoneCosmosSignature extends RegistryItem {
  final Uint8List requestId;
  final Uint8List signature;
  final Uint8List publicKey;

  KeystoneCosmosSignature({
    required this.requestId,
    required this.signature,
    required this.publicKey,
  });

  Uint8List getRequestId() => requestId;
  Uint8List getSignature() => signature;
  Uint8List getPublicKey() => publicKey;

  @override
  RegistryType getRegistryType() => RegistryType.COSMOS_SIGNATURE;

  @override
  CborValue toCborValue() {
    final Map<CborValue, CborValue> map = {};

    map[CborSmallInt(_KeystoneCosmosSignatureKeys.requestId.index)] = cborBytes(
      requestId,
      tags: [RegistryType.UUID.tag],
    );
    map[CborSmallInt(_KeystoneCosmosSignatureKeys.signature.index)] = cborBytes(signature);
    map[CborSmallInt(_KeystoneCosmosSignatureKeys.publicKey.index)] = cborBytes(publicKey);

    return CborMap(map);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    return KeystoneCosmosSignature(
      requestId: RegistryItem.readBytes(map, _KeystoneCosmosSignatureKeys.requestId.index),
      signature: RegistryItem.readBytes(map, _KeystoneCosmosSignatureKeys.signature.index),
      publicKey: RegistryItem.readBytes(map, _KeystoneCosmosSignatureKeys.publicKey.index),
    );
  }

  static KeystoneCosmosSignature fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<KeystoneCosmosSignature>(
      cborPayload,
      KeystoneCosmosSignature(
        requestId: Uint8List(0),
        signature: Uint8List(0),
        publicKey: Uint8List(0),
      ),
    );
  }

  static UR fromSignature({
    required KeystoneCosmosSignRequest request,
    required Uint8List signature,
    required Uint8List publicKey,
  }) {
    return KeystoneCosmosSignature(
      requestId: request.getRequestId(),
      signature: signature,
      publicKey: publicKey,
    ).toUR();
  }
}
