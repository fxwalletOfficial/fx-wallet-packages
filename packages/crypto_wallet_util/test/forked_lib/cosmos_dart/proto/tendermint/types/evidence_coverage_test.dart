import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/types/evidence.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/types/types.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/types/validator.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/timestamp.pb.dart';

void main() {
  group('Tendermint Evidence Coverage Tests', () {
    group('Evidence Class Coverage', () {
      test('should cover Evidence oneof field operations and whichSum', () {
        final evidence = Evidence();
        
        // Test initially not set
        expect(evidence.whichSum(), equals(Evidence_Sum.notSet));
        expect(evidence.hasDuplicateVoteEvidence(), isFalse);
        expect(evidence.hasLightClientAttackEvidence(), isFalse);
        
        // Test setting duplicateVoteEvidence
        final duplicateEvidence = DuplicateVoteEvidence()
          ..totalVotingPower = Int64(1000)
          ..validatorPower = Int64(100);
        evidence.duplicateVoteEvidence = duplicateEvidence;
        
        expect(evidence.whichSum(), equals(Evidence_Sum.duplicateVoteEvidence));
        expect(evidence.hasDuplicateVoteEvidence(), isTrue);
        expect(evidence.hasLightClientAttackEvidence(), isFalse);
        expect(evidence.duplicateVoteEvidence.totalVotingPower, equals(Int64(1000)));
        
        // Test switching to lightClientAttackEvidence
        final lightClientEvidence = LightClientAttackEvidence()
          ..commonHeight = Int64(12345)
          ..totalVotingPower = Int64(5000);
        evidence.lightClientAttackEvidence = lightClientEvidence;
        
        expect(evidence.whichSum(), equals(Evidence_Sum.lightClientAttackEvidence));
        expect(evidence.hasDuplicateVoteEvidence(), isFalse);
        expect(evidence.hasLightClientAttackEvidence(), isTrue);
        expect(evidence.lightClientAttackEvidence.commonHeight, equals(Int64(12345)));
        
        // Test clearing
        evidence.clearSum();
        expect(evidence.whichSum(), equals(Evidence_Sum.notSet));
        expect(evidence.hasDuplicateVoteEvidence(), isFalse);
        expect(evidence.hasLightClientAttackEvidence(), isFalse);
      });

      test('should cover Evidence ensure methods', () {
        final evidence = Evidence();
        
        // Test ensureDuplicateVoteEvidence
        final ensuredDuplicate = evidence.ensureDuplicateVoteEvidence();
        expect(ensuredDuplicate, isA<DuplicateVoteEvidence>());
        expect(evidence.hasDuplicateVoteEvidence(), isTrue);
        expect(evidence.whichSum(), equals(Evidence_Sum.duplicateVoteEvidence));
        
        // Test ensureLightClientAttackEvidence (will switch the oneof)
        final ensuredLightClient = evidence.ensureLightClientAttackEvidence();
        expect(ensuredLightClient, isA<LightClientAttackEvidence>());
        expect(evidence.hasLightClientAttackEvidence(), isTrue);
        expect(evidence.whichSum(), equals(Evidence_Sum.lightClientAttackEvidence));
        expect(evidence.hasDuplicateVoteEvidence(), isFalse); // Should be cleared
      });

      test('should cover Evidence clear methods', () {
        final evidence = Evidence()
          ..duplicateVoteEvidence = (DuplicateVoteEvidence()..totalVotingPower = Int64(999));
        
        expect(evidence.hasDuplicateVoteEvidence(), isTrue);
        
        // Test clearDuplicateVoteEvidence
        evidence.clearDuplicateVoteEvidence();
        expect(evidence.hasDuplicateVoteEvidence(), isFalse);
        expect(evidence.whichSum(), equals(Evidence_Sum.notSet));
        
        // Test clearLightClientAttackEvidence  
        evidence.lightClientAttackEvidence = LightClientAttackEvidence()..commonHeight = Int64(888);
        expect(evidence.hasLightClientAttackEvidence(), isTrue);
        
        evidence.clearLightClientAttackEvidence();
        expect(evidence.hasLightClientAttackEvidence(), isFalse);
        expect(evidence.whichSum(), equals(Evidence_Sum.notSet));
      });

      test('should cover Evidence serialization methods', () {
        final duplicateEvidence = DuplicateVoteEvidence()
          ..totalVotingPower = Int64(1500)
          ..validatorPower = Int64(150);
        
        final original = Evidence()
          ..duplicateVoteEvidence = duplicateEvidence;
        
        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = Evidence.fromBuffer(buffer);
        
        expect(fromBuffer.whichSum(), equals(Evidence_Sum.duplicateVoteEvidence));
        expect(fromBuffer.duplicateVoteEvidence.totalVotingPower, equals(Int64(1500)));
        expect(fromBuffer.duplicateVoteEvidence.validatorPower, equals(Int64(150)));
        
        // Test fromJson
        final json = original.writeToJson();
        final fromJson = Evidence.fromJson(json);
        
        expect(fromJson.whichSum(), equals(Evidence_Sum.duplicateVoteEvidence));
        expect(fromJson.duplicateVoteEvidence.totalVotingPower, equals(Int64(1500)));
      });

      test('should cover Evidence clone method', () {
        final original = Evidence()
          ..lightClientAttackEvidence = (LightClientAttackEvidence()
            ..commonHeight = Int64(7777)
            ..totalVotingPower = Int64(8888));
        
        final cloned = original.clone();
        
        expect(cloned.whichSum(), equals(Evidence_Sum.lightClientAttackEvidence));
        expect(cloned.lightClientAttackEvidence.commonHeight, equals(Int64(7777)));
        expect(cloned.lightClientAttackEvidence.totalVotingPower, equals(Int64(8888)));
        
        // Modify original to ensure separation
        original.lightClientAttackEvidence.commonHeight = Int64(9999);
        expect(cloned.lightClientAttackEvidence.commonHeight, equals(Int64(7777)));
      });

      test('should cover Evidence copyWith method', () {
        final original = Evidence()
          ..duplicateVoteEvidence = (DuplicateVoteEvidence()..totalVotingPower = Int64(1000));
        
        final modified = original.copyWith((evidence) {
          evidence.clearSum();
          evidence.lightClientAttackEvidence = LightClientAttackEvidence()
            ..commonHeight = Int64(5555)
            ..totalVotingPower = Int64(6666);
        });
        
        expect(modified.whichSum(), equals(Evidence_Sum.lightClientAttackEvidence));
        expect(modified.lightClientAttackEvidence.commonHeight, equals(Int64(5555)));
        expect(modified.lightClientAttackEvidence.totalVotingPower, equals(Int64(6666)));
      });

      test('should cover Evidence static methods', () {
        // Test create
        final created = Evidence.create();
        expect(created, isA<Evidence>());
        expect(created.whichSum(), equals(Evidence_Sum.notSet));
        
        // Test createEmptyInstance
        final emptyInstance = created.createEmptyInstance();
        expect(emptyInstance, isA<Evidence>());
        
        // Test createRepeated
        final list = Evidence.createRepeated();
        expect(list, isA<List<Evidence>>());
        expect(list.isEmpty, isTrue);
        
        list.add(Evidence()..duplicateVoteEvidence = DuplicateVoteEvidence());
        list.add(Evidence()..lightClientAttackEvidence = LightClientAttackEvidence());
        
        expect(list.length, equals(2));
        expect(list.first.whichSum(), equals(Evidence_Sum.duplicateVoteEvidence));
        expect(list.last.whichSum(), equals(Evidence_Sum.lightClientAttackEvidence));
        
        // Test getDefault
        final defaultInstance = Evidence.getDefault();
        expect(defaultInstance, isA<Evidence>());
        expect(defaultInstance.whichSum(), equals(Evidence_Sum.notSet));
        
        final anotherDefault = Evidence.getDefault();
        expect(identical(defaultInstance, anotherDefault), isTrue);
      });
    });

    group('DuplicateVoteEvidence Class Coverage', () {
      test('should cover DuplicateVoteEvidence constructor and field operations', () {
        final voteA = Vote()
          ..height = Int64(100)
          ..round = 1
          ..type = SignedMsgType.SIGNED_MSG_TYPE_PROPOSAL;
        
        final voteB = Vote()
          ..height = Int64(100)
          ..round = 1
          ..type = SignedMsgType.SIGNED_MSG_TYPE_PREVOTE;
        
        final timestamp = Timestamp()
          ..seconds = Int64(1640995200)
          ..nanos = 123456;
        
        final evidence = DuplicateVoteEvidence()
          ..voteA = voteA
          ..voteB = voteB
          ..totalVotingPower = Int64(10000)
          ..validatorPower = Int64(500)
          ..timestamp = timestamp;
        
        // Test all getters
        expect(evidence.hasVoteA(), isTrue);
        expect(evidence.voteA.height, equals(Int64(100)));
        expect(evidence.voteA.type, equals(SignedMsgType.SIGNED_MSG_TYPE_PROPOSAL));
        
        expect(evidence.hasVoteB(), isTrue);
        expect(evidence.voteB.height, equals(Int64(100)));
        expect(evidence.voteB.type, equals(SignedMsgType.SIGNED_MSG_TYPE_PREVOTE));
        
        expect(evidence.hasTotalVotingPower(), isTrue);
        expect(evidence.totalVotingPower, equals(Int64(10000)));
        
        expect(evidence.hasValidatorPower(), isTrue);
        expect(evidence.validatorPower, equals(Int64(500)));
        
        expect(evidence.hasTimestamp(), isTrue);
        expect(evidence.timestamp.seconds, equals(Int64(1640995200)));
        expect(evidence.timestamp.nanos, equals(123456));
      });

      test('should cover DuplicateVoteEvidence clear methods', () {
        final evidence = DuplicateVoteEvidence()
          ..voteA = Vote()
          ..voteB = Vote()
          ..totalVotingPower = Int64(1000)
          ..validatorPower = Int64(100)
          ..timestamp = Timestamp();
        
        // Test all clear methods
        evidence.clearVoteA();
        expect(evidence.hasVoteA(), isFalse);
        
        evidence.clearVoteB();
        expect(evidence.hasVoteB(), isFalse);
        
        evidence.clearTotalVotingPower();
        expect(evidence.hasTotalVotingPower(), isFalse);
        expect(evidence.totalVotingPower, equals(Int64.ZERO));
        
        evidence.clearValidatorPower();
        expect(evidence.hasValidatorPower(), isFalse);
        expect(evidence.validatorPower, equals(Int64.ZERO));
        
        evidence.clearTimestamp();
        expect(evidence.hasTimestamp(), isFalse);
      });

      test('should cover DuplicateVoteEvidence ensure methods', () {
        final evidence = DuplicateVoteEvidence();
        
        // Test ensure methods
        final ensuredVoteA = evidence.ensureVoteA();
        expect(ensuredVoteA, isA<Vote>());
        expect(evidence.hasVoteA(), isTrue);
        
        final ensuredVoteB = evidence.ensureVoteB();
        expect(ensuredVoteB, isA<Vote>());
        expect(evidence.hasVoteB(), isTrue);
        
        final ensuredTimestamp = evidence.ensureTimestamp();
        expect(ensuredTimestamp, isA<Timestamp>());
        expect(evidence.hasTimestamp(), isTrue);
      });

      test('should cover DuplicateVoteEvidence serialization methods', () {
        final original = DuplicateVoteEvidence()
          ..totalVotingPower = Int64(9999)
          ..validatorPower = Int64(888)
          ..timestamp = (Timestamp()..seconds = Int64(1234567890));
        
        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = DuplicateVoteEvidence.fromBuffer(buffer);
        
        expect(fromBuffer.totalVotingPower, equals(Int64(9999)));
        expect(fromBuffer.validatorPower, equals(Int64(888)));
        expect(fromBuffer.timestamp.seconds, equals(Int64(1234567890)));
        
        // Test fromJson
        final json = original.writeToJson();
        final fromJson = DuplicateVoteEvidence.fromJson(json);
        
        expect(fromJson.totalVotingPower, equals(Int64(9999)));
        expect(fromJson.validatorPower, equals(Int64(888)));
      });

      test('should cover DuplicateVoteEvidence clone and copyWith methods', () {
        final original = DuplicateVoteEvidence()
          ..totalVotingPower = Int64(3333)
          ..validatorPower = Int64(333);
        
        // Test clone
        final cloned = original.clone();
        expect(cloned.totalVotingPower, equals(Int64(3333)));
        expect(cloned.validatorPower, equals(Int64(333)));
        
        // Test copyWith
        final modified = original.copyWith((evidence) {
          evidence.totalVotingPower = Int64(4444);
          evidence.validatorPower = Int64(444);
          evidence.timestamp = Timestamp()..seconds = Int64(999999);
        });
        
        expect(modified.totalVotingPower, equals(Int64(4444)));
        expect(modified.validatorPower, equals(Int64(444)));
        expect(modified.timestamp.seconds, equals(Int64(999999)));
      });

      test('should cover DuplicateVoteEvidence static methods', () {
        // Test create
        final created = DuplicateVoteEvidence.create();
        expect(created, isA<DuplicateVoteEvidence>());
        
        // Test createEmptyInstance
        final emptyInstance = created.createEmptyInstance();
        expect(emptyInstance, isA<DuplicateVoteEvidence>());
        
        // Test createRepeated
        final list = DuplicateVoteEvidence.createRepeated();
        expect(list, isA<List<DuplicateVoteEvidence>>());
        expect(list.isEmpty, isTrue);
        
        // Test getDefault
        final defaultInstance = DuplicateVoteEvidence.getDefault();
        expect(defaultInstance, isA<DuplicateVoteEvidence>());
        
        final anotherDefault = DuplicateVoteEvidence.getDefault();
        expect(identical(defaultInstance, anotherDefault), isTrue);
      });
    });

    group('LightClientAttackEvidence Class Coverage', () {
      test('should cover LightClientAttackEvidence constructor and field operations', () {
        final conflictingBlock = LightBlock()
          ..signedHeader = (SignedHeader()
            ..header = (Header()..height = Int64(1000)))
          ..validatorSet = ValidatorSet();
        
        final validator = Validator()
          ..address = [0x01, 0x02, 0x03]
          ..votingPower = Int64(777);
        
        final timestamp = Timestamp()
          ..seconds = Int64(1609459200)
          ..nanos = 999999;
        
        final evidence = LightClientAttackEvidence()
          ..conflictingBlock = conflictingBlock
          ..commonHeight = Int64(5000)
          ..byzantineValidators.add(validator)
          ..totalVotingPower = Int64(15000)
          ..timestamp = timestamp;
        
        // Test all getters
        expect(evidence.hasConflictingBlock(), isTrue);
        expect(evidence.conflictingBlock.signedHeader.header.height, equals(Int64(1000)));
        
        expect(evidence.hasCommonHeight(), isTrue);
        expect(evidence.commonHeight, equals(Int64(5000)));
        
        expect(evidence.byzantineValidators.length, equals(1));
        expect(evidence.byzantineValidators.first.votingPower, equals(Int64(777)));
        
        expect(evidence.hasTotalVotingPower(), isTrue);
        expect(evidence.totalVotingPower, equals(Int64(15000)));
        
        expect(evidence.hasTimestamp(), isTrue);
        expect(evidence.timestamp.seconds, equals(Int64(1609459200)));
      });

      test('should cover LightClientAttackEvidence clear methods', () {
        final evidence = LightClientAttackEvidence()
          ..conflictingBlock = LightBlock()
          ..commonHeight = Int64(123)
          ..totalVotingPower = Int64(456)
          ..timestamp = Timestamp();
        
        // Test clear methods
        evidence.clearConflictingBlock();
        expect(evidence.hasConflictingBlock(), isFalse);
        
        evidence.clearCommonHeight();
        expect(evidence.hasCommonHeight(), isFalse);
        expect(evidence.commonHeight, equals(Int64.ZERO));
        
        evidence.clearTotalVotingPower();
        expect(evidence.hasTotalVotingPower(), isFalse);
        expect(evidence.totalVotingPower, equals(Int64.ZERO));
        
        evidence.clearTimestamp();
        expect(evidence.hasTimestamp(), isFalse);
      });

      test('should cover LightClientAttackEvidence ensure methods', () {
        final evidence = LightClientAttackEvidence();
        
        // Test ensure methods
        final ensuredBlock = evidence.ensureConflictingBlock();
        expect(ensuredBlock, isA<LightBlock>());
        expect(evidence.hasConflictingBlock(), isTrue);
        
        final ensuredTimestamp = evidence.ensureTimestamp();
        expect(ensuredTimestamp, isA<Timestamp>());
        expect(evidence.hasTimestamp(), isTrue);
      });

      test('should cover LightClientAttackEvidence serialization methods', () {
        final original = LightClientAttackEvidence()
          ..commonHeight = Int64(7890)
          ..totalVotingPower = Int64(12345)
          ..timestamp = (Timestamp()..seconds = Int64(1700000000));
        
        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = LightClientAttackEvidence.fromBuffer(buffer);
        
        expect(fromBuffer.commonHeight, equals(Int64(7890)));
        expect(fromBuffer.totalVotingPower, equals(Int64(12345)));
        expect(fromBuffer.timestamp.seconds, equals(Int64(1700000000)));
        
        // Test fromJson
        final json = original.writeToJson();
        final fromJson = LightClientAttackEvidence.fromJson(json);
        
        expect(fromJson.commonHeight, equals(Int64(7890)));
        expect(fromJson.totalVotingPower, equals(Int64(12345)));
      });

      test('should cover LightClientAttackEvidence clone and copyWith methods', () {
        final original = LightClientAttackEvidence()
          ..commonHeight = Int64(6666)
          ..totalVotingPower = Int64(7777);
        
        // Test clone
        final cloned = original.clone();
        expect(cloned.commonHeight, equals(Int64(6666)));
        expect(cloned.totalVotingPower, equals(Int64(7777)));
        
        // Test copyWith
        final modified = original.copyWith((evidence) {
          evidence.commonHeight = Int64(8888);
          evidence.totalVotingPower = Int64(9999);
          evidence.timestamp = Timestamp()..seconds = Int64(1800000000);
        });
        
        expect(modified.commonHeight, equals(Int64(8888)));
        expect(modified.totalVotingPower, equals(Int64(9999)));
        expect(modified.timestamp.seconds, equals(Int64(1800000000)));
      });

      test('should cover LightClientAttackEvidence static methods', () {
        // Test create
        final created = LightClientAttackEvidence.create();
        expect(created, isA<LightClientAttackEvidence>());
        
        // Test createEmptyInstance
        final emptyInstance = created.createEmptyInstance();
        expect(emptyInstance, isA<LightClientAttackEvidence>());
        
        // Test createRepeated
        final list = LightClientAttackEvidence.createRepeated();
        expect(list, isA<List<LightClientAttackEvidence>>());
        expect(list.isEmpty, isTrue);
        
        // Test getDefault
        final defaultInstance = LightClientAttackEvidence.getDefault();
        expect(defaultInstance, isA<LightClientAttackEvidence>());
        
        final anotherDefault = LightClientAttackEvidence.getDefault();
        expect(identical(defaultInstance, anotherDefault), isTrue);
      });

      test('should cover complex byzantineValidators operations', () {
        final evidence = LightClientAttackEvidence();
        
        // Initially empty
        expect(evidence.byzantineValidators, isEmpty);
        
        // Add multiple validators
        final validator1 = Validator()
          ..address = [0x01, 0x02]
          ..votingPower = Int64(100);
        final validator2 = Validator()
          ..address = [0x03, 0x04]
          ..votingPower = Int64(200);
        
        evidence.byzantineValidators.addAll([validator1, validator2]);
        
        expect(evidence.byzantineValidators.length, equals(2));
        expect(evidence.byzantineValidators.first.votingPower, equals(Int64(100)));
        expect(evidence.byzantineValidators.last.votingPower, equals(Int64(200)));
        
        // Test cloning with validators
        final cloned = evidence.clone();
        expect(cloned.byzantineValidators.length, equals(2));
        expect(cloned.byzantineValidators.first.votingPower, equals(Int64(100)));
      });
    });

    group('EvidenceList Class Remaining Coverage', () {
      test('should cover EvidenceList missing serialization methods', () {
        final evidence1 = Evidence()
          ..duplicateVoteEvidence = (DuplicateVoteEvidence()..totalVotingPower = Int64(1111));
        final evidence2 = Evidence()
          ..lightClientAttackEvidence = (LightClientAttackEvidence()..commonHeight = Int64(2222));
        
        final original = EvidenceList()
          ..evidence.addAll([evidence1, evidence2]);
        
        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = EvidenceList.fromBuffer(buffer);
        
        expect(fromBuffer.evidence.length, equals(2));
        expect(fromBuffer.evidence.first.duplicateVoteEvidence.totalVotingPower, equals(Int64(1111)));
        expect(fromBuffer.evidence.last.lightClientAttackEvidence.commonHeight, equals(Int64(2222)));
        
        // Test fromJson
        final json = original.writeToJson();
        final fromJson = EvidenceList.fromJson(json);
        
        expect(fromJson.evidence.length, equals(2));
      });

      test('should cover EvidenceList clone and copyWith methods', () {
        final evidence1 = Evidence()
          ..duplicateVoteEvidence = (DuplicateVoteEvidence()..validatorPower = Int64(500));
        
        final original = EvidenceList()
          ..evidence.add(evidence1);
        
        // Test clone
        final cloned = original.clone();
        expect(cloned.evidence.length, equals(1));
        expect(cloned.evidence.first.duplicateVoteEvidence.validatorPower, equals(Int64(500)));
        
        // Test copyWith
        final newEvidence = Evidence()
          ..lightClientAttackEvidence = (LightClientAttackEvidence()..totalVotingPower = Int64(3000));
        
        final modified = original.copyWith((evidenceList) {
          evidenceList.evidence.clear();
          evidenceList.evidence.add(newEvidence);
        });
        
        expect(modified.evidence.length, equals(1));
        expect(modified.evidence.first.lightClientAttackEvidence.totalVotingPower, equals(Int64(3000)));
      });

      test('should cover EvidenceList missing static methods', () {
        // Test createEmptyInstance
        final list = EvidenceList();
        final emptyInstance = list.createEmptyInstance();
        expect(emptyInstance, isA<EvidenceList>());
        
        // Test createRepeated
        final repeatedList = EvidenceList.createRepeated();
        expect(repeatedList, isA<List<EvidenceList>>());
        expect(repeatedList.isEmpty, isTrue);
        
        repeatedList.add(EvidenceList()..evidence.add(Evidence()));
        expect(repeatedList.length, equals(1));
        
        // Test getDefault
        final defaultInstance = EvidenceList.getDefault();
        expect(defaultInstance, isA<EvidenceList>());
        expect(defaultInstance.evidence, isEmpty);
        
        final anotherDefault = EvidenceList.getDefault();
        expect(identical(defaultInstance, anotherDefault), isTrue);
      });
    });

    group('Comprehensive Integration Tests', () {
      test('should cover complex evidence scenarios with all types', () {
        // Create comprehensive evidence instances
        final duplicateEvidence = DuplicateVoteEvidence()
          ..voteA = (Vote()
            ..height = Int64(1000)
            ..type = SignedMsgType.SIGNED_MSG_TYPE_PROPOSAL)
          ..voteB = (Vote()
            ..height = Int64(1000)
            ..type = SignedMsgType.SIGNED_MSG_TYPE_PREVOTE)
          ..totalVotingPower = Int64(100000)
          ..validatorPower = Int64(5000)
          ..timestamp = (Timestamp()..seconds = Int64(1640995200));
        
        final lightClientEvidence = LightClientAttackEvidence()
          ..conflictingBlock = (LightBlock()
            ..signedHeader = (SignedHeader()
              ..header = (Header()..height = Int64(2000))))
          ..commonHeight = Int64(1500)
          ..totalVotingPower = Int64(200000)
          ..timestamp = (Timestamp()..seconds = Int64(1641081600));
        
        final evidence1 = Evidence()..duplicateVoteEvidence = duplicateEvidence;
        final evidence2 = Evidence()..lightClientAttackEvidence = lightClientEvidence;
        
        final evidenceList = EvidenceList()
          ..evidence.addAll([evidence1, evidence2]);
        
        // Test comprehensive serialization
        final buffer = evidenceList.writeToBuffer();
        final deserialized = EvidenceList.fromBuffer(buffer);
        
        expect(deserialized.evidence.length, equals(2));
        
        final deserializedDuplicate = deserialized.evidence[0];
        expect(deserializedDuplicate.whichSum(), equals(Evidence_Sum.duplicateVoteEvidence));
        expect(deserializedDuplicate.duplicateVoteEvidence.totalVotingPower, equals(Int64(100000)));
        
        final deserializedLightClient = deserialized.evidence[1];
        expect(deserializedLightClient.whichSum(), equals(Evidence_Sum.lightClientAttackEvidence));
        expect(deserializedLightClient.lightClientAttackEvidence.commonHeight, equals(Int64(1500)));
      });

      test('should cover edge cases with empty and default values', () {
        // Test with empty values
        final emptyEvidence = Evidence();
        expect(emptyEvidence.whichSum(), equals(Evidence_Sum.notSet));
        
        final emptyDuplicate = DuplicateVoteEvidence();
        expect(emptyDuplicate.totalVotingPower, equals(Int64.ZERO));
        expect(emptyDuplicate.validatorPower, equals(Int64.ZERO));
        
        final emptyLightClient = LightClientAttackEvidence();
        expect(emptyLightClient.commonHeight, equals(Int64.ZERO));
        expect(emptyLightClient.totalVotingPower, equals(Int64.ZERO));
        expect(emptyLightClient.byzantineValidators, isEmpty);
        
        final emptyList = EvidenceList();
        expect(emptyList.evidence, isEmpty);
        
        // Test serialization of empty objects
        final buffer = emptyList.writeToBuffer();
        final deserialized = EvidenceList.fromBuffer(buffer);
        expect(deserialized.evidence, isEmpty);
      });
    });
  });
} 