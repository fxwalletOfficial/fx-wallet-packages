/// Result from the SC WASM after processing a [ScUnsignedTransaction].
///
/// The WASM returns the transaction JSON with signing digests pre-filled in
/// `siacoinInputs[].satisfiedPolicy.signatures[0]` (first 64 hex chars = digest).
class ScWasmResult {
  /// The full transaction JSON returned by the WASM.
  /// Same structure as [ScUnsignedTransaction] with computed digests.
  final Map<String, dynamic> transaction;

  /// Hex-encoded digests to be signed, one per siacoinInput.
  /// Extracted from `satisfiedPolicy.signatures[0].substring(0, 64)`.
  final List<String> toSign;

  ScWasmResult({
    required this.transaction,
    required this.toSign,
  });

  factory ScWasmResult.fromJson(Map<String, dynamic> json) {
    final List<String> toSign = [];
    final inputs = (json['siacoinInputs'] as List<dynamic>?) ?? [];
    for (final input in inputs) {
      final sigs =
          (input['satisfiedPolicy']['signatures'] as List<dynamic>?) ?? [];
      if (sigs.isNotEmpty) {
        // First 64 hex chars = the 32-byte signing digest
        toSign.add((sigs.first as String).substring(0, 64));
      }
    }
    return ScWasmResult(
      transaction: Map<String, dynamic>.from(json),
      toSign: toSign,
    );
  }
}

/// Raw unsigned transaction input for the SC WASM module (`sc.wasm`).
///
/// Contains merkle proofs and raw addresses, before the WASM computes signing
/// digests via `getUnsignedV2Transaction`.
class ScUnsignedTransaction {
  final List<ScUnsignedSiacoinInput> siacoinInputs;
  final List<ScUnsignedSiacoinOutput> siacoinOutputs;
  final String minerFee;

  ScUnsignedTransaction({
    this.siacoinInputs = const [],
    this.siacoinOutputs = const [],
    required this.minerFee,
  });

  factory ScUnsignedTransaction.fromJson(Map<String, dynamic> json) {
    return ScUnsignedTransaction(
      siacoinInputs: (json['siacoinInputs'] as List? ?? [])
          .map((item) => ScUnsignedSiacoinInput.fromJson(item))
          .toList(),
      siacoinOutputs: (json['siacoinOutputs'] as List? ?? [])
          .map((item) => ScUnsignedSiacoinOutput.fromJson(item))
          .toList(),
      minerFee: '${json['minerFee']}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'siacoinInputs': siacoinInputs.map((item) => item.toJson()).toList(),
      'siacoinOutputs': siacoinOutputs.map((item) => item.toJson()).toList(),
      'minerFee': minerFee,
    };
  }
}

class ScUnsignedSiacoinInput {
  final ScUnsignedParent parent;
  final ScSatisfiedPolicy satisfiedPolicy;

  ScUnsignedSiacoinInput({
    required this.parent,
    required this.satisfiedPolicy,
  });

  factory ScUnsignedSiacoinInput.fromJson(Map<String, dynamic> json) {
    return ScUnsignedSiacoinInput(
      parent: ScUnsignedParent.fromJson(json['parent'] ?? {}),
      satisfiedPolicy:
          ScSatisfiedPolicy.fromJson(json['satisfiedPolicy'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent': parent.toJson(),
      'satisfiedPolicy': satisfiedPolicy.toJson(),
    };
  }
}

class ScUnsignedParent {
  final String id;
  final ScStateElement stateElement;
  final ScUnsignedSiacoinOutput siacoinOutput;

  ScUnsignedParent({
    required this.id,
    required this.stateElement,
    required this.siacoinOutput,
  });

  factory ScUnsignedParent.fromJson(Map<String, dynamic> json) {
    return ScUnsignedParent(
      id: json['id'] ?? '',
      stateElement: ScStateElement.fromJson(json['stateElement'] ?? {}),
      siacoinOutput:
          ScUnsignedSiacoinOutput.fromJson(json['siacoinOutput'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stateElement': stateElement.toJson(),
      'siacoinOutput': siacoinOutput.toJson(),
    };
  }
}

class ScStateElement {
  final int leafIndex;
  final List<String> merkleProof;

  ScStateElement({
    required this.leafIndex,
    this.merkleProof = const [],
  });

  factory ScStateElement.fromJson(Map<String, dynamic> json) {
    return ScStateElement(
      leafIndex: json['leafIndex'] ?? 0,
      merkleProof: (json['merkleProof'] as List? ?? [])
          .map((item) => '$item')
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leafIndex': leafIndex,
      'merkleProof': merkleProof,
    };
  }
}

class ScUnsignedSiacoinOutput {
  final String value;
  final String address;

  ScUnsignedSiacoinOutput({
    required this.value,
    required this.address,
  });

  factory ScUnsignedSiacoinOutput.fromJson(Map<String, dynamic> json) {
    return ScUnsignedSiacoinOutput(
      value: '${json['value']}',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'address': address,
    };
  }
}

class ScSatisfiedPolicy {
  final ScPolicy policy;
  final List<String> signatures;

  ScSatisfiedPolicy({
    required this.policy,
    this.signatures = const [],
  });

  factory ScSatisfiedPolicy.fromJson(Map<String, dynamic> json) {
    return ScSatisfiedPolicy(
      policy: ScPolicy.fromJson(json['policy'] ?? {}),
      signatures:
          (json['signatures'] as List? ?? []).map((item) => '$item').toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'policy': policy.toJson(),
      'signatures': signatures,
    };
  }
}

class ScPolicy {
  final String type;
  final ScPolicyDetail policy;

  ScPolicy({
    required this.type,
    required this.policy,
  });

  factory ScPolicy.fromJson(Map<String, dynamic> json) {
    return ScPolicy(
      type: json['type'] ?? '',
      policy: ScPolicyDetail.fromJson(json['policy'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'policy': policy.toJson(),
    };
  }
}

class ScPolicyDetail {
  final int timelock;
  final List<String> publicKeys;
  final int signaturesRequired;

  ScPolicyDetail({
    this.timelock = 0,
    this.publicKeys = const [],
    this.signaturesRequired = 1,
  });

  factory ScPolicyDetail.fromJson(Map<String, dynamic> json) {
    return ScPolicyDetail(
      timelock: json['timelock'] ?? 0,
      publicKeys: (json['publicKeys'] as List? ?? [])
          .map((item) => '$item')
          .toList(),
      signaturesRequired: json['signaturesRequired'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timelock': timelock,
      'publicKeys': publicKeys,
      'signaturesRequired': signaturesRequired,
    };
  }
}

