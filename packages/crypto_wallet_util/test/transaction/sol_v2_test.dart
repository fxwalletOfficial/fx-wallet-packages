import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto_wallet_util/src/wallets/sol.dart';
import 'package:crypto_wallet_util/transaction.dart';
import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';

void main() async {
  test('test sign', () async {
    final transactionsJson = json.decode(
        File('./test/transaction/data/sol_v2.json')
            .readAsStringSync(encoding: utf8));
    final transactionData = transactionsJson["transaction"];

    final target = transactionsJson['message'];

    final solTx = SolanaTransaction.fromBase64(transactionData);
    final message = solTx.message.serialize().asUint8List().toStr();

    expect(message, target);
  });

  // Additional test suites
  const String mnemonic = 'few tag video grain jealous light tired vapor shed festival shine tag';
  final solWallet = await SolCoin.fromMnemonic(mnemonic);

  group('Pubkey tests', () {
    test('create Pubkey from string', () {
      const pubkeyString = 'J6XAG36WMVKVpyAknbRE5h3trsNi2mDjZUy2v2pvT1Jk';
      final pubkey = Pubkey.fromString(pubkeyString);
      expect(pubkey.toBase58(), pubkeyString);
    });

    test('create Pubkey from base64', () {
      const pubkeyBase64 = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
      final pubkey = Pubkey.fromBase64(pubkeyBase64);
      expect(pubkey.toBase58(), '11111111111111111111111111111111');
    });

    test('create zero Pubkey', () {
      final zeroPubkey = Pubkey.zero();
      expect(zeroPubkey.toBase58(), '11111111111111111111111111111111');
    });

    test('Pubkey equality comparison', () {
      const pubkeyString = 'J6XAG36WMVKVpyAknbRE5h3trsNi2mDjZUy2v2pvT1Jk';
      final pubkey1 = Pubkey.fromString(pubkeyString);
      final pubkey2 = Pubkey.fromString(pubkeyString);
      expect(pubkey1 == pubkey2, isTrue);
    });
  });

  group('AccountMeta tests', () {
    final testPubkey = Pubkey.fromString('J6XAG36WMVKVpyAknbRE5h3trsNi2mDjZUy2v2pvT1Jk');

    test('create basic AccountMeta', () {
      final accountMeta = AccountMeta(testPubkey);
      expect(accountMeta.pubkey, testPubkey);
      expect(accountMeta.isSigner, isFalse);
      expect(accountMeta.isWritable, isFalse);
    });

    test('create signer AccountMeta', () {
      final signerMeta = AccountMeta.signer(testPubkey);
      expect(signerMeta.isSigner, isTrue);
      expect(signerMeta.isWritable, isFalse);
    });

    test('create writable AccountMeta', () {
      final writableMeta = AccountMeta.writable(testPubkey);
      expect(writableMeta.isSigner, isFalse);
      expect(writableMeta.isWritable, isTrue);
    });

    test('create signer and writable AccountMeta', () {
      final signerWritableMeta = AccountMeta.signerAndWritable(testPubkey);
      expect(signerWritableMeta.isSigner, isTrue);
      expect(signerWritableMeta.isWritable, isTrue);
    });

    test('AccountMeta copyWith functionality', () {
      final originalMeta = AccountMeta(testPubkey);
      final copiedMeta = originalMeta.copyWith(isSigner: true);
      expect(copiedMeta.isSigner, isTrue);
      expect(copiedMeta.isWritable, isFalse);
      expect(copiedMeta.pubkey, testPubkey);
    });
  });

  group('TransactionInstruction tests', () {
    final programId = Pubkey.fromString('11111111111111111111111111111111');
    final accountPubkey = Pubkey.fromString('J6XAG36WMVKVpyAknbRE5h3trsNi2mDjZUy2v2pvT1Jk');

    test('create TransactionInstruction', () {
      final instruction = TransactionInstruction(
        keys: [AccountMeta.signer(accountPubkey)],
        programId: programId,
        data: Uint8List.fromList([1, 2, 3, 4]),
      );

      expect(instruction.keys.length, 1);
      expect(instruction.keys.first.pubkey, accountPubkey);
      expect(instruction.programId, programId);
      expect(instruction.data, Uint8List.fromList([1, 2, 3, 4]));
    });

    test('convert to MessageInstruction', () {
      final instruction = TransactionInstruction(
        keys: [AccountMeta.signer(accountPubkey)],
        programId: programId,
        data: Uint8List.fromList([1, 2, 3, 4]),
      );

      final allKeys = [accountPubkey, programId];
      final messageInstruction = instruction.toMessageInstruction(allKeys);

      expect(messageInstruction.programIdIndex, 1); // programId at index 1
      expect(messageInstruction.accounts.first, 0); // accountPubkey at index 0
    });
  });

  group('SolanaTransaction tests', () {
    final payer = Pubkey.fromString('J6XAG36WMVKVpyAknbRE5h3trsNi2mDjZUy2v2pvT1Jk');
    const recentBlockhash = 'EETubP5AKHgjPAhzPAFcb8BAY1hMH639CWCFTqi3hq1k';

    test('create legacy transaction', () {
      final transaction = SolanaTransaction.legacy(
        payer: payer,
        recentBlockhash: recentBlockhash,
        instructions: [],
      );

      expect(transaction.signatures.length, 1);
      expect(transaction.version, isNull); // legacy transaction has no version
      expect(transaction.blockhash, recentBlockhash);
    });

    test('serialize and deserialize transaction', () {
      final transaction = SolanaTransaction.legacy(
        payer: payer,
        recentBlockhash: recentBlockhash,
        instructions: [],
      );

      final serialized = transaction.serialize();
      expect(serialized, isNotEmpty);

      final deserializedBase64 = base64.encode(serialized.asUint8List());
      final deserialized = SolanaTransaction.fromBase64(deserializedBase64);
      expect(deserialized.blockhash, recentBlockhash);
    });
  });

  group('SolTxDataV2 tests', () {
    test('create SolTxDataV2 from JSON', () {
      final jsonData = {
        'feePayer': 'J6XAG36WMVKVpyAknbRE5h3trsNi2mDjZUy2v2pvT1Jk',
        'recentBlockhash': 'EETubP5AKHgjPAhzPAFcb8BAY1hMH639CWCFTqi3hq1k',
        'instructions': [
          {
            'programId': '11111111111111111111111111111111',
            'data': [1, 2, 3, 4],
            'keys': [
              {
                'pubkey': 'J6XAG36WMVKVpyAknbRE5h3trsNi2mDjZUy2v2pvT1Jk',
                'isSigner': true,
                'isWritable': false
              }
            ]
          }
        ]
      };

      final txData = SolTxDataV2.fromJson(jsonData);
      expect(txData.solanaTransaction, isNotNull);
      expect(txData.solanaTransaction.blockhash, 'EETubP5AKHgjPAhzPAFcb8BAY1hMH639CWCFTqi3hq1k');
    });

    test('toBroadcast and toJson methods', () {
      final jsonData = {
        'feePayer': 'J6XAG36WMVKVpyAknbRE5h3trsNi2mDjZUy2v2pvT1Jk',
        'recentBlockhash': 'EETubP5AKHgjPAhzPAFcb8BAY1hMH639CWCFTqi3hq1k',
        'instructions': []
      };

      final txData = SolTxDataV2.fromJson(jsonData);
      final broadcastData = txData.toBroadcast();
      final jsonResult = txData.toJson();

      expect(broadcastData, isA<Map<String, dynamic>>());
      expect(jsonResult, isA<Map<String, dynamic>>());
    });
  });

  group('SolTxSignerV2 tests', () {
    test('sign transaction', () {
      final jsonData = {
        'feePayer': solWallet.address,
        'recentBlockhash': 'EETubP5AKHgjPAhzPAFcb8BAY1hMH639CWCFTqi3hq1k',
        'instructions': []
      };

      final txData = SolTxDataV2.fromJson(jsonData);
      final signer = SolTxSignerV2(solWallet, txData);

      signer.sign();

      expect(txData.isSigned, isTrue);
      expect(txData.signature, isNotEmpty);
      expect(txData.message, isNotEmpty);
    });

    test('verify signature', () {
      final jsonData = {
        'feePayer': solWallet.address,
        'recentBlockhash': 'EETubP5AKHgjPAhzPAFcb8BAY1hMH639CWCFTqi3hq1k',
        'instructions': []
      };

      final txData = SolTxDataV2.fromJson(jsonData);
      final signer = SolTxSignerV2(solWallet, txData);

      signer.sign();
      expect(signer.verify(), isTrue);
    });

    test('unsigned transaction verification fails', () {
      final jsonData = {
        'feePayer': solWallet.address,
        'recentBlockhash': 'EETubP5AKHgjPAhzPAFcb8BAY1hMH639CWCFTqi3hq1k',
        'instructions': []
      };

      final txData = SolTxDataV2.fromJson(jsonData);
      final signer = SolTxSignerV2(solWallet, txData);

      expect(signer.verify(), isFalse);
    });
  });

  group('integration tests', () {
    test('complete transaction creation and signing flow', () {
      // Create a complete transaction with instructions
      final receiverPubkey = Pubkey.fromString('11111111111111111111111111111111');
      final jsonData = {
        'feePayer': solWallet.address,
        'recentBlockhash': 'EETubP5AKHgjPAhzPAFcb8BAY1hMH639CWCFTqi3hq1k',
        'instructions': [
          {
            'programId': '11111111111111111111111111111111',
            'data': [2, 0, 0, 0, 128, 150, 152, 0, 0, 0, 0, 0], // transfer instruction data
            'keys': [
              {
                'pubkey': solWallet.address,
                'isSigner': true,
                'isWritable': true
              },
              {
                'pubkey': receiverPubkey.toBase58(),
                'isSigner': false,
                'isWritable': true
              }
            ]
          }
        ]
      };

      // Create transaction data
      final txData = SolTxDataV2.fromJson(jsonData);
      expect(txData.solanaTransaction.message.instructions.length, 1);

      // Create signer and sign
      final signer = SolTxSignerV2(solWallet, txData);
      signer.sign();

      // Verify signing results
      expect(txData.isSigned, isTrue);
      expect(signer.verify(), isTrue);
      expect(txData.solanaTransaction.signatures.first, isNotEmpty);

      // Verify transaction can be serialized
      final serialized = txData.solanaTransaction.serialize();
      expect(serialized, isNotEmpty);
    });
  });
}
