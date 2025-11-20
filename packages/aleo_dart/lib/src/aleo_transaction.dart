import 'package:aleo_dart/src/aleo_record.dart';

class TransferMethod {
  static const String public = 'transfer_public';
  static const String public_to_private = 'transfer_public_to_private';
  static const String private = 'transfer_private';
  static const String private_to_public = 'transfer_private_to_public';
  static const String join = 'join';
  static const String split = 'split';
  static const String contract = 'contract';
  static const String upgrade = 'upgrade';
}

class ContractMethod {
  static const String stake = 'stake';
  static const String withdraw = 'withdraw';
  static const String claim = 'claim';
}

class FeeType {
  static const String public = 'fee_public';
  static const String private = 'fee_private';
}

class TransferType {
  static const String income = 'income';
  static const String expense = 'expense';
}

class FunctionName {
  static const String deposit = 'deposit_public_as_signer';
  static const String instant_withdraw_public_signer =
      'instant_withdraw_public_signer';
  static const String mint = 'mint_public';
  static const String burn = 'burn_public';
  static const String transfer = 'transfer_public';
  static const String transfer_as_signer = 'transfer_public_as_signer';
  static const String stake_public = 'stake_public';
  static const String withdraw = 'withdraw';
  static const String transfer_public = 'transfer_public';
}

class ProgramName {
  static const String credits = 'credits.aleo';
  static const String pondo = 'pondo_protocol.aleo';
  static const String tokenRegistry = 'token_registry.aleo';
  static const String betastaking = 'betastaking.aleo';
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

class TokenTransfer {
  String transferType;
  String value;
  int decimal = 6;
  String symbol = '';
  TokenTransfer({
    required this.transferType,
    required this.value,
    required this.symbol,
  });

  Map<String, dynamic> toJson() {
    return {
      'transferType': transferType,
      'value': value,
      'symbol': symbol,
    };
  }
}

class SendMessage {
  String record;

  String senderCiphertext;
  SendMessage({
    required this.record,
    required this.senderCiphertext,
  });

  static SendMessage? getSendMessage(List<dynamic> outputs) {
    try {
      final output = outputs[0];
      return SendMessage(
          record: output['value'],
          senderCiphertext: output['sender_ciphertext']);
    } catch (e) {
      return null;
    }
  }

  toJson() {
    return {
      'record': record,
      'senderCiphertext': senderCiphertext,
    };
  }
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
  SendMessage? sendMessage;
  int? height;
  int? timestamp;
  List<TokenTransfer> tokenTransfers = [];
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
      this.tokenTransfers = const [],
      this.height,
      this.timestamp,
      this.sendMessage});

  factory AleoTransaction.fromJson(Map<String, dynamic> jsonRaw,
      {List<String> programs = const [], String address = ''}) {
    final json = jsonRaw['transaction'];
    final type = json['type'];
    final transactionId = json['id'];
    final transition = json['execution']['transitions'][0];
    final feeTx = json['fee'] != null ? json['fee']['transition'] : null;
    final feeType = feeTx != null ? feeTx['function'] : '';
    final List<String> transitionIds = [
      transition['id'].toString(),
      feeTx != null ? feeTx['id'].toString() : ''
    ];
    String program = transition['program'];
    String transitionType = transition['function'];
    final txOutput = findFuture(transition['outputs']);
    String inputAddress = '';
    String outputAddress = '';
    String value = '';

    FeeDetail feeDetail = getFee(feeTx);
    List<TokenTransfer> tokenTransfers = [];
    SendMessage? sendMessage;

    /// transfer_[inputAddress]_to_[outputAddress], when private in [], this address is '';
    if (program == ProgramName.credits) {
      switch (transitionType) {
        case TransferMethod.private:
        case TransferMethod.join:
          final outputs = transition['outputs'];
          sendMessage = SendMessage.getSendMessage(outputs);
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
        case TransferMethod.upgrade:
          value = getValue(txOutput[0]);
          break;
        default:
          final tokenTransferData = parseTokenTransfer(
              json['execution']['transitions'],
              programs: programs,
              address: address);
          tokenTransfers = tokenTransferData['tokenTransfers'];
          program = tokenTransferData['program'];
          transitionType = TransferMethod.contract;
          if (tokenTransferData['inputAddress'] != '') {
            inputAddress = tokenTransferData['inputAddress'];
          }
          if (tokenTransferData['outputAddress'] != '') {
            outputAddress = tokenTransferData['outputAddress'];
          }
          break;
      }
    } else {
      final tokenTransferData = parseTokenTransfer(
          json['execution']['transitions'],
          programs: programs,
          address: address);
      tokenTransfers = tokenTransferData['tokenTransfers'];
      program = tokenTransferData['program'];
      if (tokenTransferData['inputAddress'] != '') {
        inputAddress = tokenTransferData['inputAddress'];
      }
      if (tokenTransferData['outputAddress'] != '') {
        outputAddress = tokenTransferData['outputAddress'];
      }
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
      timestamp: jsonRaw['timestamp'],
      tokenTransfers: tokenTransfers,
      sendMessage: sendMessage,
    );
  }

  getSymbol(String program) {
    switch (program) {
      case ProgramName.pondo:
        return 'paleo';
      case ProgramName.betastaking:
        return 'staleo';
      default:
        return '';
    }
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
      'fee_record': fee_record,
      'tokenTransfers': tokenTransfers.map((e) => e.toJson()).toList(),
      'sendMessage': sendMessage?.toJson()
    };
  }

  static String getValue(String microcredits) {
    if (microcredits.contains('u64') || microcredits.contains('u128')) {
      return microcredits.split('u')[0];
    } else {
      return '';
    }
  }

  static FeeDetail getFee(feeTx) {
    final function = feeTx != null ? feeTx['function'] : '';
    final inputs = feeTx != null ? feeTx['inputs'] : [];
    final outputs = feeTx != null ? feeTx['outputs'] : [];

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

  static Map<String, dynamic> parseTokenTransfer(List<dynamic> transitions,
      {List<String> programs = const [], String address = ''}) {
    final List<TokenTransfer> tokenTransfers = [];
    String inputAddress = '';
    String outputAddress = '';

    String program = 'contract';
    for (final transition in transitions) {
      if (programs.contains(transition['program'])) {
        program = transition['program'];
      }

      String inputSymbol = '';
      String outputSymbol = '';
      final inputs = transition['inputs'];
      String valueIn = getValue(inputs[1]['value']);
      String valueOut = getValue(inputs[0]['value']);
      switch (transition['program']) {
        case ProgramName.pondo:
          switch (transition['function']) {
            case FunctionName.deposit:
              inputSymbol = "paleo";
              outputSymbol = "aleo";
              break;
            case FunctionName.instant_withdraw_public_signer:
              outputSymbol = "paleo";
              inputSymbol = "aleo";
              break;
            default:
              break;
          }
          if ([
            FunctionName.deposit,
            FunctionName.instant_withdraw_public_signer
          ].contains(transition['function'])) {
            tokenTransfers.add(TokenTransfer(
                transferType: TransferType.income,
                value: valueIn,
                symbol: inputSymbol));
            tokenTransfers.add(TokenTransfer(
                transferType: TransferType.expense,
                value: valueOut,
                symbol: outputSymbol));
          }
          break;
        case ProgramName.betastaking:
          switch (transition['function']) {
            case FunctionName.stake_public:
              inputSymbol = "staleo";
              outputSymbol = "aleo";
              break;
            case FunctionName.withdraw:
              inputSymbol = "aleo";
              outputSymbol = "staleo";
              break;
            default:
              break;
          }
          if ([FunctionName.stake_public, FunctionName.withdraw]
              .contains(transition['function'])) {
            tokenTransfers.add(TokenTransfer(
                transferType: TransferType.income,
                value: valueIn,
                symbol: inputSymbol));
            tokenTransfers.add(TokenTransfer(
                transferType: TransferType.expense,
                value: valueOut,
                symbol: outputSymbol));
          }
          break;
        // 标准token交易解析
        case ProgramName.tokenRegistry:
          switch (transition['function']) {
            case FunctionName.transfer_public:
              // 把argument中拿到数据拿出来
              final arguments = findFuture(transition['outputs']);
              String symbol = '';
              // 前四个值分别是token id, from, amount, to
              final tokenId = arguments[0];
              if (tokenId ==
                  '1751493913335802797273486270793650302076377624243810059080883537084141842600field') {
                symbol = "paleo";
                program = ProgramName.pondo;
              }
              inputAddress = arguments[3];
              outputAddress = arguments[1];


              final amount = arguments[2];
              tokenTransfers.add(TokenTransfer(
                  transferType: address == outputAddress
                      ? TransferType.income
                      : TransferType.expense,
                  value: getValue(amount),
                  symbol: symbol));
          }
          break;
        default:
          break;
      }
    }
    final result = {
      'program': program,
      'tokenTransfers': tokenTransfers,
      'inputAddress': inputAddress,
      'outputAddress': outputAddress
    };
    print(tokenTransfers.map((e) => e.toJson()).toList());
    return result;
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
    if (this.value.contains('record')) {
      final records = this.value.split(",");
      for (final record in records) {
        final isOwner = rust.isOwner(record, viewKey);
        if (isOwner) {
          final recordText = rust.decryptCipherText(record, viewKey);
          this.value = recordText.getMicrocredits();
          break;
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
  List<String> programs;

  TxsResult(
      {required this.recordFFI,
      required this.recordCipherTexts,
      required this.viewKey,
      required this.address,
      List<String>? programs})
      : programs = _initializePrograms(programs);

  // 辅助方法：初始化 programs 列表，默认添加 token_registry.aleo
  static List<String> _initializePrograms(List<String>? programs) {
    final result = programs ?? <String>[];
    const tokenRegistry = 'token_registry.aleo';
    if (!result.contains(tokenRegistry)) {
      return [...result, tokenRegistry];
    }
    return result;
  }

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
          final outTx = AleoTransaction.fromJson(outTxJson, address: address);
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
        final tx = AleoTransaction.fromJson(inTxJson, address: address);
        if (tx.transitionType == TransferMethod.private_to_public) {
          tx.transferType = TransferType.expense;
          txs.add(tx);
          txIds.add(tx.transactionId.toString());
          continue;
        }

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
      final tx = AleoTransaction.fromJson(inTxJson, programs: programs, address: address);
      if (tx.inputAddress == address) {
        tx.transferType = TransferType.expense;
      }
      if (tx.outputAddress == address) {
        tx.transferType = TransferType.income;
      }
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
        case TransferMethod.contract:
          txs.add(tx);
          break;
        default:
          break;
      }
    }
  }

  // 从交易中找出token交易
  getTokenTxs(List<AleoTransaction> txs, String program) {
    final tokenTxs = [];
    for (final tx in txs) {
      // 如果交易类型为contract
      if (tx.transitionType == TransferMethod.contract &&
          tx.program == program) {
        tokenTxs.add(tx);
      }
      // 对于 public 类型的交易，如果已经有 tokenTransfers（比如从 parseTokenTransfer 中解析的），
      // 就不需要再添加了，避免重复
      if (tx.transitionType == TransferMethod.public && 
          tx.program == program && 
          tx.tokenTransfers.isEmpty) {
        tx.tokenTransfers.add(TokenTransfer(
            transferType: tx.transferType,
            value: tx.value,
            symbol: tx.getSymbol(program)));
        tx.value = '';
        tokenTxs.add(tx);
      } else if (tx.transitionType == TransferMethod.public && 
                 tx.program == program && 
                 tx.tokenTransfers.isNotEmpty) {
        // 如果已经有 tokenTransfers，直接添加交易，不需要再创建新的 token transfer
        tokenTxs.add(tx);
      }
    }
    return tokenTxs;
  }

  getSender() {
    for (final tx in txs) {
      if (tx.sendMessage != null) {
        final sender = recordFFI.decryptSenderCiphertext(
            tx.sendMessage?.record ?? '',
            viewKey,
            tx.sendMessage?.senderCiphertext ?? '');
        tx.inputAddress = sender;
      }
    }
  }
}
