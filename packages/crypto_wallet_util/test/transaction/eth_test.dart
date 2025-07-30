import 'dart:typed_data';

import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/utils.dart';
import 'package:test/test.dart';

void main() {
  var privateKey =
      '3c9229289a6125f7fdf1885a77bb12c37a8d3b4962d936f7e3084dece32a3ca1';
  final WalletType wallet = EthCoin.fromPrivateKey(privateKey);
  TxNetwork txNetwork = TxNetwork(chainId: 1);

  EthTxDataRaw txData = EthTxDataRaw(
    nonce: 0,
    gasLimit: 21000,
    value: BigInt.from(10),
    to: '0x1234567890abcdef',
  );
  group('EIP1559 transition', () {
    Eip1559TxData eip1559transaction =
        Eip1559TxData(data: txData, network: txNetwork);
    const targetSignature =
        "02f85601808080825208881234567890abcdef0a80c080a0fe52d1ef3b2ede9e83b6e3ffccde63c6f125228e28b640d0736509b23b50df17a0535c3c92bf39ddc838f2d1ed0d5c91061d35a4bc4bb4a99f282dbe775181d7a0";
    final signer = EthTxSigner(wallet, eip1559transaction);
    Uint8List signature;
    final signedTxData = signer.sign();
    signature = signedTxData.serialize();
    test('sign', () {
      expect(signedTxData.signature.toUint8List(), signature);
      expect(signature.toUint8List(), targetSignature.toUint8List());
      assert(signer.verify());

      final broadcastData = signedTxData.toBroadcast();
      expect(broadcastData['signature'], signature.toStr());
      final jsonData = signedTxData.toJson();
      expect(jsonData['data'], signedTxData.data.data);

      final hdData = eip1559transaction.txsMsg(jsonData['v'], jsonData['r'], jsonData['s']);
      assert(hdData.toStr().isNotEmpty);
    });

    test('deserialize', () {
      final EthTxData txData = Eip1559TxData.deserialize(signature.toStr());
      expect(txData.serialize(), signature);
    });

    test('signIng', () {
      final String signature =
          eip1559transaction.signIng(privateKey.toUint8List());
      final String target =
          "0&fe52d1ef3b2ede9e83b6e3ffccde63c6f125228e28b640d0736509b23b50df17&535c3c92bf39ddc838f2d1ed0d5c91061d35a4bc4bb4a99f282dbe775181d7a0";
      expect(signature, target);
    });
  });

  group('legacy transition', () {
    LegacyTxData legacyTransaction =
        LegacyTxData(data: txData, network: txNetwork);
    const targetSignature =
        "f8538080825208881234567890abcdef0a8026a0d8a3b9c6322344dbec2e0f947f577dd596cd53ed4adb3f8c0d14ce691474de4da062d12d9194e0c45ba2d0b039be086d5718ee6ace290be0b78a873b0edd829ee2";
    final signer = EthTxSigner(wallet, legacyTransaction);
    Uint8List signature;
    final signedTxData = signer.sign();
    signature = signedTxData.serialize();
    test('sign', () {
      expect(signedTxData.signature.toUint8List(), signature);
      expect(signature.toUint8List(), targetSignature.toUint8List());
      assert(signer.verify());

      final broadcastData = signedTxData.toBroadcast();
      expect(broadcastData['signature'], signature.toStr());
      final jsonData = signedTxData.toJson();
      expect(jsonData['data'], signedTxData.data.data);

      final hdData = legacyTransaction.txsMsg(jsonData['v'], jsonData['r'], jsonData['s']);
      assert(hdData.toStr().isNotEmpty);
    });

    test('deserialize', () {
      final EthTxData txData = LegacyTxData.deserialize(signature.toStr());
      expect(txData.serialize(), signature);
    });

    test('signIng', () {
      final String signature =
          legacyTransaction.signIng(privateKey.toUint8List());
      final String target =
          "26&d8a3b9c6322344dbec2e0f947f577dd596cd53ed4adb3f8c0d14ce691474de4d&62d12d9194e0c45ba2d0b039be086d5718ee6ace290be0b78a873b0edd829ee2";
      expect(signature, target);
    });
  });
}
