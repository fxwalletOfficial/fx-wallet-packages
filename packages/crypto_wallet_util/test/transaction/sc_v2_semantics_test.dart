import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto_wallet_util/transaction.dart';
import 'package:test/test.dart';

void main() {
  const expectedDigest =
      'c191c3f2478833e66eb8911038f7fbe4f1810ec16cb3f0628c0ccfe7a4bc2f4d';

  late Map<String, dynamic> unsignedTransaction;
  late ScWasmRunBridge bridge;
  late ScV2TransactionSemantics extracted;
  const ffiLibPath = './test/native/libsc_transaction_darwin_arm64.dylib';
  final ffiSkip =
      Platform.isMacOS &&
          Abi.current() == Abi.macosArm64 &&
          File(ffiLibPath).existsSync()
      ? false
      : 'native SC semantic fixture requires macOS arm64';

  setUpAll(() async {
    unsignedTransaction = Map<String, dynamic>.from(
      json.decode(
            File(
              './test/transaction/data/sc_unsigned.json',
            ).readAsStringSync(encoding: utf8),
          )
          as Map,
    );
    bridge = ScWasmRunBridge(
      File('./lib/src/transaction/sc/sc.wasm').readAsBytesSync(),
    );
    final outputs = unsignedTransaction['siacoinOutputs'] as List;
    final changeAddress = (outputs[1] as Map)['address'] as String;
    extracted = await bridge.extractV2TransactionSemantics(
      unsignedTransaction,
      changeAddresses: [changeAddress],
    );
  });

  tearDownAll(() => bridge.dispose());

  test('extracts the official canonical semantics and typed display model', () {
    expect(extracted.profile, scV2SiacoinTransferProfile);
    expect(extracted.inputSigHash, expectedDigest);
    expect(extracted.bytes, hasLength(217));
    expect(extracted.inputCount, 1);
    expect(extracted.parentIds, hasLength(1));
    expect(extracted.outputs, hasLength(2));
    expect(
      extracted.outputs.first.value.toString(),
      '100000000000000000000000',
    );
    expect(extracted.externalOutputs, hasLength(1));
    expect(extracted.changeOutputs, hasLength(1));
    expect(extracted.minerFee.toString(), '20000000000000000000000');
  });

  test('cold-side inspection recomputes the same digest and model', () async {
    final inspected = await bridge.inspectV2TransactionSemantics(
      extracted.bytes,
      changeAddresses: [extracted.changeOutputs.single.address],
    );

    expect(inspected.inputSigHash, extracted.inputSigHash);
    expect(inspected.bytes, extracted.bytes);
    expect(inspected.toJson(), extracted.toJson());
  });

  test('native FFI bridge returns the same semantics and digest', () async {
    final ffiBridge = ScGoFfiBridge(DynamicLibrary.open(ffiLibPath));
    final ffiResult = await ffiBridge.extractV2TransactionSemantics(
      unsignedTransaction,
    );
    final inspected = await ffiBridge.inspectV2TransactionSemantics(
      ffiResult.bytes,
    );

    expect(ffiResult.inputSigHash, extracted.inputSigHash);
    expect(ffiResult.bytes, extracted.bytes);
    expect(inspected.inputSigHash, extracted.inputSigHash);
  }, skip: ffiSkip);

  test('default isolate builder exposes the same semantic API', () async {
    final builder = await ScTransactionBuilder.create();
    addTearDown(builder.dispose);
    final result = await builder.extractV2TransactionSemantics(
      unsignedTransaction,
    );

    expect(result.inputSigHash, extracted.inputSigHash);
    expect(result.bytes, extracted.bytes);
    final inspected = await builder.inspectV2TransactionSemantics(result.bytes);
    expect(inspected.inputSigHash, result.inputSigHash);
    expect(inspected.bytes, result.bytes);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('strict inspection rejects trailing semantic bytes', () async {
    await expectLater(
      bridge.inspectV2TransactionSemantics(
        Uint8List.fromList([...extracted.bytes, 0]),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('full-payload extraction rejects unknown fields', () async {
    final invalid = Map<String, dynamic>.from(unsignedTransaction)
      ..['futureConsensusField'] = true;
    await expectLater(
      bridge.extractV2TransactionSemantics(invalid),
      throwsA(isA<StateError>()),
    );
  });

  test('typed model rejects inconsistent bridge responses', () {
    final zeroOutput = extracted.toJson();
    final originalOutputs = zeroOutput['outputs'] as List;
    zeroOutput['outputs'] = [
      {
        ...Map<String, dynamic>.from(originalOutputs.first as Map),
        'value': '0',
      },
      ...originalOutputs.skip(1),
    ];
    final cases = <Map<String, dynamic>>[
      {...extracted.toJson(), 'profile': 'future-profile'},
      {...extracted.toJson(), 'byteLength': extracted.bytes.length + 1},
      {...extracted.toJson(), 'inputCount': 0},
      {...extracted.toJson(), 'parentIds': const <String>[]},
      {...extracted.toJson(), 'outputs': const <Object>[]},
      {...extracted.toJson(), 'minerFee': '01'},
      {
        ...extracted.toJson(),
        'parentIds': [List.filled(64, '0').join()],
      },
      zeroOutput,
    ];

    for (final response in cases) {
      expect(
        () => ScV2TransactionSemantics.fromJson(response),
        throwsFormatException,
      );
    }
  });
}
