import 'transaction_instruction.dart';

/// Nonce Information
/// ------------------------------------------------------------------------------------------------
class NonceInformation {

  /// Nonce information to be used to build an offline Transaction.
  const NonceInformation({
    required this.nonce,
    required this.nonceInstruction,
  });

  /// The current blockhash stored in the nonce.
  final String nonce;

  /// AdvanceNonceAccount Instruction
  final TransactionInstruction nonceInstruction;
}
