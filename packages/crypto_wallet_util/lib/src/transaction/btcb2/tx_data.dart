import 'package:blockchain_utils/blockchain_utils.dart';

import '../../config/chain/btc/btcb2.dart';
import '../../wallets/btcb2.dart';

const int _maxMoneySats = 21000000 * 100000000;

/// One input returned by the BTCB2 transaction assembly endpoint.
class Btcb2TransactionInput {
  const Btcb2TransactionInput({
    required this.transactionId,
    required this.outputIndex,
    required this.sequence,
    required this.amountSats,
    required this.address,
    required this.scriptPubKey,
    required this.scriptCode,
    required this.scriptType,
    required this.derivationPath,
  });

  final String transactionId;
  final int outputIndex;
  final int sequence;
  final int amountSats;
  final String address;
  final List<int> scriptPubKey;
  final List<int> scriptCode;
  final int scriptType;
  final String derivationPath;

  factory Btcb2TransactionInput.fromJson(Map<String, dynamic> json) {
    return Btcb2TransactionInput(
      transactionId: _hex(json, 'transactionId', length: 32),
      outputIndex: _uint32(json, 'outputIndex'),
      sequence: _uint32(json, 'sequence'),
      amountSats: _money(json, 'amountSats', positive: true),
      address: _string(json, 'address'),
      scriptPubKey: _hexBytes(json, 'scriptPubKey'),
      scriptCode: _hexBytes(json, 'scriptCode'),
      scriptType: _integer(json, 'scriptType'),
      derivationPath: _string(json, 'derivationPath'),
    );
  }
}

/// One output returned by the BTCB2 transaction assembly endpoint.
class Btcb2TransactionOutput {
  const Btcb2TransactionOutput({
    required this.address,
    required this.amountSats,
    required this.scriptPubKey,
  });

  final String address;
  final int amountSats;
  final List<int> scriptPubKey;

  factory Btcb2TransactionOutput.fromJson(Map<String, dynamic> json) {
    return Btcb2TransactionOutput(
      address: _string(json, 'address'),
      amountSats: _money(json, 'amountSats', positive: true),
      scriptPubKey: _hexBytes(json, 'scriptPubKey'),
    );
  }
}

/// Fee selected by the service for an assembled BTCB2 transaction.
class Btcb2TransactionFee {
  const Btcb2TransactionFee({
    required this.amountSats,
    required this.rateSatPerVbyte,
    required this.subtractFromOutputs,
  });

  final int amountSats;
  final String rateSatPerVbyte;
  final bool subtractFromOutputs;

  factory Btcb2TransactionFee.fromJson(Map<String, dynamic> json) {
    final rate = _string(json, 'rateSatPerVbyte');
    final parsedRate = num.tryParse(rate);
    if (parsedRate == null || !parsedRate.isFinite || parsedRate <= 0) {
      throw const FormatException('fee.rateSatPerVbyte must be positive.');
    }
    return Btcb2TransactionFee(
      amountSats: _money(json, 'amountSats'),
      rateSatPerVbyte: rate,
      subtractFromOutputs: _boolean(json, 'subtractFromOutputs'),
    );
  }
}

/// Fully validated, deterministic BTCB2 transaction assembly returned by the
/// service. The signing digest is always recomputed locally from this data.
class Btcb2TransactionAssemblyData {
  Btcb2TransactionAssemblyData._({
    required this.senderAddress,
    required this.senderDerivationPath,
    required this.inputs,
    required this.outputs,
    required this.fee,
    required this.transactionVersion,
    required this.lockTime,
  });

  static const String payloadType = 'btcb2_unified_transaction_assembly_state';
  static const int activationHeight = 961640;
  static const String activationBlockHash =
      '0000000000000050c1e5f69672f459293be14f46e5a494e7a8c8541396f18eeb';
  static const int unifiedSighashType = 0x21;

  final String senderAddress;
  final String senderDerivationPath;
  final List<Btcb2TransactionInput> inputs;
  final List<Btcb2TransactionOutput> outputs;
  final Btcb2TransactionFee fee;
  final int transactionVersion;
  final int lockTime;

  int get totalInputSats =>
      inputs.fold(0, (sum, input) => sum + input.amountSats);

  int get totalOutputSats =>
      outputs.fold(0, (sum, output) => sum + output.amountSats);

  /// Parses and validates a complete BTCB2 transaction assembly response.
  factory Btcb2TransactionAssemblyData.fromServiceResponse(
    Map<String, dynamic> response,
  ) {
    final payload = _map(response, 'signing_payload');
    if (_string(payload, 'type') != payloadType) {
      throw const FormatException('Unexpected BTCB2 signing payload type.');
    }

    final signingInfo = _map(response, 'signing_info');
    _expect(signingInfo, 'method', 'btcb2_unified_sighash');
    _expect(signingInfo, 'digest_algorithm', 'tagged-sha256');
    _expect(signingInfo, 'digest_encoding', 'bytes');
    _expect(signingInfo, 'signature_algorithm', 'secp256k1-ecdsa');
    _expect(signingInfo, 'signature_encoding', 'der-plus-sighash-byte');
    _expect(signingInfo, 'serialized_transaction_encoding', 'hex');

    final data = _map(payload, 'data');
    if (_integer(data, 'version') != 2) {
      throw const FormatException('Unsupported BTCB2 assembly version.');
    }
    if (!BTCB2Chain.matchesName(_string(data, 'chain'))) {
      throw const FormatException('Unsupported BTCB2 chain name.');
    }
    _expect(data, 'network', 'mainnet');

    final sender = _map(data, 'sender');
    final senderAddress = _string(sender, 'address');
    final senderPath = _string(sender, 'derivationPath');
    if (senderPath != Btcb2Coin.defaultDerivationPath) {
      throw FormatException(
        'BTCB2 only supports derivation path ${Btcb2Coin.defaultDerivationPath}.',
      );
    }

    final identity = _map(data, 'chainIdentity');
    if (_integer(identity, 'activationHeight') != activationHeight ||
        _hex(identity, 'activationHash', length: 32) != activationBlockHash) {
      throw const FormatException('Unexpected BTCB2 chain identity.');
    }

    final sighash = _map(data, 'sighash');
    if (_integer(sighash, 'type') != unifiedSighashType ||
        _string(sighash, 'typeHex').toLowerCase() != '0x21' ||
        _integer(sighash, 'epoch') != 0 ||
        _string(sighash, 'tag') != 'UnifiedSighash') {
      throw const FormatException('Unsupported BTCB2 sighash settings.');
    }

    final transaction = _map(data, 'transaction');
    final transactionVersion = _integer(transaction, 'version');
    if (transactionVersion != 2) {
      throw const FormatException('BTCB2 transaction version must be 2.');
    }
    final lockTime = _uint32(transaction, 'lockTime');

    final inputJson = _listOfMaps(data, 'inputs');
    final outputJson = _listOfMaps(data, 'outputs');
    if (inputJson.isEmpty || outputJson.isEmpty) {
      throw const FormatException('BTCB2 inputs and outputs cannot be empty.');
    }
    final inputs = inputJson.map(Btcb2TransactionInput.fromJson).toList();
    final outputs = outputJson.map(Btcb2TransactionOutput.fromJson).toList();
    final fee = Btcb2TransactionFee.fromJson(_map(data, 'fee'));

    final seenOutpoints = <String>{};
    final senderScript = Btcb2Coin.scriptPubKeyFromAddress(senderAddress);
    if (!Btcb2Coin.isP2pkhScript(senderScript)) {
      throw const FormatException(
        'BTCB2 sender must be a mainnet P2PKH address.',
      );
    }
    for (final input in inputs) {
      final outpoint = '${input.transactionId}:${input.outputIndex}';
      if (!seenOutpoints.add(outpoint)) {
        throw FormatException('Duplicate BTCB2 input: $outpoint');
      }
      if (input.sequence != 0xfffffffd ||
          input.address != senderAddress ||
          input.derivationPath != senderPath ||
          input.scriptType != 0 ||
          !Btcb2Coin.isP2pkhScript(input.scriptPubKey) ||
          !_bytesEqual(input.scriptPubKey, input.scriptCode) ||
          !_bytesEqual(input.scriptPubKey, senderScript)) {
        throw FormatException('Invalid BTCB2 input metadata for $outpoint.');
      }
    }
    for (final output in outputs) {
      final expected = Btcb2Coin.scriptPubKeyFromAddress(output.address);
      if (!_bytesEqual(output.scriptPubKey, expected)) {
        throw FormatException(
          'Output script does not match address ${output.address}.',
        );
      }
    }

    final totalInput = inputs.fold<int>(
      0,
      (sum, item) => sum + item.amountSats,
    );
    final totalOutput = outputs.fold<int>(
      0,
      (sum, item) => sum + item.amountSats,
    );
    if (totalInput > _maxMoneySats ||
        totalOutput > _maxMoneySats ||
        fee.amountSats > _maxMoneySats ||
        totalInput != totalOutput + fee.amountSats) {
      throw const FormatException(
        'BTCB2 input/output/fee arithmetic is invalid.',
      );
    }

    return Btcb2TransactionAssemblyData._(
      senderAddress: senderAddress,
      senderDerivationPath: senderPath,
      inputs: List.unmodifiable(inputs),
      outputs: List.unmodifiable(outputs),
      fee: fee,
      transactionVersion: transactionVersion,
      lockTime: lockTime,
    );
  }
}

Map<String, dynamic> _map(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  throw FormatException('$key must be an object.');
}

List<Map<String, dynamic>> _listOfMaps(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('$key must be an array.');
  return value.map((item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return item.cast<String, dynamic>();
    throw FormatException('$key must contain objects.');
  }).toList();
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('$key must be a non-empty string.');
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is String && RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(value)) {
    return int.parse(value);
  }
  if (value is num && value.isFinite && value == value.truncate()) {
    return value.toInt();
  }
  throw FormatException('$key must be an integer.');
}

int _uint32(Map<String, dynamic> json, String key) {
  final value = _integer(json, key);
  if (value < 0 || value > 0xffffffff) {
    throw FormatException('$key must be a uint32.');
  }
  return value;
}

int _money(Map<String, dynamic> json, String key, {bool positive = false}) {
  final value = _integer(json, key);
  if (value < (positive ? 1 : 0) || value > _maxMoneySats) {
    throw FormatException('$key is outside the valid money range.');
  }
  return value;
}

bool _boolean(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('$key must be a boolean.');
}

String _hex(Map<String, dynamic> json, String key, {int? length}) {
  final value = _string(json, key).toLowerCase();
  final bytes = _decodeHex(value, key);
  if (length != null && bytes.length != length) {
    throw FormatException('$key must contain $length bytes.');
  }
  return value;
}

List<int> _hexBytes(Map<String, dynamic> json, String key) =>
    List.unmodifiable(_decodeHex(_string(json, key), key));

List<int> _decodeHex(String value, String key) {
  if (value.length.isOdd || !RegExp(r'^[0-9a-fA-F]*$').hasMatch(value)) {
    throw FormatException('$key must be canonical hexadecimal.');
  }
  return BytesUtils.fromHexString(value);
}

void _expect(Map<String, dynamic> json, String key, String expected) {
  if (_string(json, key) != expected) {
    throw FormatException('$key must be $expected.');
  }
}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
