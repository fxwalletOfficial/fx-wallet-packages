import 'package:aleo_dart/src/aleo_record.dart';

class TransferMethod {
  static const String public = 'transfer_public';
  static const String public_to_private = 'transfer_public_to_private';
  static const String private = 'transfer_private';
  static const String private_to_public = 'transfer_private_to_public';
}

class FeeType {
  static const String public = 'fee_public';
  static const String private = 'fee_private';
}

class TransferType {
  static const String income = 'income';
  static const String expense = 'expense';
}

class FeeDetail {
  String fee;
  String baseFee;
  String priorityFee;
  String change = '0'; // 找零

  FeeDetail({
    required this.fee,
    required this.baseFee,
    required this.priorityFee,
  });
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
  String baseFee;
  String priorityFee;
  String feeChange = '';
  String change = ''; // 找零
  String transferType = '';
  String amount_record = '';
  String fee_record = '';
  int? height;
  int? timestamp;

  AleoTransaction(
      {required this.type,
      required this.transactionId,
      required this.transitionIds,
      required this.program,
      required this.transitionType,
      required this.inputAddress,
      required this.outputAddress,
      required this.value,
      required this.feeType,
      required this.fee,
      required this.baseFee,
      required this.priorityFee,
      required this.feeChange,
      this.height,
      this.timestamp});

  factory AleoTransaction.fromJson(Map<String, dynamic> jsonRaw) {
    final json = jsonRaw['transaction'];
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
    String inputAddress = '';
    String outputAddress = '';
    String value = '';

    FeeDetail feeDetail = getFee(feeTx);

    /// transfer_[inputAddress]_to_[outputAddress], when private in [], this address is '';
    switch (transitionType) {
      case TransferMethod.private:
        final outputs = transition['outputs'];
        value = outputs
            .map((e) => e['value'])
            .toString()
            .replaceAll('(', '')
            .replaceAll(')', '')
            .replaceAll(' ', '');
        break;
      case TransferMethod.private_to_public:
        outputAddress = txOutput[0];
        value = getValue(txOutput[1]); // input is private.
        break;
      case TransferMethod.public:
        inputAddress = txOutput[0];
        outputAddress = txOutput[1];
        value = getValue(txOutput[2]);
        break;
      case TransferMethod.public_to_private:
        inputAddress = txOutput[0];
        value = getValue(txOutput[1]); // output is private, can not get.
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
        fee: feeDetail.fee,
        baseFee: feeDetail.baseFee,
        priorityFee: feeDetail.priorityFee,
        feeChange: feeDetail.change,
        height: jsonRaw['height'],
        timestamp: jsonRaw['timestamp']);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'height': height,
      'timestamp': timestamp,
      'transactionId': transactionId,
      'transitionIds': transitionIds,
      'program': program,
      'transitionType': transitionType,
      'inputAddress': inputAddress,
      'outputAddress': outputAddress,
      'value': value,
      'feeType': feeType,
      'fee': fee,
      'baseFee': baseFee,
      'priorityFee': priorityFee,
      'transferType': transferType,
      'change': change,
      'feeChange': feeChange,
      'amount_record': amount_record,
      'fee_record': fee_record
    };
  }

  static String getValue(String microcredits) {
    if (microcredits.contains('u64')) {
      return microcredits.split('u')[0];
    } else {
      return '';
    }
  }

  static FeeDetail getFee(feeTx) {
    final function = feeTx['function'];
    final inputs = feeTx['inputs'];
    final outputs = feeTx['outputs'];

    String baseFee = '0';
    String priorityFee = '0';
    String fee = '0';

    switch (function) {
      case FeeType.private:
        baseFee = getValue(inputs[1]['value']);
        priorityFee = getValue(inputs[2]['value']);
        fee = (int.parse(priorityFee) + int.parse(baseFee)).toString();

        final feeDetail =
            FeeDetail(baseFee: baseFee, priorityFee: priorityFee, fee: fee);
        feeDetail.change = outputs[0]['value'];
        return feeDetail;
      case FeeType.public:
        baseFee = getValue(inputs[0]['value']);
        priorityFee = getValue(inputs[1]['value']);
        fee = (int.parse(priorityFee) + int.parse(baseFee)).toString();

        return FeeDetail(baseFee: baseFee, priorityFee: priorityFee, fee: fee);
      default:
        return FeeDetail(baseFee: baseFee, priorityFee: priorityFee, fee: fee);
    }
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
        int argumentsIndex = value.indexOf('arguments:');
        String argumentsString =
            value.substring(argumentsIndex + 'arguments:'.length);
        return argumentsString.split(',');
      }
    }
  }

  static findInputRecord(List<dynamic> inputs) {
    for (final input in inputs) {
      if (input['type'] == 'record') {
        return input['id'];
      }
    }
    return '';
  }

  static findRecordValue(List<dynamic> inputs) {
    for (final input in inputs) {
      if (input['type'] == 'record') {
        return input['value'];
      }
    }
    return '';
  }

  /// 解析outputs中，属于该地址的部分，作为value。
  processPrivateTx(AleoRecord rust, String viewKey, String privateKey,
      Map<String, dynamic> json, List<String> recordCipherTexts) {
    if (this.transitionType == TransferMethod.private) {
      final amountRecordId =
          findInputRecord(json['execution']['transitions'][0]['inputs']);
      final feeRecordId = findInputRecord(json['fee']['transition']['inputs']);

      /// 处理fee找零
      if (this.feeType == FeeType.private && this.feeChange != '0') {
        final isOwner = rust.isOwner(this.feeChange, viewKey);
        if (isOwner) {
          final feeRecord = rust.decryptCipherText(this.feeChange, viewKey);
          this.feeChange = feeRecord.getMicrocredits();
        }
      }

      for (final recordCipherText in recordCipherTexts) {
        final isOwner = rust.isOwner(recordCipherText, viewKey);
        if (!isOwner) continue;
        final numberString =
            rust.serialNumberString(recordCipherText, privateKey);
        if (numberString == amountRecordId) {
          this.amount_record = recordCipherText;
        }
        if (numberString == feeRecordId) {
          this.fee_record = recordCipherText;
        }
      }
      if (this.transferType == TransferType.expense) {
        if (this.amount_record != '') {
          final record = rust.decryptCipherText(this.amount_record, viewKey);
          this.value = record.getMicrocredits();
          for (final output in json['execution']['transitions'][0]['outputs']) {
            if (output['type'] == 'record') {
              final recordCipherText = output['value'];
              if (rust.isOwner(recordCipherText, viewKey)) {
                final recordPlainText =
                    rust.decryptCipherText(recordCipherText, viewKey);
                this.change = recordPlainText.getMicrocredits();
                this.value =
                    (BigInt.parse(this.value) - BigInt.parse(this.change))
                        .toString();
              }
            }
          }
        } else {
          final records = this.value.split(',');
          BigInt income = BigInt.from(0);
          for (final record in records) {
            if (rust.isOwner(record, viewKey)) {
              final RecordPlainText recordPlainText =
                  rust.decryptCipherText(record, viewKey);
              income += BigInt.parse(recordPlainText.getMicrocredits());
            }
          }
          this.value = income.toString();
        }
      }
    }
  }
}

class TxsResult {
  List<String> txIds = [];
  List<AleoTransaction> txs = [];
  String privateBalance = '0';
  AleoRecord recordFFI;
  List<String> recordCipherTexts;
  String viewKey;
  String address;

  TxsResult(
      {required this.recordFFI,
      required this.recordCipherTexts,
      required this.viewKey,
      required this.address});

  getOutputTxs(
    List<dynamic> transactions,
    String privateKey,
  ) {
    BigInt privateBalance = BigInt.from(0);

    for (final outTxJson in transactions) {
      if (outTxJson['transaction'] == null) {
        /// 交易详情为空时，说明该record未被使用，加入余额
        final recordCipherText = recordFFI.findRecord(
            recordCipherTexts, outTxJson['serialNumber'], privateKey, viewKey);
        if (recordCipherText == '') continue;
        final RecordPlainText record =
            recordFFI.decryptCipherText(recordCipherText, viewKey);
        privateBalance += BigInt.parse(record.getMicrocredits());
      } else {
        final transactionId = outTxJson['transaction']['id'];
        if (!txIds.contains(transactionId)) {
          final outTx = AleoTransaction.fromJson(outTxJson);
          outTx.transferType = TransferType.expense;
          outTx.processPrivateTx(recordFFI, viewKey, privateKey,
              outTxJson['transaction'], recordCipherTexts);
          txs.add(outTx);
          txIds.add(outTx.transactionId);
          outTx.inputAddress = address;
        } // 包含时，说明有两个record被用作同个交易。即用了 fee_private
      }
    }
    this.privateBalance = privateBalance.toString();
  }

  getInputTxs(
    List<dynamic> inTxsJson,
    String privateKey,
  ) {
    for (final inTxJson in inTxsJson) {
      final transactionId = inTxJson['transaction']['id'];
      if (!txIds.contains(transactionId)) {
        final tx = AleoTransaction.fromJson(inTxJson);
        tx.processPrivateTx(recordFFI, viewKey, privateKey,
            inTxJson['transaction'], recordCipherTexts);
        tx.transferType = TransferType.income;
        txs.add(tx);
        txIds.add(tx.transactionId.toString());
        tx.outputAddress = address;
      }
    }
  }

  getPublicTxs(List<dynamic> inTxsJson) {
    if (recordCipherTexts.length != 0) {
      throw Exception('Unsupport record in public txs');
    }
    for (final inTxJson in inTxsJson) {
      final tx = AleoTransaction.fromJson(inTxJson);
      switch (tx.transitionType) {
        case TransferMethod.public_to_private:
          final outputs =
              inTxJson['transaction']['execution']['transitions'][0]['outputs'];
          final record = AleoTransaction.findRecordValue(outputs);
          if (!recordFFI.isOwner(record, viewKey)) {
            txs.add(tx);
          }
          break;
        case TransferMethod.private_to_public:
          txs.add(tx);
          break;
        case TransferMethod.public:
          txs.add(tx);
          break;
        default:
          break;
      }
    }
  }
}
