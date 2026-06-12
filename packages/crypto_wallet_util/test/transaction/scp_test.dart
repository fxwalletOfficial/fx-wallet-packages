import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/sc.dart';
import 'package:crypto_wallet_util/transaction.dart';

void main() async {
  const String mnemonic =
      'elite proof vital episode image acoustic panda ridge welcome clump clerk riot';

  /// Known values from the JS reference script output.
  const expectedAddress =
      '328c18b6cbdb538185aaf58a3e5e71fa17d66e93ae39c1426864ba3b7903b9d56050b56937f8';
  const expectedDigestHex =
      'ad4eddb6bded2b7925fce75d17936f299d455b91b09b49b40f96d8b53c99aefe';
  const expectedSignatureBase64 =
      '+do9LFX2kmjeLEjeq1718QFaCGklqRu1eYBPspb1eNvNuVctZegxGvz56psdHo8DnDiHEeAkFXTmCzxYl9hoAg==';

  final wallet = await SiaCoin.fromMnemonic(mnemonic);

  /// Load the unsigned transaction fixture matching the JS
  /// `HARDCODED_UNSIGNED_TX` in scp-v2-api-local-test.mjs.
  final unsignedJson = json.decode(
      File('./test/transaction/data/scp_unsigned.json')
          .readAsStringSync(encoding: utf8));
  final unsignedTx = ScpUnsignedTransaction.fromJson(unsignedJson);

  group('scp account derivation', () {
    test('derives the expected address from mnemonic', () {
      expect(wallet.address, expectedAddress);
    });
  });

  group('scp digest computation', () {
    test('produces the expected digest from HARDCODED_UNSIGNED_TX', () {
      final digests = ScpSigHash.computeDigests(unsignedTx);
      expect(digests.length, 1);
      expect(digests.first, expectedDigestHex);
    });

    test('digest is deterministic', () {
      final d1 = ScpSigHash.computeDigests(unsignedTx);
      final d2 = ScpSigHash.computeDigests(unsignedTx);
      expect(d1, d2);
    });

    test('digest changes when input changes', () {
      final d1 = ScpSigHash.computeDigests(unsignedTx);

      final modified = ScpUnsignedTransaction.fromJson(
          Map<String, dynamic>.from(unsignedJson));
      modified.minerFees[0] = '999999999999999999999999';
      final d2 = ScpSigHash.computeDigests(modified);

      expect(d1, isNot(d2));
    });
  });

  group('scp sign & verify', () {
    test('signs the digests and verifies with expected signature', () {
      final watch = Stopwatch()..start();
      final digests = ScpSigHash.computeDigests(unsignedTx);

      // Build the mutable transaction map for signing
      final txMap = Map<String, dynamic>.from(unsignedJson);
      final sigEntries = unsignedTx.transactionSignatures
          .map((e) => ScpTransactionSignature(
                parentID: e.parentID,
                publicKeyIndex: e.publicKeyIndex,
                coveredFields: e.coveredFields,
              ))
          .toList();

      final txData = ScpTxData(
        transaction: txMap,
        toSign: digests,
        transactionSignatures: sigEntries,
      );

      final signer = ScpTxSigner(wallet, txData);
      signer.sign();

      expect(signer.verify(), isTrue);
      expect(txData.isSigned, isTrue);

      // Verify exact signature matches JS output
      final txSigs =
          txData.transaction['transactionSignatures'] as List<dynamic>;
      expect(txSigs.first['signature'], expectedSignatureBase64);

      watch.stop();
      print(
          '[scp_test] signs the digests and verifies: ${watch.elapsedMilliseconds} ms');
    });

    test('broadcast format is { data: signedTx }', () {
      final digests = ScpSigHash.computeDigests(unsignedTx);
      final txMap = Map<String, dynamic>.from(unsignedJson);
      final sigEntries = unsignedTx.transactionSignatures
          .map((e) => ScpTransactionSignature(
                parentID: e.parentID,
                publicKeyIndex: e.publicKeyIndex,
                coveredFields: e.coveredFields,
              ))
          .toList();

      final txData = ScpTxData(
        transaction: txMap,
        toSign: digests,
        transactionSignatures: sigEntries,
      );

      ScpTxSigner(wallet, txData).sign();

      final broadcast = txData.toBroadcast();
      expect(broadcast.containsKey('data'), isTrue);

      final data = broadcast['data'] as Map;
      expect(data['siacoinInputs'], isNotEmpty);
      expect(data['transactionSignatures'], isNotEmpty);
      expect(
          data['transactionSignatures'][0]['signature'],
          expectedSignatureBase64);
    });

    test('throws when transactionSignatures count != toSign count', () {
      final digests = ScpSigHash.computeDigests(unsignedTx);
      final txMap = Map<String, dynamic>.from(unsignedJson);
      final sigEntries = unsignedTx.transactionSignatures
          .map((e) => ScpTransactionSignature(
                parentID: e.parentID,
                publicKeyIndex: e.publicKeyIndex,
                coveredFields: e.coveredFields,
              ))
          .toList();

      final txData = ScpTxData(
        transaction: txMap,
        toSign: [...digests, 'deadbeef'], // extra digest
        transactionSignatures: sigEntries,
      );

      expect(() => ScpTxSigner(wallet, txData).sign(), throwsStateError);
    });
  });
}
