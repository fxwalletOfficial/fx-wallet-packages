class TransferType {
  static const String public = 'transfer_public';
  static const String public_to_private = 'transfer_public_to_private';
  static const String private = 'transfer_private';
  static const String private_to_public = 'transfer_private_to_public';
}

class FeeType {
  static const String public = 'fee_public';
  static const String private = 'fee_private';
}

class AleoTransaction {
  String type;
  String transactionId;
  List<String> transitionIds;
  String program;
  String transitionType;
  String inputAddress;
  String outputAddress;
  String value;
  String feeType;
  String fee;
  String change = ''; // 找零
  String transferType = '';

  AleoTransaction({
    required this.type,
    required this.transactionId,
    required this.transitionIds,
    required this.program,
    required this.transitionType,
    required this.inputAddress,
    required this.outputAddress,
    required this.value,
    required this.feeType,
    required this.fee,
  });

  factory AleoTransaction.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    final transactionId = json['id'];
    final transition = json['execution']['transitions'][0];
    final feeTx = json['fee']['transition'];
    final feeType = feeTx['function'];
    final List<String> transitionIds = [
      transition['id'].toString(),
      feeTx['id'].toString()
    ];
    final program = transition['program'];
    final String transitionType = transition['function'];
    final txOutput = findFuture(transition['outputs']);
    final feeOutput = findFuture(feeTx['outputs']);

    String inputAddress = '';
    String outputAddress = '';
    String value = '';
    String fee = '';

    /// transfer_[inputAddress]_to_[outputAddress], when private in [], this address is '';
    switch (transitionType) {
      case TransferType.private:
        final outputs = transition['outputs'];
        value = outputs
            .map((e) => e['value'])
            .toString()
            .replaceAll('(', '')
            .replaceAll(')', '')
            .replaceAll(' ', '');
        break;
      case TransferType.private_to_public:
        outputAddress = txOutput[0];
        value = txOutput[1].split('u')[0]; // input is private.
        if (feeType == FeeType.public) {
          fee = feeOutput[1].split('u')[0]; // fee is private, fee = ''
        }
        break;
      case TransferType.public:
        inputAddress = txOutput[0];
        outputAddress = txOutput[1];
        value = txOutput[2].split('u')[0];
        fee = feeOutput[1].split('u')[0];
        break;
      case TransferType.public_to_private:
        inputAddress = txOutput[0];
        value = txOutput[1].split('u')[0]; // output is private, can not get.
        fee = feeOutput[1].split('u')[0];
        break;
      default:
        break;
    }

    return AleoTransaction(
      type: type,
      transactionId: transactionId,
      transitionIds: transitionIds,
      program: program,
      transitionType: transitionType,
      inputAddress: inputAddress,
      outputAddress: outputAddress,
      value: value,
      feeType: feeType,
      fee: fee,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'transactionId': transactionId,
      'transitionIds': transitionIds,
      'program': program,
      'transitionType': transitionType,
      'inputAddress': inputAddress,
      'outputAddress': outputAddress,
      'value': value,
      'feeType': feeType,
      'fee': fee,
      'transferType': transferType
    };
  }

  static findFuture(List<dynamic> outputs) {
    for (final output in outputs) {
      if (output['type'] == 'future') {
        final value = output['value']
            .replaceAll('\n', '')
            .replaceAll(' ', '')
            .replaceAll('{', '')
            .replaceAll('}', '')
            .replaceAll('[', '')
            .replaceAll(']', '');
        int argumentsIndex = value.indexOf("arguments:");
        String argumentsString =
            value.substring(argumentsIndex + "arguments:".length);
        return argumentsString.split(',');
      }
    }
  }
}
