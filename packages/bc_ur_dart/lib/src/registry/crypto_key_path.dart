import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

enum KeyPathKeys {
  zero,
  components,
  sourceFingerprint,
  depth,
}

class PathComponent {
  // ignore: constant_identifier_names
  static const int HARDENED_BIT = 0x80000000;

  final int? index;
  final bool wildcard;
  final bool hardened;

  PathComponent({this.index, required this.hardened}) : wildcard = index == null {
    if (index != null && (index! & HARDENED_BIT) != 0) {
      throw ArgumentError(
        'Invalid index $index - most significant bit cannot be set',
      );
    }
  }

  int? getIndex() => index;
  bool isWildcard() => wildcard;
  bool isHardened() => hardened;
}

class CryptoKeypath extends RegistryItem {
  final List<PathComponent> components;
  final Uint8List? sourceFingerprint;
  final int? depth;

  CryptoKeypath({
    this.components = const [],
    this.sourceFingerprint,
    this.depth,
  });

  String? getPath() {
    if (components.isEmpty) return null;
    return components.map((c) {
      return '${c.isWildcard() ? '*' : c.getIndex()}${c.isHardened() ? "'" : ''}';
    }).join('/');
  }

  List<PathComponent> getComponents() => components;
  Uint8List? getSourceFingerprint() => sourceFingerprint;
  int? getDepth() => depth;

  @override
  RegistryType getRegistryType() => RegistryType.CRYPTO_KEYPATH;

  @override
  CborValue toCborValue() {
    // components: [index/[], isHardened, ...]
    final List<CborValue> componentsData = [];
    for (final component in components) {
      if (component.isWildcard()) {
        componentsData.add(CborList([]));
      } else {
        componentsData.add(CborSmallInt(component.getIndex()!));
      }
      componentsData.add(CborBool(component.isHardened()));
    }

    final Map<CborValue, CborValue> innerMap = {
      CborSmallInt(KeyPathKeys.components.index): CborList(componentsData),
    };

    // sourceFingerprint：xfp uint32，字节序与 Keystone 基准一致
    if (sourceFingerprint != null) {
      final fp = sourceFingerprint!.buffer.asByteData().getUint32(0, Endian.little);
      innerMap[CborSmallInt(KeyPathKeys.sourceFingerprint.index)] = CborInt(BigInt.from(fp));
    }

    if (depth != null) {
      innerMap[CborSmallInt(KeyPathKeys.depth.index)] = CborSmallInt(depth!);
    }

    return CborMap(innerMap, tags: [getRegistryType().tag]);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    final pathComponents = <PathComponent>[];
    final componentsList = map[CborSmallInt(KeyPathKeys.components.index)];

    if (componentsList is CborList) {
      final items = componentsList.toList();
      for (var i = 0; i + 1 < items.length; i += 2) {
        final pathItem = items[i];
        final hardenedItem = items[i + 1];
        final isHardened = hardenedItem is CborBool && hardenedItem.value;

        if (pathItem is CborList && pathItem.isEmpty) {
          pathComponents.add(PathComponent(hardened: isHardened));
        } else if (pathItem is CborInt) {
          pathComponents.add(PathComponent(
            index: pathItem.toInt(),
            hardened: isHardened,
          ));
        }
      }
    }

    Uint8List? sourceFingerprint;
    if (RegistryItem.hasKey(map, KeyPathKeys.sourceFingerprint.index)) {
      final fp = RegistryItem.readInt(map, KeyPathKeys.sourceFingerprint.index);
      sourceFingerprint = Uint8List(4);
      sourceFingerprint.buffer.asByteData().setUint32(0, fp, Endian.little);
    }

    final depth = RegistryItem.readOptionalInt(map, KeyPathKeys.depth.index);

    return CryptoKeypath(
      components: pathComponents,
      sourceFingerprint: sourceFingerprint,
      depth: depth,
    );
  }

  static CryptoKeypath fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<CryptoKeypath>(cborPayload, CryptoKeypath());
  }
}
