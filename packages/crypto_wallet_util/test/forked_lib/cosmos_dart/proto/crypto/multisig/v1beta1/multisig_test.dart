import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/crypto/multisig/v1beta1/multisig.pb.dart';

void main() {
	group('cosmos.crypto.multisig.v1beta1 MultiSignature', () {
		test('signatures list operations and basic functionality', () {
			final multiSig = MultiSignature(signatures: [
				[1, 2, 3],
				[4, 5, 6],
				[7, 8, 9]
			]);
			
			expect(multiSig.signatures.length, 3);
			expect(multiSig.signatures.first, [1, 2, 3]);
			expect(multiSig.signatures.last, [7, 8, 9]);
			
			// List operations
			multiSig.signatures.add([10, 11]);
			expect(multiSig.signatures.length, 4);
			multiSig.signatures.removeAt(1);
			expect(multiSig.signatures.length, 3);
			expect(multiSig.signatures[1], [7, 8, 9]); // [4,5,6] was removed
			
			multiSig.signatures.clear();
			expect(multiSig.signatures, isEmpty);
		});
		
		test('clone/copyWith/json/buffer operations', () {
			final original = MultiSignature(signatures: [
				[0xAB, 0xCD],
				[0xEF, 0x12]
			]);
			
			final cloned = original.clone();
			expect(cloned.signatures.length, 2);
			expect(identical(cloned.signatures, original.signatures), isFalse);
			expect(cloned.signatures.first, [0xAB, 0xCD]);
			
			final copied = original.copyWith((x) => x.signatures.add([0x34, 0x56]));
			expect(copied.signatures.length, 3);
			expect(original.signatures.length, 2); // original unchanged
			
			final json = jsonEncode(original.writeToJsonMap());
			final fromJson = MultiSignature.fromJson(json);
			expect(fromJson.signatures.length, 2);
			
			final buffer = original.writeToBuffer();
			final fromBuffer = MultiSignature.fromBuffer(buffer);
			expect(fromBuffer.signatures.length, 2);
		});
		
		test('getDefault/createEmptyInstance/createRepeated/info_', () {
			expect(identical(MultiSignature.getDefault(), MultiSignature.getDefault()), isTrue);
			final empty = MultiSignature().createEmptyInstance();
			expect(empty.signatures, isEmpty);
			final list = MultiSignature.createRepeated();
			expect(list, isA<pb.PbList<MultiSignature>>());
			expect(MultiSignature().info_.qualifiedMessageName, contains('MultiSignature'));
		});
		
		test('empty and large signatures', () {
			final empty = MultiSignature();
			expect(empty.signatures, isEmpty);
			
			final large = MultiSignature(signatures: List.generate(100, (i) => [i, i+1, i+2]));
			expect(large.signatures.length, 100);
			expect(large.signatures[50], [50, 51, 52]);
		});
	});
	
	group('cosmos.crypto.multisig.v1beta1 CompactBitArray', () {
		test('has/clear/json/buffer with extraBitsStored and elems', () {
			final bitArray = CompactBitArray(
				extraBitsStored: 5,
				elems: [0xFF, 0x00, 0xAB]
			);
			
			expect(bitArray.hasExtraBitsStored(), isTrue);
			expect(bitArray.hasElems(), isTrue);
			expect(bitArray.extraBitsStored, 5);
			expect(bitArray.elems, [0xFF, 0x00, 0xAB]);
			
			bitArray.clearExtraBitsStored();
			expect(bitArray.hasExtraBitsStored(), isFalse);
			bitArray.clearElems();
			expect(bitArray.hasElems(), isFalse);
			
			final json = jsonEncode(bitArray.writeToJsonMap());
			final fromJson = CompactBitArray.fromJson(json);
			expect(fromJson.hasExtraBitsStored(), isFalse);
			expect(fromJson.hasElems(), isFalse);
		});
		
		test('clone/copyWith operations', () {
			final original = CompactBitArray(extraBitsStored: 3, elems: [1, 2]);
			
			final cloned = original.clone();
			expect(cloned.extraBitsStored, 3);
			expect(cloned.elems, [1, 2]);
			expect(cloned.elems, [1, 2]);
			
			final copied = original.copyWith((x) => x.extraBitsStored = 7);
			expect(copied.extraBitsStored, 7);
			expect(copied.elems, [1, 2]);
			expect(original.extraBitsStored, 3); // original unchanged
		});
		
		test('zero extraBitsStored and empty elems', () {
			final bitArray = CompactBitArray()
				..extraBitsStored = 0
				..elems = [];
			expect(bitArray.extraBitsStored, 0);
			expect(bitArray.elems, isEmpty);
		});
		
		test('getDefault/createEmptyInstance/createRepeated/info_', () {
			expect(identical(CompactBitArray.getDefault(), CompactBitArray.getDefault()), isTrue);
			final empty = CompactBitArray().createEmptyInstance();
			expect(empty.extraBitsStored, 0);
			final list = CompactBitArray.createRepeated();
			expect(list, isA<pb.PbList<CompactBitArray>>());
			expect(CompactBitArray().info_.qualifiedMessageName, contains('CompactBitArray'));
		});
		
		test('large extraBitsStored and elems values', () {
			final bitArray = CompactBitArray(
				extraBitsStored: 0xFFFFFFFF, // max uint32
				elems: List.generate(256, (i) => i % 256)
			);
			
			expect(bitArray.extraBitsStored, 0xFFFFFFFF);
			expect(bitArray.elems.length, 256);
			expect(bitArray.elems.first, 0);
			expect(bitArray.elems.last, 255);
			
			final buffer = bitArray.writeToBuffer();
			final fromBuffer = CompactBitArray.fromBuffer(buffer);
			expect(fromBuffer.extraBitsStored, 0xFFFFFFFF);
			expect(fromBuffer.elems.length, 256);
		});
	});
	
	group('cosmos.crypto.multisig.v1beta1 edge cases & errors', () {
		test('invalid buffer/json error handling', () {
			expect(() => MultiSignature.fromBuffer([0xFF, 0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => CompactBitArray.fromJson('invalid json'), throwsA(isA<FormatException>()));
		});
		
		test('nested operations and modifications', () {
			final multiSig = MultiSignature(signatures: [[1, 2], [3, 4]]);
			
			// Modify nested list
			multiSig.signatures.first.add(5);
			expect(multiSig.signatures.first, [1, 2, 5]);
			
			// Replace entire signature
			multiSig.signatures[1] = [10, 20, 30];
			expect(multiSig.signatures[1], [10, 20, 30]);
			
			final cloned = multiSig.clone();
			expect(cloned.signatures.first, [1, 2, 5]);
			expect(multiSig.signatures.first, [1, 2, 5]); // both have same content
		});
	});
} 