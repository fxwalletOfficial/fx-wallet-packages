import 'dart:convert';
import 'dart:typed_data';

import 'package:cbor/cbor.dart';
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

  @override
  RegistryType getRegistryType() {
    return RegistryType.CRYPTO_KEYPATH;
  }

  String? getPath() {
    if (components.isEmpty) {
      return null;
    }

    final pathComponents = components.map((component) {
      return '${component.isWildcard() ? '*' : component.getIndex()}${component.isHardened() ? "'" : ''}';
    }).join('/');

    return pathComponents;
  }

  List<PathComponent> getComponents() => components;
  Uint8List? getSourceFingerprint() => sourceFingerprint;
  int? getDepth() => depth;

  @override
  CborValue toCborValue() {
    final map = {};
    final List componentsData = [];

    for (var component in components) {
      if (component.isWildcard()) {
        componentsData.add([]);
      } else {
        componentsData.add(component.getIndex());
      }
      componentsData.add(component.isHardened());
    }

    map[KeyPathKeys.components.index] = componentsData;
    if (sourceFingerprint != null) {
      map[KeyPathKeys.sourceFingerprint.index] = sourceFingerprint!.buffer.asByteData().getUint32(0, Endian.little); // , Endian.little
    }
    if (depth != null) {
      map[KeyPathKeys.depth.index] = depth;
    }

    return CborValue(map);
  }

  static CryptoKeypath fromDataItem(dynamic jsonData) {
    final map = jsonData is String
        ? jsonDecode(jsonData)
        : jsonData is Map
            ? jsonData
            : null;
    if (map == null) {
      throw "Param for fromDataItem is neither String nor Map, please check it!";
    }
    final pathComponents = <PathComponent>[];
    final components = map[KeyPathKeys.components.index.toString()] as List<dynamic>? ?? [];

    for (var i = 0; i < components.length; i += 2) {
      final isHardened = components[i + 1] as bool;
      final path = components[i];

      if (path is int) {
        pathComponents.add(PathComponent(index: path, hardened: isHardened));
      } else {
        pathComponents.add(PathComponent(hardened: isHardened));
      }
    }
    final sourceFingerprintData = map[KeyPathKeys.sourceFingerprint.index.toString()];
    Uint8List? sourceFingerprint;
    if (sourceFingerprintData != null) {
      sourceFingerprint = Uint8List(4);
      sourceFingerprint.buffer.asByteData().setUint32(0, sourceFingerprintData, Endian.little); // , Endian.little
    }

    final depth = map[KeyPathKeys.depth.index.toString()];

    return CryptoKeypath(
      components: pathComponents,
      sourceFingerprint: sourceFingerprint,
      depth: depth,
    );
  }

  static CryptoKeypath fromCBOR(Uint8List cborPayload) {
    CborValue cborValue = cbor.decode(cborPayload);
    String jsonData = const CborJsonEncoder().convert(cborValue);
    return fromDataItem(jsonData);
  }
}
