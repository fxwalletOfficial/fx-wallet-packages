import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:crypto_wallet_util/transaction.dart';
import 'package:test/test.dart';

void main() {
  late ScWasmRunBridge bridge;
  late Map<String, dynamic> transaction;

  setUpAll(() {
    transaction = Map<String, dynamic>.from(
      json.decode(
        File(
          '../crypto_wallet_util/test/transaction/data/sc_unsigned.json',
        ).readAsStringSync(),
      ) as Map,
    );
    bridge = ScWasmRunBridge(
      File(
        '../crypto_wallet_util/lib/src/transaction/sc/sc.wasm',
      ).readAsBytesSync(),
    );
  });

  tearDownAll(() => bridge.dispose());

  test('every accepted SC semantic payload fits ScV2SignRequest', () async {
    final semantics = await bridge.extractV2TransactionSemantics(transaction);

    expect(
      scV2MaxSemanticTransactionBytes,
      ScV2SignRequest.maxSemanticTransactionBytes,
    );
    expect(
      semantics.bytes.length,
      lessThanOrEqualTo(ScV2SignRequest.maxSemanticTransactionBytes),
    );

    final request = ScV2SignRequest(
      requestId: Uint8List(16),
      profile: ScV2Profile.sc,
      masterFingerprint: Uint8List(4),
      signerCoreAddress: Uint8List(32),
      semanticTransaction: semantics.bytes,
    );
    expect(request.semanticTransaction, semantics.bytes);
  });
}
