import 'dart:typed_data';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:hex/hex.dart';

import '../src/classify.dart';
import '../src/crypto.dart' as bcrypto;
import '../../../utils/bip32/src/utils/ecpair.dart';
import '../src/payments/index.dart' show PaymentData;
import '../src/payments/p2pk.dart' show P2PK;
import '../src/payments/p2pkh.dart' show P2PKH;
import '../src/payments/p2sh.dart' show P2SH;
import '../src/payments/p2wpkh.dart' show P2WPKH;
import '../src/utils/buffer.dart';
import '../src/utils/check_types.dart';
import '../src/utils/constants/op.dart';
import '../src/utils/script.dart' as bscript;
import '../src/utils/varuint.dart' as varuint;

const DEFAULT_SEQUENCE = 0xffffffff;
const SIGHASH_DEFAULT = 0x00;
const SIGHASH_ALL = 0x01;
const SIGHASH_NONE = 0x02;
const SIGHASH_SINGLE = 0x03;
const SIGHASH_ANYONECANPAY = 0x80;
const SIGHASH_OUTPUT_MASK = 0x03;
const SIGHASH_INPUT_MASK = 0x80;
const SIGHASH_BITCOINCASHBIP143 = 0x40;
const ADVANCED_TRANSACTION_MARKER = 0x00;
const ADVANCED_TRANSACTION_FLAG = 0x01;
final EMPTY_SCRIPT = Uint8List.fromList([]);
final EMPTY_WITNESS = <Uint8List>[];
final ZERO = HEX
    .decode('0000000000000000000000000000000000000000000000000000000000000000');
final ONE = Uint8List.fromList(HEX.decode(
    '0000000000000000000000000000000000000000000000000000000000000001'));
final VALUE_UINT64_MAX = HEX.decode('ffffffffffffffff');
final BLANK_OUTPUT = Output(
    script: EMPTY_SCRIPT, valueBuffer: Uint8List.fromList(VALUE_UINT64_MAX));
const MIN_VERSION_NO_TOKENS = 3;

class Transaction {
  int? version = 1;
  int? locktime = 0;
  List<Input> ins = [];
  List<OutputBase> outs = [];
  Transaction();

  int addInput(Uint8List hash, int? index,
      {int? sequence,
      Uint8List? scriptSig,
      int? value,
      Uint8List? prevoutScript,
      Uint8List? witnessUtxo,
      Uint8List? tapInternalKey,
      List<TapLeafScript>? tapLeafScript}) {
    ins.add(Input(
        hash: hash,
        index: index,
        sequence: sequence ?? DEFAULT_SEQUENCE,
        script: scriptSig ?? EMPTY_SCRIPT,
        prevOutScript: prevoutScript ?? EMPTY_SCRIPT,
        witness: EMPTY_WITNESS,
        value: value,
        witnessUtxo: witnessUtxo,
        tapInternalKey: tapInternalKey,
        tapLeafScript: tapLeafScript));
    return ins.length - 1;
  }

  int addOutput(Uint8List? scriptPubKey, int? value) {
    outs.add(Output(script: scriptPubKey, value: value));
    return outs.length - 1;
  }

  int addOutputAt(Uint8List? scriptPubKey, int value, int at) {
    final output = Output(script: scriptPubKey, value: value);
    return addBaseOutputAt(output, at);
  }

  int addBaseOutput(OutputBase output) {
    outs.add(output);
    return outs.length - 1;
  }

  int addBaseOutputAt(OutputBase output, int index) {
    outs.insert(index, output);
    return index;
  }

  bool hasWitnesses() {
    var witness = ins.firstWhereOrNull(
        (input) => input.witness != null && input.witness!.isNotEmpty);
    return witness != null;
  }

  void setInputScript(int index, Uint8List? scriptSig) {
    ins[index].script = scriptSig;
  }

  void setWitness(int index, List<Uint8List?>? witness) {
    ins[index].witness = witness;
  }

  void setVersion(int value) => version = value;

  void setLocktime(int value) => locktime = value;

  Uint8List createHashesForSig({required int vin, int? hashType}) {
    if (vin >= ins.length) throw ArgumentError('No input at index: $vin');

    hashType = hashType ?? SIGHASH_DEFAULT;
    final input = ins[vin];

    final prevouts =
        ins.where((e) => e.prevOutScript != null && e.value != null);
    final scripts = prevouts.map((e) {
      if (e.witnessUtxo != null) return e.witnessUtxo!;
      return e.prevOutScript!;
    }).toList();
    final values = prevouts.map((e) => e.value!).toList();
    final leafHash = tapLeafHash((input.tapLeafScript?.isNotEmpty ?? false)
        ? input.tapLeafScript!.first
        : null);

    final hashesForSig =
        hashForWitnessV1(vin, scripts, values, hashType, leafHash, null);
    return hashesForSig;
  }

  Uint8List verifySchnorr({required int vin, Uint8List? signature}) {
    final input = ins[vin];
    return input.witness![0]!;
  }

  void signSchnorr(
      {required int vin,
      required ECPair keyPair,
      int? hashType,
      bool hd = false}) {
    if (vin >= ins.length) throw ArgumentError('No input at index: $vin');

    hashType = hashType ?? SIGHASH_DEFAULT;
    final input = ins[vin];

    final prevouts =
        ins.where((e) => e.prevOutScript != null && e.value != null);
    final scripts = prevouts.map((e) {
      if (e.witnessUtxo != null) return e.witnessUtxo!;
      return e.prevOutScript!;
    }).toList();
    final values = prevouts.map((e) => e.value!).toList();
    final leafHash = tapLeafHash((input.tapLeafScript?.isNotEmpty ?? false)
        ? input.tapLeafScript!.first
        : null);

    final hashesForSig =
        hashForWitnessV1(vin, scripts, values, hashType, leafHash, null);
    final sig = keyPair.signSchnorr(message: hashesForSig);

    final witness = [_serializeTaprootSignature(sig, hashType)];
    if (input.tapLeafScript?.isNotEmpty ?? false) {
      final item = input.tapLeafScript!.first;
      witness.addAll([item.script, item.controlBlock]);
    }

    input.update(witness: witness);
  }

  void signSchnorrHd(
      {required int vin, required Uint8List sig, int? hashType}) {
    if (vin >= ins.length) throw ArgumentError('No input at index: $vin');

    hashType = hashType ?? SIGHASH_DEFAULT;
    final input = ins[vin];

    final witness = [_serializeTaprootSignature(sig, hashType)];
    if (input.tapLeafScript?.isNotEmpty ?? false) {
      final item = input.tapLeafScript!.first;
      witness.addAll([item.script, item.controlBlock]);
    }

    input.update(witness: witness);
  }

  Uint8List? tapLeafHash(TapLeafScript? tapLeaf) {
    if (tapLeaf == null) return null;

    return Uint8List.fromList(bscript.taggedHash('TapLeaf',
        [tapLeaf.version] + [tapLeaf.script.length] + tapLeaf.script));
  }

  Uint8List _serializeTaprootSignature(Uint8List sig, int? type) {
    if (type == null || type <= 0) return sig;
    return Uint8List.fromList(Uint8List.fromList([type]) + sig);
  }

  Uint8List hashForWitnessV0(
      int inIndex, Uint8List prevOutScript, int value, int hashType) {
    var hashOutputs = ZERO;
    var hashPrevouts = ZERO;
    var hashSequence = ZERO;

    if ((hashType & SIGHASH_ANYONECANPAY) == 0) {
      final prevoutsBuf = Buffer(36 * ins.length);

      for (var txIn in ins) {
        prevoutsBuf.writeSlice(txIn.hash);
        prevoutsBuf.writeUInt32(txIn.index);
      }
      hashPrevouts = prevoutsBuf.toHash256();
    }

    if ((hashType & SIGHASH_ANYONECANPAY) == 0 &&
        (hashType & 0x1f) != SIGHASH_SINGLE &&
        (hashType & 0x1f) != SIGHASH_NONE) {
      final sequenceBuf = Buffer(4 * ins.length);

      for (var txIn in ins) {
        sequenceBuf.writeUInt32(txIn.sequence);
      }
      hashSequence = sequenceBuf.toHash256();
    }

    if ((hashType & 0x1f) != SIGHASH_SINGLE &&
        (hashType & 0x1f) != SIGHASH_NONE) {
      final txOutsSize = outs.fold(
          0,
          (dynamic sum, output) =>
              sum +
              (version! > MIN_VERSION_NO_TOKENS ? 1 : 0) +
              8 +
              varSliceSize(output.script!));
      final outputsBuf = Buffer(txOutsSize);

      for (var txOut in outs) {
        outputsBuf.writeUInt64(txOut.value);
        outputsBuf.writeVarSlice(txOut.script);
        if (version! > MIN_VERSION_NO_TOKENS) outputsBuf.writeVarInt(txOut.tokenId);
      }
      hashOutputs = outputsBuf.toHash256();
    } else if ((hashType & 0x1f) == SIGHASH_SINGLE && inIndex < outs.length) {
      // SIGHASH_SINGLE only hash that according output
      final output = outs[inIndex];
      final outputsBuf = Buffer(8 +
          (version! > MIN_VERSION_NO_TOKENS ? 1 : 0) +
          varSliceSize(output.script!));

      outputsBuf.writeUInt64(output.value);
      outputsBuf.writeVarSlice(output.script);
      if (version! > MIN_VERSION_NO_TOKENS)
        outputsBuf.writeVarInt(output.tokenId);

      hashOutputs = outputsBuf.toHash256();
    }

    final buf = Buffer(156 + varSliceSize(prevOutScript));
    final input = ins[inIndex];
    buf.writeUInt32(version);
    buf.writeSlice(hashPrevouts);
    buf.writeSlice(hashSequence);
    buf.writeSlice(input.hash);
    buf.writeUInt32(input.index);
    buf.writeVarSlice(prevOutScript);
    buf.writeUInt64(value);
    buf.writeUInt32(input.sequence);
    buf.writeSlice(hashOutputs);
    buf.writeUInt32(locktime);
    buf.writeUInt32(hashType);

    return buf.toHash256();
  }

  Uint8List hashForWitnessV1(int inIndex, List<Uint8List> prevOutScripts,
      List<int> values, int hashType, Uint8List? leafHash, Uint8List? annex) {
    final outputType = hashType == SIGHASH_DEFAULT
        ? SIGHASH_ALL
        : hashType & SIGHASH_OUTPUT_MASK;
    final inputType = hashType & SIGHASH_INPUT_MASK;
    final isAnyoneCanPay = inputType == SIGHASH_ANYONECANPAY;
    final isNone = outputType == SIGHASH_NONE;
    final isSingle = outputType == SIGHASH_SINGLE;

    var hashPrevouts = Uint8List.fromList([]);
    var hashAmounts = Uint8List.fromList([]);
    var hashScriptPubKeys = Uint8List.fromList([]);
    var hashSequences = Uint8List.fromList([]);
    var hashOutputs = Uint8List.fromList([]);

    if (!isAnyoneCanPay) {
      // Hash txid.
      final hashBuf = Buffer(36 * ins.length);

      for (var txIn in ins) {
        hashBuf.writeSlice(txIn.hash);
        hashBuf.writeUInt32(txIn.index);
      }

      hashPrevouts = hashBuf.toSha256();

      // Hash value.
      final valueBuf = Buffer(8 * ins.length);

      for (var value in values) {
        valueBuf.writeUInt64(value);
      }
      hashAmounts = valueBuf.toSha256();

      // Hash prevout script.
      final scriptBuf =
          Buffer(prevOutScripts.map(varSliceSize).reduce((a, b) => a + b));
      for (var prevOutScript in prevOutScripts) {
        scriptBuf.writeVarSlice(prevOutScript);
      }
      hashScriptPubKeys = scriptBuf.toSha256();

      // Hash sequence.
      final sequenceBuf = Buffer(4 * ins.length);

      for (var txIn in ins) {
        sequenceBuf.writeUInt32(txIn.sequence);
      }
      hashSequences = sequenceBuf.toSha256();
    }

    if (!(isNone || isSingle)) {
      final txOutsSize = outs
          .map((output) => 8 + varSliceSize(output.script!))
          .reduce((a, b) => a + b);
      final outBuf = Buffer(txOutsSize);

      for (var out in outs) {
        outBuf.writeUInt64(out.value);
        outBuf.writeVarSlice(out.script);
      }

      hashOutputs = outBuf.toSha256();
    } else if (isSingle && inIndex < outs.length) {
      final output = outs[inIndex];
      final outBuf = Buffer(8 + varSliceSize(output.script!));

      outBuf.writeUInt64(output.value);
      outBuf.writeVarSlice(output.script);
      hashOutputs = outBuf.toSha256();
    }

    final spendType = (leafHash != null ? 2 : 0) + (annex != null ? 1 : 0);
    final sigMsgSize = 174 -
        (isAnyoneCanPay ? 49 : 0) -
        (isNone ? 32 : 0) +
        (annex != null ? 32 : 0) +
        (leafHash != null ? 37 : 0);
    final buf = Buffer(sigMsgSize);

    buf.writeUInt8(hashType);
    // Transaction
    buf.writeInt32(version);
    buf.writeUInt32(locktime);
    buf.writeSlice(hashPrevouts);
    buf.writeSlice(hashAmounts);
    buf.writeSlice(hashScriptPubKeys);
    buf.writeSlice(hashSequences);

    if (!(isNone || isSingle)) buf.writeSlice(hashOutputs);

    // Input
    buf.writeUInt8(spendType);
    if (isAnyoneCanPay) {
      final input = ins[inIndex];
      buf.writeSlice(input.hash);
      buf.writeUInt32(input.index);
      buf.writeUInt64(values[inIndex]);
      buf.writeVarSlice(prevOutScripts[inIndex]);
      buf.writeUInt32(input.sequence);
    } else {
      buf.writeUInt32(inIndex);
    }

    if (annex != null) {
      final annexBuf = Buffer(varSliceSize(annex));

      annexBuf.writeVarSlice(annex);
      buf.writeSlice(annexBuf.toSha256());
    }
    // Output
    if (isSingle) buf.writeSlice(hashOutputs);

    // BIP342 extension
    if (leafHash != null) {
      buf.writeSlice(leafHash);
      buf.writeUInt8(0);
      buf.writeUInt32(0xffffffff);
    }
    // Extra zero byte because:
    // https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki#cite_note-19
    return Uint8List.fromList(
        bscript.taggedHash('TapSighash', [0x00] + buf.tBuffer));
  }

  Uint8List hashForSignature(
      int inIndex, Uint8List? prevOutScript, int? hashType) {
    if (inIndex >= ins.length) return ONE;
    final ourScript =
        bscript.compile(bscript.decompile(prevOutScript)!.where((x) {
      return x != OPS['OP_CODESEPARATOR'];
    }).toList());
    final txTmp = Transaction.clone(this);
    // SIGHASH_NONE: ignore all outputs? (wildcard payee)
    if ((hashType! & 0x1f) == SIGHASH_NONE) {
      txTmp.outs = [];
      // ignore sequence numbers (except at inIndex)
      for (var i = 0; i < txTmp.ins.length; i++) {
        if (i != inIndex) txTmp.ins[i].sequence = 0;
      }

      // SIGHASH_SINGLE: ignore all outputs, except at the same index?
    } else if ((hashType & 0x1f) == SIGHASH_SINGLE) {
      // https://github.com/bitcoin/bitcoin/blob/master/src/test/sighash_tests.cpp#L60
      if (inIndex >= outs.length) return ONE;

      // truncate outputs after
      txTmp.outs.length = inIndex + 1;

      // 'blank' outputs before
      for (var i = 0; i < inIndex; i++) {
        txTmp.outs[i] = BLANK_OUTPUT;
      }
      // ignore sequence numbers (except at inIndex)
      for (var i = 0; i < txTmp.ins.length; i++) {
        if (i != inIndex) txTmp.ins[i].sequence = 0;
      }
    }

    // SIGHASH_ANYONECANPAY: ignore inputs entirely?
    if (hashType & SIGHASH_ANYONECANPAY != 0) {
      txTmp.ins = [txTmp.ins[inIndex]];
      txTmp.ins[0].script = ourScript;
      // SIGHASH_ALL: only ignore input scripts
    } else {
      // 'blank' others input scripts
      for (var input in txTmp.ins) {
        input.script = EMPTY_SCRIPT;
      }
      txTmp.ins[inIndex].script = ourScript;
    }
    // serialize and hash
    final buffer = Uint8List(txTmp.virtualSize() + 4);
    buffer.buffer
        .asByteData()
        .setUint32(buffer.length - 4, hashType, Endian.little);
    txTmp._toBuffer(buffer, 0);
    return bcrypto.hash256(buffer);
  }

  int _byteLength(ALLOW_WITNESS) {
    final hasWitness = ALLOW_WITNESS && hasWitnesses();
    return (hasWitness ? 10 : 8) +
        varuint.encodingLength(ins.length) +
        varuint.encodingLength(outs.length) +
        ins.fold<int>(
            0, (sum, input) => sum + 40 + varSliceSize(input.script!)) +
        outs.fold<int>(
            0,
            (sum, output) =>
                sum +
                (version! > MIN_VERSION_NO_TOKENS ? 1 : 0) +
                8 +
                varSliceSize(output.script!)) +
        (hasWitness
            ? ins.fold(0, (sum, input) => sum + vectorSizeNew(input))
            : 0);
  }

  int vectorSizeNew(Input input) {
    if (input.witness != null && input.witness!.isNotEmpty) {
      return vectorSize(input.witness!);
    }

    return varuint.encodingLength(0);
  }

  int vectorSize(List<Uint8List?> someVector) {
    var length = someVector.length;
    return varuint.encodingLength(length) +
        someVector.fold(0, (sum, witness) => sum + varSliceSize(witness!));
  }

  int weight() {
    var base = _byteLength(false);
    var total = _byteLength(true);
    return base * 3 + total;
  }

  int byteLength() {
    return _byteLength(true);
  }

  int virtualSize() {
    return (weight() / 4).ceil();
  }

  Uint8List toBuffer([Uint8List? buffer, int? initialOffset]) {
    return _toBuffer(buffer, initialOffset, true);
  }

  String toHex() {
    return HEX.encode(toBuffer());
  }

  bool isCoinbaseHash(buffer) {
    isHash256bit(buffer);
    for (var i = 0; i < 32; ++i) {
      if (buffer[i] != 0) return false;
    }
    return true;
  }

  bool isCoinbase() {
    return ins.length == 1 && isCoinbaseHash(ins[0].hash);
  }

  Uint8List getHash() {
    // if (isCoinbase()) return Uint8List.fromList(List.generate(32, (i) => 0));
    return bcrypto.hash256(_toBuffer(null, null, false));
  }

  String getId() {
    return HEX.encode(getHash().reversed.toList());
  }

  Uint8List _toBuffer(
      [Uint8List? buffer, initialOffset, bool ALLOW_WITNESS = false]) {
    final buf = Buffer.fromUint8List(
        data: buffer,
        initialOffset: initialOffset,
        length: _byteLength(ALLOW_WITNESS));

    // Start writeBuffer
    buf.writeInt32(version);

    if (ALLOW_WITNESS && hasWitnesses()) {
      buf.writeUInt8(ADVANCED_TRANSACTION_MARKER);
      buf.writeUInt8(ADVANCED_TRANSACTION_FLAG);
    }

    buf.writeVarInt(ins.length);

    for (var txIn in ins) {
      buf.writeSlice(txIn.hash);
      buf.writeUInt32(txIn.index);
      buf.writeVarSlice(txIn.script);
      buf.writeUInt32(txIn.sequence);
    }

    buf.writeVarInt(outs.length);

    for (var txOut in outs) {
      if (txOut.valueBuffer == null) {
        buf.writeUInt64(txOut.value);
      } else {
        buf.writeSlice(txOut.valueBuffer);
      }
      buf.writeVarSlice(txOut.script);
      if (version! > MIN_VERSION_NO_TOKENS) buf.writeVarInt(txOut.tokenId);
    }

    if (ALLOW_WITNESS && hasWitnesses()) {
      for (var txInt in ins) {
        if (txInt.witness == null) {
          buf.writeVarInt(0);
        } else {
          buf.writeVector(txInt.witness);
        }
      }
    }

    buf.writeUInt32(locktime);
    // End writeBuffer

    // avoid slicing unless necessary
    if (initialOffset != null)
      return buf.tBuffer.sublist(initialOffset, buf.tOffset);

    return buf.tBuffer;
  }

  factory Transaction.clone(Transaction tx) {
    final transaction = Transaction();
    transaction.version = tx.version;
    transaction.locktime = tx.locktime;
    transaction.ins = tx.ins.map((input) {
      return Input.clone(input);
    }).toList();
    transaction.outs = tx.outs.map((output) {
      return OutputBase.clone(output);
    }).toList();
    return transaction;
  }

  factory Transaction.fromBuffer(Uint8List buffer, {bool noStrict = false}) {
    var offset = 0;
    // Any changes made to the ByteData will also change the buffer, and vice versa.
    // https://api.dart.dev/stable/2.7.1/dart-typed_data/ByteBuffer/asByteData.html
    var bytes = buffer.buffer.asByteData();

    int readUInt8() {
      final i = bytes.getUint8(offset);
      offset++;
      return i;
    }

    int readUInt32() {
      final i = bytes.getUint32(offset, Endian.little);
      offset += 4;
      return i;
    }

    int readInt32() {
      final i = bytes.getInt32(offset, Endian.little);
      offset += 4;
      return i;
    }

    int readUInt64() {
      final i = bytes.getUint64(offset, Endian.little);
      offset += 8;
      return i;
    }

    Uint8List readSlice(int n) {
      offset += n;
      return buffer.sublist(offset - n, offset);
    }

    int readVarInt() {
      final vi = varuint.decode(buffer, offset);
      offset += varuint.encodingLength(vi);
      return vi;
    }

    Uint8List readVarSlice() {
      return readSlice(readVarInt());
    }

    List<Uint8List> readVector() {
      var count = readVarInt();
      var vector = <Uint8List>[];
      for (var i = 0; i < count; ++i) {
        vector.add(readVarSlice());
      }
      return vector;
    }

    final tx = Transaction();
    tx.version = readInt32();
    final marker = readUInt8();
    final flag = readUInt8();
    var hasWitnesses = false;

    if (marker == ADVANCED_TRANSACTION_MARKER &&
        flag == ADVANCED_TRANSACTION_FLAG) {
      hasWitnesses = true;
    } else {
      offset -= 2; // Reset offset if not segwit tx
    }

    final vinLen = readVarInt();
    for (var i = 0; i < vinLen; ++i) {
      tx.ins.add(Input(
          hash: readSlice(32),
          index: readUInt32(),
          script: readVarSlice(),
          sequence: readUInt32()));
    }

    final voutLen = readVarInt();
    for (var i = 0; i < voutLen; ++i) {
      tx.outs.add(Output(value: readUInt64(), script: readVarSlice()));
    }

    if (hasWitnesses) {
      for (var i = 0; i < vinLen; ++i) {
        tx.ins[i].witness = readVector();
      }
    }

    tx.locktime = readUInt32();

    if (noStrict) return tx;

    if (offset != buffer.length) {
      throw ArgumentError('Transaction has unexpected data');
    }

    return tx;
  }

  factory Transaction.fromHex(String hex, {bool noStrict = false}) {
    return Transaction.fromBuffer(Uint8List.fromList(HEX.decode(hex)),
        noStrict: noStrict);
  }

  @override
  String toString() {
    final s = [];
    for (var txInput in ins) {
      s.add(txInput.toString());
    }
    for (var txOutput in outs) {
      s.add(txOutput.toString());
    }
    return s.join('\n');
  }
}

class Input {
  Uint8List? hash;
  int? index;
  int? sequence;
  int? value;
  Uint8List? script;
  Uint8List? signScript;
  Uint8List? prevOutScript;
  Uint8List? redeemScript;
  Uint8List? witnessScript;
  String? signType;
  String? prevOutType;
  String? redeemScriptType;
  String? witnessScriptType;
  bool hasWitness = false;
  List<Uint8List?>? pubkeys;
  List<Uint8List?>? signatures;
  List<Uint8List?>? witness;
  int? maxSignatures;
  Uint8List? tapKeySig;
  Uint8List? witnessUtxo;
  Uint8List? tapInternalKey;
  List<TapLeafScript>? tapLeafScript;

  Input(
      {this.hash,
      this.index,
      this.script,
      this.sequence,
      this.value,
      this.prevOutScript,
      this.redeemScript,
      this.witnessScript,
      this.pubkeys,
      this.signatures,
      this.witness,
      this.signType,
      this.prevOutType,
      this.redeemScriptType,
      this.witnessScriptType,
      this.maxSignatures,
      this.witnessUtxo,
      this.tapInternalKey,
      this.tapLeafScript}) {
    if (hash != null && !isHash256bit(hash!))
      throw ArgumentError('Invalid input hash');
    if (index != null && !isUint(index!, 32))
      throw ArgumentError('Invalid input index');
    if (sequence != null && !isUint(sequence!, 32))
      throw ArgumentError('Invalid input sequence');
    if (value != null && !isShatoshi(value!))
      throw ArgumentError('Invalid output value');
  }

  void update({Uint8List? tapKeySig, List<Uint8List>? witness}) {
    if (tapKeySig != null) this.tapKeySig = tapKeySig;
    if (witness != null) this.witness = witness;
  }

  factory Input.expandInput(Uint8List scriptSig, List<Uint8List?>? witness,
      [String? type, Uint8List? scriptPubKey]) {
    if (scriptSig.isEmpty && witness!.isEmpty) {
      return Input();
    }
    if (type == null || type == '') {
      var ssType = classifyInput(scriptSig, true);
      var wsType = classifyWitness(witness);
      if (ssType == SCRIPT_TYPES['NONSTANDARD']) ssType = null;
      if (wsType == SCRIPT_TYPES['NONSTANDARD']) wsType = null;
      type = ssType ?? wsType;
    }
    if (type == SCRIPT_TYPES['P2WPKH']) {
      var p2wpkh = P2WPKH(data: PaymentData(witness: witness));
      return Input(
          prevOutScript: p2wpkh.data.output,
          prevOutType: SCRIPT_TYPES['P2WPKH'],
          pubkeys: [p2wpkh.data.pubkey],
          signatures: [p2wpkh.data.signature]);
    }
    if (type == SCRIPT_TYPES['P2PKH']) {
      var p2pkh = P2PKH(data: PaymentData(input: scriptSig));
      return Input(
          prevOutScript: p2pkh.data.output,
          prevOutType: SCRIPT_TYPES['P2PKH'],
          pubkeys: [p2pkh.data.pubkey],
          signatures: [p2pkh.data.signature]);
    }
    if (type == SCRIPT_TYPES['P2PK']) {
      var p2pk = P2PK(data: PaymentData(input: scriptSig));
      return Input(
          prevOutType: SCRIPT_TYPES['P2PK'],
          pubkeys: [],
          signatures: [p2pk.data.signature]);
    }
    if (type == SCRIPT_TYPES['P2MS']) {}
    if (type == SCRIPT_TYPES['P2SH']) {
      var p2sh = P2SH(data: PaymentData(input: scriptSig, witness: witness));
      final output = p2sh.data.output;
      final redeem = p2sh.data.redeem!;
      final outputType = classifyOutput(redeem.output!);
      final expanded = Input.expandInput(
          redeem.input!, redeem.witness, outputType, redeem.output);

      if (expanded.prevOutType == null) return Input();

      return Input(
          prevOutScript: output,
          prevOutType: SCRIPT_TYPES['P2SH'],
          redeemScript: redeem.output,
          redeemScriptType: expanded.prevOutType,
          witnessScript: expanded.witnessScript,
          witnessScriptType: expanded.witnessScriptType,
          pubkeys: expanded.pubkeys,
          signatures: expanded.signatures);
    }

    return Input(
        prevOutType: SCRIPT_TYPES['NONSTANDARD'], prevOutScript: scriptSig);
  }

  factory Input.clone(Input input) {
    return Input(
      hash: input.hash != null ? Uint8List.fromList(input.hash!) : null,
      index: input.index,
      script: input.script != null ? Uint8List.fromList(input.script!) : null,
      sequence: input.sequence,
      value: input.value,
      prevOutScript: input.prevOutScript != null
          ? Uint8List.fromList(input.prevOutScript!)
          : null,
      pubkeys: input.pubkeys != null
          ? input.pubkeys!.map((pubkey) =>
                  pubkey != null ? Uint8List.fromList(pubkey) : null)
              as List<Uint8List?>?
          : null,
      signatures: input.signatures != null
          ? input.signatures!.map((signature) =>
                  signature != null ? Uint8List.fromList(signature) : null)
              as List<Uint8List?>?
          : null,
    );
  }

  @override
  String toString() {
    return '''
    Input{
      hash: $hash,
      index: $index,
      sequence: $sequence,
      value: $value,
      script: $script,
      signScript: $signScript,
      prevOutScript: $prevOutScript,
      redeemScript: $redeemScript,
      witnessScript: $witnessScript,
      pubkeys: $pubkeys,
      signatures: $signatures,
      witness: $witness,
      signType: $signType,
      prevOutType: $prevOutType,
      redeemScriptType: $redeemScriptType,
      witnessScriptType: $witnessScriptType,
    }
    ''';
  }
}

class OutputBase {
  String? type;
  Uint8List? script;
  int? value;
  Uint8List? valueBuffer;
  List<Uint8List?>? pubkeys;
  List<Uint8List?>? signatures;
  int? maxSignatures;

  final int tokenId;

  OutputBase(
      {this.type,
      this.script,
      this.value,
      this.pubkeys,
      this.signatures,
      this.valueBuffer,
      this.maxSignatures,
      this.tokenId = 0});

  factory OutputBase.expandOutput(Uint8List? script, [Uint8List? ourPubKey]) {
    if (ourPubKey == null) return OutputBase();
    var type = classifyOutput(script!);
    if (type == SCRIPT_TYPES['P2WPKH']) {
      var wpkh1 = P2WPKH(data: PaymentData(output: script)).data.hash;
      var wpkh2 = bcrypto.hash160(ourPubKey);
      if (wpkh1.toString() != wpkh2.toString()) {
        throw ArgumentError('Hash mismatch!');
      }
      return OutputBase(type: type, pubkeys: [ourPubKey], signatures: [null]);
    }

    if (type == SCRIPT_TYPES['P2PKH']) {
      var pkh1 = P2PKH(data: PaymentData(output: script)).data.hash;
      var pkh2 = bcrypto.hash160(ourPubKey);
      if (pkh1.toString() != pkh2.toString()) {
        throw ArgumentError('Hash mismatch!');
      }
      return OutputBase(type: type, pubkeys: [ourPubKey], signatures: [null]);
    }

    return OutputBase();
  }

  factory OutputBase.clone(OutputBase output) {
    return OutputBase(
      type: output.type,
      script: output.script != null ? Uint8List.fromList(output.script!) : null,
      value: output.value,
      valueBuffer: output.valueBuffer != null
          ? Uint8List.fromList(output.valueBuffer!)
          : null,
      pubkeys: output.pubkeys != null
          ? output.pubkeys!.map((pubkey) =>
                  pubkey != null ? Uint8List.fromList(pubkey) : null)
              as List<Uint8List>?
          : null,
      signatures: output.signatures != null
          ? output.signatures!.map((signature) =>
                  signature != null ? Uint8List.fromList(signature) : null)
              as List<Uint8List?>?
          : null,
    );
  }

  @override
  String toString() {
    return '''
      Output{
        type: $type,
        script: $script,
        value: $value,
        valueBuffer: $valueBuffer,
        pubkeys: $pubkeys,
        signatures: $signatures
      }
    ''';
  }
}

class Output extends OutputBase {
  Output(
      {super.type,
      super.script,
      int? value,
      super.valueBuffer,
      List<Uint8List>? super.pubkeys,
      List<Uint8List>? super.signatures,
      super.maxSignatures})
      : super(
            value: value) {
    if (value != null && !isShatoshi(value))
      throw ArgumentError('Invalid output value');
  }
}

bool isCoinbaseHash(Uint8List buffer) {
  if (!isHash256bit(buffer)) throw ArgumentError('Invalid hash');
  for (var i = 0; i < 32; ++i) {
    if (buffer[i] != 0) return false;
  }
  return true;
}

int varSliceSize(Uint8List someScript) {
  final length = someScript.length;
  return varuint.encodingLength(length) + length;
}

class TapLeafScript {
  final int version;
  final Uint8List script;
  final Uint8List controlBlock;

  TapLeafScript(
      {required this.version,
      required this.script,
      required this.controlBlock});
}
