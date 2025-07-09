import '../crypto/buffer.dart';
import '../crypto/pubkey.dart';
import '../transactions/account_meta.dart';
import '../transactions/transaction_instruction.dart';

/// Program
/// ------------------------------------------------------------------------------------------------

abstract class Program {
  /// Solana program.
  const Program(this.pubkey);

  /// The public key that identifies this program (i.e. program id).
  final Pubkey pubkey;

  /// Encodes the program [instruction].
  Iterable<int> encodeInstruction<T extends Enum>(final T instruction) =>
      Buffer.fromUint8(instruction.index);

  /// Creates a [TransactionInstruction] for the program [instruction].
  TransactionInstruction createTransactionIntruction(
    final Enum instruction, {
    required final List<AccountMeta> keys,
    final List<Iterable<int>> data = const [],
  }) {
    return TransactionInstruction(
      keys: keys,
      programId: pubkey,
      data: Buffer.flatten([encodeInstruction(instruction), ...data])
          .asUint8List(),
    );
  }
}
