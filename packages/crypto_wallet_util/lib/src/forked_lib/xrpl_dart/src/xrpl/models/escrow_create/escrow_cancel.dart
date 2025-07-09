import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/xrpl/models/xrp_transactions.dart';

/// Represents an [EscrowCancel](https://xrpl.org/escrowcancel.html)
/// transaction, which returns escrowed XRP to the sender after the Escrow has
/// expired.
class EscrowCancel extends XRPTransaction {
  /// [owner] The address of the account that funded the Escrow.
  final String owner;

  /// [offerSequence] Transaction sequence (or Ticket number) of the EscrowCreate transaction that created the Escrow.
  final int offerSequence;

  EscrowCancel(
      {required super.account,
      required this.owner,
      required this.offerSequence,
      super.memos,
      super.signingPubKey,
      super.ticketSequance,
      super.fee,
      super.lastLedgerSequence,
      super.sequence,
      super.signers,
      super.flags = null,
      super.sourceTag,
      super.multiSigSigners})
      : super(
            transactionType: XRPLTransactionType.escrowCancel);

  /// Converts the object to a JSON representation.
  @override
  Map<String, dynamic> toJson() {
    return {"owner": owner, "offer_sequence": offerSequence, ...super.toJson()};
  }

  EscrowCancel.fromJson(super.json)
      : owner = json["owner"],
        offerSequence = json["offer_sequence"],
        super.json();
}
