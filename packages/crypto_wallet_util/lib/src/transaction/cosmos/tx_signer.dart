import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/crypto/secp256k1/export.dart';
import 'package:crypto_wallet_util/src/transaction/cosmos/tx_data.dart';
import 'package:crypto_wallet_util/src/type/type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Require [CosmosTxData] and wallet. 
class CosmosTxSigner extends TxSigner {
  @override
  final CosmosTxData txData;

  CosmosTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  String sign() {
    // Set the config to the default value if not given
    txData.config ??= DefaultTxConfig.create();
    final signMode = txData.config!.defaultSignMode();

    // Set the default fees
    txData.fee ??= Fee()..gasLimit = 250000.toInt64();
    if (!txData.fee!.hasGasLimit())
      throw Exception('Invalid fees: invalid gas amount specified');

    // Get the public key from the account, or generate it if the chain does not have it yet
    final secp256Key = PubKey.create()..key = wallet.publicKey;
    final pubKey = Codec.serialize(secp256Key);
    var sigData = SingleSignatureData(signMode: signMode, signature: null);

    // Set SignatureV2 with empty signatures, to set correct signer infos.
    var sig = SignatureV2(
      pubKey: pubKey,
      data: sigData,
      sequence: txData.data.sequence,
    );

    // Create the transaction builder
    final tx = txData.config!.newTxBuilder()
      ..setMsgs(txData.msgs)
      ..setSignatures([sig])
      ..setMemo(txData.memo)
      ..setFeeAmount(txData.fee!.amount)
      ..setFeePayer(txData.fee!.payer)
      ..setFeeGranter(txData.fee!.granter)
      ..setGasLimit(txData.fee!.gasLimit);

    // Generate the bytes to be signed.
    final handler = txData.config!.signModeHandler();
    final bytesToSign = handler.getSignBytes(signMode, txData.data, tx.getTx());

    // Sign those bytes
    final sigBytes = wallet.sign(dynamicToString(bytesToSign));
    txData.message = dynamicToString(bytesToSign);
    txData.signature = sigBytes;
    txData.isSigned = true;
    // Construct the SignatureV2
    sigData = SingleSignatureData(
        signMode: signMode, signature: dynamicToUint8List(sigBytes));
    sig = SignatureV2(
      pubKey: pubKey,
      data: sigData,
      sequence: txData.data.sequence,
    );
    tx.setSignatures([sig]);

    // Return the signed transaction
    final encoder = txData.config!.txEncoder();
    return dynamicToString(encoder(tx.getTx()));
  }
}
