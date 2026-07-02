import 'dart:typed_data';

import 'package:bs58check/bs58check.dart';
import 'package:crypto_wallet_util/config.dart' show chainConfigs;
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart' as btc;
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/src/utils/constants/op.dart';
import 'package:crypto_wallet_util/src/transaction/btc/sign_data.dart';
import 'package:crypto_wallet_util/src/type/type.dart';
import 'package:crypto_wallet_util/src/utils/bip32/bip32.dart' show NetworkType;
import 'package:crypto_wallet_util/src/utils/utils.dart';

class GsplTxData extends TxData {
  List<GsplItem> inputs;
  final GsplItem? change;
  String hex;
  final BtcSignDataType dataType;

  GsplTxData({required this.inputs, required this.hex, this.change, required this.dataType});

  NetworkType get _networkType {
    final path = inputs.map((input) => input.path).whereType<String>().firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => change?.path ?? '',
        );
    if (path.isEmpty) {
      throw Exception('No path found');
    }

    final segments = path.split('/');
    if (segments.length < 3) {
      throw Exception('Invalid bip44 path: $path');
    }

    final coinType = segments[2].replaceAll("'", '');
    for (final chainConfig in chainConfigs) {
      final chainPath = chainConfig.mainnet.bip44Path;
      final chainSegments = chainPath.split('/');
      if (chainSegments.length < 3) {
        continue;
      }
      if (chainSegments[2].replaceAll("'", '') == coinType) {
        final networkType = chainConfig.mainnet.networkType;
        if (networkType != null) {
          return networkType;
        }
      }
    }

    throw Exception('Network type not found for path: $path');
  }

  String _generateAddress(Uint8List hash160, int versionByte) {

    // Concatenate version + pubkeyHash
    final Uint8List payload = Uint8List(hash160.length + 1);
    payload[0] = versionByte;
    payload.setRange(1, payload.length, hash160);

    // Double SHA256
    final sha256Hash = getSHA256Digest(getSHA256Digest(payload));

    // Take first 4 bytes as checksum
    Uint8List checksum = Uint8List.fromList(sha256Hash.sublist(0, 4));

    // Concatenate payload + checksum
    Uint8List fullData = Uint8List.fromList([...payload, ...checksum]);

    // Base58 encoding
    return base58.encode(fullData);
  }

  String? _extractAddress(Uint8List? script) {
    if (script == null) return null;
    final net = _networkType;

    if (script.length == 25 &&
        script[0] == OPS['OP_DUP'] &&
        script[1] == OPS['OP_HASH160'] &&
        script[2] == 0x14 &&
        script[23] == OPS['OP_EQUALVERIFY'] &&
        script[24] == OPS['OP_CHECKSIG']) {
      return _generateAddress(script.sublist(3, 23), net.pubKeyHash);
    }

    if (script.length == 23 &&
        script[0] == OPS['OP_HASH160'] &&
        script[1] == 0x14 &&
        script[22] == OPS['OP_EQUAL']) {
      return _generateAddress(script.sublist(2, 22), net.scriptHash);
    }

    return null;
  }

  int _getFee(int? amount) {
    if (amount == null) {
      throw Exception('Payment amount is null');
    }
    try {
      final inputAmount = inputs.map((input) => input.amount).whereType<int>().reduce((a, b) => a + b);
      return inputAmount - amount;
    } catch (e) {
      throw Exception('Failed to get fee: $e');
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final transaction = btc.Transaction.fromHex(hex);

    final outputs = transaction.outs;
    final changeAmount = change?.amount;
    final allPayments = outputs.map((output) => {'address': _extractAddress(output.script), 'amount': output.value}).toList();
    final payments = changeAmount != null && allPayments.isNotEmpty && allPayments.last['amount'] == changeAmount ? allPayments.sublist(0, allPayments.length - 1) : allPayments;
    final payAmount = payments.map((payment) => payment['amount']).toList().whereType<int>().fold<int>(0, (sum, amount) => sum + amount);
    final amount = outputs.map((output) => output.value).toList().whereType<int>().fold<int>(0, (sum, amount) => sum + amount);
    final fee = _getFee(amount);

    return {
      'inputs': inputs,
      'change': change,
      'amount': amount,
      'payAmount': payAmount,
      'payments': payments,
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
