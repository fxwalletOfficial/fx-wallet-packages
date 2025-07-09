import 'dart:typed_data';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/numbers/bigint_utils.dart';
import 'package:blockchain_utils/numbers/int_utils.dart';
import 'package:blockchain_utils/tuple/tuple.dart';

import '../script/script.dart';

/// Represents a transaction output.
///
/// [amount] the value we want to send to this output in satoshis
/// [scriptPubKey] the script that will lock this amount
class TxOutput {
  TxOutput({required this.amount, required this.scriptPubKey});
  final BigInt amount;
  final Script scriptPubKey;

  ///  creates a copy of the object
  TxOutput copy() {
    return TxOutput(amount: amount, scriptPubKey: scriptPubKey);
  }

  /// serializes TxInput to bytes
  List<int> toBytes() {
    final amountBytes =
        BigintUtils.toBytes(amount, length: 8, order: Endian.little);
    List<int> scriptBytes = scriptPubKey.toBytes();
    final data = [
      ...amountBytes,
      ...IntUtils.encodeVarint(scriptBytes.length),
      ...scriptBytes
    ];
    return data;
  }

  static Tuple<TxOutput, int> fromRaw(
      {required String raw, required int cursor, bool hasSegwit = false}) {
    final txoutPutRaw = BytesUtils.fromHexString(raw);
    final value = BigintUtils.fromBytes(txoutPutRaw.sublist(cursor, cursor + 8),
            byteOrder: Endian.little)
        .toSigned(64);
    cursor += 8;

    final vi = IntUtils.decodeVarint(txoutPutRaw.sublist(cursor, cursor + 9));
    cursor += vi.item2;
    List<int> lockScript = txoutPutRaw.sublist(cursor, cursor + vi.item1);
    cursor += vi.item1;
    return Tuple(
        TxOutput(
            amount: value,
            scriptPubKey: Script.fromRaw(
                hexData: BytesUtils.toHexString(lockScript),
                hasSegwit: hasSegwit)),
        cursor);
  }
}
