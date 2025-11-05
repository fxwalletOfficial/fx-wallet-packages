import 'dart:convert';
import 'dart:typed_data';

import 'package:bs58check/bs58check.dart';

import '../crypto/buffer.dart';
import '../crypto/keypair.dart';
import '../crypto/nacl.dart' as nacl;
import '../crypto/pubkey.dart';
import '../crypto/shortvec.dart' as shortvec;
import '../messages/message.dart';
import '../programs/address_lookup_table/state.dart';
import 'transaction_instruction.dart';

/// Transaction
/// ------------------------------------------------------------------------------------------------

class SolanaTransaction {
  /// One or more signatures for the transaction. Typically created by invoking the [sign] method.
  final List<Uint8List> signatures;

  /// One or more signatures for the transaction. Typically created by invoking the [sign] method.
  final Message message;

  /// Transaction.
  SolanaTransaction({final List<Uint8List>? signatures, required this.message})
      : signatures = signatures ?? [] {
    if (this.signatures.isEmpty) {
      for (int i = 0; i < message.header.numRequiredSignatures; i++) {
        this.signatures.add(Uint8List(nacl.signatureLength));
      }
      return;
    }

    if (this.signatures.length != message.header.numRequiredSignatures)
      throw Exception(
          'Number of required signatures mismatch: ${message.header.numRequiredSignatures}.');
  }

  /// The first Transaction signature (fee payer).
  Uint8List? get signature => signatures.isNotEmpty ? signatures.first : null;

  /// The transaction/message version (`null` == legacy).
  int? get version => message.version;

  /// The transaction/message blockhash.
  String get blockhash => message.recentBlockhash;

  /// Creates a `legacy` transaction.
  factory SolanaTransaction.legacy({
    final List<Uint8List>? signatures,
    required final Pubkey payer,
    required final List<TransactionInstruction> instructions,
    required final String recentBlockhash,
  }) =>
      SolanaTransaction(
          signatures: signatures,
          message: Message.legacy(
              payer: payer,
              instructions: instructions,
              recentBlockhash: recentBlockhash));

  /// Creates a `v0` transaction.
  factory SolanaTransaction.v0({
    final List<Uint8List>? signatures,
    required final Pubkey payer,
    required final List<TransactionInstruction> instructions,
    required final String recentBlockhash,
    final List<AddressLookupTableAccount>? addressLookupTableAccounts,
  }) =>
      SolanaTransaction(
        signatures: signatures,
        message: Message.v0(
          payer: payer,
          instructions: instructions,
          recentBlockhash: recentBlockhash,
          addressLookupTableAccounts: addressLookupTableAccounts,
        ),
      );

  Buffer serialize() {
    // Create a writable buffer large enough to store the transaction data.
    final BufferWriter serializedTransaction = BufferWriter(2048);

    /// Serialize the transaction message.
    final Buffer serializedMessage = message.serialize();

    // Write the [signatures] encoded length.
    final List<int> signaturesEncodedLength =
        shortvec.encodeLength(signatures.length);
    serializedTransaction.setBuffer(signaturesEncodedLength);

    /// Write the [signatures].
    for (final Uint8List signature in signatures) {
      serializedTransaction.setBuffer(signature);
    }

    /// Write the [message].
    serializedTransaction.setBuffer(serializedMessage);

    /// Resize the buffer.
    return serializedTransaction.toBuffer(slice: true);
  }

  Buffer serializeMessage() => message.serialize();

  /// Decodes a `base-58` [encoded] transaction into a [Transaction] object.
  factory SolanaTransaction.fromBase58(final String encoded) =>
      SolanaTransaction.deserialize(base58.decode(encoded));

  /// Decodes a `base-64` [encoded] transaction into a [Transaction] object.
  factory SolanaTransaction.fromBase64(final String encoded) =>
      SolanaTransaction.deserialize(base64.decode(encoded));

  /// Decodes a serialized transaction into a [Transaction] object.
  factory SolanaTransaction.deserialize(
    final Iterable<int> bytes,
  ) {
    // Create a buffer reader over the serialized transaction data.
    final BufferReader reader = BufferReader.fromList(bytes);

    // Read the [signatures].
    final List<Uint8List> signatures = [];
    final int signaturesLength = shortvec.decodeLength(reader);
    for (int i = 0; i < signaturesLength; ++i) {
      signatures.add(reader.getBuffer(nacl.signatureLength).asUint8List());
    }

    // Read the [message].
    final Message message = Message.fromBufferReader(reader);

    // Create the [Transaction].
    return SolanaTransaction(signatures: signatures, message: message);
  }

  /// Signs this [Transaction] with the specified signers. Multiple signatures may be applied to a
  /// [Transaction]. The first signature is considered 'primary' and is used to identify and confirm
  /// transactions.
  void sign(final List<Signer> signers) {
    final Uint8List serializedMessage = message.serialize().asUint8List();
    final int numRequiredSignatures = message.header.numRequiredSignatures;
    final List<Pubkey> signerPubkeys =
        message.accountKeys.sublist(0, numRequiredSignatures);
    for (final Signer signer in signers) {
      final int signerIndex = signerPubkeys.indexOf(signer.pubkey);
      if (signerIndex < 0) throw Exception('Unknown transaction signer.');

      signatures[signerIndex] =
          nacl.sign.detached.sync(serializedMessage, signer.seckey);
    }
  }

  /// Add an externally created [signature] to a transaction. The [pubkey] must correspond to the
  /// fee payer or a signer account in the transaction instructions ([Message.accountKeys]).
  void addSignature(final Pubkey pubkey, final Uint8List signature) {
    if (signature.length != nacl.signatureLength)
      throw Exception('Invalid signature length ${signature.length}');

    final int numRequiredSignatures = message.header.numRequiredSignatures;
    final List<Pubkey> signerPubkeys =
        message.accountKeys.sublist(0, numRequiredSignatures);
    final int signerIndex =
        signerPubkeys.indexWhere((signerPubkey) => signerPubkey == pubkey);
    if (signerIndex < 0) throw Exception('Unknown transaction signer.');

    signatures[signerIndex] = signature;
  }
}
