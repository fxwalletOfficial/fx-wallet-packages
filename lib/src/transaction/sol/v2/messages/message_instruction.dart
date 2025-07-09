/// Message Instruction
class MessageInstruction {

  /// An instruction to execute by a program.
  const MessageInstruction({
    required this.programIdIndex,
    required this.accounts,
    required this.data,
  });

  /// Index into the [Message.accountKeys] array indicating the program account that executes this
  /// instruction.
  final int programIdIndex;

  /// List of ordered indices into the message.accountKeys array indicating which accounts to pass
  /// to the program.
  final Iterable<int> accounts;

   /// The program's input data encoded as a `base-58` string.
  final String data;
}
