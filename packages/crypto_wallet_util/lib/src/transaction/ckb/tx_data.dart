import 'dart:typed_data';

import 'package:crypto_wallet_util/src/type/type.dart';
import 'package:crypto_wallet_util/src/transaction/ckb/lib/ckb_lib.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// [CkbTxData] requires [version], [hash], [cellDeps], [headerDeps], [inputs], [outputs], [outputsData], [witnesses]
/// [getMessage] is the parameter to be signed.
class CkbTxData extends TxData {
  String? version;
  String? hash;
  List<CellDep>? cellDeps;
  List<String>? headerDeps;
  List<CellInput>? inputs;
  List<CellOutput>? outputs;
  List<String>? outputsData;
  List<dynamic>? witnesses;
  List<dynamic> groupWitnesses = [];
  ScriptGroup? scriptGroup;

  CkbTxData(
      {this.version,
      this.hash,
      this.cellDeps,
      this.headerDeps,
      this.inputs,
      this.outputs,
      this.outputsData,
      this.witnesses});

  factory CkbTxData.fromJson(Map<String, dynamic> json) {
    final tx = CkbTxData(
        version: json['version'],
        hash: json['hash'],
        cellDeps: (json['cell_deps'] as List)
            .map((cellDep) => CellDep.fromJson(cellDep))
            .toList(),
        headerDeps: (json['header_deps'] as List)
            .map((headerDep) => headerDep.toString())
            .toList(),
        inputs: (json['inputs'] as List)
            .map((input) => CellInput.fromJson(input))
            .toList(),
        outputs: (json['outputs'] as List)
            .map((output) => CellOutput.fromJson(output))
            .toList(),
        outputsData: (json['outputs_data'] as List)
            .map((outputData) => outputData.toString())
            .toList(),
        witnesses: (json['witnesses'] as List)
            .map((witness) => witness == '0x'
                ? witness
                : Witness(lock: Witness.SIGNATURE_PLACEHOLDER))
            .toList());
    tx.setScriptGroup();
    tx.setGroupWitnesses();
    return tx;
  }

  @override
  Map<String, dynamic> toBroadcast() {
    return {
      'version': version,
      'hash': hash,
      'cell_deps': cellDeps?.map((cellDep) => cellDep.toJson()).toList(),
      'header_deps': headerDeps,
      'inputs': inputs?.map((input) => input.toJson()).toList(),
      'outputs': outputs?.map((output) => output.toJson()).toList(),
      'outputs_data': outputsData,
      'witnesses': witnesses
          ?.map((witness) => witness is String ? witness : null)
          .toList()
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'hash': hash,
      'cell_deps': cellDeps?.map((cellDep) => cellDep.toJson()).toList(),
      'header_deps': headerDeps,
      'inputs': inputs?.map((input) => input.toJson()).toList(),
      'outputs': outputs?.map((output) => output.toJson()).toList(),
      'outputs_data': outputsData,
      'witnesses': witnesses
          ?.map((witness) => witness is String ? witness : null)
          .toList()
    };
  }

  setScriptGroup() {
    scriptGroup = ScriptGroup(regionToList(0, inputs!.length));
  }

  setGroupWitnesses() {
    if (witnesses!.length < inputs!.length) {
      throw Exception(
          'Transaction witnesses count must not be smaller than inputs count');
    }
    if (scriptGroup!.inputIndexes.isEmpty) {
      throw Exception('Need at least one witness!');
    }
    for (var index in scriptGroup!.inputIndexes) {
      groupWitnesses.add(witnesses![index]);
    }
    for (var i = inputs!.length; i < witnesses!.length; i++) {
      groupWitnesses.add(witnesses![i]);
    }
    if (groupWitnesses[0] is! Witness) {
      throw Exception('First witness must be of Witness type!');
    }
  }

  String getMessage() {
    final hash = Serializer.serializeRawTransaction(this).toBytes();
    var txHash =
        Blake2b.getBlake2bHash(hash, personalization: CKB_HASH_PERSONALIZATION);
    Witness emptiedWitness = groupWitnesses[0];
    emptiedWitness.lock = Witness.SIGNATURE_PLACEHOLDER;
    var witnessTable = Serializer.serializeWitnessArgs(emptiedWitness);
    var blake2b = Blake2b(personalization: CKB_HASH_PERSONALIZATION);
    blake2b.defaultUpdate(txHash);
    blake2b.defaultUpdate(UInt64.fromInt(witnessTable.getLength()).toBytes());
    blake2b.defaultUpdate(witnessTable.toBytes());
    for (var i = 1; i < groupWitnesses.length; i++) {
      Uint8List bytes;
      if (groupWitnesses[i] is Witness) {
        bytes = Serializer.serializeWitnessArgs(groupWitnesses[i]).toBytes();
      } else {
        bytes = dynamicToUint8List(groupWitnesses[i]);
      }
      blake2b.defaultUpdate(UInt64.fromInt(bytes.length).toBytes());
      blake2b.defaultUpdate(bytes);
    }
    return dynamicToHex(blake2b.doFinal());
  }

  setWitnesses() {
    final signedWitness = groupWitnesses[0];
    signedWitness.lock = signature;
    witnesses![scriptGroup!.inputIndexes[0]] =
        dynamicToHex(Serializer.serializeWitnessArgs(signedWitness).toBytes());
  }
}
