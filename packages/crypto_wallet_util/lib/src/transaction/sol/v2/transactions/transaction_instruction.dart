import 'dart:typed_data';

import 'package:bs58check/bs58check.dart';

import '../crypto/pubkey.dart';
import '../messages/message_instruction.dart';
import '../transactions/account_meta.dart';

/// Transaction Instruction
/// ------------------------------------------------------------------------------------------------
class TransactionInstruction {
  /// A TransactionInstruction object.
  TransactionInstruction({
    required this.keys,
    required this.programId,
    required this.data,
  });

  /// Public keys to include in this transaction.
  final List<AccountMeta> keys;

  //// Program Id to execute
  final Pubkey programId;

  /// Program input
  final Uint8List data;

  /// Converts this [TransactionInstruction] into an [MessageInstruction]. The [keys] are an ordered
  /// list of `all` public keys referenced by this transaction.
  MessageInstruction toMessageInstruction(final List<Pubkey> keys) =>
      MessageInstruction(
        programIdIndex: keys.indexOf(programId),
        accounts: this
            .keys
            .map((final AccountMeta meta) => keys.indexOf(meta.pubkey)),
        data: base58.encode(Uint8List.fromList(data)),
      );
}
