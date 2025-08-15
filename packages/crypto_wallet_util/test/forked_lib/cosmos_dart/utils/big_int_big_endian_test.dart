import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/utils/big_int_big_endian.dart';

void main() {
  group('BigIntBigEndian Tests', () {
    test('should decode empty byte array to zero', () {
      final bytes = <int>[];
      final result = BigIntBigEndian.decode(bytes);
      expect(result, equals(BigInt.zero));
    });

    test('should decode single byte correctly', () {
      // Test various single byte values
      final testCases = [
        {'bytes': [0], 'expected': BigInt.zero},
        {'bytes': [1], 'expected': BigInt.one},
        {'bytes': [255], 'expected': BigInt.from(255)},
        {'bytes': [127], 'expected': BigInt.from(127)},
        {'bytes': [128], 'expected': BigInt.from(128)},
      ];

      for (final testCase in testCases) {
        final bytes = testCase['bytes'] as List<int>;
        final expected = testCase['expected'] as BigInt;
        final result = BigIntBigEndian.decode(bytes);
        expect(result, equals(expected), reason: 'Failed for bytes: $bytes');
      }
    });

    test('should decode two bytes in big-endian order', () {
      // Test two-byte combinations
      final testCases = [
        {'bytes': [0, 0], 'expected': BigInt.zero},
        {'bytes': [0, 1], 'expected': BigInt.one},
        {'bytes': [1, 0], 'expected': BigInt.from(256)}, // 1 * 256 + 0
        {'bytes': [1, 1], 'expected': BigInt.from(257)}, // 1 * 256 + 1
        {'bytes': [255, 255], 'expected': BigInt.from(65535)}, // 255 * 256 + 255
        {'bytes': [1, 255], 'expected': BigInt.from(511)}, // 1 * 256 + 255
        {'bytes': [255, 0], 'expected': BigInt.from(65280)}, // 255 * 256 + 0
      ];

      for (final testCase in testCases) {
        final bytes = testCase['bytes'] as List<int>;
        final expected = testCase['expected'] as BigInt;
        final result = BigIntBigEndian.decode(bytes);
        expect(result, equals(expected), reason: 'Failed for bytes: $bytes');
      }
    });

    test('should decode three bytes in big-endian order', () {
      final testCases = [
        {'bytes': [0, 0, 0], 'expected': BigInt.zero},
        {'bytes': [0, 0, 1], 'expected': BigInt.one},
        {'bytes': [0, 1, 0], 'expected': BigInt.from(256)},
        {'bytes': [1, 0, 0], 'expected': BigInt.from(65536)}, // 1 * 256^2
        {'bytes': [1, 2, 3], 'expected': BigInt.from(66051)}, // 1*65536 + 2*256 + 3
        {'bytes': [255, 255, 255], 'expected': BigInt.from(16777215)}, // 2^24 - 1
      ];

      for (final testCase in testCases) {
        final bytes = testCase['bytes'] as List<int>;
        final expected = testCase['expected'] as BigInt;
        final result = BigIntBigEndian.decode(bytes);
        expect(result, equals(expected), reason: 'Failed for bytes: $bytes');
      }
    });

    test('should decode four bytes (32-bit values)', () {
      final testCases = [
        {'bytes': [0, 0, 0, 0], 'expected': BigInt.zero},
        {'bytes': [0, 0, 0, 1], 'expected': BigInt.one},
        {'bytes': [0, 0, 1, 0], 'expected': BigInt.from(256)},
        {'bytes': [0, 1, 0, 0], 'expected': BigInt.from(65536)},
        {'bytes': [1, 0, 0, 0], 'expected': BigInt.from(16777216)}, // 1 * 256^3
        {'bytes': [255, 255, 255, 255], 'expected': BigInt.from(4294967295)}, // 2^32 - 1
        {'bytes': [128, 0, 0, 0], 'expected': BigInt.from(2147483648)}, // 2^31
        {'bytes': [1, 2, 3, 4], 'expected': BigInt.from(16909060)}, // 1*16777216 + 2*65536 + 3*256 + 4
      ];

      for (final testCase in testCases) {
        final bytes = testCase['bytes'] as List<int>;
        final expected = testCase['expected'] as BigInt;
        final result = BigIntBigEndian.decode(bytes);
        expect(result, equals(expected), reason: 'Failed for bytes: $bytes');
      }
    });

    test('should decode large byte arrays', () {
      // Test 8-byte (64-bit) values
      final eightBytes = [0, 0, 0, 0, 255, 255, 255, 255];
      final expected8 = BigInt.from(4294967295); // 2^32 - 1
      expect(BigIntBigEndian.decode(eightBytes), equals(expected8));

      // Test maximum 8-byte value
      final maxEightBytes = [255, 255, 255, 255, 255, 255, 255, 255];
      final expectedMax8 = BigInt.parse('18446744073709551615'); // 2^64 - 1
      expect(BigIntBigEndian.decode(maxEightBytes), equals(expectedMax8));
    });

    test('should handle Uint8List input', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final expected = BigInt.from(16909060);
      final result = BigIntBigEndian.decode(bytes);
      expect(result, equals(expected));
    });

    test('should decode cryptocurrency-related values', () {
      // Test common cryptocurrency values (32-byte values for private keys, etc.)
      
      // Simulate a small private key value
      final privateKeyBytes = List.filled(32, 0);
      privateKeyBytes[31] = 1; // Set the last byte to 1 (smallest possible private key)
      final result = BigIntBigEndian.decode(privateKeyBytes);
      expect(result, equals(BigInt.one));

      // Test a larger value
      final largerKeyBytes = List.filled(32, 0);
      largerKeyBytes[30] = 1; // Set second-to-last byte to 1
      largerKeyBytes[31] = 0;
      final largerResult = BigIntBigEndian.decode(largerKeyBytes);
      expect(largerResult, equals(BigInt.from(256)));
    });

    test('should decode sequential byte patterns', () {
      // Test ascending sequence
      final ascending = [1, 2, 3, 4, 5];
      final ascendingResult = BigIntBigEndian.decode(ascending);
      final expectedAscending = BigInt.from(1) * BigInt.from(256).pow(4) +
                                BigInt.from(2) * BigInt.from(256).pow(3) +
                                BigInt.from(3) * BigInt.from(256).pow(2) +
                                BigInt.from(4) * BigInt.from(256).pow(1) +
                                BigInt.from(5) * BigInt.from(256).pow(0);
      expect(ascendingResult, equals(expectedAscending));

      // Test descending sequence
      final descending = [5, 4, 3, 2, 1];
      final descendingResult = BigIntBigEndian.decode(descending);
      final expectedDescending = BigInt.from(5) * BigInt.from(256).pow(4) +
                                 BigInt.from(4) * BigInt.from(256).pow(3) +
                                 BigInt.from(3) * BigInt.from(256).pow(2) +
                                 BigInt.from(2) * BigInt.from(256).pow(1) +
                                 BigInt.from(1) * BigInt.from(256).pow(0);
      expect(descendingResult, equals(expectedDescending));
    });

    test('should handle big-endian vs little-endian correctly', () {
      // Verify that we're actually doing big-endian decoding
      // In big-endian, the most significant byte comes first
      
      final bigEndianBytes = [1, 0]; // Should be 256 in big-endian
      final result = BigIntBigEndian.decode(bigEndianBytes);
      expect(result, equals(BigInt.from(256)));
      
      // Verify this is different from little-endian interpretation
      // In little-endian, [1, 0] would be just 1
      expect(result, isNot(equals(BigInt.one)));
    });

    test('should decode hex-like patterns', () {
      // Test patterns that might come from hex strings
      final hexPatterns = [
        {'bytes': [0xDE, 0xAD, 0xBE, 0xEF], 'name': 'DEADBEEF'},
        {'bytes': [0xCA, 0xFE, 0xBA, 0xBE], 'name': 'CAFEBABE'},
        {'bytes': [0xFF, 0xFF], 'name': 'FFFF'},
        {'bytes': [0x12, 0x34], 'name': '1234'},
      ];

      for (final pattern in hexPatterns) {
        final bytes = pattern['bytes'] as List<int>;
        final name = pattern['name'] as String;
        final result = BigIntBigEndian.decode(bytes);
        
        // Verify the result is positive and non-zero for non-zero inputs
        if (bytes.any((b) => b != 0)) {
          expect(result, greaterThan(BigInt.zero), reason: 'Pattern $name should be positive');
        }
      }
    });

    test('should handle edge case byte values', () {
      // Test with boundary values
      final edgeCases = [
        {'bytes': [0x7F], 'expected': BigInt.from(127)}, // Max positive 7-bit
        {'bytes': [0x80], 'expected': BigInt.from(128)}, // Min "negative" in signed 8-bit
        {'bytes': [0xFF], 'expected': BigInt.from(255)}, // Max unsigned 8-bit
        {'bytes': [0x00, 0x80], 'expected': BigInt.from(128)}, // 128 with leading zero
        {'bytes': [0x80, 0x00], 'expected': BigInt.from(32768)}, // 128 * 256
      ];

      for (final testCase in edgeCases) {
        final bytes = testCase['bytes'] as List<int>;
        final expected = testCase['expected'] as BigInt;
        final result = BigIntBigEndian.decode(bytes);
        expect(result, equals(expected), reason: 'Failed for edge case bytes: $bytes');
      }
    });

    test('should be consistent with manual calculation', () {
      // Manual verification of the algorithm
      final testBytes = [0x12, 0x34, 0x56, 0x78];
      
      // Manual calculation:
      // 0x12 * 256^3 + 0x34 * 256^2 + 0x56 * 256^1 + 0x78 * 256^0
      final manual = BigInt.from(0x12) * BigInt.from(256 * 256 * 256) +
                     BigInt.from(0x34) * BigInt.from(256 * 256) +
                     BigInt.from(0x56) * BigInt.from(256) +
                     BigInt.from(0x78);
      
      final result = BigIntBigEndian.decode(testBytes);
      expect(result, equals(manual));
      expect(result, equals(BigInt.from(0x12345678)));
    });

    test('should handle very large numbers', () {
      // Test with 16 bytes (128-bit value)
      final sixteenBytes = [
        0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0,
        0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0
      ];
      
      final result = BigIntBigEndian.decode(sixteenBytes);
      
      // Verify it's a very large positive number
      expect(result, greaterThan(BigInt.zero));
      expect(result, greaterThan(BigInt.parse('1000000000000000000000'))); // Should be huge
    });

    test('should handle mixed zero and non-zero bytes', () {
      final testCases = [
        {'bytes': [0, 0, 0, 1], 'expected': BigInt.one},
        {'bytes': [1, 0, 0, 0], 'expected': BigInt.from(16777216)},
        {'bytes': [0, 1, 0, 1], 'expected': BigInt.from(65537)}, // 1*65536 + 1
        {'bytes': [1, 0, 1, 0], 'expected': BigInt.from(16777472)}, // 1*16777216 + 1*256
      ];

      for (final testCase in testCases) {
        final bytes = testCase['bytes'] as List<int>;
        final expected = testCase['expected'] as BigInt;
        final result = BigIntBigEndian.decode(bytes);
        expect(result, equals(expected), reason: 'Failed for mixed bytes: $bytes');
      }
    });
  });
} 