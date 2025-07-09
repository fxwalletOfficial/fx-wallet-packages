import 'package:crypto_wallet_util/src/type/type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/transaction/sol/v2/solana.dart';

/// Provide another way to get [SolTxData]
class SolTxDataV2 extends TxData {
  final SolanaTransaction solanaTransaction;

  SolTxDataV2(this.solanaTransaction);

  factory SolTxDataV2.fromJson(Map<String, dynamic> params) {
    final tx = SolanaTransaction.legacy(
        payer: Pubkey.fromString(params['feePayer']),
        recentBlockhash: params['recentBlockhash'],
        instructions: (params['instructions'] as List).map((item) {
          final data =
              (item['data'] as List).map((e) => NumberUtil.toInt(e)).toList();

          return TransactionInstruction(
              data: data.toUint8List(),
              programId: Pubkey.fromString(item['programId']),
              keys: (item['keys'] as List)
                  .map((k) => AccountMeta(Pubkey.fromString(k['pubkey']),
                      isSigner: k['isSigner'], isWritable: k['isWritable']))
                  .toList());
        }).toList());

    return SolTxDataV2(tx);
  }

  @override
  Map<String, dynamic> toBroadcast() {
    return {};
  }

  @override
  Map<String, dynamic> toJson() {
    return {};
  }
}
