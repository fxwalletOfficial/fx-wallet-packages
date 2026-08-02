import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/transaction.dart'
    as psbt;
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/transaction_input.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/transaction_output.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/script_signature.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/script_public_key.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/utils/converter.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart'
    as bf;

/// Regression tests for F2: PSBT Taproot signing previously reused the
/// BIP143 (`isSegwit: true`) sighash for P2TR key-path inputs, which signs
/// the wrong message. `Transaction.getTaprootSigHash` implements BIP341
/// TapSighash directly against the PSBT transaction model; these tests
/// cross-check it byte-for-byte against `hashForWitnessV1`, an independent,
/// already-exercised BIP341 implementation used by the GSPL/legacy Taproot
/// signing path (see ecpair/gspl characterization tests), for a synthetic
/// multi-input transaction built identically in both models.
void main() {
  // Two arbitrary 32-byte (internal byte order) previous txids.
  final prevHash0 = Uint8List.fromList(List.generate(32, (i) => i));
  final prevHash1 =
      Uint8List.fromList(List.generate(32, (i) => 0xa0 + i & 0xff));

  // Raw (unprefixed) P2TR scriptPubKeys: OP_1 <32-byte-x-only-pubkey>.
  final rawScript0 =
      Uint8List.fromList([0x51, 0x20, ...List.generate(32, (i) => 0x11 + i)]);
  final rawScript1 =
      Uint8List.fromList([0x51, 0x20, ...List.generate(32, (i) => 0x55 + i)]);

  final rawOutScript0 =
      Uint8List.fromList([0x51, 0x20, ...List.generate(32, (i) => 0x99 - i)]);
  final rawOutScript1 =
      Uint8List.fromList([0x51, 0x20, ...List.generate(32, (i) => 0x30 + i)]);

  psbt.Transaction buildPsbtTx() {
    final inputs = [
      TransactionInput(prevHash0, Converter.intToLittleEndianBytes(0, 4),
          ScriptSignature.empty(), Converter.intToLittleEndianBytes(0xfffffffd, 4)),
      TransactionInput(prevHash1, Converter.intToLittleEndianBytes(1, 4),
          ScriptSignature.empty(), Converter.intToLittleEndianBytes(0xffffffff, 4)),
    ];
    final outputs = [
      TransactionOutput(Converter.intToLittleEndianBytes(100000, 8),
          ScriptPublicKey.fromScriptByte(rawOutScript0.toList())),
      TransactionOutput(Converter.intToLittleEndianBytes(50000, 8),
          ScriptPublicKey.fromScriptByte(rawOutScript1.toList())),
    ];
    return psbt.Transaction(Converter.intToLittleEndianBytes(2, 4), inputs,
        outputs, Converter.intToLittleEndianBytes(0, 4), false);
  }

  bf.Transaction buildBfTx() {
    final tx = bf.Transaction();
    tx.setVersion(2);
    tx.setLocktime(0);
    tx.addInput(prevHash0, 0, sequence: 0xfffffffd);
    tx.addInput(prevHash1, 1, sequence: 0xffffffff);
    tx.addOutput(rawOutScript0, 100000);
    tx.addOutput(rawOutScript1, 50000);
    return tx;
  }

  String prefixedScriptHex(Uint8List raw) {
    return ScriptPublicKey.fromScriptByte(raw.toList()).serialize();
  }

  group('getTaprootSigHash matches independent hashForWitnessV1', () {
    test('SIGHASH_DEFAULT, input 0', () {
      final psbtTx = buildPsbtTx();
      final bfTx = buildBfTx();

      final actual = psbtTx.getTaprootSigHash(
        0,
        [prefixedScriptHex(rawScript0), prefixedScriptHex(rawScript1)],
        [600000, 700000],
      );
      final expected = Converter.bytesToHex(bfTx.hashForWitnessV1(
        0,
        [rawScript0, rawScript1],
        [600000, 700000],
        0x00,
        null,
        null,
      ));

      expect(actual, expected);
      expect(actual.length, 64); // 32 bytes hex
    });

    test('SIGHASH_DEFAULT, input 1', () {
      final psbtTx = buildPsbtTx();
      final bfTx = buildBfTx();

      final actual = psbtTx.getTaprootSigHash(
        1,
        [prefixedScriptHex(rawScript0), prefixedScriptHex(rawScript1)],
        [600000, 700000],
      );
      final expected = Converter.bytesToHex(bfTx.hashForWitnessV1(
        1,
        [rawScript0, rawScript1],
        [600000, 700000],
        0x00,
        null,
        null,
      ));

      expect(actual, expected);
    });

    test('explicit SIGHASH_ALL differs from SIGHASH_DEFAULT but still matches',
        () {
      final psbtTx = buildPsbtTx();
      final bfTx = buildBfTx();

      final actualDefault = psbtTx.getTaprootSigHash(
        0,
        [prefixedScriptHex(rawScript0), prefixedScriptHex(rawScript1)],
        [600000, 700000],
      );
      final actualAll = psbtTx.getTaprootSigHash(
        0,
        [prefixedScriptHex(rawScript0), prefixedScriptHex(rawScript1)],
        [600000, 700000],
        hashType: 0x01,
      );
      final expectedAll = Converter.bytesToHex(bfTx.hashForWitnessV1(
        0,
        [rawScript0, rawScript1],
        [600000, 700000],
        0x01,
        null,
        null,
      ));

      expect(actualAll, expectedAll);
      expect(actualAll, isNot(actualDefault));
    });

    test('SIGHASH_NONE|ANYONECANPAY matches', () {
      final psbtTx = buildPsbtTx();
      final bfTx = buildBfTx();
      const hashType = 0x02 | 0x80; // NONE | ANYONECANPAY

      final actual = psbtTx.getTaprootSigHash(
        1,
        [prefixedScriptHex(rawScript0), prefixedScriptHex(rawScript1)],
        [600000, 700000],
        hashType: hashType,
      );
      final expected = Converter.bytesToHex(bfTx.hashForWitnessV1(
        1,
        [rawScript0, rawScript1],
        [600000, 700000],
        hashType,
        null,
        null,
      ));

      expect(actual, expected);
    });

    test('SIGHASH_SINGLE matches', () {
      final psbtTx = buildPsbtTx();
      final bfTx = buildBfTx();
      const hashType = 0x03; // SINGLE

      final actual = psbtTx.getTaprootSigHash(
        1,
        [prefixedScriptHex(rawScript0), prefixedScriptHex(rawScript1)],
        [600000, 700000],
        hashType: hashType,
      );
      final expected = Converter.bytesToHex(bfTx.hashForWitnessV1(
        1,
        [rawScript0, rawScript1],
        [600000, 700000],
        hashType,
        null,
        null,
      ));

      expect(actual, expected);
    });

    test('rejects mismatched prevout list length', () {
      final psbtTx = buildPsbtTx();
      expect(
        () => psbtTx.getTaprootSigHash(0, [prefixedScriptHex(rawScript0)], [1]),
        throwsArgumentError,
      );
    });
  });
}
