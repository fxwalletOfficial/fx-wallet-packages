import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/types/params.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/duration.pb.dart';

void main() {
  group('Tendermint Params Coverage Tests', () {
    group('ConsensusParams Class Coverage', () {
      test('should cover ConsensusParams constructor and field operations', () {
        final blockParams = BlockParams()
          ..maxBytes = Int64(1000000)
          ..maxGas = Int64(10000000)
          ..timeIotaMs = Int64(1000);
        
        final evidenceParams = EvidenceParams()
          ..maxAgeNumBlocks = Int64(100000)
          ..maxBytes = Int64(50000)
          ..maxAgeDuration = (Duration()..seconds = Int64(172800));
        
        final validatorParams = ValidatorParams()
          ..pubKeyTypes.addAll(['ed25519', 'secp256k1']);
        
        final versionParams = VersionParams()
          ..appVersion = Int64(1);
        
        final consensusParams = ConsensusParams()
          ..block = blockParams
          ..evidence = evidenceParams
          ..validator = validatorParams
          ..version = versionParams;
        
        // Test all getters and has methods
        expect(consensusParams.hasBlock(), isTrue);
        expect(consensusParams.block.maxBytes, equals(Int64(1000000)));
        expect(consensusParams.block.maxGas, equals(Int64(10000000)));
        expect(consensusParams.block.timeIotaMs, equals(Int64(1000)));
        
        expect(consensusParams.hasEvidence(), isTrue);
        expect(consensusParams.evidence.maxAgeNumBlocks, equals(Int64(100000)));
        expect(consensusParams.evidence.maxBytes, equals(Int64(50000)));
        expect(consensusParams.evidence.maxAgeDuration.seconds, equals(Int64(172800)));
        
        expect(consensusParams.hasValidator(), isTrue);
        expect(consensusParams.validator.pubKeyTypes, contains('ed25519'));
        expect(consensusParams.validator.pubKeyTypes, contains('secp256k1'));
        
        expect(consensusParams.hasVersion(), isTrue);
        expect(consensusParams.version.appVersion, equals(Int64(1)));
      });

      test('should cover ConsensusParams clear methods', () {
        final consensusParams = ConsensusParams()
          ..block = BlockParams()
          ..evidence = EvidenceParams()
          ..validator = ValidatorParams()
          ..version = VersionParams();
        
        // Test all clear methods
        consensusParams.clearBlock();
        expect(consensusParams.hasBlock(), isFalse);
        
        consensusParams.clearEvidence();
        expect(consensusParams.hasEvidence(), isFalse);
        
        consensusParams.clearValidator();
        expect(consensusParams.hasValidator(), isFalse);
        
        consensusParams.clearVersion();
        expect(consensusParams.hasVersion(), isFalse);
      });

      test('should cover ConsensusParams ensure methods', () {
        final consensusParams = ConsensusParams();
        
        // Test all ensure methods
        final ensuredBlock = consensusParams.ensureBlock();
        expect(ensuredBlock, isA<BlockParams>());
        expect(consensusParams.hasBlock(), isTrue);
        
        final ensuredEvidence = consensusParams.ensureEvidence();
        expect(ensuredEvidence, isA<EvidenceParams>());
        expect(consensusParams.hasEvidence(), isTrue);
        
        final ensuredValidator = consensusParams.ensureValidator();
        expect(ensuredValidator, isA<ValidatorParams>());
        expect(consensusParams.hasValidator(), isTrue);
        
        final ensuredVersion = consensusParams.ensureVersion();
        expect(ensuredVersion, isA<VersionParams>());
        expect(consensusParams.hasVersion(), isTrue);
      });

      test('should cover ConsensusParams serialization methods', () {
        final original = ConsensusParams()
          ..block = (BlockParams()..maxBytes = Int64(2000000))
          ..evidence = (EvidenceParams()..maxAgeNumBlocks = Int64(200000))
          ..validator = (ValidatorParams()..pubKeyTypes.add('ed25519'))
          ..version = (VersionParams()..appVersion = Int64(2));
        
        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = ConsensusParams.fromBuffer(buffer);
        
        expect(fromBuffer.block.maxBytes, equals(Int64(2000000)));
        expect(fromBuffer.evidence.maxAgeNumBlocks, equals(Int64(200000)));
        expect(fromBuffer.validator.pubKeyTypes.first, equals('ed25519'));
        expect(fromBuffer.version.appVersion, equals(Int64(2)));
        
        // Test fromJson
        final json = original.writeToJson();
        final fromJson = ConsensusParams.fromJson(json);
        
        expect(fromJson.block.maxBytes, equals(Int64(2000000)));
        expect(fromJson.evidence.maxAgeNumBlocks, equals(Int64(200000)));
      });

      test('should cover ConsensusParams clone and copyWith methods', () {
        final original = ConsensusParams()
          ..block = (BlockParams()..maxGas = Int64(15000000))
          ..validator = (ValidatorParams()..pubKeyTypes.add('secp256k1'));
        
        // Test clone
        final cloned = original.clone();
        expect(cloned.block.maxGas, equals(Int64(15000000)));
        expect(cloned.validator.pubKeyTypes.first, equals('secp256k1'));
        
        // Test copyWith
        final modified = original.copyWith((params) {
          params.block.maxGas = Int64(20000000);
          params.version = VersionParams()..appVersion = Int64(3);
        });
        
        expect(modified.block.maxGas, equals(Int64(20000000)));
        expect(modified.version.appVersion, equals(Int64(3)));
      });

      test('should cover ConsensusParams static methods', () {
        // Test create
        final created = ConsensusParams.create();
        expect(created, isA<ConsensusParams>());
        
        // Test createEmptyInstance
        final emptyInstance = created.createEmptyInstance();
        expect(emptyInstance, isA<ConsensusParams>());
        
        // Test createRepeated
        final list = ConsensusParams.createRepeated();
        expect(list, isA<List<ConsensusParams>>());
        expect(list.isEmpty, isTrue);
        
        // Test getDefault
        final defaultInstance = ConsensusParams.getDefault();
        expect(defaultInstance, isA<ConsensusParams>());
        
        final anotherDefault = ConsensusParams.getDefault();
        expect(identical(defaultInstance, anotherDefault), isTrue);
      });
    });

    group('BlockParams Class Coverage', () {
      test('should cover BlockParams constructor and field operations', () {
        final blockParams = BlockParams()
          ..maxBytes = Int64(5000000)
          ..maxGas = Int64(50000000)
          ..timeIotaMs = Int64(500);
        
        // Test all getters
        expect(blockParams.maxBytes, equals(Int64(5000000)));
        expect(blockParams.maxGas, equals(Int64(50000000)));
        expect(blockParams.timeIotaMs, equals(Int64(500)));
        
        // Test has methods
        expect(blockParams.hasMaxBytes(), isTrue);
        expect(blockParams.hasMaxGas(), isTrue);
        expect(blockParams.hasTimeIotaMs(), isTrue);
      });

      test('should cover BlockParams clear methods', () {
        final blockParams = BlockParams()
          ..maxBytes = Int64(1000)
          ..maxGas = Int64(2000)
          ..timeIotaMs = Int64(3000);
        
        // Test clear methods
        blockParams.clearMaxBytes();
        expect(blockParams.hasMaxBytes(), isFalse);
        expect(blockParams.maxBytes, equals(Int64.ZERO));
        
        blockParams.clearMaxGas();
        expect(blockParams.hasMaxGas(), isFalse);
        expect(blockParams.maxGas, equals(Int64.ZERO));
        
        blockParams.clearTimeIotaMs();
        expect(blockParams.hasTimeIotaMs(), isFalse);
        expect(blockParams.timeIotaMs, equals(Int64.ZERO));
      });

      test('should cover BlockParams serialization methods', () {
        final original = BlockParams()
          ..maxBytes = Int64(7777777)
          ..maxGas = Int64(8888888)
          ..timeIotaMs = Int64(9999);
        
        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = BlockParams.fromBuffer(buffer);
        
        expect(fromBuffer.maxBytes, equals(Int64(7777777)));
        expect(fromBuffer.maxGas, equals(Int64(8888888)));
        expect(fromBuffer.timeIotaMs, equals(Int64(9999)));
        
        // Test fromJson
        final json = original.writeToJson();
        final fromJson = BlockParams.fromJson(json);
        
        expect(fromJson.maxBytes, equals(Int64(7777777)));
        expect(fromJson.maxGas, equals(Int64(8888888)));
      });

      test('should cover BlockParams clone and copyWith methods', () {
        final original = BlockParams()
          ..maxBytes = Int64(111111)
          ..maxGas = Int64(222222);
        
        // Test clone
        final cloned = original.clone();
        expect(cloned.maxBytes, equals(Int64(111111)));
        expect(cloned.maxGas, equals(Int64(222222)));
        
        // Test copyWith
        final modified = original.copyWith((params) {
          params.maxBytes = Int64(333333);
          params.timeIotaMs = Int64(444444);
        });
        
        expect(modified.maxBytes, equals(Int64(333333)));
        expect(modified.timeIotaMs, equals(Int64(444444)));
      });

      test('should cover BlockParams static methods', () {
        // Test create
        final created = BlockParams.create();
        expect(created, isA<BlockParams>());
        
        // Test createEmptyInstance
        final emptyInstance = created.createEmptyInstance();
        expect(emptyInstance, isA<BlockParams>());
        
        // Test createRepeated
        final list = BlockParams.createRepeated();
        expect(list, isA<List<BlockParams>>());
        expect(list.isEmpty, isTrue);
        
        // Test getDefault
        final defaultInstance = BlockParams.getDefault();
        expect(defaultInstance, isA<BlockParams>());
        expect(defaultInstance.maxBytes, equals(Int64.ZERO));
        expect(defaultInstance.maxGas, equals(Int64.ZERO));
      });
    });

    group('EvidenceParams Class Coverage', () {
      test('should cover EvidenceParams constructor and field operations', () {
        final duration = Duration()
          ..seconds = Int64(86400)
          ..nanos = 500000000;
        
        final evidenceParams = EvidenceParams()
          ..maxAgeNumBlocks = Int64(500000)
          ..maxAgeDuration = duration
          ..maxBytes = Int64(750000);
        
        // Test all getters
        expect(evidenceParams.maxAgeNumBlocks, equals(Int64(500000)));
        expect(evidenceParams.maxAgeDuration.seconds, equals(Int64(86400)));
        expect(evidenceParams.maxAgeDuration.nanos, equals(500000000));
        expect(evidenceParams.maxBytes, equals(Int64(750000)));
        
        // Test has methods
        expect(evidenceParams.hasMaxAgeNumBlocks(), isTrue);
        expect(evidenceParams.hasMaxAgeDuration(), isTrue);
        expect(evidenceParams.hasMaxBytes(), isTrue);
      });

      test('should cover EvidenceParams clear methods', () {
        final evidenceParams = EvidenceParams()
          ..maxAgeNumBlocks = Int64(1000)
          ..maxAgeDuration = Duration()
          ..maxBytes = Int64(2000);
        
        // Test clear methods
        evidenceParams.clearMaxAgeNumBlocks();
        expect(evidenceParams.hasMaxAgeNumBlocks(), isFalse);
        expect(evidenceParams.maxAgeNumBlocks, equals(Int64.ZERO));
        
        evidenceParams.clearMaxAgeDuration();
        expect(evidenceParams.hasMaxAgeDuration(), isFalse);
        
        evidenceParams.clearMaxBytes();
        expect(evidenceParams.hasMaxBytes(), isFalse);
        expect(evidenceParams.maxBytes, equals(Int64.ZERO));
      });

      test('should cover EvidenceParams ensure methods', () {
        final evidenceParams = EvidenceParams();
        
        // Test ensureMaxAgeDuration
        final ensuredDuration = evidenceParams.ensureMaxAgeDuration();
        expect(ensuredDuration, isA<Duration>());
        expect(evidenceParams.hasMaxAgeDuration(), isTrue);
      });

      test('should cover EvidenceParams serialization methods', () {
        final original = EvidenceParams()
          ..maxAgeNumBlocks = Int64(999999)
          ..maxBytes = Int64(888888)
          ..maxAgeDuration = (Duration()..seconds = Int64(43200));
        
        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = EvidenceParams.fromBuffer(buffer);
        
        expect(fromBuffer.maxAgeNumBlocks, equals(Int64(999999)));
        expect(fromBuffer.maxBytes, equals(Int64(888888)));
        expect(fromBuffer.maxAgeDuration.seconds, equals(Int64(43200)));
        
        // Test fromJson
        final json = original.writeToJson();
        final fromJson = EvidenceParams.fromJson(json);
        
        expect(fromJson.maxAgeNumBlocks, equals(Int64(999999)));
        expect(fromJson.maxBytes, equals(Int64(888888)));
      });

      test('should cover EvidenceParams clone and copyWith methods', () {
        final original = EvidenceParams()
          ..maxAgeNumBlocks = Int64(555555)
          ..maxBytes = Int64(666666);
        
        // Test clone
        final cloned = original.clone();
        expect(cloned.maxAgeNumBlocks, equals(Int64(555555)));
        expect(cloned.maxBytes, equals(Int64(666666)));
        
        // Test copyWith
        final modified = original.copyWith((params) {
          params.maxAgeNumBlocks = Int64(777777);
          params.maxAgeDuration = Duration()..seconds = Int64(3600);
        });
        
        expect(modified.maxAgeNumBlocks, equals(Int64(777777)));
        expect(modified.maxAgeDuration.seconds, equals(Int64(3600)));
      });

      test('should cover EvidenceParams static methods', () {
        // Test create
        final created = EvidenceParams.create();
        expect(created, isA<EvidenceParams>());
        
        // Test createEmptyInstance
        final emptyInstance = created.createEmptyInstance();
        expect(emptyInstance, isA<EvidenceParams>());
        
        // Test createRepeated
        final list = EvidenceParams.createRepeated();
        expect(list, isA<List<EvidenceParams>>());
        expect(list.isEmpty, isTrue);
        
        // Test getDefault
        final defaultInstance = EvidenceParams.getDefault();
        expect(defaultInstance, isA<EvidenceParams>());
        expect(defaultInstance.maxAgeNumBlocks, equals(Int64.ZERO));
        expect(defaultInstance.maxBytes, equals(Int64.ZERO));
      });
    });

    group('ValidatorParams Class Coverage', () {
      test('should cover ValidatorParams constructor and field operations', () {
        final validatorParams = ValidatorParams()
          ..pubKeyTypes.addAll(['ed25519', 'secp256k1', 'secp256r1']);
        
        // Test list operations
        expect(validatorParams.pubKeyTypes.length, equals(3));
        expect(validatorParams.pubKeyTypes, contains('ed25519'));
        expect(validatorParams.pubKeyTypes, contains('secp256k1'));
        expect(validatorParams.pubKeyTypes, contains('secp256r1'));
        expect(validatorParams.pubKeyTypes.first, equals('ed25519'));
        expect(validatorParams.pubKeyTypes.last, equals('secp256r1'));
      });

      test('should cover ValidatorParams list manipulations', () {
        final validatorParams = ValidatorParams();
        
        // Test initially empty
        expect(validatorParams.pubKeyTypes, isEmpty);
        
        // Test adding individual items
        validatorParams.pubKeyTypes.add('ed25519');
        expect(validatorParams.pubKeyTypes.length, equals(1));
        
        validatorParams.pubKeyTypes.add('secp256k1');
        expect(validatorParams.pubKeyTypes.length, equals(2));
        
        // Test removing items
        validatorParams.pubKeyTypes.remove('ed25519');
        expect(validatorParams.pubKeyTypes.length, equals(1));
        expect(validatorParams.pubKeyTypes.first, equals('secp256k1'));
        
        // Test clearing
        validatorParams.pubKeyTypes.clear();
        expect(validatorParams.pubKeyTypes, isEmpty);
      });

      test('should cover ValidatorParams serialization methods', () {
        final original = ValidatorParams()
          ..pubKeyTypes.addAll(['ed25519', 'secp256k1', 'rsa2048']);
        
        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = ValidatorParams.fromBuffer(buffer);
        
        expect(fromBuffer.pubKeyTypes.length, equals(3));
        expect(fromBuffer.pubKeyTypes, contains('ed25519'));
        expect(fromBuffer.pubKeyTypes, contains('secp256k1'));
        expect(fromBuffer.pubKeyTypes, contains('rsa2048'));
        
        // Test fromJson
        final json = original.writeToJson();
        final fromJson = ValidatorParams.fromJson(json);
        
        expect(fromJson.pubKeyTypes.length, equals(3));
        expect(fromJson.pubKeyTypes, contains('ed25519'));
      });

      test('should cover ValidatorParams clone and copyWith methods', () {
        final original = ValidatorParams()
          ..pubKeyTypes.addAll(['ed25519', 'secp256k1']);
        
        // Test clone
        final cloned = original.clone();
        expect(cloned.pubKeyTypes.length, equals(2));
        expect(cloned.pubKeyTypes, contains('ed25519'));
        expect(cloned.pubKeyTypes, contains('secp256k1'));
        
        // Test copyWith
        final modified = original.copyWith((params) {
          params.pubKeyTypes.add('secp256r1');
          params.pubKeyTypes.remove('ed25519');
        });
        
        expect(modified.pubKeyTypes.length, equals(2));
        expect(modified.pubKeyTypes, contains('secp256k1'));
        expect(modified.pubKeyTypes, contains('secp256r1'));
        expect(modified.pubKeyTypes, isNot(contains('ed25519')));
      });

      test('should cover ValidatorParams static methods', () {
        // Test create
        final created = ValidatorParams.create();
        expect(created, isA<ValidatorParams>());
        expect(created.pubKeyTypes, isEmpty);
        
        // Test createEmptyInstance
        final emptyInstance = created.createEmptyInstance();
        expect(emptyInstance, isA<ValidatorParams>());
        
        // Test createRepeated
        final list = ValidatorParams.createRepeated();
        expect(list, isA<List<ValidatorParams>>());
        expect(list.isEmpty, isTrue);
        
        list.add(ValidatorParams()..pubKeyTypes.add('ed25519'));
        list.add(ValidatorParams()..pubKeyTypes.add('secp256k1'));
        
        expect(list.length, equals(2));
        expect(list.first.pubKeyTypes.first, equals('ed25519'));
        expect(list.last.pubKeyTypes.first, equals('secp256k1'));
        
        // Test getDefault
        final defaultInstance = ValidatorParams.getDefault();
        expect(defaultInstance, isA<ValidatorParams>());
        expect(defaultInstance.pubKeyTypes, isEmpty);
      });
    });

    group('VersionParams Class Coverage', () {
      test('should cover VersionParams constructor and field operations', () {
        final versionParams = VersionParams()
          ..appVersion = Int64(123456789);
        
        // Test getter
        expect(versionParams.appVersion, equals(Int64(123456789)));
        expect(versionParams.hasAppVersion(), isTrue);
      });

      test('should cover VersionParams clear methods', () {
        final versionParams = VersionParams()
          ..appVersion = Int64(999);
        
        expect(versionParams.hasAppVersion(), isTrue);
        
        // Test clear
        versionParams.clearAppVersion();
        expect(versionParams.hasAppVersion(), isFalse);
        expect(versionParams.appVersion, equals(Int64.ZERO));
      });

      test('should cover VersionParams serialization methods', () {
        final original = VersionParams()
          ..appVersion = Int64.MAX_VALUE;
        
        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = VersionParams.fromBuffer(buffer);
        
        expect(fromBuffer.appVersion, equals(Int64.MAX_VALUE));
        
        // Test fromJson
        final json = original.writeToJson();
        final fromJson = VersionParams.fromJson(json);
        
        expect(fromJson.appVersion, equals(Int64.MAX_VALUE));
      });

      test('should cover VersionParams clone and copyWith methods', () {
        final original = VersionParams()
          ..appVersion = Int64(42);
        
        // Test clone
        final cloned = original.clone();
        expect(cloned.appVersion, equals(Int64(42)));
        
        // Test copyWith
        final modified = original.copyWith((params) {
          params.appVersion = Int64(84);
        });
        
        expect(modified.appVersion, equals(Int64(84)));
        expect(original.appVersion, equals(Int64(42))); // Original unchanged
      });

      test('should cover VersionParams static methods', () {
        // Test create
        final created = VersionParams.create();
        expect(created, isA<VersionParams>());
        expect(created.appVersion, equals(Int64.ZERO));
        
        // Test createEmptyInstance
        final emptyInstance = created.createEmptyInstance();
        expect(emptyInstance, isA<VersionParams>());
        
        // Test createRepeated
        final list = VersionParams.createRepeated();
        expect(list, isA<List<VersionParams>>());
        expect(list.isEmpty, isTrue);
        
        // Test getDefault
        final defaultInstance = VersionParams.getDefault();
        expect(defaultInstance, isA<VersionParams>());
        expect(defaultInstance.appVersion, equals(Int64.ZERO));
      });
    });

    group('HashedParams Class Coverage', () {
      test('should cover HashedParams constructor and field operations', () {
        final hashedParams = HashedParams()
          ..blockMaxBytes = Int64(8000000)
          ..blockMaxGas = Int64(80000000);
        
        // Test getters
        expect(hashedParams.blockMaxBytes, equals(Int64(8000000)));
        expect(hashedParams.blockMaxGas, equals(Int64(80000000)));
        
        // Test has methods
        expect(hashedParams.hasBlockMaxBytes(), isTrue);
        expect(hashedParams.hasBlockMaxGas(), isTrue);
      });

      test('should cover HashedParams clear methods', () {
        final hashedParams = HashedParams()
          ..blockMaxBytes = Int64(1000)
          ..blockMaxGas = Int64(2000);
        
        // Test clear methods
        hashedParams.clearBlockMaxBytes();
        expect(hashedParams.hasBlockMaxBytes(), isFalse);
        expect(hashedParams.blockMaxBytes, equals(Int64.ZERO));
        
        hashedParams.clearBlockMaxGas();
        expect(hashedParams.hasBlockMaxGas(), isFalse);
        expect(hashedParams.blockMaxGas, equals(Int64.ZERO));
      });

      test('should cover HashedParams serialization methods', () {
        final original = HashedParams()
          ..blockMaxBytes = Int64(12345678)
          ..blockMaxGas = Int64(87654321);
        
        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = HashedParams.fromBuffer(buffer);
        
        expect(fromBuffer.blockMaxBytes, equals(Int64(12345678)));
        expect(fromBuffer.blockMaxGas, equals(Int64(87654321)));
        
        // Test fromJson
        final json = original.writeToJson();
        final fromJson = HashedParams.fromJson(json);
        
        expect(fromJson.blockMaxBytes, equals(Int64(12345678)));
        expect(fromJson.blockMaxGas, equals(Int64(87654321)));
      });

      test('should cover HashedParams clone and copyWith methods', () {
        final original = HashedParams()
          ..blockMaxBytes = Int64(100)
          ..blockMaxGas = Int64(200);
        
        // Test clone
        final cloned = original.clone();
        expect(cloned.blockMaxBytes, equals(Int64(100)));
        expect(cloned.blockMaxGas, equals(Int64(200)));
        
        // Test copyWith
        final modified = original.copyWith((params) {
          params.blockMaxBytes = Int64(300);
          params.blockMaxGas = Int64(400);
        });
        
        expect(modified.blockMaxBytes, equals(Int64(300)));
        expect(modified.blockMaxGas, equals(Int64(400)));
      });

      test('should cover HashedParams static methods', () {
        // Test create
        final created = HashedParams.create();
        expect(created, isA<HashedParams>());
        expect(created.blockMaxBytes, equals(Int64.ZERO));
        expect(created.blockMaxGas, equals(Int64.ZERO));
        
        // Test createEmptyInstance
        final emptyInstance = created.createEmptyInstance();
        expect(emptyInstance, isA<HashedParams>());
        
        // Test createRepeated
        final list = HashedParams.createRepeated();
        expect(list, isA<List<HashedParams>>());
        expect(list.isEmpty, isTrue);
        
        // Test getDefault
        final defaultInstance = HashedParams.getDefault();
        expect(defaultInstance, isA<HashedParams>());
        expect(defaultInstance.blockMaxBytes, equals(Int64.ZERO));
        expect(defaultInstance.blockMaxGas, equals(Int64.ZERO));
      });
    });

    group('Integration and Edge Case Tests', () {
      test('should cover comprehensive integration scenario', () {
        // Create a fully configured ConsensusParams with all nested parameters
        final consensusParams = ConsensusParams()
          ..block = (BlockParams()
            ..maxBytes = Int64(4000000)
            ..maxGas = Int64(40000000)
            ..timeIotaMs = Int64(2000))
          ..evidence = (EvidenceParams()
            ..maxAgeNumBlocks = Int64(300000)
            ..maxAgeDuration = (Duration()
              ..seconds = Int64(259200)
              ..nanos = 123456789)
            ..maxBytes = Int64(1000000))
          ..validator = (ValidatorParams()
            ..pubKeyTypes.addAll(['ed25519', 'secp256k1', 'secp256r1', 'rsa2048']))
          ..version = (VersionParams()
            ..appVersion = Int64(1000));
        
        // Test comprehensive serialization
        final buffer = consensusParams.writeToBuffer();
        final deserialized = ConsensusParams.fromBuffer(buffer);
        
        // Verify all nested parameters are correctly deserialized
        expect(deserialized.block.maxBytes, equals(Int64(4000000)));
        expect(deserialized.block.maxGas, equals(Int64(40000000)));
        expect(deserialized.block.timeIotaMs, equals(Int64(2000)));
        
        expect(deserialized.evidence.maxAgeNumBlocks, equals(Int64(300000)));
        expect(deserialized.evidence.maxAgeDuration.seconds, equals(Int64(259200)));
        expect(deserialized.evidence.maxAgeDuration.nanos, equals(123456789));
        expect(deserialized.evidence.maxBytes, equals(Int64(1000000)));
        
        expect(deserialized.validator.pubKeyTypes.length, equals(4));
        expect(deserialized.validator.pubKeyTypes, contains('ed25519'));
        expect(deserialized.validator.pubKeyTypes, contains('rsa2048'));
        
        expect(deserialized.version.appVersion, equals(Int64(1000)));
      });

      test('should cover edge cases with extreme values', () {
        // Test with maximum values
        final maxParams = BlockParams()
          ..maxBytes = Int64.MAX_VALUE
          ..maxGas = Int64.MAX_VALUE
          ..timeIotaMs = Int64.MAX_VALUE;
        
        expect(maxParams.maxBytes, equals(Int64.MAX_VALUE));
        expect(maxParams.maxGas, equals(Int64.MAX_VALUE));
        expect(maxParams.timeIotaMs, equals(Int64.MAX_VALUE));
        
        // Test with minimum/zero values
        final minParams = EvidenceParams()
          ..maxAgeNumBlocks = Int64.ZERO
          ..maxBytes = Int64.ZERO;
        
        expect(minParams.maxAgeNumBlocks, equals(Int64.ZERO));
        expect(minParams.maxBytes, equals(Int64.ZERO));
        
        // Test with empty validator params
        final emptyValidator = ValidatorParams();
        expect(emptyValidator.pubKeyTypes, isEmpty);
        
        // Test serialization of edge cases
        final buffer = maxParams.writeToBuffer();
        final deserialized = BlockParams.fromBuffer(buffer);
        expect(deserialized.maxBytes, equals(Int64.MAX_VALUE));
      });

      test('should cover complex copyWith scenarios', () {
        final original = ConsensusParams()
          ..block = (BlockParams()..maxBytes = Int64(1000))
          ..evidence = (EvidenceParams()..maxBytes = Int64(2000));
        
        // Test complex copyWith that modifies multiple nested objects
        final modified = original.copyWith((params) {
          params.block.maxBytes = Int64(3000);
          params.block.maxGas = Int64(4000);
          params.evidence.maxBytes = Int64(5000);
          params.validator = ValidatorParams()..pubKeyTypes.add('ed25519');
          params.version = VersionParams()..appVersion = Int64(999);
        });
        
        // Verify the copyWith operation executed successfully and returned an instance
        expect(modified, isA<ConsensusParams>());
        expect(modified.block.maxBytes, equals(Int64(3000)));
        expect(modified.block.maxGas, equals(Int64(4000)));
        expect(modified.evidence.maxBytes, equals(Int64(5000)));
        expect(modified.hasValidator(), isTrue);
        expect(modified.hasVersion(), isTrue);
        
        if (modified.hasValidator()) {
          expect(modified.validator.pubKeyTypes.first, equals('ed25519'));
        }
        if (modified.hasVersion()) {
          expect(modified.version.appVersion, equals(Int64(999)));
        }
      });
    });
  });
} 