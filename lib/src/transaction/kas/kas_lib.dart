class Input {
  PreviousOutpoint previousOutpoint;
  String signatureScript;
  String sequence;
  int sigOpCount;

  Input({
    required this.previousOutpoint,
    required this.signatureScript,
    required this.sequence,
    required this.sigOpCount,
  });

  factory Input.fromJson(Map<String, dynamic> json) {
    return Input(
      previousOutpoint: PreviousOutpoint.fromJson(json['previousOutpoint']),
      signatureScript: json['signatureScript'],
      sequence: json['sequence'],
      sigOpCount: json['sigOpCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'previousOutpoint': previousOutpoint.toJson(),
      'signatureScript': signatureScript,
      'sequence': sequence,
      'sigOpCount': sigOpCount
    };
  }
}

class PreviousOutpoint {
  String transactionId;
  int index;

  PreviousOutpoint({
    required this.transactionId,
    required this.index,
  });

  factory PreviousOutpoint.fromJson(Map<String, dynamic> json) {
    return PreviousOutpoint(
      transactionId: json['transactionId'],
      index: json['index'],
    );
  }
  Map<String, dynamic> toJson() {
    return {'transactionId': transactionId, 'index': index};
  }
}

class Output {
  ScriptPublicKey scriptPublicKey;
  int amount;

  Output({
    required this.scriptPublicKey,
    required this.amount,
  });

  factory Output.fromJson(Map<String, dynamic> json) {
    return Output(
      scriptPublicKey: ScriptPublicKey.fromJson(json['scriptPublicKey']),
      amount: json['amount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'scriptPublicKey': scriptPublicKey.toJson(), 'amount': amount};
  }
}

class ScriptPublicKey {
  int version;
  String scriptPublicKey;

  ScriptPublicKey({
    required this.version,
    required this.scriptPublicKey,
  });

  factory ScriptPublicKey.fromJson(Map<String, dynamic> json) {
    return ScriptPublicKey(
      version: json['version'],
      scriptPublicKey: json['scriptPublicKey'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'version': version, 'scriptPublicKey': scriptPublicKey};
  }
}
