/// Data models for SCP (SiaCoin Prime) transactions.
///
/// The unsigned transaction structure differs from SC: uses `parentID` +
/// `unlockConditions` instead of `parent` + `satisfiedPolicy`, and has
/// `transactionSignatures`, `minerFees` (array), and `arbitraryData` fields.

/// Result after computing signing digests for an [ScpUnsignedTransaction].
class ScpDigestResult {
  /// The original unsigned transaction map.
  final Map<String, dynamic> transaction;

  /// Hex-encoded digests to be signed, one per [transactionSignatures] entry.
  final List<String> toSign;

  ScpDigestResult({
    required this.transaction,
    required this.toSign,
  });
}

/// Raw unsigned transaction input from the SCP API.
class ScpUnsignedTransaction {
  final List<ScpSiacoinInput> siacoinInputs;
  final List<ScpSiacoinOutput> siacoinOutputs;
  final List<String> minerFees;
  final List<ScpTransactionSignature> transactionSignatures;
  final List<String> arbitraryData;

  ScpUnsignedTransaction({
    this.siacoinInputs = const [],
    this.siacoinOutputs = const [],
    this.minerFees = const [],
    this.transactionSignatures = const [],
    this.arbitraryData = const [],
  });

  factory ScpUnsignedTransaction.fromJson(Map<String, dynamic> json) {
    return ScpUnsignedTransaction(
      siacoinInputs: (json['siacoinInputs'] as List? ?? [])
          .map((item) => ScpSiacoinInput.fromJson(item))
          .toList(),
      siacoinOutputs: (json['siacoinOutputs'] as List? ?? [])
          .map((item) => ScpSiacoinOutput.fromJson(item))
          .toList(),
      minerFees: (json['minerFees'] as List? ?? [])
          .map((item) => '$item')
          .toList(),
      transactionSignatures: (json['transactionSignatures'] as List? ?? [])
          .map((item) => ScpTransactionSignature.fromJson(item))
          .toList(),
      arbitraryData: (json['arbitraryData'] as List? ?? [])
          .map((item) => '$item')
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'siacoinInputs': siacoinInputs.map((item) => item.toJson()).toList(),
      'siacoinOutputs': siacoinOutputs.map((item) => item.toJson()).toList(),
      'minerFees': minerFees,
      'transactionSignatures':
          transactionSignatures.map((item) => item.toJson()).toList(),
      'arbitraryData': arbitraryData,
    };
  }
}

class ScpSiacoinInput {
  final String parentID;
  final ScpUnlockConditions unlockConditions;

  ScpSiacoinInput({
    required this.parentID,
    required this.unlockConditions,
  });

  factory ScpSiacoinInput.fromJson(Map<String, dynamic> json) {
    return ScpSiacoinInput(
      parentID: json['parentID'] ?? '',
      unlockConditions:
          ScpUnlockConditions.fromJson(json['unlockConditions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parentID': parentID,
      'unlockConditions': unlockConditions.toJson(),
    };
  }
}

class ScpUnlockConditions {
  final int timelock;
  final List<String> publicKeys;
  final int signaturesRequired;

  ScpUnlockConditions({
    this.timelock = 0,
    this.publicKeys = const [],
    this.signaturesRequired = 1,
  });

  factory ScpUnlockConditions.fromJson(Map<String, dynamic> json) {
    return ScpUnlockConditions(
      timelock: json['timelock'] ?? json['timeLock'] ?? 0,
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

class ScpSiacoinOutput {
  final String value;
  final String unlockHash;

  ScpSiacoinOutput({
    required this.value,
    required this.unlockHash,
  });

  factory ScpSiacoinOutput.fromJson(Map<String, dynamic> json) {
    return ScpSiacoinOutput(
      value: '${json['value']}',
      unlockHash: json['unlockHash'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unlockHash': unlockHash,
    };
  }
}

class ScpTransactionSignature {
  final String parentID;
  final int publicKeyIndex;
  final ScpCoveredFields coveredFields;
  final String signature;

  ScpTransactionSignature({
    required this.parentID,
    this.publicKeyIndex = 0,
    ScpCoveredFields? coveredFields,
    this.signature = '',
  }) : coveredFields = coveredFields ?? ScpCoveredFields(wholeTransaction: true);

  factory ScpTransactionSignature.fromJson(Map<String, dynamic> json) {
    return ScpTransactionSignature(
      parentID: json['parentID'] ?? '',
      publicKeyIndex: json['publicKeyIndex'] ?? 0,
      coveredFields: ScpCoveredFields.fromJson(json['coveredFields'] ?? {}),
      signature: json['signature'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'parentID': parentID,
      'publicKeyIndex': publicKeyIndex,
      'coveredFields': coveredFields.toJson(),
    };
    if (signature.isNotEmpty) {
      map['signature'] = signature;
    }
    return map;
  }
}

class ScpCoveredFields {
  final bool wholeTransaction;

  ScpCoveredFields({this.wholeTransaction = true});

  factory ScpCoveredFields.fromJson(Map<String, dynamic> json) {
    return ScpCoveredFields(
      wholeTransaction: json['wholeTransaction'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'wholeTransaction': wholeTransaction};
  }
}
