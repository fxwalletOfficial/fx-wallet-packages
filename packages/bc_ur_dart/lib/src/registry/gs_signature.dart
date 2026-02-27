import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

/// 使用枚举管理 CBOR key，避免硬编码数字
enum GsSignatureKeys {
  zero, // 0
  uuid, // 1
  signature, // 2
  origin, // 3
}

class GsSignature extends RegistryItem {
  final Uint8List? uuid;
  final Uint8List signature;
  final String? origin;

  GsSignature({
    this.uuid,
    required this.signature,
    this.origin,
  });

  Uint8List getRequestId() {
    assert(uuid != null, 'GsSignature.uuid must not be null when used as a response');
    return uuid!;
  }

  Uint8List getSignature() => signature;
  String? getOrigin() => origin;

  @override
  RegistryType getRegistryType() => ExtendedRegistryType.GS_SIGNATURE;

  @override
  Map<int, CborValue> buildCbor() {
    final map = <int, CborValue>{};

    // uuid optional，有值才写入（与 Tron 行为统一）
    if (uuid != null) {
      map[GsSignatureKeys.uuid.index] = cborBytes(
        uuid!,
        tags: [RegistryType.UUID.tag],
      );
    }

    map[GsSignatureKeys.signature.index] = cborBytes(signature);

    if (origin != null) {
      map[GsSignatureKeys.origin.index] = CborString(origin!);
    }

    return map;
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    return GsSignature(
      uuid: RegistryItem.hasKey(map, GsSignatureKeys.uuid.index) ? RegistryItem.readBytes(map, GsSignatureKeys.uuid.index) : null,
      signature: RegistryItem.readBytes(map, GsSignatureKeys.signature.index),
      origin: RegistryItem.readOptionalText(map, GsSignatureKeys.origin.index),
    );
  }

  static GsSignature fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<GsSignature>(cborPayload, GsSignature(uuid: Uint8List(0), signature: Uint8List(0)));
  }
}
