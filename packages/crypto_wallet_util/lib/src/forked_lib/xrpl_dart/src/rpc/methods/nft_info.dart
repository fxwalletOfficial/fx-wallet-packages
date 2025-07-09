import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/rpc/methods/methods.dart';
import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/rpc/on_chain_models/on_chain_models.dart';
import '../core/methods_impl.dart';

/// The `nft_info` method retrieves all the information about the
/// NFToken
class RPCNFTInfo extends XRPLedgerRequest<Map<String, dynamic>> {
  RPCNFTInfo({
    required this.nftId,
    super.ledgerIndex = XRPLLedgerIndex.validated,
  });
  @override
  String get method => XRPRequestMethod.nftInfo;

  final String nftId;

  @override
  Map<String, dynamic> toJson() {
    return {"nft_id": nftId};
  }
}
