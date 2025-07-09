// ignore_for_file: avoid_print

import 'package:crypto_wallet_util/crypto_utils.dart';

void main() async {
  /// prepare mnemonic
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';

  /// get wallet
  final WalletType wallet = await AlphCoin.fromMnemonic(mnemonic);

  /// prepare txData
  final Map<String, dynamic> transactionJson = {
    "rawTransaction":
        "00010080004e20c1174876e800010d520e8f8e22db7212974db72229fec7ca2c06d20909eded1e590a3fd75b8e8dbe51c6d80003924ffa00114be641f4ee20bd43bcee300c457751812683eda8e09f2e1a7321c202c4016345785d8a0000003446ca3b43c708d23da2dc2433c2319e1c2cae60437550f6e6b0b196dc83cd5900000000000000000000c49f667825022300000062ccfe193ec1c3d1f3c277668bc8b27fa0ed013c5d3676dc04c76833e6f06de300000000000000000000",
    "txId": "56a026c3aa3dbad056d5f21c6a8cde407f647822ac9be95cfbe3a63a614295d0"
  };

  /// create txData
  final AlphTxData txData = AlphTxData.fromJson(transactionJson);

  /// create signer
  final AlphTxSigner signer = AlphTxSigner(wallet, txData);

  /// sign message
  final AlphTxData signedTxData = signer.sign();

  /// verify signature
  print(signer.verify());

  /// get pending transactions for broadcast
  print(signedTxData.toBroadcast());
}
