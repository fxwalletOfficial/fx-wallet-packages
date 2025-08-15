import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/types/block.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/types/types.pb.dart' as types;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/types/evidence.pb.dart' as evidence;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/version/types.pb.dart' as version;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/timestamp.pb.dart' as timestamp;

void main() {
  group('Block Tests', () {
    test('should create empty Block', () {
      final block = Block();
      
      expect(block.hasHeader(), false);
      expect(block.hasData(), false);
      expect(block.hasEvidence(), false);
      expect(block.hasLastCommit(), false);
    });

    test('should create Block with all fields', () {
      final header = types.Header(
        chainId: 'test-chain',
        height: Int64(100),
        time: timestamp.Timestamp(seconds: Int64.ONE, nanos: 0),
      );
      
      final data = types.Data(
        txs: [Uint8List.fromList([1, 2, 3, 4])],
      );
      
      final evidenceList = evidence.EvidenceList(
        evidence: [],
      );
      
      final lastCommit = types.Commit(
        height: Int64(99),
        round: 0,
        blockId: types.BlockID(),
        signatures: [],
      );
      
      final block = Block(
        header: header,
        data: data,
        evidence: evidenceList,
        lastCommit: lastCommit,
      );
      
      expect(block.hasHeader(), true);
      expect(block.hasData(), true);
      expect(block.hasEvidence(), true);
      expect(block.hasLastCommit(), true);
      expect(block.header.chainId, 'test-chain');
      expect(block.header.height, Int64(100));
      expect(block.data.txs.length, 1);
      expect(block.lastCommit.height, Int64(99));
    });

    test('should set and get Block fields individually', () {
      final block = Block();
      
      // Set header
      final header = types.Header(chainId: 'new-chain', height: Int64(200));
      block.header = header;
      expect(block.hasHeader(), true);
      expect(block.header.chainId, 'new-chain');
      expect(block.header.height, Int64(200));
      
      // Set data
      final data = types.Data(txs: [
        Uint8List.fromList([10, 20, 30]),
        Uint8List.fromList([40, 50, 60])
      ]);
      block.data = data;
      expect(block.hasData(), true);
      expect(block.data.txs.length, 2);
      
      // Set evidence
      final evidenceList = evidence.EvidenceList();
      block.evidence = evidenceList;
      expect(block.hasEvidence(), true);
      
      // Set last commit
      final lastCommit = types.Commit(height: Int64(199), round: 1);
      block.lastCommit = lastCommit;
      expect(block.hasLastCommit(), true);
      expect(block.lastCommit.height, Int64(199));
      expect(block.lastCommit.round, 1);
    });

    test('should clear Block fields', () {
      final block = Block(
        header: types.Header(chainId: 'test'),
        data: types.Data(),
        evidence: evidence.EvidenceList(),
        lastCommit: types.Commit(),
      );
      
      // Clear fields
      block.clearHeader();
      block.clearData();
      block.clearEvidence();
      block.clearLastCommit();
      
      expect(block.hasHeader(), false);
      expect(block.hasData(), false);
      expect(block.hasEvidence(), false);
      expect(block.hasLastCommit(), false);
    });

    test('should ensure Block fields', () {
      final block = Block();
      
      // Ensure header
      final ensuredHeader = block.ensureHeader();
      expect(block.hasHeader(), true);
      expect(ensuredHeader, isA<types.Header>());
      
      // Ensure data
      final ensuredData = block.ensureData();
      expect(block.hasData(), true);
      expect(ensuredData, isA<types.Data>());
      
      // Ensure evidence
      final ensuredEvidence = block.ensureEvidence();
      expect(block.hasEvidence(), true);
      expect(ensuredEvidence, isA<evidence.EvidenceList>());
      
      // Ensure lastCommit
      final ensuredLastCommit = block.ensureLastCommit();
      expect(block.hasLastCommit(), true);
      expect(ensuredLastCommit, isA<types.Commit>());
    });

    test('should clone Block correctly', () {
      final original = Block(
        header: types.Header(
          chainId: 'original-chain',
          height: Int64(500),
        ),
        data: types.Data(
          txs: [Uint8List.fromList([100, 101, 102])],
        ),
      );
      
      final cloned = original.clone();
      
      expect(cloned.hasHeader(), true);
      expect(cloned.hasData(), true);
      expect(cloned.header.chainId, 'original-chain');
      expect(cloned.header.height, Int64(500));
      expect(cloned.data.txs.length, 1);
      expect(cloned.data.txs[0], [100, 101, 102]);
    });

    test('should serialize Block to and from buffer', () {
      final original = Block(
        header: types.Header(
          chainId: 'serialization-test',
          height: Int64(1000),
          time: timestamp.Timestamp(seconds: Int64(1234567890)),
        ),
        data: types.Data(
          txs: [
            Uint8List.fromList([1, 2, 3]),
            Uint8List.fromList([4, 5, 6]),
          ],
        ),
        evidence: evidence.EvidenceList(),
        lastCommit: types.Commit(
          height: Int64(999),
          round: 0,
        ),
      );
      
      final buffer = original.writeToBuffer();
      final deserialized = Block.fromBuffer(buffer);
      
      expect(deserialized.hasHeader(), true);
      expect(deserialized.hasData(), true);
      expect(deserialized.hasEvidence(), true);
      expect(deserialized.hasLastCommit(), true);
      
      expect(deserialized.header.chainId, 'serialization-test');
      expect(deserialized.header.height, Int64(1000));
      expect(deserialized.header.time.seconds, Int64(1234567890));
      expect(deserialized.data.txs.length, 2);
      expect(deserialized.data.txs[0], [1, 2, 3]);
      expect(deserialized.data.txs[1], [4, 5, 6]);
      expect(deserialized.lastCommit.height, Int64(999));
    });

    test('should serialize Block to and from JSON', () {
      final original = Block(
        header: types.Header(
          chainId: 'json-test-chain',
          height: Int64(2000),
        ),
        data: types.Data(
          txs: [Uint8List.fromList([10, 20, 30])],
        ),
      );
      
      final json = original.writeToJson();
      final deserialized = Block.fromJson(json);
      
      expect(deserialized.header.chainId, 'json-test-chain');
      expect(deserialized.header.height, Int64(2000));
      expect(deserialized.data.txs.length, 1);
      expect(deserialized.data.txs[0], [10, 20, 30]);
    });

    test('should handle copyWith correctly', () {
      final original = Block(
        header: types.Header(chainId: 'original', height: Int64(100)),
        data: types.Data(),
      );
      
      final modified = original.copyWith((block) {
        block.header.chainId = 'modified';
        block.header.height = Int64(200);
        block.lastCommit = types.Commit(height: Int64(199));
      });
      
      expect(modified.header.chainId, 'modified');
      expect(modified.header.height, Int64(200));
      expect(modified.hasLastCommit(), true);
      expect(modified.lastCommit.height, Int64(199));
    });

    test('should return correct default instance', () {
      final defaultInstance = Block.getDefault();
      
      expect(defaultInstance, isNotNull);
      expect(defaultInstance.hasHeader(), false);
      expect(defaultInstance.hasData(), false);
      expect(defaultInstance.hasEvidence(), false);
      expect(defaultInstance.hasLastCommit(), false);
    });

    test('should create repeated list', () {
      final list = Block.createRepeated();
      
      expect(list, isNotNull);
      expect(list.isEmpty, true);
      
      list.add(Block(header: types.Header(chainId: 'test')));
      expect(list.length, 1);
      expect(list[0].header.chainId, 'test');
    });

    test('should handle complex block structures', () {
      // Create a complete block with all components
      final header = types.Header(
                 version: version.Consensus(block: Int64(11), app: Int64(1)),
        chainId: 'cosmos-hub-4',
        height: Int64(10000000),
        time: timestamp.Timestamp(seconds: Int64(1640995200), nanos: 500000000),
        lastBlockId: types.BlockID(
          hash: Uint8List.fromList(List.filled(32, 1)),
          partSetHeader: types.PartSetHeader(
            total: 1,
            hash: Uint8List.fromList(List.filled(32, 2)),
          ),
        ),
        lastCommitHash: Uint8List.fromList(List.filled(32, 3)),
        dataHash: Uint8List.fromList(List.filled(32, 4)),
        validatorsHash: Uint8List.fromList(List.filled(32, 5)),
        nextValidatorsHash: Uint8List.fromList(List.filled(32, 6)),
        consensusHash: Uint8List.fromList(List.filled(32, 7)),
        appHash: Uint8List.fromList(List.filled(32, 8)),
        lastResultsHash: Uint8List.fromList(List.filled(32, 9)),
        evidenceHash: Uint8List.fromList(List.filled(32, 10)),
        proposerAddress: Uint8List.fromList(List.filled(20, 11)),
      );
      
      final data = types.Data(
        txs: [
          Uint8List.fromList([1, 2, 3, 4, 5]),
          Uint8List.fromList([6, 7, 8, 9, 10]),
        ],
      );
      
      final evidenceList = evidence.EvidenceList(
        evidence: [], // Empty for this test
      );
      
      final lastCommit = types.Commit(
        height: Int64(9999999),
        round: 0,
        blockId: types.BlockID(
          hash: Uint8List.fromList(List.filled(32, 20)),
        ),
        signatures: [
          types.CommitSig(
            blockIdFlag: types.BlockIDFlag.BLOCK_ID_FLAG_COMMIT,
            validatorAddress: Uint8List.fromList(List.filled(20, 30)),
            timestamp: timestamp.Timestamp(seconds: Int64(1640995100)),
            signature: Uint8List.fromList(List.filled(64, 40)),
          ),
        ],
      );
      
      final block = Block(
        header: header,
        data: data,
        evidence: evidenceList,
        lastCommit: lastCommit,
      );
      
      // Verify all components
      expect(block.header.chainId, 'cosmos-hub-4');
      expect(block.header.height, Int64(10000000));
      expect(block.header.version.block, Int64(11));
      expect(block.header.time.seconds, Int64(1640995200));
      expect(block.header.time.nanos, 500000000);
      expect(block.header.proposerAddress.length, 20);
      
      expect(block.data.txs.length, 2);
      expect(block.data.txs[0], [1, 2, 3, 4, 5]);
      
      expect(block.lastCommit.height, Int64(9999999));
      expect(block.lastCommit.signatures.length, 1);
      expect(block.lastCommit.signatures[0].blockIdFlag, types.BlockIDFlag.BLOCK_ID_FLAG_COMMIT);
      
      // Test serialization of complex structure
      final buffer = block.writeToBuffer();
      final deserialized = Block.fromBuffer(buffer);
      
      expect(deserialized.header.chainId, block.header.chainId);
      expect(deserialized.header.height, block.header.height);
      expect(deserialized.data.txs.length, block.data.txs.length);
      expect(deserialized.lastCommit.signatures.length, block.lastCommit.signatures.length);
    });
  });
} 