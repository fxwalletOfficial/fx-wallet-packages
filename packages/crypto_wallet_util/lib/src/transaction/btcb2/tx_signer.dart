import 'dart:convert';

import 'package:blockchain_utils/blockchain_utils.dart';

import '../../wallets/btcb2.dart';
import 'tx_data.dart';

/// Builds and signs the validated service-provided BTCB2 assembly state.
class Btcb2TransactionAssembler {
  Btcb2TransactionAssembler._(List<int> publicKeyBytes)
    : publicKeyBytes = List<int>.unmodifiable(publicKeyBytes),
      senderAddress = Btcb2Coin.addressFromPublicKeyBytes(publicKeyBytes);

  final List<int> publicKeyBytes;
  final String senderAddress;

  factory Btcb2TransactionAssembler.fromPublicKeyBytes(
    List<int> publicKeyBytes,
  ) {
    if (publicKeyBytes.length != 33 ||
        (publicKeyBytes.first != 0x02 && publicKeyBytes.first != 0x03)) {
      throw ArgumentError('BTCB2 requires a compressed secp256k1 public key.');
    }
    Secp256k1Verifier.fromKeyBytes(publicKeyBytes);
    return Btcb2TransactionAssembler._(publicKeyBytes);
  }

  factory Btcb2TransactionAssembler.fromPublicKeyHex(String publicKeyHex) {
    return Btcb2TransactionAssembler.fromPublicKeyBytes(
      BytesUtils.fromHexString(publicKeyHex),
    );
  }

  Btcb2TransactionDraft build(Btcb2TransactionAssemblyData state) {
    if (state.senderAddress != senderAddress) {
      throw const FormatException(
        'The BTCB2 assembly sender does not match the local public key.',
      );
    }
    return Btcb2TransactionDraft._(state, publicKeyBytes);
  }
}

/// Unsigned transaction plus the exact UNIFIED digests to be signed.
class Btcb2TransactionDraft {
  Btcb2TransactionDraft._(this.state, List<int> publicKeyBytes)
    : publicKeyBytes = List<int>.unmodifiable(publicKeyBytes);

  final Btcb2TransactionAssemblyData state;
  final List<int> publicKeyBytes;

  List<int> get unsignedTransactionBytes => _serializeTransaction(
    state,
    List<List<int>>.generate(state.inputs.length, (_) => const []),
  );

  String get unsignedTransactionHex =>
      BytesUtils.toHexString(unsignedTransactionBytes);

  List<int> signingHashBytes(int inputIndex) {
    if (inputIndex < 0 || inputIndex >= state.inputs.length) {
      throw RangeError.index(inputIndex, state.inputs, 'inputIndex');
    }
    final inputs = state.inputs
        .map(
          (input) => Btcb2SighashInput(
            transactionId: input.transactionId,
            outputIndex: input.outputIndex,
            sequence: input.sequence,
          ),
        )
        .toList();
    final spentOutputs = state.inputs
        .map(
          (input) => Btcb2SpentOutput(
            amountSats: input.amountSats,
            scriptPubKey: input.scriptPubKey,
          ),
        )
        .toList();
    final outputs = state.outputs
        .map(
          (output) => Btcb2SpentOutput(
            amountSats: output.amountSats,
            scriptPubKey: output.scriptPubKey,
          ),
        )
        .toList();
    return Btcb2UnifiedSighash.compute(
      version: state.transactionVersion,
      lockTime: state.lockTime,
      inputs: inputs,
      spentOutputs: spentOutputs,
      outputs: outputs,
      inputIndex: inputIndex,
      scriptCode: state.inputs[inputIndex].scriptCode,
      hashType: Btcb2TransactionAssemblyData.unifiedSighashType,
      scriptType: state.inputs[inputIndex].scriptType,
    );
  }

  String signingHashHex(int inputIndex) =>
      BytesUtils.toHexString(signingHashBytes(inputIndex));

  /// Signs every input with a local secp256k1 private key.
  Btcb2SignedTransaction sign(List<int> privateKeyBytes) {
    final key = Secp256k1PrivateKey.fromBytes(privateKeyBytes);
    if (!_bytesEqual(key.publicKey.compressed, publicKeyBytes)) {
      throw ArgumentError(
        'Private key does not match the assembly public key.',
      );
    }
    final signingKey = Secp256k1SigningKey.fromBytes(keyBytes: privateKeyBytes);
    final signatures = List<List<int>>.generate(
      state.inputs.length,
      (index) => signingKey.signDer(digest: signingHashBytes(index)),
    );
    return attachSignatures(signatures);
  }

  /// Attaches strict-DER, low-S signatures from an external signer.
  ///
  /// Each signature must exclude the final BTCB2 sighash byte. This method
  /// validates the signature against the locally rebuilt digest and appends
  /// the required `0x21` byte before serializing the transaction.
  Btcb2SignedTransaction attachSignatures(List<List<int>> derSignatures) {
    if (derSignatures.length != state.inputs.length) {
      throw ArgumentError('Expected one signature for each BTCB2 input.');
    }
    final verifier = Secp256k1Verifier.fromKeyBytes(publicKeyBytes);
    final scriptSigs = <List<int>>[];
    for (var index = 0; index < derSignatures.length; index++) {
      final der = List<int>.from(derSignatures[index]);
      final compact = _strictDerToCompactLowS(der);
      if (!verifier.verify(signingHashBytes(index), compact)) {
        throw FormatException(
          'Signature $index does not match the public key.',
        );
      }
      scriptSigs.add([
        ..._pushData([...der, Btcb2TransactionAssemblyData.unifiedSighashType]),
        ..._pushData(publicKeyBytes),
      ]);
    }
    return Btcb2SignedTransaction._(_serializeTransaction(state, scriptSigs));
  }
}

/// A fully signed BTCB2 transaction ready for broadcasting by the caller.
class Btcb2SignedTransaction {
  Btcb2SignedTransaction._(List<int> bytes)
    : rawTransactionBytes = List<int>.unmodifiable(bytes),
      rawTransactionHex = BytesUtils.toHexString(bytes),
      transactionId = BytesUtils.toHexString(
        QuickCrypto.sha256DoubleHash(bytes).reversed.toList(),
      );

  final List<int> rawTransactionBytes;
  final String rawTransactionHex;
  final String transactionId;

  /// Legacy P2PKH transactions have no witness discount.
  int get virtualSize => rawTransactionBytes.length;

  Map<String, String> toBroadcast() => {'tx': rawTransactionHex};
}

/// A previous or new transaction output used by the UNIFIED sighash.
class Btcb2SpentOutput {
  Btcb2SpentOutput({required this.amountSats, required List<int> scriptPubKey})
    : scriptPubKey = List<int>.unmodifiable(scriptPubKey);

  final int amountSats;
  final List<int> scriptPubKey;
}

class Btcb2SighashInput {
  const Btcb2SighashInput({
    required this.transactionId,
    required this.outputIndex,
    required this.sequence,
  });

  final String transactionId;
  final int outputIndex;
  final int sequence;
}

/// BTCB2's post-activation UNIFIED signature-hash algorithm.
class Btcb2UnifiedSighash {
  static List<int> compute({
    required int version,
    required int lockTime,
    required List<Btcb2SighashInput> inputs,
    required List<Btcb2SpentOutput> spentOutputs,
    required List<Btcb2SpentOutput> outputs,
    required int inputIndex,
    required List<int> scriptCode,
    int hashType = 0x21,
    int scriptType = 0,
  }) {
    if (inputs.length != spentOutputs.length ||
        inputIndex < 0 ||
        inputIndex >= inputs.length) {
      throw ArgumentError('Missing spent outputs or invalid input index.');
    }
    if ((hashType & 0x20) == 0 || hashType < 0 || hashType > 0xff) {
      throw ArgumentError('UNIFIED sighash bit 0x20 is required.');
    }
    if (scriptType != 0 && scriptType != 1) {
      throw ArgumentError('Only BTCB2 script types 0 and 1 are supported.');
    }

    final mode = hashType & 0x1f;
    final anyoneCanPay = (hashType & 0x80) != 0;
    final message = <int>[
      0,
      hashType,
      ..._littleEndian(version, 4),
      ..._littleEndian(lockTime, 5),
    ];
    if (!anyoneCanPay) {
      message.addAll(
        _sha256(inputs.expand(_serializeOutpoint).toList(growable: false)),
      );
      message.addAll(
        _sha256(
          spentOutputs
              .expand((output) => _littleEndian(output.amountSats, 8))
              .toList(growable: false),
        ),
      );
      message.addAll(
        _sha256(
          spentOutputs
              .expand((output) => _serializeScript(output.scriptPubKey))
              .toList(growable: false),
        ),
      );
      message.addAll(
        _sha256(
          inputs
              .expand((input) => _littleEndian(input.sequence, 4))
              .toList(growable: false),
        ),
      );
    }
    if (mode != 2 && mode != 3) {
      message.addAll(
        _sha256(outputs.expand(_serializeOutput).toList(growable: false)),
      );
    }
    message.add(scriptType);
    if (anyoneCanPay) {
      message
        ..addAll(_serializeOutpoint(inputs[inputIndex]))
        ..addAll(_serializeOutput(spentOutputs[inputIndex]))
        ..addAll(_littleEndian(inputs[inputIndex].sequence, 4));
    } else {
      message.addAll(_littleEndian(inputIndex, 4));
    }
    message.addAll(_serializeScript(scriptCode));
    if (mode == 3) {
      if (inputIndex >= outputs.length) {
        throw ArgumentError('SIGHASH_SINGLE has no matching output.');
      }
      message.addAll(_sha256(_serializeOutput(outputs[inputIndex])));
    }
    return _taggedSha256('UnifiedSighash', message);
  }
}

List<int> _serializeTransaction(
  Btcb2TransactionAssemblyData state,
  List<List<int>> scriptSigs,
) {
  if (scriptSigs.length != state.inputs.length) {
    throw ArgumentError('scriptSigs length must match inputs.');
  }
  return [
    ..._littleEndian(state.transactionVersion, 4),
    ..._compactSize(state.inputs.length),
    for (var index = 0; index < state.inputs.length; index++) ...[
      ..._serializeOutpoint(
        Btcb2SighashInput(
          transactionId: state.inputs[index].transactionId,
          outputIndex: state.inputs[index].outputIndex,
          sequence: state.inputs[index].sequence,
        ),
      ),
      ..._serializeScript(scriptSigs[index]),
      ..._littleEndian(state.inputs[index].sequence, 4),
    ],
    ..._compactSize(state.outputs.length),
    for (final output in state.outputs)
      ..._serializeOutput(
        Btcb2SpentOutput(
          amountSats: output.amountSats,
          scriptPubKey: output.scriptPubKey,
        ),
      ),
    ..._littleEndian(state.lockTime, 4),
  ];
}

List<int> _serializeOutpoint(Btcb2SighashInput input) => [
  ...BytesUtils.fromHexString(input.transactionId).reversed,
  ..._littleEndian(input.outputIndex, 4),
];

List<int> _serializeOutput(Btcb2SpentOutput output) => [
  ..._littleEndian(output.amountSats, 8),
  ..._serializeScript(output.scriptPubKey),
];

List<int> _serializeScript(List<int> script) => [
  ..._compactSize(script.length),
  ...script,
];

List<int> _compactSize(int value) {
  if (value < 0) throw ArgumentError.value(value, 'value');
  if (value < 0xfd) return [value];
  if (value <= 0xffff) return [0xfd, ..._littleEndian(value, 2)];
  if (value <= 0xffffffff) return [0xfe, ..._littleEndian(value, 4)];
  return [0xff, ..._littleEndian(value, 8)];
}

List<int> _littleEndian(int value, int length) {
  if (value < 0) throw ArgumentError.value(value, 'value');
  final result = List<int>.filled(length, 0);
  var remaining = value;
  for (var i = 0; i < length; i++) {
    result[i] = remaining & 0xff;
    remaining ~/= 256;
  }
  if (remaining != 0) {
    throw ArgumentError('$value does not fit in $length bytes.');
  }
  return result;
}

List<int> _pushData(List<int> data) {
  if (data.length <= 75) return [data.length, ...data];
  if (data.length <= 0xff) return [0x4c, data.length, ...data];
  throw ArgumentError('BTCB2 P2PKH pushdata is unexpectedly large.');
}

List<int> _sha256(List<int> data) => QuickCrypto.sha256Hash(data);

List<int> _taggedSha256(String tag, List<int> message) {
  final tagHash = _sha256(utf8.encode(tag));
  return _sha256([...tagHash, ...tagHash, ...message]);
}

List<int> _strictDerToCompactLowS(List<int> der) {
  if (der.any((byte) => byte < 0 || byte > 0xff) ||
      der.length < 8 ||
      der.length > 72 ||
      der[0] != 0x30) {
    throw const FormatException('Invalid strict-DER ECDSA signature.');
  }
  if (der[1] != der.length - 2 || der[2] != 0x02) {
    throw const FormatException('Invalid strict-DER ECDSA signature.');
  }
  final rLength = der[3];
  final rStart = 4;
  final sTag = rStart + rLength;
  if (rLength == 0 || sTag + 2 > der.length || der[sTag] != 0x02) {
    throw const FormatException('Invalid strict-DER ECDSA signature.');
  }
  final sLength = der[sTag + 1];
  final sStart = sTag + 2;
  if (sLength == 0 || sStart + sLength != der.length) {
    throw const FormatException('Invalid strict-DER ECDSA signature.');
  }
  final rBytes = der.sublist(rStart, sTag);
  final sBytes = der.sublist(sStart);
  if ((rBytes.first & 0x80) != 0 ||
      (sBytes.first & 0x80) != 0 ||
      (rBytes.length > 1 && rBytes.first == 0 && (rBytes[1] & 0x80) == 0) ||
      (sBytes.length > 1 && sBytes.first == 0 && (sBytes[1] & 0x80) == 0)) {
    throw const FormatException('Signature is not strict DER.');
  }
  final r = BigintUtils.fromBytes(rBytes);
  final s = BigintUtils.fromBytes(sBytes);
  final order = CryptoSignerConst.secp256k1Order;
  if (r <= BigInt.zero || r >= order || s <= BigInt.zero || s > order >> 1) {
    throw const FormatException(
      'Signature must contain valid r and low-S values.',
    );
  }
  return [
    ...BigintUtils.toBytes(r, length: 32),
    ...BigintUtils.toBytes(s, length: 32),
  ];
}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
