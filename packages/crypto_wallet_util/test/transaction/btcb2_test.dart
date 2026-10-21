import 'dart:convert';
import 'dart:io';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:test/test.dart';

const _testMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon about';

// Expected addresses for [_testMnemonic], computed with a standalone
// BIP39/BIP32/hash160/Base58Check implementation outside this package.
const _subAccountAddresses = {
  "m/44'/0'/1'/0/0": '15qucUWKf95Fo58FdCBhUTSAtsm22HHE2Q',
  "m/44'/0'/0'/0/5": '19a7HGg32ecPQo49rDeM2NSFJHPqrwSJto',
};

void main() {
  test(
    'registers BTCB2 without changing the Bitcoin wallet identity',
    () async {
      expect(getWallet('btcb2'), Wallet.BTCB2);
      expect(getWallet('xbt'), Wallet.BTCB2);
      expect(getWallet('XBT'), Wallet.BTCB2);
      expect(getChainConfig('btcb2').name, 'btcb2');
      expect(getChainConfig('xbt').name, 'btcb2');
      expect(getChainConfig('XBT').name, 'btcb2');
      expect(supportCrypto(), contains('BTCB2'));

      final wallet = await getMnemonicWallet('btcb2', _testMnemonic);
      expect(wallet, isA<Btcb2Coin>());
      expect(wallet.address, '1LqBGSKuX5yYUonjxT5qGfpUsXKYYWeabA');

      final xbtWallet = await getMnemonicWallet('xbt', _testMnemonic);
      expect(xbtWallet.address, wallet.address);
    },
  );

  test('derives the standard BTCB2 BIP44 P2PKH account', () async {
    final wallet = await Btcb2Coin.fromMnemonic(_testMnemonic);

    expect(wallet.setting.bip44Path, "m/44'/0'/0'/0/0");
    expect(wallet.address, '1LqBGSKuX5yYUonjxT5qGfpUsXKYYWeabA');
    expect(wallet.publicKey.length, 33);
    expect(wallet.publicKey.first, anyOf(0x02, 0x03));

    final fromPrivateKey = Btcb2Coin.fromPrivateKey(wallet.privateKey);
    expect(fromPrivateKey.address, wallet.address);

    final digest = BytesUtils.toHexString(List<int>.filled(32, 1));
    final signature = wallet.sign(digest);
    expect(signature.endsWith('21'), isTrue);
    expect(wallet.verify(signature, digest), isTrue);
  });

  test('derives BTCB2 sub-accounts on custom BIP44 paths', () async {
    for (final entry in _subAccountAddresses.entries) {
      final wallet = await Btcb2Coin.fromMnemonic(
        _testMnemonic,
        WalletSetting(bip44Path: entry.key),
      );
      expect(wallet.setting.bip44Path, entry.key);
      expect(wallet.address, entry.value);
      expect(Btcb2Coin.fromPrivateKey(wallet.privateKey).address, entry.value);
    }
  });

  test(
    'converts only supported Bitcoin mainnet addresses to output scripts',
    () {
      final p2pkh = Btcb2Coin.scriptPubKeyFromAddress(
        '1MNyhAE9NvWfkRvgm12beN3m86dBNvSVVS',
      );
      final p2sh = Btcb2Coin.scriptPubKeyFromAddress(
        '3Qfxt4ayJ6tozsGHp8ub7fHNfB6fv7NZP1',
      );
      final segwit = Btcb2Coin.scriptPubKeyFromAddress(
        'bc1qj05a4upvdcd6fzxjd86855egf8dar84y9he3mt',
      );
      final taproot = Btcb2Coin.scriptPubKeyFromAddress(
        'bc1p8g698qj3tgvp6qr592g8mpqwetm4k2tju0efkl9n4uyncm9rgztsgsldmq',
      );

      expect(p2pkh.length, 25);
      expect(p2pkh.take(3), [0x76, 0xa9, 0x14]);
      expect(p2sh.length, 23);
      expect(p2sh.take(2), [0xa9, 0x14]);
      expect(p2sh.last, 0x87);
      expect(segwit.length, 22);
      expect(segwit.first, 0x00);
      expect(taproot.length, 34);
      expect(taproot.first, 0x51);
      expect(
        () => Btcb2Coin.scriptPubKeyFromAddress(
          'tb1qj05a4upvdcd6fzxjd86855egf8dar84y9he3mt',
        ),
        throwsFormatException,
      );
    },
  );

  test('validates, signs, and serializes a complete BTCB2 assembly', () async {
    final fixture = await _validAssemblyFixture();
    final signed = fixture.draft.sign(fixture.account.privateKey);

    expect(
      fixture.draft.signingHashHex(0),
      'a42e1bc17076cd0ba89d8907217d0bbe5abcc1a98957c02220a6c2ee328a6274',
    );
    expect(
      fixture.draft.unsignedTransactionHex,
      '020000000101000000000000000000000000000000000000000000000000000000000000000000000000fdffffff01905f010000000000160014d4a83264a4e35d27aa755f41ebb0dc70c395876e00000000',
    );
    expect(
      signed.rawTransactionHex,
      '02000000010100000000000000000000000000000000000000000000000000000000000000000000006a473044022004f968d1daaf2d9af170e0c29b5e338c33300688f1ac6132eb0497c4ef2c730e02201cc42ed20db2672a22f44bccddb1cee7957dfda01961a28e037637b2339be419212103aaeb52dd7494c361049de67cc680e83ebcbbbdbeb13637d92cd845f70308af5efdffffff01905f010000000000160014d4a83264a4e35d27aa755f41ebb0dc70c395876e00000000',
    );
    expect(signed.rawTransactionBytes.length, greaterThan(0));
    expect(signed.virtualSize, signed.rawTransactionBytes.length);
    expect(
      signed.transactionId,
      'ca0cf7f4b2985834d3fb3006e11a4bd737ba23cd6325a21460bb388c4a14cf06',
    );
    expect(signed.toBroadcast(), {'tx': signed.rawTransactionHex});
  });

  test('assembles and signs multiple inputs in service order', () async {
    final fixture = await _validAssemblyFixture(inputCount: 2);
    final draft = fixture.draft;
    final firstInput = fixture.state.inputs[0];
    final secondInput = fixture.state.inputs[1];
    final firstHash = draft.signingHashBytes(0);
    final secondHash = draft.signingHashBytes(1);
    final signer = Secp256k1SigningKey.fromBytes(
      keyBytes: fixture.account.privateKey,
    );
    final signatures = [
      signer.signDer(digest: firstHash),
      signer.signDer(digest: secondHash),
    ];

    expect(firstInput.transactionId, isNot(secondInput.transactionId));
    expect(firstHash, isNot(equals(secondHash)));
    final signed = draft.attachSignatures(signatures);
    final parsed = _ParsedTransaction.parse(signed.rawTransactionHex);

    expect(parsed.inputs.map((input) => input.transactionId), [
      firstInput.transactionId,
      secondInput.transactionId,
    ]);
    expect(parsed.inputs.map((input) => input.outputIndex), [
      firstInput.outputIndex,
      secondInput.outputIndex,
    ]);
    expect(
      signed.virtualSize,
      greaterThan(fixture.draft.unsignedTransactionBytes.length),
    );
    expect(
      () => draft.attachSignatures([signatures[1], signatures[0]]),
      throwsFormatException,
    );

    final duplicate = _assemblyResponse(
      sender: fixture.account.address,
      sourceScript: fixture.sourceScript,
      recipient: fixture.recipient,
      recipientScript: fixture.recipientScript,
      inputCount: 2,
    );
    final duplicateInputs =
        (((duplicate['signing_payload'] as Map)['data'] as Map)['inputs']
            as List);
    final firstDuplicate = duplicateInputs[0] as Map;
    final secondDuplicate = duplicateInputs[1] as Map;
    secondDuplicate['transactionId'] = firstDuplicate['transactionId'];
    secondDuplicate['outputIndex'] = firstDuplicate['outputIndex'];
    expect(
      () => Btcb2TransactionAssemblyData.fromServiceResponse(duplicate),
      throwsFormatException,
    );
  });

  test('assembles, signs, and verifies a sub-account sender', () async {
    const path = "m/44'/0'/1'/0/0";
    final fixture = await _validAssemblyFixture(path: path, inputCount: 2);
    expect(fixture.account.address, _subAccountAddresses[path]);
    expect(fixture.state.senderAddress, fixture.account.address);

    final signed = fixture.draft.sign(fixture.account.privateKey);
    expect(
      signed.rawTransactionHex,
      contains(BytesUtils.toHexString(fixture.account.publicKey)),
    );
    final parsed = _ParsedTransaction.parse(
      fixture.draft.unsignedTransactionHex,
    );
    expect(parsed.inputs.length, 2);
    final signer = Secp256k1SigningKey.fromBytes(
      keyBytes: fixture.account.privateKey,
    );
    final signatures = <List<int>>[];
    for (var index = 0; index < parsed.inputs.length; index++) {
      final digest = fixture.draft.signingHashBytes(index);
      final signature = signer.signDer(digest: digest);
      expect(
        fixture.account.verify(
          BytesUtils.toHexString([...signature, 0x21]),
          BytesUtils.toHexString(digest),
        ),
        isTrue,
      );
      signatures.add(signature);
    }
    expect(
      fixture.draft.attachSignatures(signatures).rawTransactionHex,
      signed.rawTransactionHex,
    );

    final defaultAccount = await Btcb2Coin.fromMnemonic(_testMnemonic);
    expect(
      () => Btcb2TransactionAssembler.fromPublicKeyBytes(
        defaultAccount.publicKey,
      ).build(fixture.state),
      throwsFormatException,
    );
  });

  test('rejects input paths that differ from the sender path', () async {
    final fixture = await _validAssemblyFixture(path: "m/44'/0'/1'/0/0");
    final mismatched = _assemblyResponse(
      sender: fixture.account.address,
      sourceScript: fixture.sourceScript,
      recipient: fixture.recipient,
      recipientScript: fixture.recipientScript,
      senderPath: "m/44'/0'/1'/0/0",
      inputPath: "m/44'/0'/0'/0/0",
    );
    expect(
      () => Btcb2TransactionAssemblyData.fromServiceResponse(mismatched),
      throwsFormatException,
    );
  });

  test('accepts xbt as the service assembly chain alias', () async {
    final fixture = await _validAssemblyFixture(chain: 'xbt');
    expect(fixture.state.senderAddress, fixture.account.address);
  });

  test(
    'local and external DER signing produce identical transactions',
    () async {
      final fixture = await _validAssemblyFixture();
      final account = fixture.account;
      final draft = fixture.draft;
      final externalSigner = Secp256k1SigningKey.fromBytes(
        keyBytes: account.privateKey,
      );
      final external = draft.attachSignatures([
        externalSigner.signDer(digest: draft.signingHashBytes(0)),
      ]);
      final local = draft.sign(account.privateKey);

      expect(external.rawTransactionHex, local.rawTransactionHex);
      expect(external.transactionId, local.transactionId);
    },
  );

  test('rejects invalid assembly metadata before signing', () async {
    final fixture = await _validAssemblyFixture();

    final invalidOutput = _assemblyResponse(
      sender: fixture.account.address,
      sourceScript: fixture.sourceScript,
      recipient: fixture.recipient,
      recipientScript: '00140000000000000000000000000000000000000000',
    );
    expect(
      () => Btcb2TransactionAssemblyData.fromServiceResponse(invalidOutput),
      throwsFormatException,
    );

    final wrongChain = _assemblyResponse(
      sender: fixture.account.address,
      sourceScript: fixture.sourceScript,
      recipient: fixture.recipient,
      recipientScript: fixture.recipientScript,
      chain: 'btc',
    );
    expect(
      () => Btcb2TransactionAssemblyData.fromServiceResponse(wrongChain),
      throwsFormatException,
    );

    final wrongKey = Btcb2Coin.fromPrivateKey(List<int>.filled(32, 1));
    expect(
      () => Btcb2TransactionAssembler.fromPublicKeyBytes(
        wrongKey.publicKey,
      ).build(fixture.state),
      throwsFormatException,
    );
  });

  test('rejects malformed or high-S external signatures', () async {
    final fixture = await _validAssemblyFixture();
    final account = fixture.account;
    final draft = fixture.draft;

    expect(
      () => draft.attachSignatures([
        [0x30, 0x01, 0x02],
      ]),
      throwsFormatException,
    );

    final der = Secp256k1SigningKey.fromBytes(
      keyBytes: account.privateKey,
    ).signDer(digest: draft.signingHashBytes(0));
    final highS = _replaceDerSWithHighS(der);
    expect(() => draft.attachSignatures([highS]), throwsFormatException);
  });

  test(
    'matches all official BTCB2 UNIFIED sighash script type 0/1 vectors',
    () {
      final fixture =
          jsonDecode(
                File(
                  'test/transaction/data/btcb2_unified_sighash.json',
                ).readAsStringSync(),
              )
              as List<Object?>;
      var checked = 0;

      for (final rawRow in fixture.skip(1)) {
        final row = rawRow as List<Object?>;
        final scriptType = row[4] as int;
        if (scriptType != 0 && scriptType != 1) continue;

        final transaction = _ParsedTransaction.parse(row[1] as String);
        final spentOutputs = (row[5] as List<Object?>).map((rawOutput) {
          final output = rawOutput as List<Object?>;
          return Btcb2SpentOutput(
            amountSats: output[0] as int,
            scriptPubKey: BytesUtils.fromHexString(output[1] as String),
          );
        }).toList();
        final digest = Btcb2UnifiedSighash.compute(
          version: transaction.version,
          lockTime: transaction.lockTime,
          inputs: transaction.inputs,
          spentOutputs: spentOutputs,
          outputs: transaction.outputs,
          inputIndex: row[2] as int,
          scriptCode: BytesUtils.fromHexString(row[0] as String),
          hashType: row[3] as int,
          scriptType: scriptType,
        );

        expect(
          BytesUtils.toHexString(digest),
          row[6],
          reason: 'official vector ${checked + 1}',
        );
        checked++;
      }

      expect(checked, 142);
    },
  );
}

final class _Btcb2AssemblyFixture {
  const _Btcb2AssemblyFixture({
    required this.account,
    required this.sourceScript,
    required this.recipient,
    required this.recipientScript,
    required this.state,
    required this.draft,
  });

  final Btcb2Coin account;
  final String sourceScript;
  final String recipient;
  final String recipientScript;
  final Btcb2TransactionAssemblyData state;
  final Btcb2TransactionDraft draft;
}

Future<_Btcb2AssemblyFixture> _validAssemblyFixture({
  String chain = 'btcb2',
  int inputCount = 1,
  String path = "m/44'/0'/0'/0/0",
}) async {
  final account = await Btcb2Coin.fromMnemonic(
    _testMnemonic,
    WalletSetting(bip44Path: path),
  );
  final sourceScript = BytesUtils.toHexString(
    Btcb2Coin.scriptPubKeyFromAddress(account.address),
  );
  const recipient = 'bc1q6j5rye9yudwj02n4taq7hvxuwrpetpmwlztgpf';
  final recipientScript = BytesUtils.toHexString(
    Btcb2Coin.scriptPubKeyFromAddress(recipient),
  );
  final state = Btcb2TransactionAssemblyData.fromServiceResponse(
    _assemblyResponse(
      sender: account.address,
      sourceScript: sourceScript,
      recipient: recipient,
      recipientScript: recipientScript,
      chain: chain,
      inputCount: inputCount,
      senderPath: path,
      inputPath: path,
    ),
  );
  final draft = Btcb2TransactionAssembler.fromPublicKeyBytes(
    account.publicKey,
  ).build(state);
  return _Btcb2AssemblyFixture(
    account: account,
    sourceScript: sourceScript,
    recipient: recipient,
    recipientScript: recipientScript,
    state: state,
    draft: draft,
  );
}

Map<String, dynamic> _assemblyResponse({
  required String sender,
  required String sourceScript,
  required String recipient,
  required String recipientScript,
  String chain = 'btcb2',
  int inputCount = 1,
  String senderPath = "m/44'/0'/0'/0/0",
  String? inputPath,
}) {
  if (inputCount < 1) {
    throw ArgumentError.value(inputCount, 'inputCount');
  }
  final inputAmounts = List<int>.generate(
    inputCount,
    (index) => 100000 * (index + 1),
  );
  final totalInput = inputAmounts.fold<int>(0, (sum, amount) => sum + amount);
  return {
    'status': 'success',
    'code': 20000,
    'signing_payload': {
      'type': 'btcb2_unified_transaction_assembly_state',
      'data': {
        'version': 2,
        'chain': chain,
        'network': 'mainnet',
        'sender': {'address': sender, 'derivationPath': senderPath},
        'inputs': List<Map<String, dynamic>>.generate(
          inputCount,
          (index) => {
            'transactionId':
                '${List.filled(31, '00').join()}${(index + 1).toRadixString(16).padLeft(2, '0')}',
            'outputIndex': index,
            'sequence': 0xfffffffd,
            'amountSats': '${inputAmounts[index]}',
            'address': sender,
            'scriptPubKey': sourceScript,
            'scriptCode': sourceScript,
            'scriptType': 0,
            'derivationPath': inputPath ?? senderPath,
          },
        ),
        'outputs': [
          {
            'address': recipient,
            'amountSats': '${totalInput - 10000}',
            'scriptPubKey': recipientScript,
          },
        ],
        'fee': {
          'amountSats': '10000',
          'rateSatPerVbyte': '1',
          'subtractFromOutputs': false,
        },
        'transaction': {'version': 2, 'lockTime': 0},
        'sighash': {
          'type': 33,
          'typeHex': '0x21',
          'epoch': 0,
          'tag': 'UnifiedSighash',
        },
        'chainIdentity': {
          'activationHeight': 961640,
          'activationHash':
              '0000000000000050c1e5f69672f459293be14f46e5a494e7a8c8541396f18eeb',
        },
      },
    },
    'signing_info': {
      'method': 'btcb2_unified_sighash',
      'digest_algorithm': 'tagged-sha256',
      'digest_encoding': 'bytes',
      'signature_algorithm': 'secp256k1-ecdsa',
      'signature_encoding': 'der-plus-sighash-byte',
      'serialized_transaction_encoding': 'hex',
    },
  };
}

List<int> _replaceDerSWithHighS(List<int> der) {
  final rLength = der[3];
  final sTag = 4 + rLength;
  final s = BigintUtils.fromBytes(der.sublist(sTag + 2));
  final highS = CryptoSignerConst.secp256k1Order - s;
  final highSBytes = BigintUtils.toBytes(highS);
  final encodedS = highSBytes.first & 0x80 == 0
      ? highSBytes
      : [0, ...highSBytes];
  return [
    0x30,
    2 + rLength + 2 + encodedS.length,
    0x02,
    rLength,
    ...der.sublist(4, 4 + rLength),
    0x02,
    encodedS.length,
    ...encodedS,
  ];
}

final class _ParsedTransaction {
  const _ParsedTransaction({
    required this.version,
    required this.inputs,
    required this.outputs,
    required this.lockTime,
  });

  final int version;
  final List<Btcb2SighashInput> inputs;
  final List<Btcb2SpentOutput> outputs;
  final int lockTime;

  factory _ParsedTransaction.parse(String hex) {
    final reader = _Reader(BytesUtils.fromHexString(hex));
    final version = reader.uint(4);
    final inputCount = reader.compactSize();
    final inputs = List<Btcb2SighashInput>.generate(inputCount, (_) {
      final transactionId = BytesUtils.toHexString(
        reader.bytes(32).reversed.toList(),
      );
      final outputIndex = reader.uint(4);
      reader.bytes(reader.compactSize());
      final sequence = reader.uint(4);
      return Btcb2SighashInput(
        transactionId: transactionId,
        outputIndex: outputIndex,
        sequence: sequence,
      );
    });
    final outputCount = reader.compactSize();
    final outputs = List<Btcb2SpentOutput>.generate(outputCount, (_) {
      final amount = reader.uint(8);
      return Btcb2SpentOutput(
        amountSats: amount,
        scriptPubKey: reader.bytes(reader.compactSize()),
      );
    });
    final lockTime = reader.uint(4);
    if (!reader.isDone) throw const FormatException('Trailing fixture bytes.');
    return _ParsedTransaction(
      version: version,
      inputs: inputs,
      outputs: outputs,
      lockTime: lockTime,
    );
  }
}

final class _Reader {
  _Reader(this.data);

  final List<int> data;
  int offset = 0;

  bool get isDone => offset == data.length;

  List<int> bytes(int count) {
    if (count < 0 || offset + count > data.length) {
      throw const FormatException('Truncated transaction fixture.');
    }
    final result = data.sublist(offset, offset + count);
    offset += count;
    return result;
  }

  int uint(int length) {
    final value = bytes(length);
    var result = 0;
    for (var i = value.length - 1; i >= 0; i--) {
      result = result * 256 + value[i];
    }
    return result;
  }

  int compactSize() {
    final prefix = uint(1);
    if (prefix < 0xfd) return prefix;
    if (prefix == 0xfd) return uint(2);
    if (prefix == 0xfe) return uint(4);
    return uint(8);
  }
}
