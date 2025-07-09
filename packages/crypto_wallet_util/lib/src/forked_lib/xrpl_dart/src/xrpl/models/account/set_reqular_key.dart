import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/xrpl/models/xrp_transactions.dart';

/// Represents a [SetRegularKey](https://xrpl.org/setregularkey.html)
/// transaction, which assigns, changes, or removes a secondary "regular" key pair
/// associated with an account.
class SetRegularKey extends XRPTransaction {
  /// [regularKey] The classic address derived from the key pair to authorize for this
  /// account. If omitted, removes any existing regular key pair from the
  /// account. Must not match the account's master key pair.
  final String? regularKey;

  SetRegularKey(
      {this.regularKey,
      required super.account,
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
            transactionType: XRPLTransactionType.setRegularKey);

  /// Converts the object to a JSON representation.
  @override
  Map<String, dynamic> toJson() {
    return {
      "regular_key": regularKey,
      ...super.toJson(),
    };
  }

  SetRegularKey.fromJson(super.json)
      : regularKey = json["regular_key"],
        super.json();
}
