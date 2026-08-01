import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/transaction.dart'
    as psbt;
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/transaction_input.dart'
    as psbt;
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/transaction_output.dart'
    as psbt;
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/script_signature.dart'
    as psbt;
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/script_public_key.dart'
    as psbt;
import 'package:crypto_wallet_util/src/forked_lib/psbt/utils/converter.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/utils/varints.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart'
    as bf;

/// Cross-checks `Transaction.getTaprootSigHash` (the F2 fix) against the
/// official BIP341 "keyPathSpending" test vectors published at
/// https://github.com/bitcoin/bips/blob/master/bip-0341/wallet-test-vectors.json
/// (fetched 2026-08-02). This is the independent-vector validation the
/// signature review's evidence-gaps section asked for, on top of the
/// existing cross-implementation check against `hashForWitnessV1` in
/// test/psbt/taproot_sighash_test.dart.
void main() {
  const rawUnsignedTx =
      '02000000097de20cbff686da83a54981d2b9bab3586f4ca7e48f57f5b55963115f3b334e9c010000000000000000d7b7cab57b1393ace2d064f4d4a2cb8af6def61273e127517d44759b6dafdd990000000000fffffffff8e1f583384333689228c5d28eac13366be082dc57441760d957275419a418420000000000fffffffff0689180aa63b30cb162a73c6d2a38b7eeda2a83ece74310fda0843ad604853b0100000000feffffffaa5202bdf6d8ccd2ee0f0202afbbb7461d9264a25e5bfd3c5a52ee1239e0ba6c0000000000feffffff956149bdc66faa968eb2be2d2faa29718acbfe3941215893a2a3446d32acd050000000000000000000e664b9773b88c09c32cb70a2a3e4da0ced63b7ba3b22f848531bbb1d5d5f4c94010000000000000000e9aa6b8e6c9de67619e6a3924ae25696bb7b694bb677a632a74ef7eadfd4eabf0000000000ffffffffa778eb6a263dc090464cd125c466b5a99667720b1c110468831d058aa1b82af10100000000ffffffff0200ca9a3b000000001976a91406afd46bcdfd22ef94ac122aa11f241244a37ecc88ac807840cb0000000020ac9a87f5594be208f8532db38cff670c450ed2fea8fcdefcc9a663f78bab962b0065cd1d';

  // utxosSpent, in input order — raw (unprefixed) scriptPubKey + amount.
  const rawScripts = [
    '512053a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda343',
    '5120147c9c57132f6e7ecddba9800bb0c4449251c92a1e60371ee77557b6620f3ea3',
    '76a914751e76e8199196d454941c45d1b3a323f1433bd688ac',
    '5120e4d810fd50586274face62b8a807eb9719cef49c04177cc6b76a9a4251d5450e',
    '512091b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605',
    '00147dd65592d0ab2fe0d0257d571abf032cd9db93dc',
    '512075169f4001aa68f15bbed28b218df1d0a62cbbcf1188c6665110c293c907b831',
    '5120712447206d7a5238acc7ff53fbe94a3b64539ad291c7cdbc490b7577e4b17df5',
    '512077e30a5522dd9f894c3f8b8bd4c4b2cf82ca7da8a3ea6a239655c39c050ab220',
  ];
  const values = [
    420000000,
    462000000,
    294000000,
    504000000,
    630000000,
    378000000,
    672000000,
    546000000,
    588000000,
  ];

  Uint8List le32(int value) {
    final b = Uint8List(4);
    ByteData.sublistView(b).setUint32(0, value, Endian.little);
    return b;
  }

  Uint8List le64(int value) {
    final b = Uint8List(8);
    ByteData.sublistView(b).setUint64(0, value, Endian.little);
    return b;
  }

  String prefixedScriptHex(String rawScriptHex) {
    final raw = Converter.hexToBytes(rawScriptHex);
    return Converter.bytesToHex(Varints.encode(raw.length)) +
        Converter.bytesToHex(raw);
  }

  // Each case: [txinIndex, hashType, expected sigHash].
  const cases = [
    [0, 3, '2514a6272f85cfa0f45eb907fcb0d121b808ed37c6ea160a5a9046ed5526d555'],
    [1, 131, '325a644af47e8a5a2591cda0ab0723978537318f10e6a63d4eed783b96a71a4d'],
    [3, 1, 'bf013ea93474aa67815b1b6cc441d23b64fa310911d991e713cd34c7f5d46669'],
    [4, 0, '4f900a0bae3f1446fd48490c2958b5a023228f01661cda3496a11da502a7f7ef'],
    [6, 2, '15f25c298eb5cdc7eb1d638dd2d45c97c4c59dcaec6679cfc16ad84f30876b85'],
    [7, 130, 'cd292de50313804dabe4685e83f923d2969577191a3e1d2882220dca88cbeb10'],
    [8, 129, 'cccb739eca6c13a8a89e6e5cd317ffe55669bbda23f2fd37b0f18755e008edd2'],
  ];

  // Build the psbt-lib Transaction manually from a parse via the other
  // (bitcoin_flutter) transaction implementation, instead of
  // `psbt.Transaction.parsePsbtTransaction` — that parser's output decoder
  // isn't built to handle every real-world scriptPubKey shape in this
  // vector (e.g. the bare 32-byte-push second output), and reproducing its
  // parsing isn't the point of this test; only feeding `getTaprootSigHash`
  // the right version/inputs/outputs/locktime is.
  psbt.Transaction buildPsbtTx() {
    final bfTx = bf.Transaction.fromHex(rawUnsignedTx);

    final inputs = bfTx.ins
        .map((input) => psbt.TransactionInput(
              input.hash!,
              le32(input.index!),
              psbt.ScriptSignature.empty(),
              le32(input.sequence!),
            ))
        .toList();

    final outputs = bfTx.outs
        .map((output) => psbt.TransactionOutput(
              le64(output.value!),
              psbt.ScriptPublicKey.fromScriptByte(output.script!.toList()),
            ))
        .toList();

    return psbt.Transaction(
      le32(bfTx.version!),
      inputs,
      outputs,
      le32(bfTx.locktime!),
      false,
    );
  }

  test('matches every official BIP341 keyPathSpending sigHash vector', () {
    final tx = buildPsbtTx();
    final prevOutScripts = rawScripts.map(prefixedScriptHex).toList();

    for (final c in cases) {
      final txinIndex = c[0] as int;
      final hashType = c[1] as int;
      final expected = c[2] as String;

      final actual =
          tx.getTaprootSigHash(txinIndex, prevOutScripts, values, hashType: hashType);

      expect(actual, expected,
          reason: 'txinIndex=$txinIndex hashType=$hashType');
    }
  });
}
