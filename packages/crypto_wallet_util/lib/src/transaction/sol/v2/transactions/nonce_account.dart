import '../crypto/pubkey.dart';

/// Nonce Account
/// ------------------------------------------------------------------------------------------------
class NonceAccount {
  /// https://docs.solana.com/offline-signing/durable-nonce
  ///
  /// Durable transaction nonces are a mechanism for getting around the typical short lifetime of a
  /// transaction's recent_blockhash.
  ///
  /// Each transaction submitted on Solana must specify a recent blockhash that was generated within
  /// 2 minutes of the latest blockhash. If it takes longer than 2 minutes to get everybody’s
  /// signatures, then you have to use nonce accounts.
  ///
  /// For example, nonce accounts are used in cases when you need multiple people to sign a
  /// transaction, but they can’t all be available to sign it on the same computer within a short
  /// enough time period.
  const NonceAccount({
    required this.version,
    required this.state,
    required this.authorizedPubkey,
    required this.nonce
  });

  /// Version.
  final int version;

  /// Account state.
  final int state;

  /// The authority of the nonce account.
  final Pubkey authorizedPubkey;

  /// Durable nonce (32 byte base-58 encoded string).
  final String nonce;
}
