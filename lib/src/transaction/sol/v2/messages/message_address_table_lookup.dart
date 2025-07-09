import '../crypto/pubkey.dart';

/// Message Address Table Lookup
/// ------------------------------------------------------------------------------------------------
class MessageAddressTableLookup {

  /// Used by a transaction to dynamically load addresses from on-chain address lookup tables.
  const MessageAddressTableLookup({
    required this.accountKey,
    required this.writableIndexes,
    required this.readonlyIndexes,
  });

  /// A base-58 encoded public key for an address lookup table account.
  final Pubkey accountKey;

  /// A List of indices used to load addresses of writable accounts from a lookup table.
  final List<int> writableIndexes;

   /// A list of indices used to load addresses of readonly accounts from a lookup table.
  final List<int> readonlyIndexes;
}