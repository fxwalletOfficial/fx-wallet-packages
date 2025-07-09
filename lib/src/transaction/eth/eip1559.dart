import 'package:crypto_wallet_util/src/transaction/eth/lib/eth_lib.dart';
import 'package:crypto_wallet_util/src/transaction/eth/tx_data.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'lib/rlp.dart' as rlp;

const int TRANSACTION_TYPE = 2;
final Uint8List TRANSACTION_TYPE_BUFFER =
    (TRANSACTION_TYPE.toRadixString(16).padLeft(2, '0')).toUint8List();

class Eip1559TxData extends EthTxData {
  Eip1559TxData({required super.data, required super.network})
      : super(txType: EthTxType.eip1559);

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
      data.v == null ? [] : intToBuffer(data.v),
      data.r == null ? [] : intToBuffer(data.r),
      data.s == null ? [] : intToBuffer(data.s)
    ];
  }

  /// Returns the serialized encoding of the EIP-1559 transaction.
  /// If [sig] is true, return with signature, false without signature. Default is true.
  @override
  Uint8List serialize({bool sig = true}) {
    final base = sig ? raw() : raw().sublist(0, 9);
    return Uint8List.fromList(TRANSACTION_TYPE_BUFFER + rlp.encode(base));
  }

  /// Returns the serialized unsigned tx (hashed or raw), which can be used.
  @override
  Uint8List getMessageToSign() {
    List base = raw().sublist(0, 9);
    var msg = TRANSACTION_TYPE_BUFFER + rlp.encode(base);

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

  String signIng(Uint8List privateKey) {
    var msg = getMessageToSign();
    EcdaSignature result =
        EcdaSignature.signForEth(dynamicToUint8List(msg), privateKey);
    return "${(result.v - 27).toRadixString(16)}&${result.r.toStr()}&${result.s.toStr()}";
  }

  @override
  Map<String, dynamic> toBroadcast() {
    return {signature: signature};
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
      'v': data.v,
      'r': data.r,
      's': data.s,
    };
  }

  factory Eip1559TxData.deserialize(String hash) {
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

    if (decodeData.length == 12) {
      txData.v = hexToBigInt(dynamicToString(decodeData[9])).toInt();
      txData.r = hexToBigInt(dynamicToString(decodeData[10]));
      txData.s = hexToBigInt(dynamicToString(decodeData[11]));
    }
    return Eip1559TxData(data: txData, network: TxNetwork(chainId: chainId));
  }
}
