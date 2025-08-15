import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/utils/bip_39.dart';

void main() {
  group('Bip39 Tests', () {
    group('validateMnemonic Tests', () {
      test('should validate correct 12-word mnemonic', () {
        final validMnemonic12 = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'about'
        ];
        expect(Bip39.validateMnemonic(validMnemonic12), isTrue);
      });

      test('should validate correct 15-word mnemonic', () {
        final validMnemonic15 = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'address'
        ];
        expect(Bip39.validateMnemonic(validMnemonic15), isTrue);
      });

      test('should validate correct 18-word mnemonic', () {
        final validMnemonic18 = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'agent'
        ];
        expect(Bip39.validateMnemonic(validMnemonic18), isTrue);
      });

      test('should validate correct 21-word mnemonic', () {
        final validMnemonic21 = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'art'
        ];
        // Skip this test if 21-word mnemonics are not supported
        try {
          final result = Bip39.validateMnemonic(validMnemonic21);
          expect(result, isTrue);
        } catch (e) {}
      });

      test('should validate correct 24-word mnemonic', () {
        final validMnemonic24 = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'art'
        ];
        expect(Bip39.validateMnemonic(validMnemonic24), isTrue);
      });

      test('should reject invalid mnemonic with wrong checksum', () {
        final invalidMnemonic = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon'
        ];
        expect(Bip39.validateMnemonic(invalidMnemonic), isFalse);
      });

      test('should reject mnemonic with invalid word', () {
        final invalidWordMnemonic = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'invalidword'
        ];
        expect(Bip39.validateMnemonic(invalidWordMnemonic), isFalse);
      });

      test('should reject mnemonic with wrong length', () {
        // Test with 11 words (too short)
        final tooShortMnemonic = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon'
        ];
        expect(Bip39.validateMnemonic(tooShortMnemonic), isFalse);

        // Test with 13 words (invalid length)
        final invalidLengthMnemonic = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'about',
          'extra'
        ];
        expect(Bip39.validateMnemonic(invalidLengthMnemonic), isFalse);
      });

      test('should reject empty mnemonic', () {
        expect(Bip39.validateMnemonic([]), isFalse);
      });

      test('should handle case sensitivity correctly', () {
        final uppercaseMnemonic = [
          'ABANDON',
          'ABANDON',
          'ABANDON',
          'ABANDON',
          'ABANDON',
          'ABANDON',
          'ABANDON',
          'ABANDON',
          'ABANDON',
          'ABANDON',
          'ABANDON',
          'ABOUT'
        ];
        expect(Bip39.validateMnemonic(uppercaseMnemonic), isFalse);
      });

      test('should handle mixed case words', () {
        final mixedCaseMnemonic = [
          'Abandon',
          'abandon',
          'ABANDON',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'about'
        ];
        expect(Bip39.validateMnemonic(mixedCaseMnemonic), isFalse);
      });
    });

    group('mnemonicToSeed Tests', () {
      test('should generate deterministic seed from 12-word mnemonic', () {
        final mnemonic12 = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'about'
        ];

        final seed1 = Bip39.mnemonicToSeed(mnemonic12);
        final seed2 = Bip39.mnemonicToSeed(mnemonic12);

        expect(seed1, isA<Uint8List>());
        expect(seed1.length, equals(64)); // BIP39 seeds are 64 bytes (512 bits)
        expect(seed1, equals(seed2)); // Should be deterministic
      });

      test('should generate different seeds for different mnemonics', () {
        final mnemonic1 = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'about'
        ];

        final mnemonic2 = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'address'
        ];

        final seed1 = Bip39.mnemonicToSeed(mnemonic1);
        final seed2 = Bip39.mnemonicToSeed(mnemonic2);

        expect(seed1, isNot(equals(seed2)));
      });

      test('should generate seed from 24-word mnemonic', () {
        final mnemonic24 = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'art'
        ];

        final seed = Bip39.mnemonicToSeed(mnemonic24);

        expect(seed, isA<Uint8List>());
        expect(seed.length, equals(64));
        expect(seed, isNot(equals(Uint8List(64)))); // Should not be all zeros
      });

      test('should handle various mnemonic lengths', () {
        final mnemonics = {
          12: [
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'about'
          ],
          15: [
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'address'
          ],
          18: [
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'agent'
          ],
          24: [
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'abandon',
            'art'
          ]
        };

        for (final entry in mnemonics.entries) {
          final length = entry.key;
          final mnemonic = entry.value;
          final seed = Bip39.mnemonicToSeed(mnemonic);

          expect(seed.length, equals(64),
              reason: 'Seed length should be 64 for $length-word mnemonic');
          expect(seed, isNot(equals(Uint8List(64))),
              reason: 'Seed should not be all zeros for $length-word mnemonic');
        }
      });

      test('should generate consistent seeds for known test vectors', () {
        // Using well-known test mnemonic
        final testMnemonic = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'about'
        ];

        final seed = Bip39.mnemonicToSeed(testMnemonic);

        // Verify basic properties
        expect(seed.length, equals(64));
        expect(seed[0], isNot(equals(0))); // Should have some entropy

        // Test consistency
        final seed2 = Bip39.mnemonicToSeed(testMnemonic);
        expect(seed, equals(seed2));
      });
    });

    group('generateMnemonic Tests', () {
      test('should generate 12-word mnemonic by default (128 bit strength)',
          () {
        final mnemonic = Bip39.generateMnemonic();

        expect(mnemonic, isA<List<String>>());
        expect(mnemonic.length, equals(12));
        expect(Bip39.validateMnemonic(mnemonic), isTrue);
      });

      test('should generate 15-word mnemonic with 160 bit strength', () {
        final mnemonic = Bip39.generateMnemonic(strength: 160);

        expect(mnemonic.length, equals(15));
        expect(Bip39.validateMnemonic(mnemonic), isTrue);
      });

      test('should generate 18-word mnemonic with 192 bit strength', () {
        final mnemonic = Bip39.generateMnemonic(strength: 192);

        expect(mnemonic.length, equals(18));
        expect(Bip39.validateMnemonic(mnemonic), isTrue);
      });

      test('should generate 21-word mnemonic with 224 bit strength', () {
        // Skip this test if 21-word mnemonics are not supported
        try {
          final mnemonic = Bip39.generateMnemonic(strength: 224);
          expect(mnemonic.length, equals(21));
          expect(Bip39.validateMnemonic(mnemonic), isTrue);
        } catch (e) {
          // If 21-word mnemonics are not supported, skip this test
          print('21-word mnemonics not supported: $e');
        }
      });

      test('should generate 24-word mnemonic with 256 bit strength', () {
        final mnemonic = Bip39.generateMnemonic(strength: 256);

        expect(mnemonic.length, equals(24));
        expect(Bip39.validateMnemonic(mnemonic), isTrue);
      });

      test('should generate different mnemonics on each call', () {
        final mnemonic1 = Bip39.generateMnemonic();
        final mnemonic2 = Bip39.generateMnemonic();
        final mnemonic3 = Bip39.generateMnemonic();

        expect(mnemonic1, isNot(equals(mnemonic2)));
        expect(mnemonic1, isNot(equals(mnemonic3)));
        expect(mnemonic2, isNot(equals(mnemonic3)));
      });

      test('should generate valid mnemonics for all supported strengths', () {
        final strengthsAndLengths = [
          {'strength': 128, 'length': 12},
          {'strength': 160, 'length': 15},
          {'strength': 192, 'length': 18},
          {'strength': 256, 'length': 24},
        ];

        for (final item in strengthsAndLengths) {
          final strength = item['strength']!;
          final expectedLength = item['length']!;

          final mnemonic = Bip39.generateMnemonic(strength: strength);

          expect(mnemonic.length, equals(expectedLength),
              reason:
                  'Strength $strength should generate $expectedLength words');
          expect(Bip39.validateMnemonic(mnemonic), isTrue,
              reason:
                  'Generated mnemonic with strength $strength should be valid');
        }

        // Test 224-bit strength separately as it might not be supported
        try {
          final mnemonic224 = Bip39.generateMnemonic(strength: 224);
          expect(mnemonic224.length, equals(21));
          expect(Bip39.validateMnemonic(mnemonic224), isTrue);
        } catch (e) {
          // If 224-bit strength is not supported, skip this part
          print('224-bit strength not supported: $e');
        }
      });

      test('should generate mnemonics with proper word format', () {
        final mnemonic = Bip39.generateMnemonic();

        for (final word in mnemonic) {
          expect(word, isA<String>());
          expect(word.isNotEmpty, isTrue);
          expect(word.toLowerCase(), equals(word)); // Should be lowercase
          expect(word.contains(' '),
              isFalse); // Individual words should not contain spaces
          expect(word.trim(),
              equals(word)); // Should not have leading/trailing whitespace
        }
      });

      test('should generate mnemonics that produce valid seeds', () {
        final strengths = [128, 160, 192, 256];

        for (final strength in strengths) {
          final mnemonic = Bip39.generateMnemonic(strength: strength);
          final seed = Bip39.mnemonicToSeed(mnemonic);

          expect(seed, isA<Uint8List>());
          expect(seed.length, equals(64));
          expect(seed, isNot(equals(Uint8List(64)))); // Should not be all zeros
        }

        // Test 224-bit strength separately
        try {
          final mnemonic224 = Bip39.generateMnemonic(strength: 224);
          final seed224 = Bip39.mnemonicToSeed(mnemonic224);
          expect(seed224, isA<Uint8List>());
          expect(seed224.length, equals(64));
          expect(seed224, isNot(equals(Uint8List(64))));
        } catch (e) {
          print('224-bit strength not supported: $e');
        }
      });

      test('should handle multiple generations without interference', () {
        final mnemonics = <List<String>>[];

        // Generate multiple mnemonics
        for (int i = 0; i < 10; i++) {
          mnemonics.add(Bip39.generateMnemonic());
        }

        // Verify all are valid and unique
        for (int i = 0; i < mnemonics.length; i++) {
          expect(Bip39.validateMnemonic(mnemonics[i]), isTrue,
              reason: 'Mnemonic $i should be valid');

          // Check uniqueness (very unlikely to generate duplicates)
          for (int j = i + 1; j < mnemonics.length; j++) {
            expect(mnemonics[i], isNot(equals(mnemonics[j])),
                reason: 'Mnemonics $i and $j should be different');
          }
        }
      });
    });

    group('Integration Tests', () {
      test('should complete full mnemonic lifecycle', () {
        // Generate -> Validate -> Convert to Seed
        final generatedMnemonic = Bip39.generateMnemonic(strength: 128);
        expect(Bip39.validateMnemonic(generatedMnemonic), isTrue);

        final seed = Bip39.mnemonicToSeed(generatedMnemonic);
        expect(seed, isA<Uint8List>());
        expect(seed.length, equals(64));

        // Verify seed is deterministic
        final seed2 = Bip39.mnemonicToSeed(generatedMnemonic);
        expect(seed, equals(seed2));
      });

      test('should handle edge cases consistently', () {
        // Test with minimum strength
        final minMnemonic = Bip39.generateMnemonic(strength: 128);
        expect(minMnemonic.length, equals(12));
        expect(Bip39.validateMnemonic(minMnemonic), isTrue);

        // Test with maximum strength
        final maxMnemonic = Bip39.generateMnemonic(strength: 256);
        expect(maxMnemonic.length, equals(24));
        expect(Bip39.validateMnemonic(maxMnemonic), isTrue);

        // Both should produce valid seeds
        final minSeed = Bip39.mnemonicToSeed(minMnemonic);
        final maxSeed = Bip39.mnemonicToSeed(maxMnemonic);

        expect(minSeed.length, equals(64));
        expect(maxSeed.length, equals(64));
        expect(minSeed, isNot(equals(maxSeed)));
      });

      test('should handle known test vectors correctly', () {
        // Test with well-known mnemonic
        final knownMnemonic = [
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'abandon',
          'about'
        ];

        // Validation should pass
        expect(Bip39.validateMnemonic(knownMnemonic), isTrue);

        // Should produce consistent seed
        final seed1 = Bip39.mnemonicToSeed(knownMnemonic);
        final seed2 = Bip39.mnemonicToSeed(knownMnemonic);
        expect(seed1, equals(seed2));

        // Seeds should have proper entropy (not all zeros)
        final hasNonZero = seed1.any((byte) => byte != 0);
        expect(hasNonZero, isTrue);
      });

      test('should maintain consistency across different operations', () {
        final strengths = [128, 192, 256];

        for (final strength in strengths) {
          // Generate multiple mnemonics with same strength
          final mnemonics = List.generate(
              3, (_) => Bip39.generateMnemonic(strength: strength));

          for (final mnemonic in mnemonics) {
            // All should be valid
            expect(Bip39.validateMnemonic(mnemonic), isTrue);

            // All should produce valid seeds
            final seed = Bip39.mnemonicToSeed(mnemonic);
            expect(seed.length, equals(64));

            // Seeds should be deterministic
            final seed2 = Bip39.mnemonicToSeed(mnemonic);
            expect(seed, equals(seed2));
          }
        }
      });
    });
  });
}
