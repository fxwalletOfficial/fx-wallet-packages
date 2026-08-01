import 'dart:typed_data';

import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/src/utils/script.dart'
    as bscript;

import '../transaction/script_signature.dart';
import '../transaction/transaction_input.dart';
import '../transaction/transaction_output.dart';
import '../utils/address_type.dart';
import '../utils/converter.dart';
import '../utils/varints.dart';

const int _sighashDefault = 0x00;
const int _sighashAll = 0x01;
const int _sighashNone = 0x02;
const int _sighashSingle = 0x03;
const int _sighashAnyoneCanPay = 0x80;
const int _sighashOutputMask = 0x03;
const int _sighashInputMask = 0x80;

/// Represents a transaction.
class Transaction {
  Uint8List _version;
  List<TransactionInput> _inputs;
  List<TransactionOutput> _outputs;
  Uint8List _lockTime;
  late bool _isSegwit;

  setIsSegwit(bool isSegwit) {
    _isSegwit = isSegwit;
  }

  /// Get the version of the transaction.
  String get version => Converter.bytesToHex(_version);

  /// Get the inputs of the transaction.
  List<TransactionInput> get inputs => _inputs;

  /// Get the outputs of the transaction.
  List<TransactionOutput> get outputs => _outputs;

  /// Get the lock time of the transaction.
  String get lockTime => Converter.bytesToHex(_lockTime);

  /// Get the transaction hash.
  String get transactionHash {
    String hash = sha256fromHex(sha256fromHex(serializeLegacy()));
    String littleEndian = Converter.toLittleEndian(hash);
    return littleEndian;
  }

  /// Get the length of the transaction.
  int get length => () {
        int total = 0;
        total += _version.length;
        if (_isSegwit) {
          total += 2;
        }
        total += Varints.encode(_inputs.length).length;
        for (TransactionInput input in _inputs) {
          total += input.length;
        }
        total += Varints.encode(_outputs.length).length;
        for (TransactionOutput output in _outputs) {
          total += output.length;
        }
        total += _lockTime.length;
        return total;
      }();

  /// Get the length of the witness.
  int get witnessLength => () {
        int total = 0;
        int witnessCount = 0;
        for (int i = 0; i < _inputs.length; i++) {
          Converter.bytesToHex(Varints.encode(inputs[i].witness.length));
          witnessCount += inputs[i].witness.length;
        }
        total += Varints.encode(witnessCount).length;
        for (TransactionInput input in _inputs) {
          total += input.witnessLength;
        }
        return total;
      }();

  /// @nodoc
  Transaction(this._version, this._inputs, this._outputs, this._lockTime,
      this._isSegwit);

  /// Create a transaction for sending Bitcoin.
  factory Transaction.forSending(List<TransactionInput> inputs,
      List<TransactionOutput> outputs, bool isSegwit,
      {int version = 2, int lockTime = 0}) {
    return Transaction(Converter.intToLittleEndianBytes(version, 4), inputs,
        outputs, Converter.intToLittleEndianBytes(lockTime, 4), isSegwit);
  }

  /// Create a transaction for sending all Bitcoin in the wallet.
  factory Transaction.forMaximumSending(
      List<TransactionInput> inputs,
      String receiverAddress,
      int inputAmount,
      bool isSegwit,
      int feeRatePerByte,
      {int version = 2,
      int lockTime = 0}) {
    TransactionOutput output =
        TransactionOutput.forSending(inputAmount, receiverAddress);
    Transaction tx = Transaction.forSending(inputs, [output], isSegwit,
        version: version, lockTime: lockTime);
    int fee = tx.estimateFee(feeRatePerByte);

    if (fee < tx.getVirtualByte()) {
      fee = tx.getVirtualByte().ceil();
    }

    output.setAmount(inputAmount - fee);

    if (fee > inputAmount) {
      throw Exception('Insufficient amount. Estimated fee is $fee');
    }

    return tx;
  }

  /// Parse the transaction.
  factory Transaction.parse(String transaction,
      {bool isEmptySignature = false}) {
    Uint8List txBytes = Converter.hexToBytes(transaction);

    Uint8List sublist = txBytes.sublist(4);
    // Uint8List version = sublist;
    // Uint8List marker = txBytes.sublist(4, 5);
    // Uint8List flag = txBytes.sublist(5, 6);
    // bool isSegwit = (marker[0] == 0x00 && flag[0] == 0x01);
    bool isSegwit = sublist[0] == 0x00;
    // Move the pointer back by 5 bytes
    //sublist = txBytes.sublist(0, txBytes.length - 5);
    if (isSegwit) {
      return Transaction._parseSegwit(txBytes);
    } else {
      return Transaction._parseLegacy(txBytes, isEmptySignature);
    }
  }

  factory Transaction._parseSegwit(Uint8List txBytes) {
    int offset = 0;
    Uint8List version = txBytes.sublist(0, 4);
    offset += 4;
    Uint8List marker = txBytes.sublist(offset, offset + 2);
    offset += 2;
    if (!(marker[0] == 0x00 && marker[1] == 0x01)) {
      throw Exception('Transaction : Not a segwit transaction maker');
    }
    int numInputs = Varints.read(txBytes, offset);
    offset += 1;
    List<TransactionInput> inputs = [];
    for (int i = 0; i < numInputs; i++) {
      TransactionInput input =
          TransactionInput.parse(Converter.bytesToHex(txBytes.sublist(offset)));
      inputs.add(input);
      int size = input.serialize().length ~/ 2;
      offset += size;
    }
    int numOutputs = Varints.read(txBytes, offset);
    offset += 1;
    List<TransactionOutput> outputs = [];
    for (int i = 0; i < numOutputs; i++) {
      TransactionOutput output = TransactionOutput.parse(
          Converter.bytesToHex(txBytes.sublist(offset)));
      outputs.add(output);
      int size = output.serialize().length ~/ 2;
      offset += size;
    }
    //witness
    for (TransactionInput txIn in inputs) {
      int numItems = Varints.read(txBytes, offset++);
      List items = [];
      for (int i = 0; i < numItems; i++) {
        int itemLen = Varints.read(txBytes, offset);
        offset++;
        if (itemLen == 0) {
          items.add(0);
        } else {
          items.add(txBytes.sublist(offset, offset + itemLen));
          offset += itemLen;
        }
      }
      txIn.witness = items;
    }
    Uint8List locktime = txBytes.sublist(offset);
    offset += 4;
    // return Transaction(version, inputs, outputs, locktime,
    //     testnet: testnet, segwit: true);
    return Transaction(version, inputs, outputs, locktime, true);
  }

  factory Transaction._parseLegacy(Uint8List txBytes, bool isEmptySignature) {
    int offset = 0;
    Uint8List version = txBytes.sublist(0, 4);
    offset += 4;
    int numInputs = Varints.read(txBytes, offset);
    offset += 1;
    List<TransactionInput> inputs = [];
    for (int i = 0; i < numInputs; i++) {
      TransactionInput input =
          TransactionInput.parse(Converter.bytesToHex(txBytes.sublist(offset)));
      inputs.add(input);
      int size = input.serialize().length ~/ 2;
      offset += size;
    }

    int numOutputs = Varints.read(txBytes, offset);
    offset++;
    List<TransactionOutput> outputs = [];
    for (int i = 0; i < numOutputs; i++) {
      TransactionOutput output = TransactionOutput.parse(
          Converter.bytesToHex(txBytes.sublist(offset)));
      outputs.add(output);
      int size = output.serialize().length ~/ 2;
      offset += size;
    }
    Uint8List locktime = txBytes.sublist(offset);
    return Transaction(version, inputs, outputs, locktime, false);
  }

  /// Parse the unsigned transaction. (for PSBT)
  factory Transaction.parseUnsignedTransaction(String transaction,
      {bool unsigned = true}) {
    int offset = 0;
    Uint8List txBytes = Converter.hexToBytes(transaction);
    Uint8List version = txBytes.sublist(0, 4);
    offset += 4;

    int numInputs = Varints.read(txBytes, offset);
    offset += 1;
    List<TransactionInput> inputs = [];

    for (int i = 0; i < numInputs; i++) {
      TransactionInput input = TransactionInput.parseForPsbt(
          Converter.bytesToHex(txBytes.sublist(offset)));
      inputs.add(input);
      int size = input.serialize().length ~/ 2;
      offset += size;
    }

    int numOutputs = Varints.read(txBytes, offset);
    offset += 1;
    List<TransactionOutput> outputs = [];
    for (int i = 0; i < numOutputs; i++) {
      TransactionOutput output = TransactionOutput.parse(
          Converter.bytesToHex(txBytes.sublist(offset)));
      outputs.add(output);
      int size = output.serialize().length ~/ 2;
      offset += size;
    }
    bool isSegwit = false;

    Uint8List locktime = txBytes.sublist(offset);
    offset += 4;

    return Transaction(version, inputs, outputs, locktime, isSegwit);
  }

  /// Parse the unsigned transaction. (for PSBT)
  factory Transaction.parsePsbtTransaction(String transaction,
      {bool unsigned = true}) {
    int offset = 0;
    Uint8List txBytes = Converter.hexToBytes(transaction);
    Uint8List version = txBytes.sublist(0, 4);
    offset += 4;

    int numInputs = Varints.read(txBytes, offset);
    offset += 1;
    List<TransactionInput> inputs = [];

    for (int i = 0; i < numInputs; i++) {
      TransactionInput input =
          TransactionInput.parse(Converter.bytesToHex(txBytes.sublist(offset)));
      inputs.add(input);
      int size = input.serialize().length ~/ 2;
      offset += size;
    }

    int numOutputs = Varints.read(txBytes, offset);
    offset += 1;
    List<TransactionOutput> outputs = [];
    for (int i = 0; i < numOutputs; i++) {
      TransactionOutput output = TransactionOutput.parse(
          Converter.bytesToHex(txBytes.sublist(offset)));
      outputs.add(output);
      int size = output.serialize().length ~/ 2;
      offset += size;
    }
    bool isSegwit = false;

    Uint8List locktime = txBytes.sublist(offset);
    offset += 4;

    return Transaction(version, inputs, outputs, locktime, isSegwit);
  }

  /// Serialize the transaction.
  String serialize() {
    if (_isSegwit) {
      return serializeSegwit();
    } else {
      return serializeLegacy();
    }
  }

  /// Serialize to segwit transaction.
  String serializeSegwit() {
    String serialized = '';
    serialized += version;
    serialized += '0001';
    serialized += Converter.bytesToHex(Varints.encode(inputs.length));
    for (int i = 0; i < inputs.length; i++) {
      serialized += inputs[i].serialize();
    }
    serialized += Converter.bytesToHex(Varints.encode(outputs.length));
    for (int i = 0; i < outputs.length; i++) {
      serialized += outputs[i].serialize();
    }
    for (int i = 0; i < inputs.length; i++) {
      serialized +=
          Converter.bytesToHex(Varints.encode(inputs[i].witness.length));
      for (int j = 0; j < inputs[i].witness.length; j++) {
        if (inputs[i].witness[j] == 0) {
          serialized += '00';
        } else {
          serialized += Converter.decToHex((inputs[i].witness[j]).length);
          serialized += Converter.bytesToHex(inputs[i].witness[j]);
        }
      }
    }
    serialized += lockTime;
    return serialized;
  }

  /// Serialize to legacy transaction.
  String serializeLegacy() {
    String serialized = '';
    serialized += version;
    serialized += Converter.bytesToHex(Varints.encode(inputs.length));
    for (int i = 0; i < inputs.length; i++) {
      serialized += inputs[i].serialize();
    }
    serialized += Converter.bytesToHex(Varints.encode(outputs.length));
    for (int i = 0; i < outputs.length; i++) {
      serialized += outputs[i].serialize();
    }
    serialized += lockTime;
    return serialized;
  }

  /// Get the signature hash of the transaction.
  String getSigHash(int index, String utxo, bool isSegwit, {int hashType = 1}) {
    if (hashType != 1) {
      throw Exception("Only SIGHASH_ALL supported.");
    }

    if (isSegwit) {
      return _getSegwitSigHash(index, utxo, hashType);
    } else {
      return _getLegacySigHash(index, utxo, hashType);
    }
  }

  String _getLegacySigHash(int index, String utxo, int hashType) {
    String thisTx = serialize();
    Transaction forSig = Transaction.parse(thisTx);
    for (int i = 0; i < forSig.inputs.length; i++) {
      if (i == index) {
        String pubkey = TransactionOutput.parse(utxo).scriptPubKey.serialize();
        forSig.inputs[i].scriptSig = ScriptSignature.parse(pubkey);
      } else {
        forSig.inputs[i].scriptSig = ScriptSignature.empty();
      }
    }
    String type =
        Converter.bytesToHex(Converter.intToLittleEndianBytes(hashType, 4));
    String sigHash = forSig.serialize() + type;
    return sha256fromHex(sha256fromHex(sigHash));
  }

  /// BIP341 TapSighash for a Taproot key-path spend (no script-path/annex
  /// support). Unlike BIP143, the sighash for input [index] commits to every
  /// spent output's scriptPubKey and amount, so callers must supply the
  /// prevout script/value for *all* inputs (in input order), not just the
  /// one being signed.
  String getTaprootSigHash(int index, List<String> prevOutScripts,
      List<int> prevOutValues, {int hashType = _sighashDefault}) {
    if (prevOutScripts.length != inputs.length ||
        prevOutValues.length != inputs.length) {
      throw ArgumentError(
          'prevOutScripts/prevOutValues must cover every input');
    }

    final outputType =
        hashType == _sighashDefault ? _sighashAll : hashType & _sighashOutputMask;
    final inputType = hashType & _sighashInputMask;
    final isAnyoneCanPay = inputType == _sighashAnyoneCanPay;
    final isNone = outputType == _sighashNone;
    final isSingle = outputType == _sighashSingle;

    String hashPrevouts = '';
    String hashAmounts = '';
    String hashScriptPubKeys = '';
    String hashSequences = '';
    String hashOutputs = '';

    if (!isAnyoneCanPay) {
      String prevoutsConcat = '';
      String sequencesConcat = '';
      for (final input in inputs) {
        prevoutsConcat += input.transactionHashInternal + input.indexHex;
        sequencesConcat += input.sequenceHex;
      }
      hashPrevouts = sha256fromHex(prevoutsConcat);
      hashSequences = sha256fromHex(sequencesConcat);

      String amountsConcat = '';
      for (final value in prevOutValues) {
        amountsConcat +=
            Converter.bytesToHex(Converter.intToLittleEndianBytes(value, 8));
      }
      hashAmounts = sha256fromHex(amountsConcat);

      hashScriptPubKeys = sha256fromHex(prevOutScripts.join());
    }

    if (!(isNone || isSingle)) {
      String outputsConcat = '';
      for (final output in outputs) {
        outputsConcat += output.serialize();
      }
      hashOutputs = sha256fromHex(outputsConcat);
    } else if (isSingle && index < outputs.length) {
      hashOutputs = sha256fromHex(outputs[index].serialize());
    }

    const spendType = 0; // key-path spend, no leaf script, no annex

    String sigMsg = '';
    sigMsg += Converter.bytesToHex(Converter.intToLittleEndianBytes(hashType, 1));
    sigMsg += version;
    sigMsg += lockTime;
    sigMsg += hashPrevouts;
    sigMsg += hashAmounts;
    sigMsg += hashScriptPubKeys;
    sigMsg += hashSequences;
    if (!(isNone || isSingle)) sigMsg += hashOutputs;

    sigMsg +=
        Converter.bytesToHex(Converter.intToLittleEndianBytes(spendType, 1));
    if (isAnyoneCanPay) {
      final input = inputs[index];
      sigMsg += input.transactionHashInternal + input.indexHex;
      sigMsg += Converter.bytesToHex(
          Converter.intToLittleEndianBytes(prevOutValues[index], 8));
      sigMsg += prevOutScripts[index];
      sigMsg += input.sequenceHex;
    } else {
      sigMsg += Converter.bytesToHex(Converter.intToLittleEndianBytes(index, 4));
    }

    if (isSingle) sigMsg += hashOutputs;

    final tagged = bscript.taggedHash(
        'TapSighash', [0x00] + Converter.hexToBytes(sigMsg));
    return Converter.bytesToHex(tagged);
  }

  //BIP143
  String _getSegwitSigHash(int index, String utxo, int hashType) {
    String sigHash = '';
    sigHash += version;
    sigHash += _getHashPrevOuts();
    sigHash += _getHashSequence();
    sigHash += _getOutPoint(index);
    TransactionOutput prevUtxo = TransactionOutput.parse(utxo);
    if (prevUtxo.scriptPubKey.isP2WPKH()) {
      sigHash +=
          "1976a914${Converter.bytesToHex(prevUtxo.scriptPubKey.commands[1])}88ac";
    } else {
      sigHash += prevUtxo.scriptPubKey.serialize();
    }

    sigHash += Converter.bytesToHex(
        Converter.intToLittleEndianBytes(prevUtxo.amount, 8));
    sigHash += Converter.bytesToHex(
        Converter.intToLittleEndianBytes(inputs[index].sequence, 4));
    sigHash += _getHashOutputs();
    sigHash += lockTime;
    sigHash +=
        Converter.bytesToHex(Converter.intToLittleEndianBytes(hashType, 4));

    return sha256fromHex(sha256fromHex(sigHash));
  }

  String _getHashPrevOuts() {
    String prevouts = '';
    for (TransactionInput input in inputs) {
      prevouts += input.transactionHash + input.indexHex;
    }
    return sha256fromHex(sha256fromHex(prevouts));
  }

  String _getHashSequence() {
    String sequences = '';
    for (TransactionInput input in inputs) {
      sequences += input.sequenceHex;
    }
    String hashSequence = sha256fromHex(sha256fromHex(sequences));
    return hashSequence;
  }

  String _getHashOutputs() {
    String outputs = '';
    for (TransactionOutput output in this.outputs) {
      outputs += output.serialize();
    }
    return sha256fromHex(sha256fromHex(outputs));
  }

  String _getOutPoint(int index) {
    String outpoint = '';
    outpoint += inputs[index].transactionHash + inputs[index].indexHex;
    return outpoint;
  }

  /// check if the signature is valid in the transaction.
  bool validateSignature(
      int inputIndex, String utxo, BtcAddressType addressType) {
    String sigHash = getSigHash(inputIndex, utxo, addressType.isSegwit);
    String signature;
    String publicKey;
    if (addressType == BtcAddressType.p2wpkh) {
      signature = inputs[inputIndex].witnessList[0];
      publicKey = inputs[inputIndex].witnessList[1];
    } else {
      signature = inputs[inputIndex].scriptSig.commands[0];
      publicKey = inputs[inputIndex].scriptSig.commands[1];
    }

    Uint8List sig = Converter.hexToBytes(signature);
    Uint8List msg = Converter.hexToBytes(sigHash);
    Uint8List pub = Converter.hexToBytes(publicKey);

    // sig is DER-encoded (optionally with a trailing sighash byte); decode
    // r/s as integers and re-encode each to a fixed 32 bytes rather than
    // copying DER bytes directly — a DER integer legitimately shorter than
    // 32 bytes must not shift where `s` starts.
    final Uint8List rs;
    try {
      rs = EcdaSignature.derToRaw(sig);
    } catch (_) {
      return false;
    }

    return EcdaSignature.verify(msg.toStr(), pub, rs.toStr());
  }

  /// Get the virtual byte size of the transaction.
  double getVirtualByte() {
    double totalByte = (Converter.hexToBytes(serialize()).length) * 1.0;
    double witnessByte = 0;
    for (TransactionInput input in inputs) {
      for (int i = 0; i < input.witness.length; i++) {
        if (input.witness[i] != 0) {
          witnessByte += (input.witnessList[i].length / 2).floor();
          witnessByte += 1;
        }
      }
      witnessByte += 1;
    }

    double vByte;
    if (_isSegwit) {
      double nonWitnessByte = totalByte - witnessByte - 2.0;
      witnessByte = witnessByte + 2;
      vByte = (nonWitnessByte * 4 + witnessByte) / 4;
    } else {
      vByte = totalByte;
    }

    return vByte;
  }

  /// Calculate the fee of the transaction.
  int calculateFee(int feeRatePerByte) {
    return (getVirtualByte() * feeRatePerByte).ceil();
  }

  /// Estimate the fee of the transaction.
  int estimateFee(int feeRatePerByte) {
    bool hasSignatureLength = !hasNoSignature();
    int unsignedInput = 0;
    double vByte = getVirtualByte();
    int sigByte = 106;
    for (TransactionInput input in inputs) {
      if (!input.hasSignature(_isSegwit)) {
        unsignedInput++;
      }
    }
    if (_isSegwit) {
      double additionalByte = 4.0;
      additionalByte += unsignedInput * sigByte;
      if (!hasSignatureLength) {
        additionalByte += 2;
      }
      vByte += (additionalByte / 4);
    } else {
      vByte += unsignedInput * sigByte;
    }
    return (vByte * feeRatePerByte).ceil();
  }

  /// Check if the transaction has no signature.
  bool hasNoSignature() {
    for (TransactionInput input in inputs) {
      if (input.hasSignature(_isSegwit)) {
        return false;
      }
    }
    return true;
  }

  /// Check if the all inputs have a signature.
  bool hasAllSignature() {
    for (TransactionInput input in inputs) {
      if (!input.hasSignature(_isSegwit)) {
        return false;
      }
    }
    return true;
  }
}
