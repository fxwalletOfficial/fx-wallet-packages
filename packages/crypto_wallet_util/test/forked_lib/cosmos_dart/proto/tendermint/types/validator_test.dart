import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/types/validator.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/crypto/keys.pb.dart' as crypto;

void main() {
  group('ValidatorSet Tests', () {
    test('should create empty ValidatorSet', () {
      final validatorSet = ValidatorSet();
      
      expect(validatorSet.validators.isEmpty, true);
      expect(validatorSet.hasProposer(), false);
      expect(validatorSet.hasTotalVotingPower(), false);
    });

    test('should create ValidatorSet with validators and proposer', () {
      final pubKey1 = crypto.PublicKey(ed25519: Uint8List.fromList(List.filled(32, 1)));
      final pubKey2 = crypto.PublicKey(secp256k1: Uint8List.fromList(List.filled(33, 2)));
      
      final validator1 = Validator(
        address: Uint8List.fromList(List.filled(20, 10)),
        pubKey: pubKey1,
        votingPower: Int64(1000),
        proposerPriority: Int64(0),
      );
      
      final validator2 = Validator(
        address: Uint8List.fromList(List.filled(20, 20)),
        pubKey: pubKey2,
        votingPower: Int64(2000),
        proposerPriority: Int64(1000),
      );
      
      final validatorSet = ValidatorSet(
        validators: [validator1, validator2],
        proposer: validator1,
        totalVotingPower: Int64(3000),
      );
      
      expect(validatorSet.validators.length, 2);
      expect(validatorSet.hasProposer(), true);
      expect(validatorSet.hasTotalVotingPower(), true);
      expect(validatorSet.proposer.votingPower, Int64(1000));
      expect(validatorSet.totalVotingPower, Int64(3000));
    });

    test('should add validators to ValidatorSet', () {
      final validatorSet = ValidatorSet();
      
      final validator = Validator(
        address: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]),
        pubKey: crypto.PublicKey(ed25519: Uint8List.fromList(List.filled(32, 50))),
        votingPower: Int64(5000),
      );
      
      validatorSet.validators.add(validator);
      
      expect(validatorSet.validators.length, 1);
      expect(validatorSet.validators[0].votingPower, Int64(5000));
    });

    test('should set and clear ValidatorSet fields', () {
      final validatorSet = ValidatorSet(
        proposer: Validator(votingPower: Int64(100)),
        totalVotingPower: Int64(500),
      );
      
      // Clear fields
      validatorSet.clearProposer();
      validatorSet.clearTotalVotingPower();
      
      expect(validatorSet.hasProposer(), false);
      expect(validatorSet.hasTotalVotingPower(), false);
    });

    test('should ensure proposer field', () {
      final validatorSet = ValidatorSet();
      
      expect(validatorSet.hasProposer(), false);
      
      final ensuredProposer = validatorSet.ensureProposer();
      
      expect(validatorSet.hasProposer(), true);
      expect(ensuredProposer, isA<Validator>());
    });

    test('should serialize ValidatorSet to and from buffer', () {
      final original = ValidatorSet(
        validators: [
          Validator(
            address: Uint8List.fromList(List.filled(20, 1)),
            pubKey: crypto.PublicKey(ed25519: Uint8List.fromList(List.filled(32, 1))),
            votingPower: Int64(1000),
          ),
        ],
        totalVotingPower: Int64(1000),
      );
      
      final buffer = original.writeToBuffer();
      final deserialized = ValidatorSet.fromBuffer(buffer);
      
      expect(deserialized.validators.length, 1);
      expect(deserialized.validators[0].votingPower, Int64(1000));
      expect(deserialized.totalVotingPower, Int64(1000));
    });
  });

  group('Validator Tests', () {
    test('should create empty Validator', () {
      final validator = Validator();
      
      expect(validator.hasAddress(), false);
      expect(validator.hasPubKey(), false);
      expect(validator.hasVotingPower(), false);
      expect(validator.hasProposerPriority(), false);
    });

    test('should create Validator with all fields', () {
      final address = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
      final pubKey = crypto.PublicKey(ed25519: Uint8List.fromList(List.filled(32, 100)));
      
      final validator = Validator(
        address: address,
        pubKey: pubKey,
        votingPower: Int64(10000),
        proposerPriority: Int64(-5000),
      );
      
      expect(validator.hasAddress(), true);
      expect(validator.hasPubKey(), true);
      expect(validator.hasVotingPower(), true);
      expect(validator.hasProposerPriority(), true);
      expect(validator.address, address);
      expect(validator.votingPower, Int64(10000));
      expect(validator.proposerPriority, Int64(-5000));
    });

    test('should set and get Validator fields individually', () {
      final validator = Validator();
      
      // Set address
      final address = Uint8List.fromList(List.filled(20, 30));
      validator.address = address;
      expect(validator.hasAddress(), true);
      expect(validator.address, address);
      
      // Set pub key
      final pubKey = crypto.PublicKey(secp256k1: Uint8List.fromList(List.filled(33, 40)));
      validator.pubKey = pubKey;
      expect(validator.hasPubKey(), true);
      expect(validator.pubKey.hasSecp256k1(), true);
      
      // Set voting power
      validator.votingPower = Int64(25000);
      expect(validator.hasVotingPower(), true);
      expect(validator.votingPower, Int64(25000));
      
      // Set proposer priority
      validator.proposerPriority = Int64(7500);
      expect(validator.hasProposerPriority(), true);
      expect(validator.proposerPriority, Int64(7500));
    });

    test('should clear Validator fields', () {
      final validator = Validator(
        address: Uint8List.fromList(List.filled(20, 1)),
        pubKey: crypto.PublicKey(ed25519: Uint8List.fromList(List.filled(32, 1))),
        votingPower: Int64(1000),
        proposerPriority: Int64(0),
      );
      
      // Clear fields
      validator.clearAddress();
      validator.clearPubKey();
      validator.clearVotingPower();
      validator.clearProposerPriority();
      
      expect(validator.hasAddress(), false);
      expect(validator.hasPubKey(), false);
      expect(validator.hasVotingPower(), false);
      expect(validator.hasProposerPriority(), false);
    });

    test('should ensure pubKey field', () {
      final validator = Validator();
      
      expect(validator.hasPubKey(), false);
      
      final ensuredPubKey = validator.ensurePubKey();
      
      expect(validator.hasPubKey(), true);
      expect(ensuredPubKey, isA<crypto.PublicKey>());
    });

    test('should handle different key types', () {
      // Test Ed25519 key
      final ed25519Validator = Validator(
        pubKey: crypto.PublicKey(ed25519: Uint8List.fromList(List.filled(32, 1))),
        votingPower: Int64(1000),
      );
      
      expect(ed25519Validator.pubKey.hasEd25519(), true);
      expect(ed25519Validator.pubKey.hasSecp256k1(), false);
      
      // Test Secp256k1 key
      final secp256k1Validator = Validator(
        pubKey: crypto.PublicKey(secp256k1: Uint8List.fromList(List.filled(33, 2))),
        votingPower: Int64(2000),
      );
      
      expect(secp256k1Validator.pubKey.hasSecp256k1(), true);
      expect(secp256k1Validator.pubKey.hasEd25519(), false);
    });

    test('should serialize Validator to and from buffer', () {
      final original = Validator(
        address: Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200]),
        pubKey: crypto.PublicKey(ed25519: Uint8List.fromList(List.filled(32, 123))),
        votingPower: Int64(99999),
        proposerPriority: Int64(-12345),
      );
      
      final buffer = original.writeToBuffer();
      final deserialized = Validator.fromBuffer(buffer);
      
      expect(deserialized.address, original.address);
      expect(deserialized.votingPower, original.votingPower);
      expect(deserialized.proposerPriority, original.proposerPriority);
      expect(deserialized.pubKey.hasEd25519(), true);
      expect(deserialized.pubKey.ed25519.length, 32);
    });

    test('should clone Validator correctly', () {
      final original = Validator(
        address: Uint8List.fromList(List.filled(20, 255)),
        pubKey: crypto.PublicKey(secp256k1: Uint8List.fromList(List.filled(33, 128))),
        votingPower: Int64(50000),
      );
      
      final cloned = original.clone();
      
      expect(cloned.address, original.address);
      expect(cloned.votingPower, original.votingPower);
      expect(cloned.pubKey.hasSecp256k1(), true);
      expect(cloned.pubKey.secp256k1.length, 33);
    });
  });

  group('SimpleValidator Tests', () {
    test('should create empty SimpleValidator', () {
      final simpleValidator = SimpleValidator();
      
      expect(simpleValidator.hasPubKey(), false);
      expect(simpleValidator.hasVotingPower(), false);
    });

    test('should create SimpleValidator with fields', () {
      final pubKey = crypto.PublicKey(ed25519: Uint8List.fromList(List.filled(32, 200)));
      
      final simpleValidator = SimpleValidator(
        pubKey: pubKey,
        votingPower: Int64(75000),
      );
      
      expect(simpleValidator.hasPubKey(), true);
      expect(simpleValidator.hasVotingPower(), true);
      expect(simpleValidator.votingPower, Int64(75000));
      expect(simpleValidator.pubKey.hasEd25519(), true);
    });

    test('should set and get SimpleValidator fields', () {
      final simpleValidator = SimpleValidator();
      
      // Set pub key
      final pubKey = crypto.PublicKey(secp256k1: Uint8List.fromList(List.filled(33, 150)));
      simpleValidator.pubKey = pubKey;
      expect(simpleValidator.hasPubKey(), true);
      expect(simpleValidator.pubKey.hasSecp256k1(), true);
      
      // Set voting power
      simpleValidator.votingPower = Int64(33333);
      expect(simpleValidator.hasVotingPower(), true);
      expect(simpleValidator.votingPower, Int64(33333));
    });

    test('should clear SimpleValidator fields', () {
      final simpleValidator = SimpleValidator(
        pubKey: crypto.PublicKey(ed25519: Uint8List.fromList(List.filled(32, 1))),
        votingPower: Int64(1000),
      );
      
      // Clear fields
      simpleValidator.clearPubKey();
      simpleValidator.clearVotingPower();
      
      expect(simpleValidator.hasPubKey(), false);
      expect(simpleValidator.hasVotingPower(), false);
    });

    test('should ensure pubKey field', () {
      final simpleValidator = SimpleValidator();
      
      expect(simpleValidator.hasPubKey(), false);
      
      final ensuredPubKey = simpleValidator.ensurePubKey();
      
      expect(simpleValidator.hasPubKey(), true);
      expect(ensuredPubKey, isA<crypto.PublicKey>());
    });

    test('should serialize SimpleValidator to and from buffer', () {
      final original = SimpleValidator(
        pubKey: crypto.PublicKey(ed25519: Uint8List.fromList(List.filled(32, 88))),
        votingPower: Int64(88888),
      );
      
      final buffer = original.writeToBuffer();
      final deserialized = SimpleValidator.fromBuffer(buffer);
      
      expect(deserialized.votingPower, Int64(88888));
      expect(deserialized.pubKey.hasEd25519(), true);
      expect(deserialized.pubKey.ed25519, original.pubKey.ed25519);
    });

    test('should serialize SimpleValidator to and from JSON', () {
      final original = SimpleValidator(
        pubKey: crypto.PublicKey(secp256k1: Uint8List.fromList(List.filled(33, 77))),
        votingPower: Int64(77777),
      );
      
      final json = original.writeToJson();
      final deserialized = SimpleValidator.fromJson(json);
      
      expect(deserialized.votingPower, Int64(77777));
      expect(deserialized.pubKey.hasSecp256k1(), true);
      expect(deserialized.pubKey.secp256k1, original.pubKey.secp256k1);
    });
  });

  group('Integration Tests', () {
    test('should handle complete validator set scenarios', () {
      // Create a realistic validator set
      final validators = <Validator>[];
      
      // Add validators with different key types and voting powers
      for (int i = 0; i < 5; i++) {
        final pubKey = i % 2 == 0
          ? crypto.PublicKey(ed25519: Uint8List.fromList(List.filled(32, i * 10)))
          : crypto.PublicKey(secp256k1: Uint8List.fromList(List.filled(33, i * 10)));
          
        validators.add(Validator(
          address: Uint8List.fromList(List.filled(20, i)),
          pubKey: pubKey,
          votingPower: Int64(1000 * (i + 1)),
          proposerPriority: Int64(i * 100),
        ));
      }
      
      // Select proposer (validator with highest voting power)
      final proposer = validators.last; // Validator with 5000 voting power
      
      final totalVotingPower = Int64(validators.fold(0, (sum, v) => sum + v.votingPower.toInt()));
      
      final validatorSet = ValidatorSet(
        validators: validators,
        proposer: proposer,
        totalVotingPower: totalVotingPower,
      );
      
      // Verify the validator set
      expect(validatorSet.validators.length, 5);
      expect(validatorSet.proposer.votingPower, Int64(5000));
      expect(validatorSet.totalVotingPower, Int64(15000)); // 1000+2000+3000+4000+5000
      
      // Verify different key types
      expect(validatorSet.validators[0].pubKey.hasEd25519(), true);
      expect(validatorSet.validators[1].pubKey.hasSecp256k1(), true);
      expect(validatorSet.validators[2].pubKey.hasEd25519(), true);
      expect(validatorSet.validators[3].pubKey.hasSecp256k1(), true);
      expect(validatorSet.validators[4].pubKey.hasEd25519(), true);
      
      // Test serialization of complex structure
      final buffer = validatorSet.writeToBuffer();
      final deserialized = ValidatorSet.fromBuffer(buffer);
      
      expect(deserialized.validators.length, validatorSet.validators.length);
      expect(deserialized.totalVotingPower, validatorSet.totalVotingPower);
      expect(deserialized.proposer.votingPower, validatorSet.proposer.votingPower);
    });

    test('should convert between Validator and SimpleValidator', () {
      // Create a full Validator
      final fullValidator = Validator(
        address: Uint8List.fromList(List.filled(20, 99)),
        pubKey: crypto.PublicKey(ed25519: Uint8List.fromList(List.filled(32, 99))),
        votingPower: Int64(99000),
        proposerPriority: Int64(9900),
      );
      
      // Create equivalent SimpleValidator (only pubKey and votingPower)
      final simpleValidator = SimpleValidator(
        pubKey: fullValidator.pubKey,
        votingPower: fullValidator.votingPower,
      );
      
      // Verify they have the same key and voting power
      expect(simpleValidator.pubKey.ed25519, fullValidator.pubKey.ed25519);
      expect(simpleValidator.votingPower, fullValidator.votingPower);
      
      // But SimpleValidator doesn't have address or proposer priority
      expect(fullValidator.hasAddress(), true);
      expect(fullValidator.hasProposerPriority(), true);
    });

    test('should handle zero and negative voting powers', () {
      // Test zero voting power
      final zeroValidator = Validator(
        pubKey: crypto.PublicKey(ed25519: Uint8List.fromList(List.filled(32, 0))),
        votingPower: Int64.ZERO,
        proposerPriority: Int64.ZERO,
      );
      
      expect(zeroValidator.votingPower, Int64.ZERO);
      expect(zeroValidator.proposerPriority, Int64.ZERO);
      
      // Test negative proposer priority
      final negativeValidator = Validator(
        pubKey: crypto.PublicKey(secp256k1: Uint8List.fromList(List.filled(33, 1))),
        votingPower: Int64(1000),
        proposerPriority: Int64(-1000),
      );
      
      expect(negativeValidator.proposerPriority, Int64(-1000));
      expect(negativeValidator.votingPower, Int64(1000));
    });
  });
} 