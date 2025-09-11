import 'package:test/test.dart';

import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

void main() async {
  const String TEST_DELEGATION_ADDRESS =
      '0x80296FF8D1ED46f8e3C7992664D13B833504c2Bb';
  String mnemonic =
      'number vapor draft title message quarter hour other hotel leave shrug donor';
  String sponsorMnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final wallet = await EthCoin.fromMnemonic(mnemonic);
  final sponsoredWallet = await EthCoin.fromMnemonic(sponsorMnemonic);

  final authorization = Eip7702Authorization(
    chainId: 11155111,
    address: TEST_DELEGATION_ADDRESS,
    gasPayerAddress: wallet.address,
    signerAddress: wallet
        .address, // gas payer can be different from signer. nonce will be increased by 1 or not.
    signerNonce: 150,
  );

  final txData = EthTxDataRaw(
      nonce: 150,
      gasLimit: 90000,
      value: BigInt.from(0),
      maxPriorityFeePerGas: 100000000,
      maxFeePerGas: 1500000000,
      to: wallet.address);

  final txNetwork = TxNetwork(chainId: 11155111);
  final eip7702transaction = Eip7702TxData(
      data: txData,
      network: txNetwork,
      authorization: authorization.sign(wallet.privateKey.toStr()));

  final signer = EthTxSigner(wallet, eip7702transaction);
  final signedTxData = signer.sign();

  final signedData = signedTxData.serialize().toStr();
  final deserializedTxData = Eip7702TxData.deserialize(signedData);

  test('test deserialize', () {
    expect(deserializedTxData.authorization.chainId,
        eip7702transaction.authorization.chainId);
    expect(deserializedTxData.authorization.address.toLowerCase(),
        eip7702transaction.authorization.address.toLowerCase());
    expect(deserializedTxData.authorization.signerNonce,
        eip7702transaction.authorization.signerNonce);

    expect(
        deserializedTxData.authorization.s, eip7702transaction.authorization.s);
    expect(
        deserializedTxData.authorization.r, eip7702transaction.authorization.r);
    expect(
        deserializedTxData.authorization.v, eip7702transaction.authorization.v);

    testAuth(eip7702transaction);

    final broadcastData = signedTxData.toBroadcast();
    expect(broadcastData['signature'], signedTxData.signature);
    final jsonData = signedTxData.toJson();
    expect(jsonData['data'], signedTxData.data.data);

    final hdData =
        deserializedTxData.txsMsg(jsonData['v'], jsonData['r'], jsonData['s']);
    assert(hdData.toStr().isNotEmpty);
  });

  test('gas sponsor demo', () {
    final calls = [
      {
        'target': '0x0000000000000000000000000000000000000001', // to
        'value': BigInt.from(10000000000000), // eth value
        'data': '0x'.toUint8List() // data
      },
    ];
    final sponsorAddress = sponsoredWallet.address;
    // from api.
    final message = getSponsorMessageToSign(calls, sponsorAddress);
    // sign by sponsor.
    final sponsorSignature = sponsoredWallet.signForSponsor(message);
    // from api.
    final txData = getSponsorData(calls, sponsorSignature);

    // operate by gas payer.
    final sponsorTxDataRaw = EthTxDataRaw(
        nonce: 1,
        gasLimit: 90000,
        value: BigInt.from(0),
        maxPriorityFeePerGas: 100000000,
        maxFeePerGas: 1500000000,
        to: sponsorAddress, // call sponsor address
        data: txData);

    final eip1559TxData = Eip1559TxData(
      data: sponsorTxDataRaw,
      network: TxNetwork(chainId: 11155111),
    );

    final gasPayer = EthTxSigner(wallet, eip1559TxData);
    final signedTxData = gasPayer.sign();

    final broadcastData = signedTxData.toBroadcast();
    expect(broadcastData['signature'], signedTxData.signature);
    final jsonData = signedTxData.toJson();
    expect(jsonData['data'], signedTxData.data.data);

    final hdData =
        deserializedTxData.txsMsg(jsonData['v'], jsonData['r'], jsonData['s']);
    assert(hdData.toStr().isNotEmpty);
  });

  test('signIng', () {
    final String signature =
        eip7702transaction.signIng(wallet.privateKey.toStr());
    final String target =
        "0&5293d5f8d78a624a168b2ed73dbdab3c268981ccdbaee6e986a58de3ece38e58&12657b00bae3e21898bfc5226f42d1ba8d63ef2a4a3bc2b02b8e5ce185063026";
    expect(signature, target);
  });
}

// get by api.
String getSponsorMessageToSign(
    List<Map<String, dynamic>> calls, String sponsorAddress) {
  return '0xed1c35ae916c40bc6d1bd62225adc59f00cb68d5ff60d61f1fd20893c78280c3';
}

// get data.
String getSponsorData(List<Map<String, dynamic>> calls, String signature) {
  return '0xfcfbd33a0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000023ab32843d51fd619464d5d4216d27f2b37e9110000000000000000000000000000000000000000000000000000009184e72a0000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000413dc190a7f3ab7e868b9cd88d365f2f6c4d3f296d7bec3fb73c451edcfc3cb7835135f76951381c133e89f56f67201d6ef211e2252f1b34bd3533cfe3516732761b00000000000000000000000000000000000000000000000000000000000000';
}

testAuth(EthTxData auth) {
  print(auth.authorization.toJson());
}
