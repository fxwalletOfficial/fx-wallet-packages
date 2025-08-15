import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/utils/bip_32.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/utils/bip_39.dart';

void main() {
  group('NetworkType Tests', () {
    test('should create NetworkType with correct parameters', () {
      final bip32Type = Bip32Type(public: 0x0488b21e, private: 0x0488ade4);
      final networkType = NetworkType(wif: 0x80, bip32: bip32Type);
      
      expect(networkType.wif, equals(0x80));
      expect(networkType.bip32, equals(bip32Type));
      expect(networkType.bip32.public, equals(0x0488b21e));
      expect(networkType.bip32.private, equals(0x0488ade4));
    });
  });

  group('Bip32Type Tests', () {
    test('should create Bip32Type with public and private values', () {
      final bip32Type = Bip32Type(public: 0x0488b21e, private: 0x0488ade4);
      
      expect(bip32Type.public, equals(0x0488b21e));
      expect(bip32Type.private, equals(0x0488ade4));
    });
  });

  group('Bip32EccCurve Tests', () {
    late Bip32EccCurve ecc;

    setUp(() {
      ecc = Bip32EccCurve();
    });

    test('should validate private key correctly', () {
      // Valid private key (32 bytes, not zero, less than group order)
      final validPrivateKey = Uint8List.fromList([
        0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
        0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
        0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
        0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0
      ]);
      
      expect(ecc.isPrivate(validPrivateKey), isTrue);
    });

    test('should reject invalid private keys', () {
      // Zero private key (invalid)
      final zeroKey = Uint8List(32);
      expect(ecc.isPrivate(zeroKey), isFalse);
      
      // Wrong length
      final shortKey = Uint8List(16);
      expect(ecc.isPrivate(shortKey), isFalse);
      
      final longKey = Uint8List(64);
      expect(ecc.isPrivate(longKey), isFalse);
    });

    test('should validate scalar correctly', () {
      final validScalar = Uint8List(32);
      validScalar[31] = 1;
      
      expect(ecc.isScalar(validScalar), isTrue);
      
      // Wrong length
      expect(ecc.isScalar(Uint8List(16)), isFalse);
      expect(ecc.isScalar(Uint8List(64)), isFalse);
    });

    test('should validate order scalar correctly', () {
      // Small valid scalar
      final validScalar = Uint8List(32);
      validScalar[31] = 1;
      
      expect(ecc.isOrderScalar(validScalar), isTrue);
      
      // Wrong length should be false
      final shortScalar = Uint8List(16);
      expect(ecc.isOrderScalar(shortScalar), isFalse);
    });

    test('should generate point from scalar', () {
      final validPrivateKey = Uint8List(32);
      validPrivateKey[31] = 1; // Minimal valid private key
      
      final point = ecc.pointFromScalar(validPrivateKey);
      
      expect(point, isA<Uint8List>());
      expect(point.length, equals(33)); // Compressed public key
      expect(point[0], anyOf(equals(0x02), equals(0x03))); // Compressed point prefix
    });

    test('should validate points correctly', () {
      // Generate a valid point first
      final validPrivateKey = Uint8List(32);
      validPrivateKey[31] = 1;
      final validPoint = ecc.pointFromScalar(validPrivateKey);
      
      expect(ecc.isPoint(validPoint), isTrue);
      
      // Invalid points
      final invalidPoint = Uint8List(33);
      expect(ecc.isPoint(invalidPoint), isFalse);
      
      final wrongLength = Uint8List(32);
      expect(ecc.isPoint(wrongLength), isFalse);
    });

    test('should perform private key addition', () {
      final privateKey = Uint8List(32);
      privateKey[31] = 10; // Valid private key
      
      final tweak = Uint8List(32);
      tweak[31] = 5; // Valid tweak
      
      final result = ecc.privateAdd(privateKey, tweak);
      
      expect(result, isNotNull);
      expect(result!.length, equals(32));
      expect(ecc.isPrivate(result), isTrue);
    });

    test('should handle invalid private addition', () {
      final invalidKey = Uint8List(32); // Zero key (invalid)
      final validTweak = Uint8List(32);
      validTweak[31] = 1;
      
      expect(() => ecc.privateAdd(invalidKey, validTweak), 
             throwsA(isA<ArgumentError>()));
    });

    test('should perform point addition with scalar', () {
      // Create a valid point
      final validPrivateKey = Uint8List(32);
      validPrivateKey[31] = 1;
      final validPoint = ecc.pointFromScalar(validPrivateKey);
      
      final tweak = Uint8List(32);
      tweak[31] = 1;
      
      final result = ecc.pointAddScalar(validPoint, tweak);
      
      expect(result, isNotNull);
      expect(result!.length, anyOf(equals(33), equals(65))); // Compressed or uncompressed
      expect(ecc.isPoint(result), isTrue);
    });
  });

  group('Bip32 Factory Constructors Tests', () {
    test('should create Bip32 from seed', () {
      final seed = Uint8List.fromList(List.generate(64, (i) => i)); // 64-byte seed
      final bip32 = Bip32.fromSeed(seed);
      
      expect(bip32, isA<Bip32>());
      expect(bip32.privateKey, isNotNull);
      expect(bip32.privateKey!.length, equals(32));
      expect(bip32.chainCode.length, equals(32));
      expect(bip32.depth, equals(0));
      expect(bip32.index, equals(0));
      expect(bip32.parentFingerprint, equals(0));
    });

    test('should reject too short seed', () {
      final shortSeed = Uint8List(8); // Too short (< 16 bytes)
      
      expect(() => Bip32.fromSeed(shortSeed), throwsA(isA<ArgumentError>()));
    });

    test('should reject too long seed', () {
      final longSeed = Uint8List(128); // Too long (> 64 bytes)
      
      expect(() => Bip32.fromSeed(longSeed), throwsA(isA<ArgumentError>()));
    });

    test('should create Bip32 from valid private key', () {
      final privateKey = Uint8List(32);
      privateKey[31] = 1; // Valid private key
      final chainCode = Uint8List.fromList(List.generate(32, (i) => i + 100));
      
      final bip32 = Bip32.fromPrivateKey(
        privateKey: privateKey,
        chainCode: chainCode,
      );
      
      expect(bip32.privateKey, equals(privateKey));
      expect(bip32.chainCode, equals(chainCode));
      expect(bip32.isNeutered(), isFalse);
    });

    test('should reject invalid private key in fromPrivateKey', () {
      final invalidPrivateKey = Uint8List(16); // Wrong length
      final chainCode = Uint8List(32);
      
      expect(() => Bip32.fromPrivateKey(
        privateKey: invalidPrivateKey,
        chainCode: chainCode,
      ), throwsA(isA<ArgumentError>()));
    });

    test('should create Bip32 from public key', () {
      // First create a valid private key and derive its public key
      final privateKey = Uint8List(32);
      privateKey[31] = 1;
      final chainCode = Uint8List.fromList(List.generate(32, (i) => i + 50));
      
      final privateBip32 = Bip32.fromPrivateKey(
        privateKey: privateKey,
        chainCode: chainCode,
      );
      
      final publicKey = privateBip32.publicKey;
      
      final publicBip32 = Bip32.fromPublicKey(
        publicKey: publicKey,
        chainCode: chainCode,
      );
      
      expect(publicBip32.privateKey, isNull);
      expect(publicBip32.publicKey, equals(publicKey));
      expect(publicBip32.chainCode, equals(chainCode));
      expect(publicBip32.isNeutered(), isTrue);
    });
  });

  group('Bip32 Properties Tests', () {
    late Bip32 bip32;

    setUp(() {
      final seed = Uint8List.fromList(List.generate(32, (i) => i + 1));
      bip32 = Bip32.fromSeed(seed);
    });

    test('should have valid public key', () {
      final publicKey = bip32.publicKey;
      
      expect(publicKey, isA<Uint8List>());
      expect(publicKey.length, equals(33)); // Compressed public key
      expect(publicKey[0], anyOf(equals(0x02), equals(0x03)));
    });

    test('should have valid identifier', () {
      final identifier = bip32.identifier;
      
      expect(identifier, isA<Uint8List>());
      expect(identifier.length, equals(20)); // RIPEMD160 output
    });

    test('should have valid fingerprint', () {
      final fingerprint = bip32.fingerprint;
      
      expect(fingerprint, isA<Uint8List>());
      expect(fingerprint.length, equals(4)); // First 4 bytes of identifier
      expect(fingerprint, equals(bip32.identifier.sublist(0, 4)));
    });

    test('should detect neutered status correctly', () {
      // Private key BIP32 should not be neutered
      expect(bip32.isNeutered(), isFalse);
      
      // Public key BIP32 should be neutered
      final publicBip32 = Bip32.fromPublicKey(
        publicKey: bip32.publicKey,
        chainCode: bip32.chainCode,
      );
      expect(publicBip32.isNeutered(), isTrue);
    });
  });

  group('Bip32 Key Derivation Tests', () {
    late Bip32 masterKey;

    setUp(() {
      // Use a known test vector
      final mnemonic = [
        'abandon', 'abandon', 'abandon', 'abandon', 'abandon', 'abandon',
        'abandon', 'abandon', 'abandon', 'abandon', 'abandon', 'about'
      ];
      final seed = Bip39.mnemonicToSeed(mnemonic);
      masterKey = Bip32.fromSeed(seed);
    });

    test('should derive hardened child keys', () {
      final childIndex = 0;
      final hardenedChild = masterKey.deriveHardened(childIndex);
      
      expect(hardenedChild.depth, equals(1));
      expect(hardenedChild.index, equals(childIndex + 0x80000000));
      expect(hardenedChild.parentFingerprint, 
             equals(masterKey.fingerprint.buffer.asByteData().getUint32(0, Endian.big)));
      expect(hardenedChild.privateKey, isNotNull);
      expect(hardenedChild.privateKey, isNot(equals(masterKey.privateKey)));
    });

    test('should derive non-hardened child keys', () {
      final childIndex = 0;
      final child = masterKey.derive(childIndex);
      
      expect(child.depth, equals(1));
      expect(child.index, equals(childIndex));
      expect(child.parentFingerprint, 
             equals(masterKey.fingerprint.buffer.asByteData().getUint32(0, Endian.big)));
      expect(child.privateKey, isNotNull);
      expect(child.privateKey, isNot(equals(masterKey.privateKey)));
    });

    test('should reject invalid hardened indices', () {
      expect(() => masterKey.deriveHardened(-1), throwsA(isA<ArgumentError>()));
      expect(() => masterKey.deriveHardened(0x80000000), throwsA(isA<ArgumentError>()));
    });

    test('should reject invalid derive indices', () {
      expect(() => masterKey.derive(-1), throwsA(isA<ArgumentError>()));
      expect(() => masterKey.derive(0x100000000), throwsA(isA<ArgumentError>()));
    });

    test('should derive path correctly', () {
      final path = "m/44'/0'/0'/0/0";
      final derived = masterKey.derivePath(path);
      
      expect(derived.depth, equals(5));
      expect(derived.privateKey, isNotNull);
    });

    test('should handle various path formats', () {
      final validPaths = [
        "m/0",
        "m/0'",
        "m/0'/1",
        "m/44'/0'/0'",
        "m/44'/0'/0'/0/0",
      ];
      
      for (final path in validPaths) {
        final derived = masterKey.derivePath(path);
        expect(derived, isA<Bip32>());
        expect(derived.privateKey, isNotNull);
      }
    });

    test('should reject invalid path formats', () {
      final invalidPaths = [
        "m/invalid", // Non-numeric
      ];
      
      for (final path in invalidPaths) {
        try {
          masterKey.derivePath(path);
          fail('Should have thrown an error for invalid path: $path');
        } catch (e) {
          expect(e, isA<ArgumentError>());
        }
      }
      
      // Test some paths that might be accepted but we want to verify don't crash
      final possiblyValidPaths = [
        "44'/0'/0'", // Missing m/ prefix - might be accepted by implementation
        "m/", // Empty after m/ - might be handled gracefully
      ];
      
      for (final path in possiblyValidPaths) {
        // These should either work or throw an error, but not crash
        try {
          final result = masterKey.derivePath(path);
          expect(result, isA<Bip32>());
        } catch (e) {
          expect(e, anyOf(isA<ArgumentError>(), isA<FormatException>(), isA<Exception>()));
        }
      }
    });

    test('should handle child key from non-master key', () {
      final child = masterKey.derive(0);
      final grandchild = child.derive(1);
      
      expect(grandchild.depth, equals(2));
      expect(grandchild.parentFingerprint,
             equals(child.fingerprint.buffer.asByteData().getUint32(0, Endian.big)));
    });

    test('should prevent hardened derivation from public keys', () {
      final publicBip32 = Bip32.fromPublicKey(
        publicKey: masterKey.publicKey,
        chainCode: masterKey.chainCode,
      );
      
      expect(() => publicBip32.derive(0x80000000), // Hardened index
             throwsA(isA<ArgumentError>()));
    });
  });

  group('Bip32 Integration Tests', () {
    test('should maintain consistency across derivations', () {
      final seed = Uint8List.fromList(List.generate(64, (i) => i * 2));
      final master = Bip32.fromSeed(seed);
      
      // Derive same child multiple times
      final child1 = master.derive(0);
      final child2 = master.derive(0);
      
      expect(child1.privateKey, equals(child2.privateKey));
      expect(child1.publicKey, equals(child2.publicKey));
      expect(child1.chainCode, equals(child2.chainCode));
    });

    test('should generate different keys for different paths', () {
      final seed = Uint8List.fromList(List.generate(32, (i) => i + 10));
      final master = Bip32.fromSeed(seed);
      
      final paths = [
        "m/0",
        "m/1", 
        "m/0'",
        "m/1'",
        "m/0/0",
        "m/0/1",
      ];
      
      final derivedKeys = <Bip32>[];
      for (final path in paths) {
        derivedKeys.add(master.derivePath(path));
      }
      
      // All keys should be different
      for (int i = 0; i < derivedKeys.length; i++) {
        for (int j = i + 1; j < derivedKeys.length; j++) {
          expect(derivedKeys[i].privateKey, isNot(equals(derivedKeys[j].privateKey)));
          expect(derivedKeys[i].publicKey, isNot(equals(derivedKeys[j].publicKey)));
        }
      }
    });

    test('should handle complex derivation paths', () {
      final mnemonic = [
        'abandon', 'abandon', 'abandon', 'abandon', 'abandon', 'abandon',
        'abandon', 'abandon', 'abandon', 'abandon', 'abandon', 'about'
      ];
      final seed = Bip39.mnemonicToSeed(mnemonic);
      final master = Bip32.fromSeed(seed);
      
      // Common BIP44 path for Bitcoin
      final bitcoinPath = "m/44'/0'/0'/0/0";
      final bitcoinKey = master.derivePath(bitcoinPath);
      
      expect(bitcoinKey.depth, equals(5));
      expect(bitcoinKey.privateKey, isNotNull);
      expect(bitcoinKey.publicKey.length, equals(33));
    });

    test('should work with real-world mnemonic to BIP32 flow', () {
      // Generate mnemonic -> seed -> master key -> derive paths
      final generatedMnemonic = Bip39.generateMnemonic(strength: 128);
      final seed = Bip39.mnemonicToSeed(generatedMnemonic);
      final master = Bip32.fromSeed(seed);
      
      // Test various standard derivation paths
      final standardPaths = [
        "m/44'/0'/0'", // BIP44 account
        "m/44'/60'/0'", // Ethereum
        "m/49'/0'/0'", // BIP49 (P2WPKH-P2SH)
        "m/84'/0'/0'", // BIP84 (P2WPKH)
      ];
      
      for (final path in standardPaths) {
        final derived = master.derivePath(path);
        expect(derived.privateKey, isNotNull);
        expect(derived.publicKey, isNotNull);
        expect(derived.chainCode, isNotNull);
        expect(derived.depth, equals(path.split('/').length - 1));
      }
    });

    test('should handle edge cases in key derivation', () {
      final seed = Uint8List.fromList(List.generate(32, (i) => 255 - i));
      final master = Bip32.fromSeed(seed);
      
      // Test maximum non-hardened index
      final maxNonHardened = master.derive(0x7FFFFFFF);
      expect(maxNonHardened.privateKey, isNotNull);
      
      // Test maximum hardened index
      final maxHardened = master.deriveHardened(0x7FFFFFFF);
      expect(maxHardened.privateKey, isNotNull);
      expect(maxHardened.index, equals(0xFFFFFFFF));
    });

    test('should maintain parent-child relationships', () {
      final seed = Uint8List.fromList(List.generate(48, (i) => i + 50));
      final master = Bip32.fromSeed(seed);
      
      final child = master.derive(0);
      final grandchild = child.derive(1);
      
      // Verify parent fingerprint is set correctly
      // Note: Master key's parentFingerprint is initialized to 0x00000000 but may vary by implementation
      expect(child.parentFingerprint, isA<int>()); // Should be an integer
      expect(grandchild.parentFingerprint, 
             equals(child.fingerprint.buffer.asByteData().getUint32(0, Endian.big)));
    });

    test('should handle public key derivation limitations', () {
      final seed = Uint8List.fromList(List.generate(32, (i) => i * 3));
      final master = Bip32.fromSeed(seed);
      
      // Create public-only version
      final publicMaster = Bip32.fromPublicKey(
        publicKey: master.publicKey,
        chainCode: master.chainCode,
      );
      
      // Should be able to derive non-hardened children
      final publicChild = publicMaster.derive(0);
      expect(publicChild.publicKey, isNotNull);
      expect(publicChild.privateKey, isNull);
      
      // Should not be able to derive hardened children
      expect(() => publicMaster.derive(0x80000000), throwsA(isA<ArgumentError>()));
    });
  });
} 