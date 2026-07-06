import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';

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
  final Endian sourceFingerprintEndian;

  CryptoKeypath({
    this.components = const [],
    this.sourceFingerprint,
    this.depth,
    this.sourceFingerprintEndian = Endian.big,
  });

  String? getPath({bool includeMaster = true}) {
    if (components.isEmpty) return null;
    final path = components.map((c) {
      return '${c.isWildcard() ? '*' : c.getIndex()}${c.isHardened() ? "'" : ''}';
    }).join('/');
    return includeMaster ? 'm/$path' : path;
  }

  String? getRelativePath() => getPath(includeMaster: false);

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
      if (sourceFingerprint!.length != 4) {
        throw ArgumentError(
          'crypto-keypath: sourceFingerprint must be 4 bytes, got ${sourceFingerprint!.length}',
        );
      }
      final fp = ByteData.sublistView(sourceFingerprint!).getUint32(0, sourceFingerprintEndian);
      innerMap[CborSmallInt(KeyPathKeys.sourceFingerprint.index)] = CborInt(BigInt.from(fp));
    }

    if (depth != null) {
      if (depth! < 0 || depth! > 255) {
        throw ArgumentError('crypto-keypath: depth out of uint8 range: $depth');
      }
      innerMap[CborSmallInt(KeyPathKeys.depth.index)] = CborSmallInt(depth!);
    }

    return CborMap(innerMap, tags: [getRegistryType().tag]);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    final componentsList = map[CborSmallInt(KeyPathKeys.components.index)];
    final pathComponents = _decodeComponentsStrict(componentsList);

    Uint8List? sourceFingerprint;
    if (RegistryItem.hasKey(map, KeyPathKeys.sourceFingerprint.index)) {
      final fp = RegistryItem.readInt(map, KeyPathKeys.sourceFingerprint.index);
      if (fp < 0 || fp > 0xFFFFFFFF) {
        throw ArgumentError('crypto-keypath: sourceFingerprint out of uint32 range: $fp');
      }
      sourceFingerprint = Uint8List(4);
      ByteData.sublistView(sourceFingerprint).setUint32(0, fp, sourceFingerprintEndian);
    }

    final depth = RegistryItem.readOptionalInt(map, KeyPathKeys.depth.index);
    if (depth != null && (depth < 0 || depth > 255)) {
      throw ArgumentError('crypto-keypath: depth out of uint8 range: $depth');
    }

    return CryptoKeypath(
      components: pathComponents,
      sourceFingerprint: sourceFingerprint,
      depth: depth,
      sourceFingerprintEndian: sourceFingerprintEndian,
    );
  }

  static CryptoKeypath fromCBOR(
    Uint8List cborPayload, {
    Endian sourceFingerprintEndian = Endian.big,
  }) {
    return RegistryItem.fromCBOR<CryptoKeypath>(
      cborPayload,
      CryptoKeypath(sourceFingerprintEndian: sourceFingerprintEndian),
    );
  }

  static List<PathComponent> _decodeComponentsStrict(CborValue? componentsList) {
    if (componentsList is! CborList) {
      throw ArgumentError('crypto-keypath: components must be CborList');
    }
    final items = componentsList.toList();
    if (items.length.isOdd) {
      throw ArgumentError('crypto-keypath: components length must be even, got ${items.length}');
    }
    final result = <PathComponent>[];
    for (var i = 0; i < items.length; i += 2) {
      final pathItem = items[i];
      final hardenedItem = items[i + 1];
      if (hardenedItem is! CborBool) {
        throw ArgumentError('crypto-keypath: is-hardened must be CborBool at $i');
      }
      final isHardened = hardenedItem.value;
      if (pathItem is CborList) {
        if (pathItem.isNotEmpty) {
          throw ArgumentError('crypto-keypath: wildcard component must be empty list');
        }
        result.add(PathComponent(hardened: isHardened));
      } else if (pathItem is CborInt) {
        final index = pathItem.toInt();
        if (index < 0 || index >= PathComponent.HARDENED_BIT) {
          throw ArgumentError('crypto-keypath: index out of range: $index');
        }
        result.add(PathComponent(index: index, hardened: isHardened));
      } else {
        throw ArgumentError(
          'crypto-keypath: component must be uint or empty list, got ${pathItem.runtimeType}',
        );
      }
    }
    return result;
  }
}
