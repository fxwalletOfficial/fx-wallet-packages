import '../crypto/pubkey.dart';

/// Account Meta
/// ------------------------------------------------------------------------------------------------

class AccountMeta {

  /// Account metadata used to define instruction accounts.
  const AccountMeta(
    this.pubkey, {
    this.isSigner = false,
    this.isWritable = false,
  });

  /// An account's public key.
  final Pubkey pubkey;

  /// True if an instruction requires a transaction signature matching `pubkey`.
  final bool isSigner;

  /// True if the `pubkey` can be loaded as a read-write account.
  final bool isWritable;

  /// Creates a signer account.
  factory AccountMeta.signer(final Pubkey pubkey, { final bool isWritable = false })
    => AccountMeta(pubkey, isSigner: true, isWritable: isWritable);

  /// Creates a writable account.
  factory AccountMeta.writable(final Pubkey pubkey, { final bool isSigner = false })
    => AccountMeta(pubkey, isSigner: isSigner, isWritable: true);

  /// Creates a signer and writable account.
  factory AccountMeta.signerAndWritable(final Pubkey pubkey)
    => AccountMeta(pubkey, isSigner: true, isWritable: true);

  /// Creates a copy of this class applying the provided parameters to the new instance.
  AccountMeta copyWith({
    final Pubkey? pubkey,
    final bool? isSigner,
    final bool? isWritable,
  }) {
    return AccountMeta(
      pubkey ?? this.pubkey,
      isSigner: isSigner ?? this.isSigner,
      isWritable: isWritable ?? this.isWritable,
    );
  }
}