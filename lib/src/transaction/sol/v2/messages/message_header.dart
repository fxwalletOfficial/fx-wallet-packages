/// Message Header
/// ------------------------------------------------------------------------------------------------
class MessageHeader {

  /// Details the account types and signatures required by the transaction (signed and read-only
  /// accounts).
  const MessageHeader({
    required this.numRequiredSignatures,
    required this.numReadonlySignedAccounts,
    required this.numReadonlyUnsignedAccounts
  });

  /// The total number of signatures required to make the transaction valid. The signatures must
  /// match the first `numRequiredSignatures` of [Message.accountKeys].
  final int numRequiredSignatures;

  /// The last `numReadonlySignedAccounts` of the signed keys are read-only accounts.
  final int numReadonlySignedAccounts;

  /// The last `numReadonlyUnsignedAccounts` of the unsigned keys are read-only accounts.
  final int numReadonlyUnsignedAccounts;
}
