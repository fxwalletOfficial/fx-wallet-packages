import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'lib/eth_lib.dart';
import 'lib/rlp.dart' as rlp;
import './tx_data.dart';

class LegacyTxData extends EthTxData {
  LegacyTxData({required super.data, required super.network})
      : super(txType: EthTxType.legacy);

  @override
  List raw() {
    return [
      intToBuffer(data.nonce),
      intToBuffer(data.gasPrice),
      intToBuffer(data.gasLimit),
      dynamicToUint8List(data.to),
      intToBuffer(data.value),
      dynamicToUint8List(data.data),
      data.v == null ? Uint8List.fromList([]) : intToBuffer(data.v),
      data.r == null ? Uint8List.fromList([]) : intToBuffer(data.r),
      data.s == null ? Uint8List.fromList([]) : intToBuffer(data.s)
    ];
  }

  /// Returns the serialized unsigned tx (hashed or raw), which can be used.
  @override
  Uint8List getMessageToSign() {
    var base = raw().sublist(0, 6);
    base.addAll([
      intToBuffer(network.chainId),
      Uint8List.fromList([]),
      Uint8List.fromList([])
    ]);

    return getKeccakDigest(rlp.encode(base));
  }

  /// Returns the serialized encoding of the legacy transaction.
  @override
  Uint8List serialize({bool sig = true}) {
    return rlp.encode(sig ? raw() : raw().sublist(0, 6));
  }

  Uint8List txsMsg(int v, BigInt r, BigInt s) {
    int legacyV;
    if (v == 0 || v == 1) {
      legacyV = v;
    } else if (v > 35) {
      legacyV = (v - 35) % 2 == 1 ? 1 : 0;
    } else {
      legacyV = v;
    }
    data.v = legacyV + network.chainId * 2 + 35;
    data.r = r;
    data.s = s;

    return serialize();
  }

  String signIng(Uint8List privateKey) {
    var msg = getMessageToSign();
    EcdaSignature result =
        EcdaSignature.signForEth(dynamicToUint8List(msg), privateKey);

    return "${(result.v + network.chainId * 2 + 8).toRadixString(16)}&${result.r.toStr()}&${result.s.toStr()}";
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
      'v': data.v,
      'r': data.r,
      's': data.s,
    };
  }

  factory LegacyTxData.deserialize(String hash, {int? chainId}) {
    final decodeData = rlp.decode(dynamicToUint8List(hash));

    final txData = EthTxDataRaw(
        nonce: hexToBigInt(dynamicToString(decodeData[0])).toInt(),
        gasPrice: hexToBigInt(dynamicToString(decodeData[1])).toInt(),
        gasLimit: hexToBigInt(dynamicToString(decodeData[2])).toInt(),
        to: dynamicToHex(decodeData[3]),
        value: hexToBigInt(dynamicToString(decodeData[4])),
        data: dynamicToHex(decodeData[5]));

    if (decodeData.length == 9) {
      txData.v = hexToBigInt(dynamicToString(decodeData[6])).toInt();
      txData.r = hexToBigInt(dynamicToString(decodeData[7]));
      txData.s = hexToBigInt(dynamicToString(decodeData[8]));
    }

    return LegacyTxData(
        data: txData, network: TxNetwork(chainId: chainId ?? -1));
  }

  @override
  Eip7702Authorization get authorization => throw UnimplementedError();
}
