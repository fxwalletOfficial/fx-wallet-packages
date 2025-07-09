import 'package:crypto_wallet_util/src/transaction/ckb/tx_data.dart';
import 'package:crypto_wallet_util/src/utils/hex.dart';

import 'data_type.dart';

/// Provides data process methods required in [CkbTxSigner]
class Convert {
  static OutPoint parseOutPoint(OutPoint outPoint) {
    return OutPoint(
        txHash: outPoint.txHash, index: dynamicToHex(outPoint.index!));
  }

  static CkbTxData parseTransaction(CkbTxData transaction) {
    var cellDeps = transaction.cellDeps!
        .map((cellDep) => CellDep(
            outPoint: parseOutPoint(cellDep.outPoint!),
            depType: cellDep.depType))
        .toList();

    var inputs = transaction.inputs!
        .map((input) => CellInput(
            previousOutput: parseOutPoint(input.previousOutput!),
            since: dynamicToHex(input.since!)))
        .toList();

    var outputs = transaction.outputs!
        .map((output) => CellOutput(
            capacity: dynamicToHex(output.capacity!),
            lock: output.lock,
            type: output.type))
        .toList();

    return CkbTxData(
        version: dynamicToHex(transaction.version!),
        cellDeps: cellDeps,
        headerDeps: transaction.headerDeps,
        inputs: inputs,
        outputs: outputs,
        outputsData: transaction.outputsData,
        witnesses: transaction.witnesses);
  }
}

class Serializer {
  static Struct serializeOutPoint(OutPoint outPoint) {
    var txHash = Byte32.fromHex(outPoint.txHash!);
    var index = UInt32.fromHex(outPoint.index!);
    return Struct(<FixedType>[txHash, index]);
  }

  static Table serializeScript(Script script) {
    return Table([
      Byte32.fromHex(script.codeHash!),
      Byte1.fromHex(Script.Data == script.hashType ? '00' : '01'),
      script.args != null
          ? Bytes.fromHex(script.args!)
          : Empty() as SerializeType<dynamic>
    ]);
  }

  static Struct serializeCellInput(CellInput cellInput) {
    var sinceUInt64 = UInt64.fromHex(cellInput.since!);
    var outPointStruct = serializeOutPoint(cellInput.previousOutput!);
    return Struct(<SerializeType>[sinceUInt64, outPointStruct]);
  }

  static Table serializeCellOutput(CellOutput cellOutput) {
    return Table([
      UInt64.fromHex(cellOutput.capacity!),
      serializeScript(cellOutput.lock!),
      cellOutput.type != null
          ? serializeScript(cellOutput.type!)
          : Empty() as SerializeType<dynamic>
    ]);
  }

  static Struct serializeCellDep(CellDep cellDep) {
    var outPointStruct = serializeOutPoint(cellDep.outPoint!);
    var depTypeBytes = CellDep.Code == cellDep.depType
        ? Byte1.fromHex('0')
        : Byte1.fromHex('1');
    return Struct([outPointStruct, depTypeBytes]);
  }

  static Fixed<Struct> serializeCellDeps(List<CellDep> cellDeps) {
    return Fixed(cellDeps.map((cellDep) => serializeCellDep(cellDep)).toList());
  }

  static Fixed<Struct> serializeCellInputs(List<CellInput> cellInputs) {
    return Fixed(
        cellInputs.map((cellInput) => serializeCellInput(cellInput)).toList());
  }

  static Dynamic<Table> serializeCellOutputs(List<CellOutput> cellOutputs) {
    return Dynamic(cellOutputs
        .map((cellOutput) => serializeCellOutput(cellOutput))
        .toList());
  }

  static Dynamic<Bytes> serializeBytes(List<String> bytes) {
    return Dynamic(bytes.map((byte) => Bytes.fromHex(byte)).toList());
  }

  static Fixed<Byte32> serializeByte32(List<String> bytes) {
    return Fixed(bytes.map((byte) => Byte32.fromHex(byte)).toList());
  }

  static Table serializeWitnessArgs(Witness witness) {
    var list = <Option>[];
    list.add(Option(witness.lock == null
        ? Empty()
        : Bytes.fromHex(witness.lock!) as SerializeType<dynamic>));
    list.add(Option(witness.inputType == null
        ? Empty()
        : Bytes.fromHex(witness.inputType!) as SerializeType<dynamic>));
    list.add(Option(witness.outputType == null
        ? Empty()
        : Bytes.fromHex(witness.outputType!) as SerializeType<dynamic>));
    return Table(list);
  }

  static Table serializeRawTransaction(CkbTxData transaction) {
    var tx = Convert.parseTransaction(transaction);

    return Table([
      UInt32.fromHex(tx.version!),
      Serializer.serializeCellDeps(tx.cellDeps!),
      Serializer.serializeByte32(tx.headerDeps!),
      Serializer.serializeCellInputs(tx.inputs!),
      Serializer.serializeCellOutputs(tx.outputs!),
      Serializer.serializeBytes(tx.outputsData!)
    ]);
  }
}
