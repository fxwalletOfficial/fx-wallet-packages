import 'dart:typed_data';

import 'package:convert/convert.dart';

/// The only SC V2 semantic signing profile currently supported.
const scV2SiacoinTransferProfile = 'sia-v2-siacoin-transfer-v1';
const _scV2MaxTransferInputs = 1000;
const _scV2MaxTransferOutputs = 1000;
const _scV2MaxSemanticBytes =
    89 + 32 * _scV2MaxTransferInputs + 48 * _scV2MaxTransferOutputs;

/// A normalized SC V2 siacoin output safe to display before signing.
class ScV2SemanticOutput {
  final BigInt value;
  final String address;
  final bool isChange;

  const ScV2SemanticOutput({
    required this.value,
    required this.address,
    required this.isChange,
  });

  factory ScV2SemanticOutput.fromJson(Map<String, dynamic> json) {
    final value = json['value'];
    final address = json['address'];
    final isChange = json['isChange'];
    if (value is! String || address is! String || isChange is! bool) {
      throw const FormatException('Malformed SC V2 semantic output');
    }
    if (!RegExp(r'^[1-9][0-9]*$').hasMatch(value) ||
        !RegExp(r'^[0-9a-f]{76}$').hasMatch(address)) {
      throw const FormatException('Non-canonical SC V2 semantic output');
    }
    return ScV2SemanticOutput(
      value: BigInt.parse(value),
      address: address,
      isChange: isChange,
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value.toString(),
    'address': address,
    'isChange': isChange,
  };
}

/// Canonical, key-free SC V2 transaction semantics and its signing digest.
///
/// The first profile contains only siacoin input parent IDs, siacoin outputs,
/// and the miner fee. Witness data (Merkle proofs, leaf indices, parent
/// outputs, policies, and signatures) is intentionally absent.
class ScV2TransactionSemantics {
  final String profile;
  final Uint8List bytes;
  final String inputSigHash;
  final int inputCount;
  final List<String> parentIds;
  final List<ScV2SemanticOutput> outputs;
  final BigInt minerFee;

  ScV2TransactionSemantics({
    required this.profile,
    required Uint8List bytes,
    required this.inputSigHash,
    required this.inputCount,
    required List<String> parentIds,
    required List<ScV2SemanticOutput> outputs,
    required this.minerFee,
  }) : bytes = Uint8List.fromList(bytes),
       parentIds = List.unmodifiable(parentIds),
       outputs = List.unmodifiable(outputs);

  factory ScV2TransactionSemantics.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final semanticsHex = json['semantics'];
    final inputSigHash = json['inputSigHash'];
    final inputCount = json['inputCount'];
    final byteLength = json['byteLength'];
    final parentIdsJson = json['parentIds'];
    final outputsJson = json['outputs'];
    final minerFee = json['minerFee'];
    if (profile != scV2SiacoinTransferProfile ||
        semanticsHex is! String ||
        inputSigHash is! String ||
        inputCount is! int ||
        byteLength is! int ||
        parentIdsJson is! List ||
        outputsJson is! List ||
        minerFee is! String) {
      throw const FormatException('Malformed SC V2 semantics response');
    }

    final bytes = Uint8List.fromList(hex.decode(semanticsHex));
    final parentIds = parentIdsJson.map((value) => value as String).toList();
    final outputs = outputsJson
        .map(
          (value) => ScV2SemanticOutput.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();
    final digestPattern = RegExp(r'^[0-9a-f]{64}$');
    final parentPattern = RegExp(r'^[0-9a-f]{64}$');
    if (bytes.length != byteLength ||
        bytes.length > _scV2MaxSemanticBytes ||
        inputCount < 1 ||
        inputCount > _scV2MaxTransferInputs ||
        inputCount != parentIds.length ||
        outputs.isEmpty ||
        outputs.length > _scV2MaxTransferOutputs ||
        !digestPattern.hasMatch(inputSigHash) ||
        parentIds.any(
          (id) =>
              !parentPattern.hasMatch(id) || RegExp(r'^0{64}$').hasMatch(id),
        ) ||
        parentIds.toSet().length != parentIds.length ||
        !RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(minerFee)) {
      throw const FormatException('Inconsistent SC V2 semantics response');
    }

    return ScV2TransactionSemantics(
      profile: profile,
      bytes: bytes,
      inputSigHash: inputSigHash,
      inputCount: inputCount,
      parentIds: parentIds,
      outputs: outputs,
      minerFee: BigInt.parse(minerFee),
    );
  }

  List<ScV2SemanticOutput> get changeOutputs =>
      List.unmodifiable(outputs.where((output) => output.isChange));

  List<ScV2SemanticOutput> get externalOutputs =>
      List.unmodifiable(outputs.where((output) => !output.isChange));

  Map<String, dynamic> toJson() => {
    'profile': profile,
    'semantics': hex.encode(bytes),
    'inputSigHash': inputSigHash,
    'inputCount': inputCount,
    'parentIds': parentIds,
    'outputs': outputs.map((output) => output.toJson()).toList(),
    'minerFee': minerFee.toString(),
    'byteLength': bytes.length,
  };
}
