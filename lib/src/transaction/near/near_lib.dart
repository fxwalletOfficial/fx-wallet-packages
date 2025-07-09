class PublicKey {
  int keyType;
  String data;

  PublicKey({required this.keyType, required this.data});

  factory PublicKey.fromJson(Map<String, dynamic> json) {
    return PublicKey(
      keyType: json['keyType'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyType': keyType,
      'data': data,
    };
  }
}

/// near transaction action type, require [Transfer] or [FunctionCall] and [enumValue]. 
class Action {
  Transfer? transfer;
  FunctionCall? functionCall;
  String enumValue;

  Action({required this.enumValue, this.transfer, this.functionCall});

  factory Action.fromJson(Map<String, dynamic> json) {
    if (json['enum'] == NearTransferType.transfer) {
      return Action(
        transfer: Transfer.fromJson(json['transfer']),
        enumValue: json['enum'],
      );
    }
    if (json['enum'] == NearTransferType.functionCall) {
      return Action(
        functionCall: FunctionCall.fromJson(json['functionCall']),
        enumValue: json['enum'],
      );
    }
    return Action(enumValue: 'errorType');
  }

  Map<String, dynamic> toJson() {
    if (enumValue == NearTransferType.transfer) {
      return {
        'transfer': transfer!.toJson(),
        'enum': enumValue,
      };
    }
    if (enumValue == NearTransferType.functionCall) {
      return {
        'functionCall': functionCall!.toJson(),
        'enum': enumValue,
      };
    }
    return {};
  }
}

class NearTransferType {
  static final functionCall = 'functionCall';
  static final transfer = 'transfer';
}

class Transfer {
  String deposit;

  Transfer({required this.deposit});

  factory Transfer.fromJson(Map<String, dynamic> json) {
    return Transfer(
      deposit: json['deposit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deposit': deposit,
    };
  }
}

class FunctionCall {
  String methodName;
  String args;
  int gas;
  String deposit;

  FunctionCall(
      {required this.methodName,
      required this.args,
      required this.gas,
      required this.deposit});

  factory FunctionCall.fromJson(Map<String, dynamic> json) {
    return FunctionCall(
      methodName: json['methodName'],
      args: json['args'],
      gas: json['gas'],
      deposit: json['deposit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'methodName': methodName,
      'args': args,
      'gas': gas,
      'deposit': deposit,
    };
  }
}

class Transaction {
  String signerId;
  PublicKey publicKey;
  String nonce;
  String receiverId;
  List<Action> actions;
  String blockHash;

  Transaction({
    required this.signerId,
    required this.publicKey,
    required this.nonce,
    required this.receiverId,
    required this.actions,
    required this.blockHash,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      signerId: json['signerId'],
      publicKey: PublicKey.fromJson(json['publicKey']),
      nonce: json['nonce'],
      receiverId: json['receiverId'],
      actions:
          (json['actions'] as List).map((e) => Action.fromJson(e)).toList(),
      blockHash: json['blockHash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'signerId': signerId,
      'publicKey': publicKey.toJson(),
      'nonce': nonce,
      'receiverId': receiverId,
      'actions': actions.map((action) => action.toJson()).toList(),
      'blockHash': blockHash,
    };
  }
}
