import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/crypto/keys.pb.dart';

void main() {
  group('PublicKey Tests', () {
    test('should create empty PublicKey', () {
      final publicKey = PublicKey();
      expect(publicKey.whichSum(), PublicKey_Sum.notSet);
      expect(publicKey.hasEd25519(), false);
      expect(publicKey.hasSecp256k1(), false);
    });

    test('should create PublicKey with Ed25519 key', () {
      final ed25519Key = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
                                            11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
                                            21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]);
      
      final publicKey = PublicKey(ed25519: ed25519Key);
      
      expect(publicKey.whichSum(), PublicKey_Sum.ed25519);
      expect(publicKey.hasEd25519(), true);
      expect(publicKey.hasSecp256k1(), false);
      expect(publicKey.ed25519, ed25519Key);
    });

    test('should create PublicKey with Secp256k1 key', () {
      final secp256k1Key = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
                                               11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
                                               21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]);
      
      final publicKey = PublicKey(secp256k1: secp256k1Key);
      
      expect(publicKey.whichSum(), PublicKey_Sum.secp256k1);
      expect(publicKey.hasSecp256k1(), true);
      expect(publicKey.hasEd25519(), false);
      expect(publicKey.secp256k1, secp256k1Key);
    });

    test('should set and get Ed25519 key', () {
      final publicKey = PublicKey();
      final ed25519Key = Uint8List.fromList([10, 20, 30, 40, 50]);
      
      publicKey.ed25519 = ed25519Key;
      
      expect(publicKey.hasEd25519(), true);
      expect(publicKey.ed25519, ed25519Key);
      expect(publicKey.whichSum(), PublicKey_Sum.ed25519);
    });

    test('should set and get Secp256k1 key', () {
      final publicKey = PublicKey();
      final secp256k1Key = Uint8List.fromList([100, 200, 50, 75, 125]);
      
      publicKey.secp256k1 = secp256k1Key;
      
      expect(publicKey.hasSecp256k1(), true);
      expect(publicKey.secp256k1, secp256k1Key);
      expect(publicKey.whichSum(), PublicKey_Sum.secp256k1);
    });

    test('should clear Ed25519 key', () {
      final publicKey = PublicKey();
      publicKey.ed25519 = Uint8List.fromList([1, 2, 3]);
      
      expect(publicKey.hasEd25519(), true);
      
      publicKey.clearEd25519();
      expect(publicKey.hasEd25519(), false);
      expect(publicKey.whichSum(), PublicKey_Sum.notSet);
    });

    test('should clear Secp256k1 key', () {
      final publicKey = PublicKey();
      publicKey.secp256k1 = Uint8List.fromList([1, 2, 3]);
      
      expect(publicKey.hasSecp256k1(), true);
      
      publicKey.clearSecp256k1();
      expect(publicKey.hasSecp256k1(), false);
      expect(publicKey.whichSum(), PublicKey_Sum.notSet);
    });

    test('should clear sum field', () {
      final publicKey = PublicKey();
      publicKey.ed25519 = Uint8List.fromList([1, 2, 3]);
      
      expect(publicKey.whichSum(), PublicKey_Sum.ed25519);
      
      publicKey.clearSum();
      expect(publicKey.whichSum(), PublicKey_Sum.notSet);
      expect(publicKey.hasEd25519(), false);
    });

    test('should clone PublicKey correctly', () {
      final originalKey = Uint8List.fromList([1, 2, 3, 4, 5]);
      final original = PublicKey(ed25519: originalKey);
      
      final cloned = original.clone();
      
      expect(cloned.hasEd25519(), true);
      expect(cloned.ed25519, originalKey);
      expect(cloned.whichSum(), PublicKey_Sum.ed25519);
    });

    test('should serialize to and from buffer', () {
      final originalKey = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final original = PublicKey(secp256k1: originalKey);
      
      final buffer = original.writeToBuffer();
      final deserialized = PublicKey.fromBuffer(buffer);
      
      expect(deserialized.hasSecp256k1(), true);
      expect(deserialized.secp256k1, originalKey);
      expect(deserialized.whichSum(), PublicKey_Sum.secp256k1);
    });

    test('should serialize to and from JSON', () {
      final originalKey = Uint8List.fromList([10, 20, 30, 40]);
      final original = PublicKey(ed25519: originalKey);
      
      final json = original.writeToJson();
      final deserialized = PublicKey.fromJson(json);
      
      expect(deserialized.hasEd25519(), true);
      expect(deserialized.ed25519, originalKey);
      expect(deserialized.whichSum(), PublicKey_Sum.ed25519);
    });

    test('should handle copyWith correctly', () {
      final original = PublicKey(ed25519: Uint8List.fromList([1, 2, 3]));
      
      final modified = original.copyWith((pk) {
        pk.clearEd25519();
        pk.secp256k1 = Uint8List.fromList([4, 5, 6]);
      });
      
      expect(modified.hasSecp256k1(), true);
      expect(modified.hasEd25519(), false);
      expect(modified.secp256k1, [4, 5, 6]);
      expect(modified.whichSum(), PublicKey_Sum.secp256k1);
    });

    test('should return correct default instance', () {
      final defaultInstance = PublicKey.getDefault();
      
      expect(defaultInstance, isNotNull);
      expect(defaultInstance.whichSum(), PublicKey_Sum.notSet);
      expect(defaultInstance.hasEd25519(), false);
      expect(defaultInstance.hasSecp256k1(), false);
    });

    test('should create repeated list', () {
      final list = PublicKey.createRepeated();
      
      expect(list, isNotNull);
      expect(list.isEmpty, true);
      
      list.add(PublicKey(ed25519: Uint8List.fromList([1, 2, 3])));
      expect(list.length, 1);
    });

    test('should handle switching between key types', () {
      final publicKey = PublicKey();
      
      // First set Ed25519
      publicKey.ed25519 = Uint8List.fromList([1, 2, 3]);
      expect(publicKey.whichSum(), PublicKey_Sum.ed25519);
      expect(publicKey.hasEd25519(), true);
      expect(publicKey.hasSecp256k1(), false);
      
      // Then switch to Secp256k1
      publicKey.secp256k1 = Uint8List.fromList([4, 5, 6]);
      expect(publicKey.whichSum(), PublicKey_Sum.secp256k1);
      expect(publicKey.hasSecp256k1(), true);
      expect(publicKey.hasEd25519(), false);
    });
  });

  group('PublicKey_Sum Enum Tests', () {
    test('should have correct enum values', () {
      expect(PublicKey_Sum.ed25519.index, 0);
      expect(PublicKey_Sum.secp256k1.index, 1);
      expect(PublicKey_Sum.notSet.index, 2);
    });

    test('should convert enum values to string', () {
      expect(PublicKey_Sum.ed25519.toString(), 'PublicKey_Sum.ed25519');
      expect(PublicKey_Sum.secp256k1.toString(), 'PublicKey_Sum.secp256k1');
      expect(PublicKey_Sum.notSet.toString(), 'PublicKey_Sum.notSet');
    });
  });
} 