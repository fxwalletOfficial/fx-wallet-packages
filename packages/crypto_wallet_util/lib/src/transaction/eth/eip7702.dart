import 'dart:typed_data';

import 'package:crypto_wallet_util/src/transaction/eth/lib/eth_lib.dart';
import 'package:crypto_wallet_util/src/transaction/eth/tx_data.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'lib/rlp.dart' as rlp;

class Eip7702TxData extends EthTxData {
  final Uint8List TxTypeBuffer = Uint8List.fromList([4]);
  Eip7702Authorization authorization;

  Eip7702TxData(
      {required super.data,
      required super.network,
      required this.authorization})
      : super(txType: EthTxType.eip7702);

  @override
  List raw() {
    return [
      intToBuffer(network.chainId),
      intToBuffer(data.nonce),
      intToBuffer(data.maxPriorityFeePerGas),
      intToBuffer(data.maxFeePerGas),
      intToBuffer(data.gasLimit),
      dynamicToUint8List(data.to),
      intToBuffer(data.value),
      dynamicToUint8List(data.data),
      [],
      [
        [
          intToBuffer(authorization.chainId),
          dynamicToUint8List(authorization.address),
          intToBuffer(authorization.signerNonce),
          authorization.v == null ? [] : intToBuffer(authorization.v!),
          authorization.r == null ? [] : dynamicToUint8List(authorization.r),
          authorization.s == null ? [] : dynamicToUint8List(authorization.s),
        ]
      ],
      data.v == null ? [] : intToBuffer(data.v),
      data.r == null ? [] : intToBuffer(data.r),
      data.s == null ? [] : intToBuffer(data.s)
    ];
  }

  /// Returns the serialized encoding of the EIP-1559 transaction.
  /// If [sig] is true, return with signature, false without signature. Default is true.
  @override
  Uint8List serialize({bool sig = true}) {
    final base = sig ? raw() : raw().sublist(0, 10);
    return Uint8List.fromList(TxTypeBuffer + rlp.encode(base));
  }

  /// Returns the serialized unsigned tx (hashed or raw), which can be used.
  @override
  Uint8List getMessageToSign() {
    List base = raw().sublist(0, 10);
    var msg = TxTypeBuffer + rlp.encode(base);

    return getKeccakDigest(dynamicToUint8List(msg));
  }

  // for hd wallet
  Uint8List txsMsg(int v, BigInt r, BigInt s) {
    if (v == 0 || v == 1) {
      data.v = v;
    } else if (v == 27 || v == 28) {
      data.v = v - 27;
    } else {
      data.v = v;
    }
    data.r = r;
    data.s = s;

    return serialize();
  }

  String signIng(String privateKey) {
    // sign tx
    var msg = getMessageToSign();
    EcdaSignature result = EcdaSignature.signForEth(
        dynamicToUint8List(msg), privateKey.toUint8List());
    return "${(result.v - 27).toRadixString(16)}&${result.r.toStr()}&${result.s.toStr()}";
  }

  @override
  Map<String, dynamic> toBroadcast() {
    return {'signature': signature};
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'nonce': data.nonce,
      'gasPrice': data.gasPrice,
      'gasLimit': data.gasLimit,
      'to': data.to,
      'value': data.value,
      'data': data.data,
      'authorization': authorization.toJson(),
      'v': data.v,
      'r': data.r,
      's': data.s,
    };
  }

  factory Eip7702TxData.deserialize(String hash) {
    /// delete transaction type
    final data = hash.substring(2);
    final decodeData = rlp.decode(dynamicToUint8List(data));
    final chainId = hexToBigInt(dynamicToString(decodeData[0])).toInt();

    final txData = EthTxDataRaw(
        nonce: hexToBigInt(dynamicToString(decodeData[1])).toInt(),
        maxPriorityFeePerGas:
            hexToBigInt(dynamicToString(decodeData[2])).toInt(),
        maxFeePerGas: hexToBigInt(dynamicToString(decodeData[3])).toInt(),
        gasLimit: hexToBigInt(dynamicToString(decodeData[4])).toInt(),
        to: dynamicToHex(decodeData[5]),
        value: hexToBigInt(dynamicToString(decodeData[6])),
        data: dynamicToHex(decodeData[7]));

    final authorization = Eip7702Authorization.deserialize(decodeData[9][0]);

    if (decodeData.length == 13) {
      txData.v = hexToBigInt(dynamicToString(decodeData[10])).toInt();
      txData.r = hexToBigInt(dynamicToString(decodeData[11]));
      txData.s = hexToBigInt(dynamicToString(decodeData[12]));
    }
    return Eip7702TxData(
        data: txData,
        network: TxNetwork(chainId: chainId),
        authorization: authorization);
  }
}
