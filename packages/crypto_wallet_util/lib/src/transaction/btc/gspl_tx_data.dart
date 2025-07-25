import 'package:crypto_wallet_util/config.dart' show getChainConfigByBip44Path;
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart' as btc;
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/src/utils/constants/op.dart';
import 'package:crypto_wallet_util/src/transaction/btc/sign_data.dart';
import 'package:crypto_wallet_util/src/type/type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

class GsplTxData extends TxData {
  final List<GsplItem> inputs;
  final GsplItem? change;
  final String hex;
  final BtcSignDataType dataType;

  GsplTxData({required this.inputs, required this.hex, this.change, required this.dataType});

  // 解析地址
  String _generateAddress(Uint8List pubKeyHashHex) {
    final paths = inputs.map((input) => input.path).toList();
    if (paths.isEmpty) {
      throw Exception('No path found');
    }
    final path = paths.first;
    if (path == null) {
      throw Exception('Path not found');
    }
    final networkType = getChainConfigByBip44Path(path).mainnet.networkType;
    if (networkType == null) {
      throw Exception('Network type not found');
    }
    final prefixHex = networkType.pubKeyHash;

    // 拼接 version + pubkeyHash
    final Uint8List payload = Uint8List(pubKeyHashHex.length + 1);
    payload[0] = prefixHex;
    payload.setRange(1, payload.length, pubKeyHashHex);

    // 双重 SHA256
    final sha256Hash = getSHA256Digest(getSHA256Digest(payload));

    // 取前4字节为校验码
    Uint8List checksum = Uint8List.fromList(sha256Hash.sublist(0, 4));

    // 拼接 payload + checksum
    Uint8List fullData = Uint8List.fromList([...payload, ...checksum]);

    // Base58 编码
    return base58.encode(fullData);
  }

  String? _extractP2PKHAddress(Uint8List? script) {
    if (script == null) return null;
    if (script.length != 25) return null;
    final op_dup = script[0];
    final op_hash160 = script[1];
    final push_20 = script[2];
    final op_equalverify = script[23];
    final op_checksig = script[24];
    if (op_dup != OPS['OP_DUP'] || op_hash160 != OPS['OP_HASH160'] || push_20 != 0x14 || op_equalverify != OPS['OP_EQUALVERIFY'] || op_checksig != OPS['OP_CHECKSIG']) return null;
    return _generateAddress(script.sublist(3, 23));
  }

  int _getFee(int? paymentAmount) {
    if (paymentAmount == null) {
      throw Exception('Payment amount is null');
    }
    try {
      final inputAmount = inputs.map((input) => input.amount).whereType<int>().reduce((a, b) => a + b);
      final changeAmount = change?.amount ?? 0;
      return inputAmount - paymentAmount - changeAmount;
    } catch (e) {
      throw Exception('Failed to get fee: $e');
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final transaction = btc.Transaction.fromHex(hex);
    final payment = transaction.outs.first;
    final paymentAddress = _extractP2PKHAddress(payment.script);
    final paymentAmount = payment.value;
    final fee = _getFee(paymentAmount);

    return {
      'inputs': inputs,
      'change': change,
      'amount': paymentAmount,
      'paymentAddress': paymentAddress,
      'dataType': dataType.name,
      'fee': fee,
    };
  }

  @override
  Map<String, dynamic> toBroadcast() {
    return {};
  }
}

class GsplItem {
  final String? path;
  final String? address;
  final int? amount;
  final int? signHashType;
  final Uint8List? signature;

  GsplItem({this.path, this.amount, this.signature, this.address, this.signHashType});

  Map<String, dynamic> toJson() => {
    'amount': amount.toString(),
    'path': path,
    'address': address,
    'signHashType': signHashType,
    'signature': signature,
  };
}
