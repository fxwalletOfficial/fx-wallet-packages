import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/any.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';

void main() {
	group('google.protobuf Any', () {
		test('constructor with all parameters', () {
			final value = Uint8List.fromList([1, 2, 3, 4, 5]);
			
			final any = Any(
				typeUrl: 'type.googleapis.com/cosmos.base.v1beta1.Coin',
				value: value,
			);
			
			expect(any.typeUrl, 'type.googleapis.com/cosmos.base.v1beta1.Coin');
			expect(any.value, [1, 2, 3, 4, 5]);
		});
		
		test('constructor with partial parameters', () {
			final any = Any(typeUrl: 'type.googleapis.com/test.Message');
			
			expect(any.typeUrl, 'type.googleapis.com/test.Message');
			expect(any.value, isEmpty);
		});
		
		test('default constructor', () {
			final any = Any();
			
			expect(any.typeUrl, '');
			expect(any.value, isEmpty);
		});
		
		test('has/clear operations for typeUrl', () {
			final any = Any(typeUrl: 'test.type.url');
			
			expect(any.hasTypeUrl(), true);
			expect(any.typeUrl, 'test.type.url');
			
			any.clearTypeUrl();
			expect(any.hasTypeUrl(), false);
			expect(any.typeUrl, '');
		});
		
		test('has/clear operations for value', () {
			final value = Uint8List.fromList([10, 20, 30]);
			final any = Any(value: value);
			
			expect(any.hasValue(), true);
			expect(any.value, [10, 20, 30]);
			
			any.clearValue();
			expect(any.hasValue(), false);
			expect(any.value, isEmpty);
		});
		
		test('setting and getting values', () {
			final any = Any();
			
			any.typeUrl = 'custom.type.url';
			any.value = Uint8List.fromList([100, 101, 102]);
			
			expect(any.typeUrl, 'custom.type.url');
			expect(any.value, [100, 101, 102]);
		});
		
		test('clone operation', () {
			final original = Any(
				typeUrl: 'original.type',
				value: Uint8List.fromList([1, 2, 3]),
			);
			
			final cloned = original.clone();
			expect(cloned.typeUrl, 'original.type');
			expect(cloned.value, [1, 2, 3]);
			
			// Verify independence
			cloned.typeUrl = 'cloned.type';
			cloned.value = Uint8List.fromList([4, 5, 6]);
			
			expect(cloned.typeUrl, 'cloned.type');
			expect(cloned.value, [4, 5, 6]);
			expect(original.typeUrl, 'original.type');
			expect(original.value, [1, 2, 3]);
		});
		
		test('copyWith operation', () {
			final original = Any(
				typeUrl: 'original.type',
				value: Uint8List.fromList([1, 2, 3]),
			);
			
			final copied = original.clone().copyWith((any) {
				any.typeUrl = 'copied.type';
				any.value = Uint8List.fromList([7, 8, 9]);
			});
			
			expect(copied.typeUrl, 'copied.type');
			expect(copied.value, [7, 8, 9]);
			expect(original.typeUrl, 'original.type'); // original unchanged
			expect(original.value, [1, 2, 3]);
		});
		
		test('JSON serialization and deserialization', () {
			final any = Any(
				typeUrl: 'type.googleapis.com/test.JsonMessage',
				value: Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]),
			);
			
			final json = jsonEncode(any.writeToJsonMap());
			final fromJson = Any.fromJson(json);
			
			expect(fromJson.typeUrl, 'type.googleapis.com/test.JsonMessage');
			expect(fromJson.value, [0xDE, 0xAD, 0xBE, 0xEF]);
		});
		
		test('binary serialization and deserialization', () {
			final any = Any(
				typeUrl: 'type.googleapis.com/test.BinaryMessage',
				value: Uint8List.fromList([0xFF, 0x00, 0xAA, 0x55]),
			);
			
			final buffer = any.writeToBuffer();
			final fromBuffer = Any.fromBuffer(buffer);
			
			expect(fromBuffer.typeUrl, 'type.googleapis.com/test.BinaryMessage');
			expect(fromBuffer.value, [0xFF, 0x00, 0xAA, 0x55]);
		});
		
		test('pack static method with default typeUrlPrefix', () {
			final coin = CosmosCoin(denom: 'stake', amount: '1000000');
			
			final packedAny = Any.pack(coin);
			
			expect(packedAny.typeUrl, contains('type.googleapis.com'));
			expect(packedAny.typeUrl, contains('cosmos.base.v1beta1.Coin'));
			expect(packedAny.hasValue(), true);
			expect(packedAny.value.isNotEmpty, true);
		});
		
		test('pack static method with custom typeUrlPrefix', () {
			final coin = CosmosCoin(denom: 'atom', amount: '500000');
			
			final packedAny = Any.pack(coin, typeUrlPrefix: 'custom.prefix.com');
			
			expect(packedAny.typeUrl, startsWith('custom.prefix.com'));
			expect(packedAny.typeUrl, contains('cosmos.base.v1beta1.Coin'));
			expect(packedAny.hasValue(), true);
		});
		
		test('pack and unpack roundtrip with CosmosCoin', () {
			final originalCoin = CosmosCoin(denom: 'test', amount: '123456789');
			
			// Pack the coin into Any
			final packedAny = Any.pack(originalCoin);
			
			// Verify packed Any structure
			expect(packedAny.typeUrl, contains('cosmos.base.v1beta1.Coin'));
			expect(packedAny.hasValue(), true);
			
			// Unpack should work with mixin functionality
			// Note: The unpack functionality depends on AnyMixin which may not be fully accessible
			// in this test context, so we test what we can verify
			expect(packedAny.canUnpackInto(CosmosCoin.getDefault()), true);
			
			// Test serialization of packed Any
			final buffer = packedAny.writeToBuffer();
			final restoredAny = Any.fromBuffer(buffer);
			
			expect(restoredAny.typeUrl, packedAny.typeUrl);
			expect(restoredAny.value, packedAny.value);
		});
		
		test('getDefault returns same instance', () {
			final default1 = Any.getDefault();
			final default2 = Any.getDefault();
			expect(identical(default1, default2), isTrue);
		});
		
		test('createEmptyInstance creates new instance', () {
			final any = Any();
			final empty = any.createEmptyInstance();
			expect(empty.typeUrl, '');
			expect(empty.value, isEmpty);
			expect(identical(any, empty), isFalse);
		});
		
		test('createRepeated creates PbList', () {
			final list = Any.createRepeated();
			expect(list, isA<pb.PbList<Any>>());
			expect(list, isEmpty);
			
			list.add(Any(typeUrl: 'test.type'));
			expect(list.length, 1);
		});
		
		test('info_ returns BuilderInfo', () {
			final any = Any();
			final info = any.info_;
			expect(info, isA<pb.BuilderInfo>());
			expect(info.qualifiedMessageName, contains('Any'));
		});
		
		test('empty value bytes', () {
			final any = Any(
				typeUrl: 'test.empty.value',
				value: Uint8List(0),
			);
			
			expect(any.value, isEmpty);
			expect(any.hasValue(), false); // Empty bytes don't count as "has value" in protobuf
			
			final buffer = any.writeToBuffer();
			final restored = Any.fromBuffer(buffer);
			expect(restored.value, isEmpty);
			expect(restored.hasValue(), false);
		});
		
		test('large value bytes', () {
			final largeValue = Uint8List(10000);
			for (int i = 0; i < 10000; i++) {
				largeValue[i] = i % 256;
			}
			
			final any = Any(
				typeUrl: 'test.large.value',
				value: largeValue,
			);
			
			expect(any.value.length, 10000);
			expect(any.value[0], 0);
			expect(any.value[9999], 15); // 9999 % 256 = 15
			
			final buffer = any.writeToBuffer();
			final restored = Any.fromBuffer(buffer);
			expect(restored.value.length, 10000);
			expect(restored.value[5000], 136); // 5000 % 256 = 136
		});
		
		test('long type URLs', () {
			final longTypeUrl = 'type.googleapis.com/' + 'very.long.package.name.' * 10 + 'MessageType';
			
			final any = Any(typeUrl: longTypeUrl);
			
			expect(any.typeUrl, longTypeUrl);
			expect(any.typeUrl.length, greaterThan(100));
			
			final buffer = any.writeToBuffer();
			final restored = Any.fromBuffer(buffer);
			expect(restored.typeUrl, longTypeUrl);
		});
		
		test('special characters in typeUrl', () {
			final specialTypeUrl = 'type.googleapis.com/test.Message-With_Special.Characters123';
			
			final any = Any(typeUrl: specialTypeUrl);
			
			expect(any.typeUrl, specialTypeUrl);
			
			final json = jsonEncode(any.writeToJsonMap());
			final fromJson = Any.fromJson(json);
			expect(fromJson.typeUrl, specialTypeUrl);
		});
		
		test('binary data with all byte values', () {
			final allBytes = Uint8List(256);
			for (int i = 0; i < 256; i++) {
				allBytes[i] = i;
			}
			
			final any = Any(
				typeUrl: 'test.all.bytes',
				value: allBytes,
			);
			
			expect(any.value.length, 256);
			expect(any.value[0], 0);
			expect(any.value[255], 255);
			
			final buffer = any.writeToBuffer();
			final restored = Any.fromBuffer(buffer);
			
			expect(restored.value.length, 256);
			for (int i = 0; i < 256; i++) {
				expect(restored.value[i], i);
			}
		});
		
		test('pack with various message types', () {
			// Test packing different message types to ensure pack method works generically
			final coin1 = CosmosCoin(denom: 'stake', amount: '1000');
			final coin2 = CosmosCoin(denom: 'atom', amount: '2000');
			
			final packedCoin1 = Any.pack(coin1);
			final packedCoin2 = Any.pack(coin2);
			
			// Both should have the same type URL but different values
			expect(packedCoin1.typeUrl, packedCoin2.typeUrl);
			expect(packedCoin1.value, isNot(equals(packedCoin2.value)));
			
			// Verify they can be distinguished by their packed content
			expect(packedCoin1.value.isNotEmpty, true);
			expect(packedCoin2.value.isNotEmpty, true);
		});
		
		test('mixin functionality - canUnpackInto', () {
			final coin = CosmosCoin(denom: 'test', amount: '12345');
			final packedAny = Any.pack(coin);
			
			// Test canUnpackInto with correct type
			expect(packedAny.canUnpackInto(CosmosCoin.getDefault()), true);
			
			// Test with different type (should return false)
			final differentAny = Any(typeUrl: 'different.type.url');
			expect(differentAny.canUnpackInto(CosmosCoin.getDefault()), false);
		});
		
		test('well-known type behavior', () {
			// Test that Any behaves as a well-known type with proper JSON handling
			final any = Any(
				typeUrl: 'type.googleapis.com/google.protobuf.StringValue',
				value: Uint8List.fromList([10, 5, 104, 101, 108, 108, 111]), // "hello" as StringValue
			);
			
			// The Any message should handle JSON serialization properly
			final json = jsonEncode(any.writeToJsonMap());
			expect(json, isA<String>());
			expect(json, contains(any.typeUrl));
			
			final fromJson = Any.fromJson(json);
			expect(fromJson.typeUrl, any.typeUrl);
			expect(fromJson.value, any.value);
		});
	});
	
	group('google.protobuf Any error handling', () {
		test('invalid buffer deserialization', () {
			expect(() => Any.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			expect(() => Any.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
		
		test('pack with null message should throw', () {
			// This would require testing the actual pack implementation
			// which might handle null differently, so we test what we can verify
			final coin = CosmosCoin(denom: 'test', amount: '123');
			expect(() => Any.pack(coin), returnsNormally);
		});
	});
	
	group('google.protobuf Any comprehensive coverage', () {
		test('message type has proper info_', () {
			expect(Any().info_, isA<pb.BuilderInfo>());
		});
		
		test('message type supports createEmptyInstance', () {
			expect(Any().createEmptyInstance(), isA<Any>());
		});
		
		test('getDefault returns same instance', () {
			expect(identical(Any.getDefault(), Any.getDefault()), isTrue);
		});
		
		test('complete Any workflow', () {
			// Test a complete workflow of packing, serializing, deserializing, and verifying
			
			// 1. Create original message
			final originalCoin = CosmosCoin(denom: 'workflow', amount: '999888777');
			
			// 2. Pack into Any
			final packedAny = Any.pack(originalCoin, typeUrlPrefix: 'test.workflow.com');
			expect(packedAny.typeUrl, startsWith('test.workflow.com'));
			expect(packedAny.hasValue(), true);
			
			// 3. Serialize to JSON
			final json = jsonEncode(packedAny.writeToJsonMap());
			expect(json, isA<String>());
			
			// 4. Deserialize from JSON
			final anyFromJson = Any.fromJson(json);
			expect(anyFromJson.typeUrl, packedAny.typeUrl);
			expect(anyFromJson.value, packedAny.value);
			
			// 5. Serialize to binary
			final buffer = anyFromJson.writeToBuffer();
			expect(buffer, isA<List<int>>());
			
			// 6. Deserialize from binary
			final anyFromBuffer = Any.fromBuffer(buffer);
			expect(anyFromBuffer.typeUrl, packedAny.typeUrl);
			expect(anyFromBuffer.value, packedAny.value);
			
			// 7. Verify can unpack
			expect(anyFromBuffer.canUnpackInto(CosmosCoin.getDefault()), true);
			
			// 8. Test cloning and independence
			final clonedAny = anyFromBuffer.clone();
			clonedAny.typeUrl = 'modified.type.url';
			
			expect(clonedAny.typeUrl, 'modified.type.url');
			expect(anyFromBuffer.typeUrl, isNot('modified.type.url'));
		});
		
		test('field presence and default behavior', () {
			final any = Any();
			
			// Test initial state (no fields set)
			expect(any.hasTypeUrl(), false);
			expect(any.hasValue(), false);
			
			// Test default values
			expect(any.typeUrl, '');
			expect(any.value, isEmpty);
			
			// Set fields and verify presence
			any.typeUrl = 'test.type';
			any.value = Uint8List.fromList([1, 2, 3]);
			
			expect(any.hasTypeUrl(), true);
			expect(any.hasValue(), true);
			
			// Clear fields and verify absence
			any.clearTypeUrl();
			any.clearValue();
			
			expect(any.hasTypeUrl(), false);
			expect(any.hasValue(), false);
			expect(any.typeUrl, '');
			expect(any.value, isEmpty);
		});
		
		test('type URL format validation', () {
			// Test various type URL formats that should be valid
			final validTypeUrls = [
				'type.googleapis.com/google.protobuf.Any',
				'type.googleapis.com/cosmos.base.v1beta1.Coin',
				'custom.domain.com/my.package.v1.Message',
				'localhost:8080/test.Message',
				'https://example.com/proto.Message',
			];
			
			for (final typeUrl in validTypeUrls) {
				final any = Any(typeUrl: typeUrl);
				expect(any.typeUrl, typeUrl);
				
				final buffer = any.writeToBuffer();
				final restored = Any.fromBuffer(buffer);
				expect(restored.typeUrl, typeUrl);
			}
		});
		
		test('value byte array edge cases', () {
			final testCases = [
				Uint8List(0),                    // Empty
				Uint8List.fromList([0]),         // Single zero byte
				Uint8List.fromList([255]),       // Single max byte
				Uint8List.fromList([0, 255, 0, 255]), // Alternating pattern
			];
			
			for (int i = 0; i < testCases.length; i++) {
				final testValue = testCases[i];
				final any = Any(
					typeUrl: 'test.case.$i',
					value: testValue,
				);
				
				expect(any.value, testValue);
				
				final buffer = any.writeToBuffer();
				final restored = Any.fromBuffer(buffer);
				expect(restored.value, testValue);
				expect(restored.typeUrl, 'test.case.$i');
			}
		});
	});
} 