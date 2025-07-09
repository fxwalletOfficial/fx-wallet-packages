import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/number/number_parser.dart';
import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/xrpl/models/xrp_transactions.dart';

class XChainModifyBridgeFlag implements FlagsInterface {
  // Transactions of the XChainModifyBridge type support additional values in the Flags
  // field. This enum represents those options.

  // Represents the option to clear account create amount in XChainModifyBridge transactions.
  static const XChainModifyBridgeFlag tfClearAccountCreateAmount =
      XChainModifyBridgeFlag._(0x00010000);

  final int value;

  // Constructor for XChainModifyBridgeFlag.
  const XChainModifyBridgeFlag._(this.value);

  @override
  int get id => value;
}

class XChainModifyBridgeFlagInterface {
  const XChainModifyBridgeFlagInterface(
      {required this.tfClearAccountCreateAmount});

  /// Transactions of the XChainModifyBridge type support additional values in the Flags
  /// field. This TypedDict represents those options.
  final bool tfClearAccountCreateAmount;
}

class XChainModifyBridge extends XRPTransaction {
  XChainModifyBridge.fromJson(super.json)
      : xchainBridge = XChainBridge.fromJson(json["xchain_bridge"]),
        signatureReward = parseBigInt(json["signature_reward"]),
        minAccountCreateAmount = parseBigInt(json["min_account_create_amount"]),
        super.json();

  /// Represents a XChainModifyBridge transaction.
  /// The XChainModifyBridge transaction allows bridge managers to modify the
  /// parameters of the bridge.
  final XChainBridge xchainBridge;

  /// The bridge to modify. This field is required.
  final BigInt? signatureReward;

  /// The signature reward split between the witnesses for submitting
  /// attestations.
  final BigInt? minAccountCreateAmount;

  // XChainModifyBridge({required String account, required super.transactionType});
  XChainModifyBridge(
      {required this.xchainBridge,
      this.signatureReward,
      this.minAccountCreateAmount,
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
          transactionType: XRPLTransactionType.xChainModifyBridge,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      "xchain_bridge": xchainBridge.toJson(),
      "signature_reward": signatureReward?.toString(),
      "min_account_create_amount": minAccountCreateAmount?.toString(),
      ...super.toJson()
    };
  }
}
