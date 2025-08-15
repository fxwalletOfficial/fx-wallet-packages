import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/types/types.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/timestamp.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/crypto/proof.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/version/types.pb.dart';

void main() {
  group('Tendermint Types Coverage Tests', () {
    group('PartSetHeader Class Missing Methods Coverage', () {
      test('should cover PartSetHeader fromBuffer and fromJson methods', () {
        final original = PartSetHeader()
          ..total = 10
          ..hash = Uint8List.fromList([1, 2, 3, 4, 5]);

        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = PartSetHeader.fromBuffer(buffer);

        expect(fromBuffer.total, equals(10));
        expect(fromBuffer.hash, equals(Uint8List.fromList([1, 2, 3, 4, 5])));

        // Test fromJson
        final json = original.writeToJson();
        final fromJson = PartSetHeader.fromJson(json);

        expect(fromJson.total, equals(10));
        expect(fromJson.hash, equals(Uint8List.fromList([1, 2, 3, 4, 5])));
      });

      test('should cover PartSetHeader clone and copyWith methods', () {
        final original = PartSetHeader()
          ..total = 20
          ..hash = Uint8List.fromList([10, 20, 30]);

        // Test clone
        final cloned = original.clone();
        expect(cloned.total, equals(20));
        expect(cloned.hash, equals(Uint8List.fromList([10, 20, 30])));

        // Test copyWith
        final modified = original.copyWith((header) {
          header.total = 30;
          header.hash = Uint8List.fromList([40, 50, 60]);
        });

        expect(modified.total, equals(30));
        expect(modified.hash, equals(Uint8List.fromList([40, 50, 60])));
      });

      test('should cover PartSetHeader static methods', () {
        // Test createEmptyInstance
        final empty = PartSetHeader.create().createEmptyInstance();
        expect(empty, isA<PartSetHeader>());

        // Test createRepeated
        final list = PartSetHeader.createRepeated();
        expect(list, isA<List<PartSetHeader>>());
        expect(list.isEmpty, isTrue);

        // Test getDefault
        final defaultInstance = PartSetHeader.getDefault();
        expect(defaultInstance, isA<PartSetHeader>());
        expect(defaultInstance.total, equals(0));
        expect(defaultInstance.hash, isEmpty);
      });

      test('should cover PartSetHeader has and clear methods', () {
        final header = PartSetHeader()
          ..total = 100
          ..hash = Uint8List.fromList([100, 200]);

        // Test has methods
        expect(header.hasTotal(), isTrue);
        expect(header.hasHash(), isTrue);

        // Test clear methods
        header.clearTotal();
        expect(header.hasTotal(), isFalse);
        expect(header.total, equals(0));

        header.clearHash();
        expect(header.hasHash(), isFalse);
        expect(header.hash, isEmpty);
      });

      test('should cover PartSetHeader getter methods', () {
        final header = PartSetHeader();

        // Test default getter values
        expect(header.total, equals(0));
        expect(header.hash, isA<List<int>>());
        expect(header.hash, isEmpty);
      });
    });

    group('Part Class Complete Coverage', () {
      test('should cover Part constructor and all methods', () {
        final proof = Proof()
          ..index = Int64(5)
          ..total = Int64(10);

        final part = Part()
          ..index = 1
          ..bytes = Uint8List.fromList([1, 2, 3, 4])
          ..proof = proof;

        // Test getters
        expect(part.index, equals(1));
        expect(part.bytes, equals(Uint8List.fromList([1, 2, 3, 4])));
        expect(part.proof.index, equals(Int64(5)));

        // Test has methods
        expect(part.hasIndex(), isTrue);
        expect(part.hasBytes(), isTrue);
        expect(part.hasProof(), isTrue);
      });

      test('should cover Part serialization methods', () {
        final original = Part()
          ..index = 42
          ..bytes = Uint8List.fromList([100, 101, 102]);

        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = Part.fromBuffer(buffer);

        expect(fromBuffer.index, equals(42));
        expect(fromBuffer.bytes, equals(Uint8List.fromList([100, 101, 102])));

        // Test fromJson
        final json = original.writeToJson();
        final fromJson = Part.fromJson(json);

        expect(fromJson.index, equals(42));
        expect(fromJson.bytes, equals(Uint8List.fromList([100, 101, 102])));
      });

      test('should cover Part clone and copyWith methods', () {
        final original = Part()
          ..index = 999
          ..bytes = Uint8List.fromList([255, 254, 253]);

        // Test clone
        final cloned = original.clone();
        expect(cloned.index, equals(999));
        expect(cloned.bytes, equals(Uint8List.fromList([255, 254, 253])));

        // Test copyWith
        final modified = original.copyWith((part) {
          part.index = 888;
          part.bytes = Uint8List.fromList([1, 2, 3]);
        });

        expect(modified.index, equals(888));
        expect(modified.bytes, equals(Uint8List.fromList([1, 2, 3])));
      });

      test('should cover Part static methods', () {
        // Test create
        final created = Part.create();
        expect(created, isA<Part>());

        // Test createEmptyInstance
        final empty = created.createEmptyInstance();
        expect(empty, isA<Part>());

        // Test createRepeated
        final list = Part.createRepeated();
        expect(list, isA<List<Part>>());
        expect(list.isEmpty, isTrue);

        // Test getDefault
        final defaultInstance = Part.getDefault();
        expect(defaultInstance, isA<Part>());
      });

      test('should cover Part clear methods', () {
        final part = Part()
          ..index = 123
          ..bytes = Uint8List.fromList([1, 2, 3])
          ..proof = Proof();

        // Test clear methods
        part.clearIndex();
        expect(part.hasIndex(), isFalse);
        expect(part.index, equals(0));

        part.clearBytes();
        expect(part.hasBytes(), isFalse);
        expect(part.bytes, isEmpty);

        part.clearProof();
        expect(part.hasProof(), isFalse);
      });

      test('should cover Part ensure methods', () {
        final part = Part();

        // Test ensureProof
        final ensuredProof = part.ensureProof();
        expect(ensuredProof, isA<Proof>());
        expect(part.hasProof(), isTrue);
      });
    });

    group('Header Class Missing Methods Coverage', () {
      test('should cover Header has methods for hash fields', () {
        final timestamp = Timestamp()
          ..seconds = Int64(1672531200)
          ..nanos = 123456789;

        final blockId = BlockID()
          ..hash = Uint8List.fromList([1, 2, 3])
          ..partSetHeader = (PartSetHeader()..total = 1);

        final header = Header()
          ..version = (Consensus()
            ..block = Int64(11)
            ..app = Int64(1))
          ..chainId = 'test-chain'
          ..height = Int64(100)
          ..time = timestamp
          ..lastBlockId = blockId
          ..lastCommitHash = Uint8List.fromList([10, 11, 12])
          ..dataHash = Uint8List.fromList([20, 21, 22])
          ..validatorsHash = Uint8List.fromList([30, 31, 32])
          ..nextValidatorsHash = Uint8List.fromList([40, 41, 42])
          ..consensusHash = Uint8List.fromList([50, 51, 52])
          ..appHash = Uint8List.fromList([60, 61, 62])
          ..lastResultsHash = Uint8List.fromList([70, 71, 72])
          ..evidenceHash = Uint8List.fromList([80, 81, 82])
          ..proposerAddress = Uint8List.fromList([90, 91, 92]);

        // Test all has methods
        expect(header.hasVersion(), isTrue);
        expect(header.hasChainId(), isTrue);
        expect(header.hasHeight(), isTrue);
        expect(header.hasTime(), isTrue);
        expect(header.hasLastBlockId(), isTrue);
        expect(header.hasLastCommitHash(), isTrue);
        expect(header.hasDataHash(), isTrue);
        expect(header.hasValidatorsHash(), isTrue);
        expect(header.hasNextValidatorsHash(), isTrue);
        expect(header.hasConsensusHash(), isTrue);
        expect(header.hasAppHash(), isTrue);
        expect(header.hasLastResultsHash(), isTrue);
        expect(header.hasEvidenceHash(), isTrue);
        expect(header.hasProposerAddress(), isTrue);
      });

      test('should cover Header clear methods for hash fields', () {
        final header = Header()
          ..chainId = 'test'
          ..height = Int64(50)
          ..time = Timestamp()
          ..lastBlockId = BlockID()
          ..lastCommitHash = Uint8List.fromList([1])
          ..dataHash = Uint8List.fromList([2])
          ..validatorsHash = Uint8List.fromList([3])
          ..nextValidatorsHash = Uint8List.fromList([4])
          ..consensusHash = Uint8List.fromList([5])
          ..appHash = Uint8List.fromList([6])
          ..lastResultsHash = Uint8List.fromList([7])
          ..evidenceHash = Uint8List.fromList([8])
          ..proposerAddress = Uint8List.fromList([9]);

        // Test all clear methods
        header.clearChainId();
        expect(header.hasChainId(), isFalse);

        header.clearHeight();
        expect(header.hasHeight(), isFalse);

        header.clearTime();
        expect(header.hasTime(), isFalse);

        header.clearLastBlockId();
        expect(header.hasLastBlockId(), isFalse);

        header.clearLastCommitHash();
        expect(header.hasLastCommitHash(), isFalse);

        header.clearDataHash();
        expect(header.hasDataHash(), isFalse);

        header.clearValidatorsHash();
        expect(header.hasValidatorsHash(), isFalse);

        header.clearNextValidatorsHash();
        expect(header.hasNextValidatorsHash(), isFalse);

        header.clearConsensusHash();
        expect(header.hasConsensusHash(), isFalse);

        header.clearAppHash();
        expect(header.hasAppHash(), isFalse);

        header.clearLastResultsHash();
        expect(header.hasLastResultsHash(), isFalse);

        header.clearEvidenceHash();
        expect(header.hasEvidenceHash(), isFalse);

        header.clearProposerAddress();
        expect(header.hasProposerAddress(), isFalse);
      });

      test('should cover Header ensure methods', () {
        final header = Header();

        // Test ensure methods
        final ensuredTime = header.ensureTime();
        expect(ensuredTime, isA<Timestamp>());
        expect(header.hasTime(), isTrue);

        final ensuredLastBlockId = header.ensureLastBlockId();
        expect(ensuredLastBlockId, isA<BlockID>());
        expect(header.hasLastBlockId(), isTrue);

        final ensuredVersion = header.ensureVersion();
        expect(ensuredVersion, isA<Consensus>());
        expect(header.hasVersion(), isTrue);
      });

      test('should cover Header getter methods for hash fields', () {
        final header = Header();

        // Test getter methods that weren't covered
        expect(header.lastCommitHash, isA<List<int>>());
        expect(header.dataHash, isA<List<int>>());
        expect(header.validatorsHash, isA<List<int>>());
        expect(header.nextValidatorsHash, isA<List<int>>());
        expect(header.consensusHash, isA<List<int>>());
        expect(header.appHash, isA<List<int>>());
        expect(header.lastResultsHash, isA<List<int>>());
        expect(header.evidenceHash, isA<List<int>>());
        expect(header.proposerAddress, isA<List<int>>());
        expect(header.lastBlockId, isA<BlockID>());
      });
    });

    group('Commit Class Missing Methods Coverage', () {
      test('should cover Commit serialization methods', () {
        final blockId = BlockID()
          ..hash = Uint8List.fromList([100, 101, 102])
          ..partSetHeader = (PartSetHeader()..total = 5);

        final commitSig = CommitSig()
          ..blockIdFlag = BlockIDFlag.BLOCK_ID_FLAG_COMMIT
          ..validatorAddress = Uint8List.fromList([1, 2, 3])
          ..timestamp = (Timestamp()..seconds = Int64(1672531200))
          ..signature = Uint8List.fromList([10, 11, 12]);

        final original = Commit()
          ..height = Int64(1000)
          ..round = 2
          ..blockId = blockId
          ..signatures.add(commitSig);

        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = Commit.fromBuffer(buffer);

        expect(fromBuffer.height, equals(Int64(1000)));
        expect(fromBuffer.round, equals(2));
        expect(fromBuffer.blockId.hash,
            equals(Uint8List.fromList([100, 101, 102])));
        expect(fromBuffer.signatures.length, equals(1));
        expect(fromBuffer.signatures.first.blockIdFlag,
            equals(BlockIDFlag.BLOCK_ID_FLAG_COMMIT));

        // Test fromJson
        final json = original.writeToJson();
        final fromJson = Commit.fromJson(json);

        expect(fromJson.height, equals(Int64(1000)));
        expect(fromJson.round, equals(2));
        expect(fromJson.signatures.length, equals(1));
      });

      test('should cover Commit clone and copyWith methods', () {
        final original = Commit()
          ..height = Int64(2000)
          ..round = 3;

        // Test clone
        final cloned = original.clone();
        expect(cloned.height, equals(Int64(2000)));
        expect(cloned.round, equals(3));

        // Test copyWith
        final modified = original.copyWith((commit) {
          commit.height = Int64(3000);
          commit.round = 4;
          commit.blockId = BlockID()..hash = Uint8List.fromList([1, 2, 3]);
        });

        expect(modified.height, equals(Int64(3000)));
        expect(modified.round, equals(4));
        expect(modified.hasBlockId(), isTrue);
      });

      test('should cover Commit static methods', () {
        // Test createEmptyInstance
        final empty = Commit.create().createEmptyInstance();
        expect(empty, isA<Commit>());

        // Test createRepeated
        final list = Commit.createRepeated();
        expect(list, isA<List<Commit>>());
        expect(list.isEmpty, isTrue);

        // Test getDefault
        final defaultInstance = Commit.getDefault();
        expect(defaultInstance, isA<Commit>());
      });

      test('should cover Commit has and clear methods', () {
        final commit = Commit()
          ..height = Int64(100)
          ..round = 1
          ..blockId = BlockID();

        // Test has methods
        expect(commit.hasHeight(), isTrue);
        expect(commit.hasRound(), isTrue);
        expect(commit.hasBlockId(), isTrue);

        // Test clear methods
        commit.clearHeight();
        expect(commit.hasHeight(), isFalse);

        commit.clearRound();
        expect(commit.hasRound(), isFalse);

        commit.clearBlockId();
        expect(commit.hasBlockId(), isFalse);
      });

      test('should cover Commit ensure methods', () {
        final commit = Commit();

        // Test ensureBlockId
        final ensuredBlockId = commit.ensureBlockId();
        expect(ensuredBlockId, isA<BlockID>());
        expect(commit.hasBlockId(), isTrue);
      });

      test('should cover Commit getter methods', () {
        final commit = Commit();

        // Test getter methods that might not be covered
        expect(commit.blockId, isA<BlockID>());
        expect(commit.signatures, isA<List<CommitSig>>());
      });
    });

    group('BlockMeta Class Complete Coverage', () {
      test('should cover BlockMeta all methods', () {
        final blockId = BlockID()
          ..hash = Uint8List.fromList([1, 2, 3, 4, 5])
          ..partSetHeader = (PartSetHeader()..total = 10);

        final header = Header()
          ..chainId = 'test-chain'
          ..height = Int64(500);

        final blockMeta = BlockMeta()
          ..blockId = blockId
          ..blockSize = Int64(12345)
          ..header = header
          ..numTxs = Int64(42);

        // Test all getters
        expect(blockMeta.blockId.hash,
            equals(Uint8List.fromList([1, 2, 3, 4, 5])));
        expect(blockMeta.blockSize, equals(Int64(12345)));
        expect(blockMeta.header.chainId, equals('test-chain'));
        expect(blockMeta.numTxs, equals(Int64(42)));

        // Test all has methods
        expect(blockMeta.hasBlockId(), isTrue);
        expect(blockMeta.hasBlockSize(), isTrue);
        expect(blockMeta.hasHeader(), isTrue);
        expect(blockMeta.hasNumTxs(), isTrue);
      });

      test('should cover BlockMeta serialization methods', () {
        final original = BlockMeta()
          ..blockSize = Int64(9999)
          ..numTxs = Int64(100);

        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = BlockMeta.fromBuffer(buffer);

        expect(fromBuffer.blockSize, equals(Int64(9999)));
        expect(fromBuffer.numTxs, equals(Int64(100)));

        // Test fromJson
        final json = original.writeToJson();
        final fromJson = BlockMeta.fromJson(json);

        expect(fromJson.blockSize, equals(Int64(9999)));
        expect(fromJson.numTxs, equals(Int64(100)));
      });

      test('should cover BlockMeta clone and copyWith methods', () {
        final original = BlockMeta()
          ..blockSize = Int64(7777)
          ..numTxs = Int64(88);

        // Test clone
        final cloned = original.clone();
        expect(cloned.blockSize, equals(Int64(7777)));
        expect(cloned.numTxs, equals(Int64(88)));

        // Test copyWith
        final modified = original.copyWith((meta) {
          meta.blockSize = Int64(8888);
          meta.numTxs = Int64(99);
          meta.header = Header()..chainId = 'modified';
        });

        expect(modified.blockSize, equals(Int64(8888)));
        expect(modified.numTxs, equals(Int64(99)));
        expect(modified.header.chainId, equals('modified'));
      });

      test('should cover BlockMeta static methods', () {
        // Test create
        final created = BlockMeta.create();
        expect(created, isA<BlockMeta>());

        // Test createEmptyInstance
        final empty = created.createEmptyInstance();
        expect(empty, isA<BlockMeta>());

        // Test createRepeated
        final list = BlockMeta.createRepeated();
        expect(list, isA<List<BlockMeta>>());
        expect(list.isEmpty, isTrue);

        // Test getDefault
        final defaultInstance = BlockMeta.getDefault();
        expect(defaultInstance, isA<BlockMeta>());
      });

      test('should cover BlockMeta clear and ensure methods', () {
        final blockMeta = BlockMeta()
          ..blockId = BlockID()
          ..blockSize = Int64(1000)
          ..header = Header()
          ..numTxs = Int64(10);

        // Test clear methods
        blockMeta.clearBlockId();
        expect(blockMeta.hasBlockId(), isFalse);

        blockMeta.clearBlockSize();
        expect(blockMeta.hasBlockSize(), isFalse);

        blockMeta.clearHeader();
        expect(blockMeta.hasHeader(), isFalse);

        blockMeta.clearNumTxs();
        expect(blockMeta.hasNumTxs(), isFalse);

        // Test ensure methods
        final ensuredBlockId = blockMeta.ensureBlockId();
        expect(ensuredBlockId, isA<BlockID>());
        expect(blockMeta.hasBlockId(), isTrue);

        final ensuredHeader = blockMeta.ensureHeader();
        expect(ensuredHeader, isA<Header>());
        expect(blockMeta.hasHeader(), isTrue);
      });
    });

    group('TxProof Class Complete Coverage', () {
      test('should cover TxProof all methods', () {
        final proof = Proof()
          ..index = Int64(3)
          ..total = Int64(10)
          ..leafHash = Uint8List.fromList([50, 51, 52])
          ..aunts.add(Uint8List.fromList([60, 61, 62]));

        final txProof = TxProof()
          ..rootHash = Uint8List.fromList([10, 11, 12, 13, 14])
          ..data = Uint8List.fromList([20, 21, 22, 23, 24])
          ..proof = proof;

        // Test all getters
        expect(
            txProof.rootHash, equals(Uint8List.fromList([10, 11, 12, 13, 14])));
        expect(txProof.data, equals(Uint8List.fromList([20, 21, 22, 23, 24])));
        expect(txProof.proof.index, equals(Int64(3)));

        // Test all has methods
        expect(txProof.hasRootHash(), isTrue);
        expect(txProof.hasData(), isTrue);
        expect(txProof.hasProof(), isTrue);
      });

      test('should cover TxProof serialization methods', () {
        final original = TxProof()
          ..rootHash = Uint8List.fromList([100, 101, 102, 103])
          ..data = Uint8List.fromList([200, 201, 202, 203]);

        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = TxProof.fromBuffer(buffer);

        expect(fromBuffer.rootHash,
            equals(Uint8List.fromList([100, 101, 102, 103])));
        expect(
            fromBuffer.data, equals(Uint8List.fromList([200, 201, 202, 203])));

        // Test fromJson
        final json = original.writeToJson();
        final fromJson = TxProof.fromJson(json);

        expect(fromJson.rootHash,
            equals(Uint8List.fromList([100, 101, 102, 103])));
        expect(fromJson.data, equals(Uint8List.fromList([200, 201, 202, 203])));
      });

      test('should cover TxProof clone and copyWith methods', () {
        final original = TxProof()
          ..rootHash = Uint8List.fromList([1, 1, 1])
          ..data = Uint8List.fromList([2, 2, 2]);

        // Test clone
        final cloned = original.clone();
        expect(cloned.rootHash, equals(Uint8List.fromList([1, 1, 1])));
        expect(cloned.data, equals(Uint8List.fromList([2, 2, 2])));

        // Test copyWith
        final modified = original.copyWith((txProof) {
          txProof.rootHash = Uint8List.fromList([3, 3, 3]);
          txProof.data = Uint8List.fromList([4, 4, 4]);
          txProof.proof = Proof()..index = Int64(999);
        });

        expect(modified.rootHash, equals(Uint8List.fromList([3, 3, 3])));
        expect(modified.data, equals(Uint8List.fromList([4, 4, 4])));
        expect(modified.proof.index, equals(Int64(999)));
      });

      test('should cover TxProof static methods', () {
        // Test create
        final created = TxProof.create();
        expect(created, isA<TxProof>());

        // Test createEmptyInstance
        final empty = created.createEmptyInstance();
        expect(empty, isA<TxProof>());

        // Test createRepeated
        final list = TxProof.createRepeated();
        expect(list, isA<List<TxProof>>());
        expect(list.isEmpty, isTrue);

        // Test getDefault
        final defaultInstance = TxProof.getDefault();
        expect(defaultInstance, isA<TxProof>());
      });

      test('should cover TxProof clear and ensure methods', () {
        final txProof = TxProof()
          ..rootHash = Uint8List.fromList([1])
          ..data = Uint8List.fromList([2])
          ..proof = Proof();

        // Test clear methods
        txProof.clearRootHash();
        expect(txProof.hasRootHash(), isFalse);

        txProof.clearData();
        expect(txProof.hasData(), isFalse);

        txProof.clearProof();
        expect(txProof.hasProof(), isFalse);

        // Test ensure methods
        final ensuredProof = txProof.ensureProof();
        expect(ensuredProof, isA<Proof>());
        expect(txProof.hasProof(), isTrue);
      });
    });

    group('Vote Class Missing Methods Coverage', () {
      test('should cover Vote missing methods', () {
        final timestamp = Timestamp()
          ..seconds = Int64(1672531200)
          ..nanos = 500000000;

        final blockId = BlockID()
          ..hash = Uint8List.fromList([1, 2, 3, 4, 5])
          ..partSetHeader = (PartSetHeader()..total = 1);

        final vote = Vote()
          ..type = SignedMsgType.SIGNED_MSG_TYPE_PREVOTE
          ..height = Int64(1000)
          ..round = 5
          ..blockId = blockId
          ..timestamp = timestamp
          ..validatorAddress = Uint8List.fromList([10, 11, 12])
          ..validatorIndex = 42
          ..signature = Uint8List.fromList([20, 21, 22]);

        // Test has methods for fields that might not be covered
        expect(vote.hasType(), isTrue);
        expect(vote.hasHeight(), isTrue);
        expect(vote.hasRound(), isTrue);
        expect(vote.hasBlockId(), isTrue);
        expect(vote.hasTimestamp(), isTrue);
        expect(vote.hasValidatorAddress(), isTrue);
        expect(vote.hasValidatorIndex(), isTrue);
        expect(vote.hasSignature(), isTrue);
      });

      test('should cover Vote clear methods', () {
        final vote = Vote()
          ..type = SignedMsgType.SIGNED_MSG_TYPE_PRECOMMIT
          ..height = Int64(1000)
          ..round = 5
          ..blockId = BlockID()
          ..timestamp = Timestamp()
          ..validatorAddress = Uint8List.fromList([10, 11, 12])
          ..validatorIndex = 42
          ..signature = Uint8List.fromList([20, 21, 22]);

        // Test clear methods
        vote.clearType();
        expect(vote.hasType(), isFalse);

        vote.clearHeight();
        expect(vote.hasHeight(), isFalse);

        vote.clearRound();
        expect(vote.hasRound(), isFalse);

        vote.clearBlockId();
        expect(vote.hasBlockId(), isFalse);

        vote.clearTimestamp();
        expect(vote.hasTimestamp(), isFalse);

        vote.clearValidatorAddress();
        expect(vote.hasValidatorAddress(), isFalse);

        vote.clearValidatorIndex();
        expect(vote.hasValidatorIndex(), isFalse);

        vote.clearSignature();
        expect(vote.hasSignature(), isFalse);
      });

      test('should cover Vote ensure methods', () {
        final vote = Vote();

        // Test ensure methods
        final ensuredBlockId = vote.ensureBlockId();
        expect(ensuredBlockId, isA<BlockID>());
        expect(vote.hasBlockId(), isTrue);

        final ensuredTimestamp = vote.ensureTimestamp();
        expect(ensuredTimestamp, isA<Timestamp>());
        expect(vote.hasTimestamp(), isTrue);
      });

      test('should cover Vote getter methods', () {
        final vote = Vote();

        // Test getter methods that might not be covered
        expect(vote.validatorAddress, isA<List<int>>());
        expect(vote.signature, isA<List<int>>());
      });
    });

    group('Integration and Edge Case Tests', () {
      test('should cover comprehensive integration scenario', () {
        // Create a complex structure with nested relationships
        final partSetHeader = PartSetHeader()
          ..total = 100
          ..hash = Uint8List.fromList([1, 2, 3, 4, 5]);

        final blockId = BlockID()
          ..hash = Uint8List.fromList([10, 11, 12, 13, 14])
          ..partSetHeader = partSetHeader;

        final header = Header()
          ..chainId = 'integration-test-chain'
          ..height = Int64(12345)
          ..time = (Timestamp()..seconds = Int64(1672531200))
          ..lastBlockId = blockId;

        final commitSig = CommitSig()
          ..blockIdFlag = BlockIDFlag.BLOCK_ID_FLAG_COMMIT
          ..validatorAddress = Uint8List.fromList([30, 31, 32])
          ..signature = Uint8List.fromList([40, 41, 42]);

        final commit = Commit()
          ..height = Int64(12345)
          ..round = 1
          ..blockId = blockId
          ..signatures.add(commitSig);

        expect(commit.signatures.first.validatorAddress,
            equals(Uint8List.fromList([30, 31, 32])));

        final blockMeta = BlockMeta()
          ..blockId = blockId
          ..blockSize = Int64(54321)
          ..header = header
          ..numTxs = Int64(10);

        // Test comprehensive serialization
        final buffer = blockMeta.writeToBuffer();
        final deserialized = BlockMeta.fromBuffer(buffer);

        // Verify all nested relationships are maintained
        expect(deserialized.blockId.hash,
            equals(Uint8List.fromList([10, 11, 12, 13, 14])));
        expect(deserialized.blockId.partSetHeader.total, equals(100));
        expect(deserialized.header.chainId, equals('integration-test-chain'));
        expect(deserialized.header.height, equals(Int64(12345)));
        expect(deserialized.blockSize, equals(Int64(54321)));
        expect(deserialized.numTxs, equals(Int64(10)));
      });

      test('should cover edge cases with empty and maximum values', () {
        // Test with empty structures
        final emptyPart = Part();
        expect(emptyPart.index, equals(0));
        expect(emptyPart.bytes, isEmpty);
        expect(emptyPart.hasProof(), isFalse);

        // Test with maximum values
        final maxValueHeader = Header()
          ..height = Int64.MAX_VALUE
          ..proposerAddress = Uint8List(20); // Maximum typical address size

        expect(maxValueHeader.height, equals(Int64.MAX_VALUE));
        expect(maxValueHeader.proposerAddress.length, equals(20));

        // Test serialization of edge cases
        final buffer = maxValueHeader.writeToBuffer();
        final deserialized = Header.fromBuffer(buffer);
        expect(deserialized.height, equals(Int64.MAX_VALUE));
      });

      test('should cover complex copyWith scenarios', () {
        final original = TxProof()
          ..rootHash = Uint8List.fromList([1, 1, 1])
          ..data = Uint8List.fromList([2, 2, 2]);

        // Test complex copyWith that adds new nested objects
        final modified = original.copyWith((txProof) {
          txProof.rootHash = Uint8List.fromList([9, 9, 9]);
          txProof.data = Uint8List.fromList([8, 8, 8]);
          txProof.proof = Proof()
            ..index = Int64(123)
            ..total = Int64(456)
            ..leafHash = Uint8List.fromList([7, 7, 7]);
        });

        expect(modified.rootHash, equals(Uint8List.fromList([9, 9, 9])));
        expect(modified.data, equals(Uint8List.fromList([8, 8, 8])));
        expect(modified.hasProof(), isTrue);
        expect(modified.proof.index, equals(Int64(123)));
        expect(modified.proof.total, equals(Int64(456)));
      });
    });
  });
}
