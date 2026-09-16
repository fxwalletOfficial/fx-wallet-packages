import 'dart:convert';
import 'dart:io';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';

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

      final wallet = await getMnemonicWallet('btcb2', mnemonic);
      expect(wallet, isA<Btcb2Coin>());
      expect(wallet.address, '1LqBGSKuX5yYUonjxT5qGfpUsXKYYWeabA');

      final xbtWallet = await getMnemonicWallet('xbt', mnemonic);
      expect(xbtWallet.address, wallet.address);
    },
  );

  test('derives the standard BTCB2 BIP44 P2PKH account', () async {
    final wallet = await Btcb2Coin.fromMnemonic(mnemonic);

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
    final account = await Btcb2Coin.fromMnemonic(mnemonic);
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
      ),
    );
    final draft = Btcb2TransactionAssembler.fromPublicKeyBytes(
      account.publicKey,
    ).build(state);
    final signed = draft.sign(account.privateKey);

    expect(
      draft.signingHashHex(0),
      'a42e1bc17076cd0ba89d8907217d0bbe5abcc1a98957c02220a6c2ee328a6274',
    );
    expect(
      draft.unsignedTransactionHex,
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

  test('accepts xbt as the service assembly chain alias', () async {
    final account = await Btcb2Coin.fromMnemonic(mnemonic);
    final sourceScript = BytesUtils.toHexString(
      Btcb2Coin.scriptPubKeyFromAddress(account.address),
    );
    const recipient = 'bc1q6j5rye9yudwj02n4taq7hvxuwrpetpmwlztgpf';
    final recipientScript = BytesUtils.toHexString(
      Btcb2Coin.scriptPubKeyFromAddress(recipient),
    );
    final response = _assemblyResponse(
      sender: account.address,
      sourceScript: sourceScript,
      recipient: recipient,
      recipientScript: recipientScript,
    );
    ((response['signing_payload'] as Map)['data'] as Map)['chain'] = 'xbt';

    final state = Btcb2TransactionAssemblyData.fromServiceResponse(response);
    expect(state.senderAddress, account.address);
  });

  test(
    'local and external DER signing produce identical transactions',
    () async {
      final account = await Btcb2Coin.fromMnemonic(mnemonic);
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
        ),
      );
      final draft = Btcb2TransactionAssembler.fromPublicKeyBytes(
        account.publicKey,
      ).build(state);
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
    final account = await Btcb2Coin.fromMnemonic(mnemonic);
    final sourceScript = BytesUtils.toHexString(
      Btcb2Coin.scriptPubKeyFromAddress(account.address),
    );
    const recipient = 'bc1q6j5rye9yudwj02n4taq7hvxuwrpetpmwlztgpf';
    final recipientScript = BytesUtils.toHexString(
      Btcb2Coin.scriptPubKeyFromAddress(recipient),
    );

    final invalidOutput = _assemblyResponse(
      sender: account.address,
      sourceScript: sourceScript,
      recipient: recipient,
      recipientScript: '00140000000000000000000000000000000000000000',
    );
    expect(
      () => Btcb2TransactionAssemblyData.fromServiceResponse(invalidOutput),
      throwsFormatException,
    );

    final wrongChain = _assemblyResponse(
      sender: account.address,
      sourceScript: sourceScript,
      recipient: recipient,
      recipientScript: recipientScript,
    );
    ((wrongChain['signing_payload'] as Map)['data'] as Map)['chain'] = 'btc';
    expect(
      () => Btcb2TransactionAssemblyData.fromServiceResponse(wrongChain),
      throwsFormatException,
    );

    final wrongKey = Btcb2Coin.fromPrivateKey(List<int>.filled(32, 1));
    final validState = Btcb2TransactionAssemblyData.fromServiceResponse(
      _assemblyResponse(
        sender: account.address,
        sourceScript: sourceScript,
        recipient: recipient,
        recipientScript: recipientScript,
      ),
    );
    expect(
      () => Btcb2TransactionAssembler.fromPublicKeyBytes(
        wrongKey.publicKey,
      ).build(validState),
      throwsFormatException,
    );
  });

  test('rejects malformed or high-S external signatures', () async {
    final account = await Btcb2Coin.fromMnemonic(mnemonic);
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
      ),
    );
    final draft = Btcb2TransactionAssembler.fromPublicKeyBytes(
      account.publicKey,
    ).build(state);

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

Map<String, dynamic> _assemblyResponse({
  required String sender,
  required String sourceScript,
  required String recipient,
  required String recipientScript,
}) {
  return {
    'status': 'success',
    'code': 20000,
    'signing_payload': {
      'type': 'btcb2_unified_transaction_assembly_state',
      'data': {
        'version': 2,
        'chain': 'btcb2',
        'network': 'mainnet',
        'sender': {'address': sender, 'derivationPath': "m/44'/0'/0'/0/0"},
        'inputs': [
          {
            'transactionId': '${List.filled(31, '00').join()}01',
            'outputIndex': 0,
            'sequence': 0xfffffffd,
            'amountSats': '100000',
            'address': sender,
            'scriptPubKey': sourceScript,
            'scriptCode': sourceScript,
            'scriptType': 0,
            'derivationPath': "m/44'/0'/0'/0/0",
          },
        ],
        'outputs': [
          {
            'address': recipient,
            'amountSats': '90000',
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
