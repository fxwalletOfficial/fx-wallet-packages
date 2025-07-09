import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/xrpl/models/xrp_transactions.dart';

/// Represents a DIDDelete transaction.
class DIDDelete extends XRPTransaction {
  DIDDelete.fromJson(super.json) : super.json();

  DIDDelete(
      {required super.account,
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
            transactionType: XRPLTransactionType.didDelete);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    return json;
  }
}
