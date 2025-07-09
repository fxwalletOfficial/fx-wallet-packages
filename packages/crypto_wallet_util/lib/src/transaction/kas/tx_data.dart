import 'package:crypto_wallet_util/src/type/tx_data_type.dart';
import 'kas_lib.dart';

/// [KasTxData] requires [version], [inputs], [outputs], [lockTime], [subnetworkId], [allowOrphan]
/// [inputs] is the parameter to be signed.
class KasTxData extends TxData {
  final int version;
  final List<Input> inputs;
  final List<Output> outputs;
  final String lockTime;
  final String subnetworkId;
  final bool allowOrphan;
  List<String> messages = [];

  KasTxData(
      {required this.version,
      required this.inputs,
      required this.outputs,
      required this.lockTime,
      required this.subnetworkId,
      required this.allowOrphan});

  factory KasTxData.fromJson(Map<String, dynamic> json) {
    List<Input> inputs = (json['transaction_kaspa']['inputs'] as List)
        .map((input) => Input.fromJson(input))
        .toList();
    List<Output> outputs = (json['transaction_kaspa']['outputs'] as List)
        .map((output) => Output.fromJson(output))
        .toList();

    return KasTxData(
      version: json['transaction_kaspa']['version'],
      inputs: inputs,
      outputs: outputs,
      lockTime: json['transaction_kaspa']['lockTime'],
      subnetworkId: json['transaction_kaspa']['subnetworkId'],
      allowOrphan: json['allowOrphan'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'transaction_kaspa': {
        'version': version,
        'inputs': inputs.map((input) => input.toJson()).toList(),
        'outputs': outputs.map((output) => output.toJson()).toList(),
        'lockTime': lockTime,
        'subnetworkId': subnetworkId
      },
      'allowOrphan': allowOrphan,
    };
  }

  @override
  Map<String, dynamic> toBroadcast() {
    if (!isSigned) return {};
    return {
      'transaction': {
        'version': version,
        'inputs': inputs.map((input) => input.toJson()).toList(),
        'outputs': outputs.map((output) => output.toJson()).toList(),
        'lockTime': lockTime,
        'subnetworkId': subnetworkId
      },
      'allowOrphan': allowOrphan,
    };
  }
}
