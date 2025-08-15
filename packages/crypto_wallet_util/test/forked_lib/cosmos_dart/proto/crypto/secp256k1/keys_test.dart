import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/crypto/secp256k1/keys.pb.dart';

void main() {
	group('cosmos.crypto.secp256k1 PubKey', () {
		test('has/clear/json/buffer with key bytes', () {
			final pubKey = PubKey(key: [
				0x04, 0x11, 0xDB, 0x93, 0xE1, 0xDC, 0xDB, 0x8A,
				0x01, 0x6B, 0x49, 0x84, 0x0F, 0x8C, 0x53, 0xBC,
				0x1E, 0xB6, 0x8A, 0x38, 0x2E, 0x97, 0xB1, 0x48,
				0x2E, 0xCA, 0xD7, 0xB1, 0x48, 0xA6, 0x90, 0x9A,
				0x5C, 0xB2, 0xE0, 0xEA, 0xDD, 0xFB, 0x84, 0xCC,
				0xF9, 0x74, 0x44, 0x64, 0xF8, 0x2E, 0x16, 0x0B,
				0xFA, 0x9B, 0x8B, 0x64, 0xF9, 0xD4, 0xC0, 0x3F,
				0x99, 0x9B, 0x86, 0x43, 0xF6, 0x56, 0xB4, 0x12,
				0xA3
			]);
			
			expect(pubKey.hasKey(), isTrue);
			expect(pubKey.key.length, 65); // uncompressed secp256k1 pubkey
			expect(pubKey.key.first, 0x04); // uncompressed prefix
			
			pubKey.clearKey();
			expect(pubKey.hasKey(), isFalse);
			
			final json = jsonEncode(pubKey.writeToJsonMap());
			final fromJson = PubKey.fromJson(json);
			expect(fromJson.hasKey(), isFalse);
			
			// Set key again for buffer test
			pubKey.key = [0x02, 0x03, 0x04]; // compressed format example
			final buffer = pubKey.writeToBuffer();
			final fromBuffer = PubKey.fromBuffer(buffer);
			expect(fromBuffer.key, [0x02, 0x03, 0x04]);
		});
		
		test('clone/copyWith operations', () {
			final original = PubKey(key: [0x03, 0xAB, 0xCD, 0xEF]);
			
			final cloned = original.clone();
			expect(cloned.key, [0x03, 0xAB, 0xCD, 0xEF]);
			
			final copied = original.copyWith((x) => x.key = [0x02, 0x12, 0x34]);
			expect(copied.key, [0x02, 0x12, 0x34]);
			expect(original.key, [0x03, 0xAB, 0xCD, 0xEF]); // original unchanged
		});
		
		test('getDefault/createEmptyInstance/createRepeated/info_', () {
			expect(identical(PubKey.getDefault(), PubKey.getDefault()), isTrue);
			final empty = PubKey().createEmptyInstance();
			expect(empty.key, isEmpty);
			final list = PubKey.createRepeated();
			expect(list, isA<pb.PbList<PubKey>>());
			expect(PubKey().info_.qualifiedMessageName, contains('PubKey'));
		});
		
		test('empty and various key sizes', () {
			final empty = PubKey();
			expect(empty.key, isEmpty);
			
			// Compressed secp256k1 pubkey (33 bytes)
			final compressed = PubKey(key: List.generate(33, (i) => i % 256));
			expect(compressed.key.length, 33);
			
			// Uncompressed secp256k1 pubkey (65 bytes)
			final uncompressed = PubKey(key: List.generate(65, (i) => i % 256));
			expect(uncompressed.key.length, 65);
		});
	});
	
	group('cosmos.crypto.secp256k1 PrivKey', () {
		test('has/clear/json/buffer with key bytes', () {
			final privKey = PrivKey(key: [
				0x4F, 0x3E, 0xDF, 0x98, 0x3A, 0xC6, 0x36, 0xA6,
				0x5A, 0x84, 0x2C, 0xE7, 0xC7, 0x8D, 0x9A, 0xA7,
				0x6F, 0x30, 0xAF, 0x76, 0xE4, 0xC4, 0xAC, 0x94,
				0x7A, 0x10, 0xF3, 0x9D, 0x0E, 0x04, 0xFC, 0x96
			]);
			
			expect(privKey.hasKey(), isTrue);
			expect(privKey.key.length, 32); // secp256k1 private key is 32 bytes
			
			privKey.clearKey();
			expect(privKey.hasKey(), isFalse);
			
			final json = jsonEncode(privKey.writeToJsonMap());
			final fromJson = PrivKey.fromJson(json);
			expect(fromJson.hasKey(), isFalse);
			
			// Set key again for buffer test
			privKey.key = List.generate(32, (i) => i);
			final buffer = privKey.writeToBuffer();
			final fromBuffer = PrivKey.fromBuffer(buffer);
			expect(fromBuffer.key.length, 32);
			expect(fromBuffer.key.first, 0);
			expect(fromBuffer.key.last, 31);
		});
		
		test('clone/copyWith operations', () {
			final original = PrivKey(key: List.filled(32, 0xFF));
			
			final cloned = original.clone();
			expect(cloned.key.length, 32);
			expect(cloned.key.every((b) => b == 0xFF), isTrue);
			
			final copied = original.copyWith((x) => x.key = List.filled(32, 0x00));
			expect(copied.key.every((b) => b == 0x00), isTrue);
			expect(original.key.every((b) => b == 0xFF), isTrue); // original unchanged
		});
		
		test('getDefault/createEmptyInstance/createRepeated/info_', () {
			expect(identical(PrivKey.getDefault(), PrivKey.getDefault()), isTrue);
			final empty = PrivKey().createEmptyInstance();
			expect(empty.key, isEmpty);
			final list = PrivKey.createRepeated();
			expect(list, isA<pb.PbList<PrivKey>>());
			expect(PrivKey().info_.qualifiedMessageName, contains('PrivKey'));
		});
		
		test('empty and invalid key sizes', () {
			final empty = PrivKey();
			expect(empty.key, isEmpty);
			
			// Valid 32-byte key
			final valid = PrivKey(key: List.generate(32, (i) => (i * 7) % 256));
			expect(valid.key.length, 32);
			
			// Invalid sizes (for testing purposes)
			final short = PrivKey(key: [1, 2, 3]);
			expect(short.key.length, 3);
			
			final long = PrivKey(key: List.generate(64, (i) => i % 256));
			expect(long.key.length, 64);
		});
	});
	
	group('cosmos.crypto.secp256k1 edge cases & errors', () {
		test('invalid buffer/json error handling', () {
			expect(() => PubKey.fromBuffer([0xFF, 0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => PrivKey.fromJson('invalid json'), throwsA(isA<FormatException>()));
		});
		
		test('key modification and roundtrips', () {
			final pubKey = PubKey(key: [0x02, 0x11, 0x22, 0x33]);
			
			// Modify key in-place
			pubKey.key[1] = 0xFF;
			expect(pubKey.key[1], 0xFF);
			
			// JSON roundtrip preserves modifications
			final json = jsonEncode(pubKey.writeToJsonMap());
			final fromJson = PubKey.fromJson(json);
			expect(fromJson.key[1], 0xFF);
			
			// Buffer roundtrip preserves modifications
			final buffer = pubKey.writeToBuffer();
			final fromBuffer = PubKey.fromBuffer(buffer);
			expect(fromBuffer.key[1], 0xFF);
		});
		
		test('zero-filled keys', () {
			final zeroPub = PubKey(key: List.filled(33, 0));
			expect(zeroPub.key.every((b) => b == 0), isTrue);
			
			final zeroPriv = PrivKey(key: List.filled(32, 0));
			expect(zeroPriv.key.every((b) => b == 0), isTrue);
			
			// Ensure they serialize/deserialize correctly
			final pubBuffer = zeroPub.writeToBuffer();
			final privBuffer = zeroPriv.writeToBuffer();
			
			final pubFromBuffer = PubKey.fromBuffer(pubBuffer);
			final privFromBuffer = PrivKey.fromBuffer(privBuffer);
			
			expect(pubFromBuffer.key.every((b) => b == 0), isTrue);
			expect(privFromBuffer.key.every((b) => b == 0), isTrue);
		});
	});
} 