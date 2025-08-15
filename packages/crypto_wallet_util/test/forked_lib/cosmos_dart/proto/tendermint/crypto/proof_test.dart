import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/crypto/proof.pb.dart';

void main() {
  group('Proof Tests', () {
    test('should create empty Proof', () {
      final proof = Proof();
      
      expect(proof.hasTotal(), false);
      expect(proof.hasIndex(), false);
      expect(proof.hasLeafHash(), false);
      expect(proof.aunts.isEmpty, true);
    });

    test('should create Proof with all fields', () {
      final total = Int64(100);
      final index = Int64(5);
      final leafHash = Uint8List.fromList([1, 2, 3, 4]);
      final aunts = [
        Uint8List.fromList([5, 6, 7, 8]),
        Uint8List.fromList([9, 10, 11, 12])
      ];
      
      final proof = Proof(
        total: total,
        index: index,
        leafHash: leafHash,
        aunts: aunts,
      );
      
      expect(proof.hasTotal(), true);
      expect(proof.hasIndex(), true);
      expect(proof.hasLeafHash(), true);
      expect(proof.total, total);
      expect(proof.index, index);
      expect(proof.leafHash, leafHash);
      expect(proof.aunts.length, 2);
      expect(proof.aunts[0], aunts[0]);
      expect(proof.aunts[1], aunts[1]);
    });

    test('should set and get Proof fields individually', () {
      final proof = Proof();
      
      // Set total
      proof.total = Int64(200);
      expect(proof.hasTotal(), true);
      expect(proof.total, Int64(200));
      
      // Set index
      proof.index = Int64(10);
      expect(proof.hasIndex(), true);
      expect(proof.index, Int64(10));
      
      // Set leafHash
      final leafHash = Uint8List.fromList([100, 101, 102]);
      proof.leafHash = leafHash;
      expect(proof.hasLeafHash(), true);
      expect(proof.leafHash, leafHash);
      
      // Add aunts
      proof.aunts.add(Uint8List.fromList([200, 201]));
      proof.aunts.add(Uint8List.fromList([202, 203]));
      expect(proof.aunts.length, 2);
    });

    test('should clear Proof fields', () {
      final proof = Proof(
        total: Int64(100),
        index: Int64(5),
        leafHash: Uint8List.fromList([1, 2, 3]),
        aunts: [Uint8List.fromList([4, 5, 6])],
      );
      
      // Clear fields
      proof.clearTotal();
      proof.clearIndex();
      proof.clearLeafHash();
      
      expect(proof.hasTotal(), false);
      expect(proof.hasIndex(), false);
      expect(proof.hasLeafHash(), false);
    });

    test('should clone Proof correctly', () {
      final original = Proof(
        total: Int64(50),
        index: Int64(3),
        leafHash: Uint8List.fromList([1, 2, 3, 4]),
        aunts: [Uint8List.fromList([5, 6])],
      );
      
      final cloned = original.clone();
      
      expect(cloned.total, original.total);
      expect(cloned.index, original.index);
      expect(cloned.leafHash, original.leafHash);
      expect(cloned.aunts.length, original.aunts.length);
      expect(cloned.aunts[0], original.aunts[0]);
    });

    test('should serialize to and from buffer', () {
      final original = Proof(
        total: Int64(1000),
        index: Int64(25),
        leafHash: Uint8List.fromList([10, 20, 30]),
        aunts: [Uint8List.fromList([40, 50])],
      );
      
      final buffer = original.writeToBuffer();
      final deserialized = Proof.fromBuffer(buffer);
      
      expect(deserialized.total, original.total);
      expect(deserialized.index, original.index);
      expect(deserialized.leafHash, original.leafHash);
      expect(deserialized.aunts.length, original.aunts.length);
      expect(deserialized.aunts[0], original.aunts[0]);
    });
  });

  group('ValueOp Tests', () {
    test('should create empty ValueOp', () {
      final valueOp = ValueOp();
      
      expect(valueOp.hasKey(), false);
      expect(valueOp.hasProof(), false);
    });

    test('should create ValueOp with key and proof', () {
      final key = Uint8List.fromList([1, 2, 3, 4, 5]);
      final proof = Proof(total: Int64(100), index: Int64(1));
      
      final valueOp = ValueOp(key: key, proof: proof);
      
      expect(valueOp.hasKey(), true);
      expect(valueOp.hasProof(), true);
      expect(valueOp.key, key);
      expect(valueOp.proof.total, Int64(100));
      expect(valueOp.proof.index, Int64(1));
    });

    test('should set and get ValueOp fields', () {
      final valueOp = ValueOp();
      final key = Uint8List.fromList([10, 20, 30]);
      
      // Set key
      valueOp.key = key;
      expect(valueOp.hasKey(), true);
      expect(valueOp.key, key);
      
      // Set proof
      valueOp.proof = Proof(total: Int64(200));
      expect(valueOp.hasProof(), true);
      expect(valueOp.proof.total, Int64(200));
    });

    test('should clear ValueOp fields', () {
      final valueOp = ValueOp(
        key: Uint8List.fromList([1, 2, 3]),
        proof: Proof(total: Int64(100)),
      );
      
      valueOp.clearKey();
      valueOp.clearProof();
      
      expect(valueOp.hasKey(), false);
      expect(valueOp.hasProof(), false);
    });

    test('should ensure proof field', () {
      final valueOp = ValueOp();
      
      expect(valueOp.hasProof(), false);
      
      final ensuredProof = valueOp.ensureProof();
      
      expect(valueOp.hasProof(), true);
      expect(ensuredProof, isA<Proof>());
    });

    test('should serialize ValueOp to and from buffer', () {
      final original = ValueOp(
        key: Uint8List.fromList([100, 101, 102]),
        proof: Proof(
          total: Int64(500),
          leafHash: Uint8List.fromList([200, 201]),
        ),
      );
      
      final buffer = original.writeToBuffer();
      final deserialized = ValueOp.fromBuffer(buffer);
      
      expect(deserialized.key, original.key);
      expect(deserialized.proof.total, original.proof.total);
      expect(deserialized.proof.leafHash, original.proof.leafHash);
    });
  });

  group('DominoOp Tests', () {
    test('should create empty DominoOp', () {
      final dominoOp = DominoOp();
      
      expect(dominoOp.hasKey(), false);
      expect(dominoOp.hasInput(), false);
      expect(dominoOp.hasOutput(), false);
    });

    test('should create DominoOp with all fields', () {
      final dominoOp = DominoOp(
        key: 'test-key',
        input: 'test-input',
        output: 'test-output',
      );
      
      expect(dominoOp.hasKey(), true);
      expect(dominoOp.hasInput(), true);
      expect(dominoOp.hasOutput(), true);
      expect(dominoOp.key, 'test-key');
      expect(dominoOp.input, 'test-input');
      expect(dominoOp.output, 'test-output');
    });

    test('should set and get DominoOp fields', () {
      final dominoOp = DominoOp();
      
      dominoOp.key = 'new-key';
      dominoOp.input = 'new-input';
      dominoOp.output = 'new-output';
      
      expect(dominoOp.key, 'new-key');
      expect(dominoOp.input, 'new-input');
      expect(dominoOp.output, 'new-output');
    });

    test('should clear DominoOp fields', () {
      final dominoOp = DominoOp(
        key: 'key',
        input: 'input',
        output: 'output',
      );
      
      dominoOp.clearKey();
      dominoOp.clearInput();
      dominoOp.clearOutput();
      
      expect(dominoOp.hasKey(), false);
      expect(dominoOp.hasInput(), false);
      expect(dominoOp.hasOutput(), false);
    });

    test('should handle empty string fields', () {
      final dominoOp = DominoOp(
        key: '',
        input: '',
        output: '',
      );
      
      expect(dominoOp.key, '');
      expect(dominoOp.input, '');
      expect(dominoOp.output, '');
    });

    test('should serialize DominoOp to and from buffer', () {
      final original = DominoOp(
        key: 'serialization-key',
        input: 'serialization-input',
        output: 'serialization-output',
      );
      
      final buffer = original.writeToBuffer();
      final deserialized = DominoOp.fromBuffer(buffer);
      
      expect(deserialized.key, original.key);
      expect(deserialized.input, original.input);
      expect(deserialized.output, original.output);
    });

    test('should serialize DominoOp to and from JSON', () {
      final original = DominoOp(
        key: 'json-key',
        input: 'json-input',
        output: 'json-output',
      );
      
      final json = original.writeToJson();
      final deserialized = DominoOp.fromJson(json);
      
      expect(deserialized.key, original.key);
      expect(deserialized.input, original.input);
      expect(deserialized.output, original.output);
    });
  });

  group('ProofOp Tests', () {
    test('should create empty ProofOp', () {
      final proofOp = ProofOp();
      
      expect(proofOp.hasType(), false);
      expect(proofOp.hasKey(), false);
      expect(proofOp.hasData(), false);
    });

    test('should create ProofOp with all fields', () {
      final type = 'iavl:v';
      final key = Uint8List.fromList([1, 2, 3]);
      final data = Uint8List.fromList([4, 5, 6, 7]);
      
      final proofOp = ProofOp(
        type: type,
        key: key,
        data: data,
      );
      
      expect(proofOp.hasType(), true);
      expect(proofOp.hasKey(), true);
      expect(proofOp.hasData(), true);
      expect(proofOp.type, type);
      expect(proofOp.key, key);
      expect(proofOp.data, data);
    });

    test('should set and get ProofOp fields', () {
      final proofOp = ProofOp();
      
      proofOp.type = 'simple:v';
      proofOp.key = Uint8List.fromList([10, 20]);
      proofOp.data = Uint8List.fromList([30, 40, 50]);
      
      expect(proofOp.type, 'simple:v');
      expect(proofOp.key, [10, 20]);
      expect(proofOp.data, [30, 40, 50]);
    });

    test('should clear ProofOp fields', () {
      final proofOp = ProofOp(
        type: 'type',
        key: Uint8List.fromList([1, 2]),
        data: Uint8List.fromList([3, 4]),
      );
      
      proofOp.clearType();
      proofOp.clearKey();
      proofOp.clearData();
      
      expect(proofOp.hasType(), false);
      expect(proofOp.hasKey(), false);
      expect(proofOp.hasData(), false);
    });

    test('should handle different proof op types', () {
      final types = ['iavl:v', 'iavl:a', 'simple:v', 'simple:a'];
      
      for (final type in types) {
        final proofOp = ProofOp(type: type);
        expect(proofOp.type, type);
      }
    });

    test('should serialize ProofOp to and from buffer', () {
      final original = ProofOp(
        type: 'test:v',
        key: Uint8List.fromList([100, 200]),
        data: Uint8List.fromList([150, 250, 50]),
      );
      
      final buffer = original.writeToBuffer();
      final deserialized = ProofOp.fromBuffer(buffer);
      
      expect(deserialized.type, original.type);
      expect(deserialized.key, original.key);
      expect(deserialized.data, original.data);
    });
  });

  group('ProofOps Tests', () {
    test('should create empty ProofOps', () {
      final proofOps = ProofOps();
      
      expect(proofOps.ops.isEmpty, true);
    });

    test('should create ProofOps with operations', () {
      final ops = [
        ProofOp(type: 'op1', key: Uint8List.fromList([1, 2])),
        ProofOp(type: 'op2', key: Uint8List.fromList([3, 4])),
      ];
      
      final proofOps = ProofOps(ops: ops);
      
      expect(proofOps.ops.length, 2);
      expect(proofOps.ops[0].type, 'op1');
      expect(proofOps.ops[1].type, 'op2');
    });

    test('should add operations to ProofOps', () {
      final proofOps = ProofOps();
      
      proofOps.ops.add(ProofOp(type: 'added-op1'));
      proofOps.ops.add(ProofOp(type: 'added-op2'));
      
      expect(proofOps.ops.length, 2);
      expect(proofOps.ops[0].type, 'added-op1');
      expect(proofOps.ops[1].type, 'added-op2');
    });

    test('should clear all operations', () {
      final proofOps = ProofOps(ops: [
        ProofOp(type: 'op1'),
        ProofOp(type: 'op2'),
      ]);
      
      expect(proofOps.ops.length, 2);
      
      proofOps.ops.clear();
      
      expect(proofOps.ops.isEmpty, true);
    });

    test('should serialize ProofOps to and from buffer', () {
      final original = ProofOps(ops: [
        ProofOp(
          type: 'iavl:v',
          key: Uint8List.fromList([1, 2, 3]),
          data: Uint8List.fromList([10, 20]),
        ),
        ProofOp(
          type: 'simple:a',
          key: Uint8List.fromList([4, 5, 6]),
          data: Uint8List.fromList([30, 40]),
        ),
      ]);
      
      final buffer = original.writeToBuffer();
      final deserialized = ProofOps.fromBuffer(buffer);
      
      expect(deserialized.ops.length, original.ops.length);
      expect(deserialized.ops[0].type, original.ops[0].type);
      expect(deserialized.ops[0].key, original.ops[0].key);
      expect(deserialized.ops[0].data, original.ops[0].data);
      expect(deserialized.ops[1].type, original.ops[1].type);
      expect(deserialized.ops[1].key, original.ops[1].key);
      expect(deserialized.ops[1].data, original.ops[1].data);
    });

    test('should handle complex proof chains', () {
      final proofOps = ProofOps();
      
      // Add IAVL operations
      proofOps.ops.add(ProofOp(
        type: 'iavl:v',
        key: Uint8List.fromList([1, 2, 3, 4]),
        data: Uint8List.fromList([100, 101, 102]),
      ));
      
      // Add simple operations  
      proofOps.ops.add(ProofOp(
        type: 'simple:v',
        key: Uint8List.fromList([5, 6, 7, 8]),
        data: Uint8List.fromList([200, 201, 202]),
      ));
      
      expect(proofOps.ops.length, 2);
      
      // Verify each operation
      final iavlOp = proofOps.ops[0];
      expect(iavlOp.type, 'iavl:v');
      expect(iavlOp.key, [1, 2, 3, 4]);
      expect(iavlOp.data, [100, 101, 102]);
      
      final simpleOp = proofOps.ops[1];
      expect(simpleOp.type, 'simple:v');
      expect(simpleOp.key, [5, 6, 7, 8]);
      expect(simpleOp.data, [200, 201, 202]);
    });
  });

  group('Integration Tests', () {
    test('should handle complex proof structures', () {
      // Create a ValueOp with a complete Proof
      final proof = Proof(
        total: Int64(1024),
        index: Int64(256),
        leafHash: Uint8List.fromList([1, 2, 3, 4, 5]),
        aunts: [
          Uint8List.fromList([10, 11, 12]),
          Uint8List.fromList([20, 21, 22]),
          Uint8List.fromList([30, 31, 32]),
        ],
      );
      
      final valueOp = ValueOp(
        key: Uint8List.fromList([100, 101, 102, 103]),
        proof: proof,
      );
      
      // Create ProofOps with multiple operations
      final proofOps = ProofOps(ops: [
        ProofOp(
          type: 'iavl:v',
          key: valueOp.key,
          data: valueOp.proof.leafHash,
        ),
        ProofOp(
          type: 'simple:v',
          key: Uint8List.fromList([200, 201]),
          data: Uint8List.fromList([300, 301, 302]),
        ),
      ]);
      
      // Verify the structure
      expect(valueOp.proof.total, Int64(1024));
      expect(valueOp.proof.aunts.length, 3);
      expect(proofOps.ops.length, 2);
      expect(proofOps.ops[0].key, valueOp.key);
    });

    test('should serialize complex structures correctly', () {
      final originalProofOps = ProofOps(ops: [
        ProofOp(
          type: 'complex:v',
          key: Uint8List.fromList([1, 2, 3]),
          data: Uint8List.fromList([10, 20, 30]),
        ),
      ]);
      
      final originalValueOp = ValueOp(
        key: Uint8List.fromList([100, 200]),
        proof: Proof(
          total: Int64(500),
          index: Int64(50),
          leafHash: Uint8List.fromList([150, 250]),
          aunts: [Uint8List.fromList([75, 125])],
        ),
      );
      
      // Serialize and deserialize
      final proofOpsBuffer = originalProofOps.writeToBuffer();
      final valueOpBuffer = originalValueOp.writeToBuffer();
      
      final deserializedProofOps = ProofOps.fromBuffer(proofOpsBuffer);
      final deserializedValueOp = ValueOp.fromBuffer(valueOpBuffer);
      
      // Verify deserialization
      expect(deserializedProofOps.ops.length, 1);
      expect(deserializedProofOps.ops[0].type, 'complex:v');
      expect(deserializedValueOp.proof.total, Int64(500));
      expect(deserializedValueOp.proof.aunts.length, 1);
    });
  });
} 