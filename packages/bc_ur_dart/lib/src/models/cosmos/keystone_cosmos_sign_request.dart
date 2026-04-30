// ignore_for_file: unused_field

import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';

enum _KeystoneCosmosKeys {
  zero,
  requestId,
  signData,
  dataType,
  derivationPaths,
  addresses,
  origin,
}

/// Official Keystone Cosmos sign data type.
///
/// Values match `@keystonehq/bc-ur-registry-cosmos`.
enum CosmosDataType {
  zero,
  amino,
  direct,
  textual,
  message,
}

/// Official Keystone-compatible `cosmos-sign-request`.
///
/// This model intentionally stays separate from [CosmosSignRequest], which is
/// retained for the existing GoldShell flow.
class KeystoneCosmosSignRequest extends RegistryItem {
  Uint8List? requestId;
  final Uint8List signData;
  final CosmosDataType dataType;
  final List<CryptoKeypath> derivationPaths;
  final List<String>? addresses;
  final String? origin;

  KeystoneCosmosSignRequest({
    this.requestId,
    required this.signData,
    required this.dataType,
    required this.derivationPaths,
    this.addresses,
    this.origin,
  });

  Uint8List getRequestId() => requestId ??= generateUuid();

  List<String?> getDerivationPaths() => derivationPaths.map((item) => item.getPath()).toList();
  List<Uint8List?> getSourceFingerprints() => derivationPaths.map((item) => item.sourceFingerprint).toList();

  @override
  RegistryType getRegistryType() => RegistryType.COSMOS_SIGN_REQUEST;

  @override
  CborValue toCborValue() {
    final Map<CborValue, CborValue> map = {};

    map[CborSmallInt(_KeystoneCosmosKeys.requestId.index)] = cborBytes(
      getRequestId(),
      tags: [RegistryType.UUID.tag],
    );
    map[CborSmallInt(_KeystoneCosmosKeys.signData.index)] = cborBytes(signData);
    map[CborSmallInt(_KeystoneCosmosKeys.dataType.index)] = cborInt(dataType.index);
    map[CborSmallInt(_KeystoneCosmosKeys.derivationPaths.index)] = CborList(
      derivationPaths.map((item) => item.toCborValue()).toList(),
    );

    if (addresses != null && addresses!.isNotEmpty) {
      map[CborSmallInt(_KeystoneCosmosKeys.addresses.index)] = CborList(
        addresses!.map(CborString.new).toList(),
      );
    }
    if (origin != null && origin!.isNotEmpty) {
      map[CborSmallInt(_KeystoneCosmosKeys.origin.index)] = CborString(origin!);
    }

    return CborMap(map);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    final int dataTypeIndex = RegistryItem.readInt(map, _KeystoneCosmosKeys.dataType.index);
    final CborValue? derivationPathValue = map[CborSmallInt(_KeystoneCosmosKeys.derivationPaths.index)];
    if (derivationPathValue is! CborList) {
      throw Exception(
        'KeystoneCosmosSignRequest: key ${_KeystoneCosmosKeys.derivationPaths.index} '
        'must be a list of crypto-keypath values.',
      );
    }

    final derivationPaths = derivationPathValue
        .toList()
        .whereType<CborMap>()
        .map((item) => CryptoKeypath().decodeFromCbor(item) as CryptoKeypath)
        .toList();

    if (derivationPaths.isEmpty) {
      throw Exception('KeystoneCosmosSignRequest: derivationPaths must not be empty.');
    }

    final addressesValue = map[CborSmallInt(_KeystoneCosmosKeys.addresses.index)];
    final List<String>? addresses = addressesValue is CborList
        ? addressesValue.toList().whereType<CborString>().map((item) => item.toString()).toList()
        : null;

    return KeystoneCosmosSignRequest(
      requestId: RegistryItem.readOptionalBytes(map, _KeystoneCosmosKeys.requestId.index),
      signData: RegistryItem.readBytes(map, _KeystoneCosmosKeys.signData.index),
      dataType: dataTypeIndex >= 0 && dataTypeIndex < CosmosDataType.values.length
          ? CosmosDataType.values[dataTypeIndex]
          : CosmosDataType.amino,
      derivationPaths: derivationPaths,
      addresses: addresses,
      origin: RegistryItem.readOptionalText(map, _KeystoneCosmosKeys.origin.index),
    );
  }

  static KeystoneCosmosSignRequest fromUR(UR ur) {
    if (ur.type.toLowerCase() != RegistryType.COSMOS_SIGN_REQUEST.type) {
      throw ArgumentError('Invalid UR type for KeystoneCosmosSignRequest: ${ur.type}');
    }

    return RegistryItem.fromCBOR<KeystoneCosmosSignRequest>(
      ur.payload,
      KeystoneCosmosSignRequest(
        signData: Uint8List(0),
        dataType: CosmosDataType.amino,
        derivationPaths: [CryptoKeypath()],
      ),
    );
  }

  static UR buildAminoRequest({
    required String signDataHex,
    required String path,
    required String xfp,
    String? address,
    String? origin,
    Uint8List? uuid,
  }) {
    return _buildSinglePath(
      signDataHex: signDataHex,
      dataType: CosmosDataType.amino,
      path: path,
      xfp: xfp,
      address: address,
      origin: origin,
      uuid: uuid,
    );
  }

  static UR buildDirectRequest({
    required String signDataHex,
    required String path,
    required String xfp,
    String? address,
    String? origin,
    Uint8List? uuid,
  }) {
    return _buildSinglePath(
      signDataHex: signDataHex,
      dataType: CosmosDataType.direct,
      path: path,
      xfp: xfp,
      address: address,
      origin: origin,
      uuid: uuid,
    );
  }

  static UR buildTextualRequest({
    required String signDataHex,
    required String path,
    required String xfp,
    String? address,
    String? origin,
    Uint8List? uuid,
  }) {
    return _buildSinglePath(
      signDataHex: signDataHex,
      dataType: CosmosDataType.textual,
      path: path,
      xfp: xfp,
      address: address,
      origin: origin,
      uuid: uuid,
    );
  }

  static UR buildMessageRequest({
    required String signDataHex,
    required String path,
    required String xfp,
    String? address,
    String? origin,
    Uint8List? uuid,
  }) {
    return _buildSinglePath(
      signDataHex: signDataHex,
      dataType: CosmosDataType.message,
      path: path,
      xfp: xfp,
      address: address,
      origin: origin,
      uuid: uuid,
    );
  }

  static UR constructCosmosRequest({
    Uint8List? uuid,
    required String signDataHex,
    required CosmosDataType dataType,
    required List<String> paths,
    required List<String> xfps,
    List<String>? addresses,
    String? origin,
  }) {
    if (paths.isEmpty) {
      throw ArgumentError('paths must not be empty');
    }
    if (paths.length != xfps.length) {
      throw ArgumentError('paths and xfps length must match');
    }
    if (addresses != null && addresses.isNotEmpty && addresses.length != paths.length) {
      throw ArgumentError('addresses length must match paths length when provided');
    }

    return KeystoneCosmosSignRequest(
      requestId: uuid,
      signData: fromHex(signDataHex),
      dataType: dataType,
      derivationPaths: List.generate(paths.length, (index) => _buildKeypath(paths[index], xfps[index])),
      addresses: addresses == null || addresses.isEmpty ? null : addresses,
      origin: origin,
    ).toUR();
  }

  static UR _buildSinglePath({
    required String signDataHex,
    required CosmosDataType dataType,
    required String path,
    required String xfp,
    String? address,
    String? origin,
    Uint8List? uuid,
  }) {
    return KeystoneCosmosSignRequest(
      requestId: uuid,
      signData: fromHex(signDataHex),
      dataType: dataType,
      derivationPaths: [_buildKeypath(path, xfp)],
      addresses: address == null || address.isEmpty ? null : [address],
      origin: origin,
    ).toUR();
  }

  static CryptoKeypath _buildKeypath(String path, String xfp) {
    return CryptoKeypath(
      components: parsePath(path).map((e) => PathComponent(index: e['index'], hardened: e['hardened'])).toList(),
      sourceFingerprint: fromHex(xfp),
    );
  }
}
