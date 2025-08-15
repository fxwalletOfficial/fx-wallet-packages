import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/signing/v1beta1/signing.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/any.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/crypto/multisig/v1beta1/multisig.pb.dart';

void main() {
	group('cosmos.tx.signing.v1beta1 SignMode enum', () {
		test('enum values', () {
			expect(SignMode.SIGN_MODE_UNSPECIFIED.value, 0);
			expect(SignMode.SIGN_MODE_DIRECT.value, 1);
			expect(SignMode.SIGN_MODE_TEXTUAL.value, 2);
			expect(SignMode.SIGN_MODE_LEGACY_AMINO_JSON.value, 127);
			expect(SignMode.SIGN_MODE_EIP_191.value, 191);
		});
		
		test('valueOf function', () {
			expect(SignMode.valueOf(0), SignMode.SIGN_MODE_UNSPECIFIED);
			expect(SignMode.valueOf(1), SignMode.SIGN_MODE_DIRECT);
			expect(SignMode.valueOf(2), SignMode.SIGN_MODE_TEXTUAL);
			expect(SignMode.valueOf(127), SignMode.SIGN_MODE_LEGACY_AMINO_JSON);
			expect(SignMode.valueOf(191), SignMode.SIGN_MODE_EIP_191);
			expect(SignMode.valueOf(999), null);
		});
		
		test('values list', () {
			expect(SignMode.values, contains(SignMode.SIGN_MODE_UNSPECIFIED));
			expect(SignMode.values, contains(SignMode.SIGN_MODE_DIRECT));
			expect(SignMode.values, contains(SignMode.SIGN_MODE_TEXTUAL));
			expect(SignMode.values, contains(SignMode.SIGN_MODE_LEGACY_AMINO_JSON));
			expect(SignMode.values, contains(SignMode.SIGN_MODE_EIP_191));
			expect(SignMode.values.length, 5);
		});
	});
	
	group('cosmos.tx.signing.v1beta1 SignatureDescriptor_Data_Single', () {
		test('constructor with all parameters', () {
			final single = SignatureDescriptor_Data_Single(
				mode: SignMode.SIGN_MODE_DIRECT,
				signature: Uint8List.fromList([1, 2, 3, 4, 5]),
			);
			
			expect(single.mode, SignMode.SIGN_MODE_DIRECT);
			expect(single.signature, [1, 2, 3, 4, 5]);
		});
		
		test('constructor with partial parameters', () {
			final single = SignatureDescriptor_Data_Single(
				mode: SignMode.SIGN_MODE_TEXTUAL,
			);
			
			expect(single.mode, SignMode.SIGN_MODE_TEXTUAL);
			expect(single.hasSignature(), false);
		});
		
		test('default constructor', () {
			final single = SignatureDescriptor_Data_Single();
			
			expect(single.mode, SignMode.SIGN_MODE_UNSPECIFIED);
			expect(single.signature, isEmpty);
		});
		
		test('has/clear operations for mode', () {
			final single = SignatureDescriptor_Data_Single(mode: SignMode.SIGN_MODE_DIRECT);
			
			expect(single.hasMode(), isTrue);
			expect(single.mode, SignMode.SIGN_MODE_DIRECT);
			
			single.clearMode();
			expect(single.hasMode(), isFalse);
			expect(single.mode, SignMode.SIGN_MODE_UNSPECIFIED);
		});
		
		test('has/clear operations for signature', () {
			final single = SignatureDescriptor_Data_Single(
				signature: Uint8List.fromList([10, 20, 30]),
			);
			
			expect(single.hasSignature(), isTrue);
			expect(single.signature, [10, 20, 30]);
			
			single.clearSignature();
			expect(single.hasSignature(), isFalse);
			expect(single.signature, isEmpty);
		});
		
		test('setting and getting values', () {
			final single = SignatureDescriptor_Data_Single();
			
			single.mode = SignMode.SIGN_MODE_LEGACY_AMINO_JSON;
			single.signature = Uint8List.fromList([100, 200, 255]);
			
			expect(single.mode, SignMode.SIGN_MODE_LEGACY_AMINO_JSON);
			expect(single.signature, [100, 200, 255]);
		});
		
		test('clone operation', () {
			final original = SignatureDescriptor_Data_Single(
				mode: SignMode.SIGN_MODE_EIP_191,
				signature: Uint8List.fromList([1, 2, 3]),
			);
			
			final cloned = original.clone();
			expect(cloned.mode, SignMode.SIGN_MODE_EIP_191);
			expect(cloned.signature, [1, 2, 3]);
			
			// Verify independence
			cloned.mode = SignMode.SIGN_MODE_DIRECT;
			cloned.signature = Uint8List.fromList([4, 5, 6]);
			
			expect(cloned.mode, SignMode.SIGN_MODE_DIRECT);
			expect(cloned.signature, [4, 5, 6]);
			expect(original.mode, SignMode.SIGN_MODE_EIP_191);
			expect(original.signature, [1, 2, 3]);
		});
		
		test('copyWith operation', () {
			final original = SignatureDescriptor_Data_Single(
				mode: SignMode.SIGN_MODE_DIRECT,
				signature: Uint8List.fromList([1, 2, 3]),
			);
			
			final copied = original.copyWith((single) {
				single.mode = SignMode.SIGN_MODE_TEXTUAL;
			});
			
			expect(copied.mode, SignMode.SIGN_MODE_TEXTUAL);
			expect(original.mode, SignMode.SIGN_MODE_DIRECT); // original unchanged
		});
		
		test('JSON and buffer serialization', () {
			final single = SignatureDescriptor_Data_Single(
				mode: SignMode.SIGN_MODE_DIRECT,
				signature: Uint8List.fromList([65, 66, 67]),
			);
			
			final json = jsonEncode(single.writeToJsonMap());
			final fromJson = SignatureDescriptor_Data_Single.fromJson(json);
			expect(fromJson.mode, SignMode.SIGN_MODE_DIRECT);
			expect(fromJson.signature, [65, 66, 67]);
			
			final buffer = single.writeToBuffer();
			final fromBuffer = SignatureDescriptor_Data_Single.fromBuffer(buffer);
			expect(fromBuffer.mode, SignMode.SIGN_MODE_DIRECT);
			expect(fromBuffer.signature, [65, 66, 67]);
		});
		
		test('getDefault and createRepeated', () {
			expect(identical(SignatureDescriptor_Data_Single.getDefault(), 
				SignatureDescriptor_Data_Single.getDefault()), isTrue);
			
			final list = SignatureDescriptor_Data_Single.createRepeated();
			expect(list, isA<pb.PbList<SignatureDescriptor_Data_Single>>());
		});
	});
	
	group('cosmos.tx.signing.v1beta1 SignatureDescriptor_Data_Multi', () {
		test('constructor with all parameters', () {
			final bitarray = CompactBitArray();
			final signatures = [SignatureDescriptor_Data()];
			
			final multi = SignatureDescriptor_Data_Multi(
				bitarray: bitarray,
				signatures: signatures,
			);
			
			expect(multi.bitarray, bitarray);
			expect(multi.signatures.length, 1);
		});
		
		test('default constructor', () {
			final multi = SignatureDescriptor_Data_Multi();
			
			expect(multi.hasBitarray(), false);
			expect(multi.signatures, isEmpty);
		});
		
		test('has/clear/ensure operations for bitarray', () {
			final multi = SignatureDescriptor_Data_Multi();
			
			expect(multi.hasBitarray(), false);
			
			final bitarray = multi.ensureBitarray();
			expect(multi.hasBitarray(), true);
			expect(bitarray, isA<CompactBitArray>());
			
			multi.clearBitarray();
			expect(multi.hasBitarray(), false);
		});
		
		test('signatures list operations', () {
			final multi = SignatureDescriptor_Data_Multi();
			
			expect(multi.signatures, isEmpty);
			
			final sig1 = SignatureDescriptor_Data();
			final sig2 = SignatureDescriptor_Data();
			
			multi.signatures.add(sig1);
			multi.signatures.add(sig2);
			
			expect(multi.signatures.length, 2);
			expect(multi.signatures[0], sig1);
			expect(multi.signatures[1], sig2);
			
			multi.signatures.clear();
			expect(multi.signatures, isEmpty);
		});
		
		test('clone operation', () {
			final original = SignatureDescriptor_Data_Multi();
			original.ensureBitarray();
			original.signatures.add(SignatureDescriptor_Data());
			
			final cloned = original.clone();
			expect(cloned.hasBitarray(), true);
			expect(cloned.signatures.length, 1);
			
			// Verify independence
			cloned.signatures.add(SignatureDescriptor_Data());
			expect(cloned.signatures.length, 2);
			expect(original.signatures.length, 1);
		});
		
		test('JSON and buffer serialization', () {
			final multi = SignatureDescriptor_Data_Multi();
			multi.ensureBitarray();
			multi.signatures.add(SignatureDescriptor_Data());
			
			final json = jsonEncode(multi.writeToJsonMap());
			final fromJson = SignatureDescriptor_Data_Multi.fromJson(json);
			expect(fromJson.hasBitarray(), true);
			expect(fromJson.signatures.length, 1);
			
			final buffer = multi.writeToBuffer();
			final fromBuffer = SignatureDescriptor_Data_Multi.fromBuffer(buffer);
			expect(fromBuffer.hasBitarray(), true);
			expect(fromBuffer.signatures.length, 1);
		});
		
		test('getDefault and createRepeated', () {
			expect(identical(SignatureDescriptor_Data_Multi.getDefault(), 
				SignatureDescriptor_Data_Multi.getDefault()), isTrue);
			
			final list = SignatureDescriptor_Data_Multi.createRepeated();
			expect(list, isA<pb.PbList<SignatureDescriptor_Data_Multi>>());
		});
	});
	
	group('cosmos.tx.signing.v1beta1 SignatureDescriptor_Data', () {
		test('constructor with single', () {
			final single = SignatureDescriptor_Data_Single(
				mode: SignMode.SIGN_MODE_DIRECT,
				signature: Uint8List.fromList([1, 2, 3]),
			);
			
			final data = SignatureDescriptor_Data(single: single);
			
			expect(data.hasSingle(), true);
			expect(data.hasMulti(), false);
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.single);
			expect(data.single.mode, SignMode.SIGN_MODE_DIRECT);
		});
		
		test('constructor with multi', () {
			final multi = SignatureDescriptor_Data_Multi();
			
			final data = SignatureDescriptor_Data(multi: multi);
			
			expect(data.hasSingle(), false);
			expect(data.hasMulti(), true);
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.multi);
		});
		
		test('default constructor', () {
			final data = SignatureDescriptor_Data();
			
			expect(data.hasSingle(), false);
			expect(data.hasMulti(), false);
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.notSet);
		});
		
		test('oneof behavior - setting single clears multi', () {
			final data = SignatureDescriptor_Data();
			
			// Set multi first
			data.multi = SignatureDescriptor_Data_Multi();
			expect(data.hasMulti(), true);
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.multi);
			
			// Set single - should clear multi
			data.single = SignatureDescriptor_Data_Single();
			expect(data.hasSingle(), true);
			expect(data.hasMulti(), false);
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.single);
		});
		
		test('oneof behavior - setting multi clears single', () {
			final data = SignatureDescriptor_Data();
			
			// Set single first
			data.single = SignatureDescriptor_Data_Single();
			expect(data.hasSingle(), true);
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.single);
			
			// Set multi - should clear single
			data.multi = SignatureDescriptor_Data_Multi();
			expect(data.hasSingle(), false);
			expect(data.hasMulti(), true);
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.multi);
		});
		
		test('clear operations', () {
			final data = SignatureDescriptor_Data();
			
			data.single = SignatureDescriptor_Data_Single();
			expect(data.hasSingle(), true);
			
			data.clearSingle();
			expect(data.hasSingle(), false);
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.notSet);
			
			data.multi = SignatureDescriptor_Data_Multi();
			expect(data.hasMulti(), true);
			
			data.clearMulti();
			expect(data.hasMulti(), false);
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.notSet);
		});
		
		test('clearSum operation', () {
			final data = SignatureDescriptor_Data();
			
			data.single = SignatureDescriptor_Data_Single();
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.single);
			
			data.clearSum();
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.notSet);
		});
		
		test('ensure operations', () {
			final data = SignatureDescriptor_Data();
			
			final single = data.ensureSingle();
			expect(data.hasSingle(), true);
			expect(single, isA<SignatureDescriptor_Data_Single>());
			
			data.clearSum();
			
			final multi = data.ensureMulti();
			expect(data.hasMulti(), true);
			expect(multi, isA<SignatureDescriptor_Data_Multi>());
		});
		
		test('clone operation', () {
			final original = SignatureDescriptor_Data();
			original.single = SignatureDescriptor_Data_Single(
				mode: SignMode.SIGN_MODE_DIRECT,
			);
			
			final cloned = original.clone();
			expect(cloned.hasSingle(), true);
			expect(cloned.single.mode, SignMode.SIGN_MODE_DIRECT);
			
			// Verify independence
			cloned.single.mode = SignMode.SIGN_MODE_TEXTUAL;
			expect(cloned.single.mode, SignMode.SIGN_MODE_TEXTUAL);
			expect(original.single.mode, SignMode.SIGN_MODE_DIRECT);
		});
		
		test('JSON and buffer serialization', () {
			final data = SignatureDescriptor_Data();
			data.single = SignatureDescriptor_Data_Single(
				mode: SignMode.SIGN_MODE_LEGACY_AMINO_JSON,
				signature: Uint8List.fromList([10, 20, 30]),
			);
			
			final json = jsonEncode(data.writeToJsonMap());
			final fromJson = SignatureDescriptor_Data.fromJson(json);
			expect(fromJson.hasSingle(), true);
			expect(fromJson.single.mode, SignMode.SIGN_MODE_LEGACY_AMINO_JSON);
			expect(fromJson.single.signature, [10, 20, 30]);
			
			final buffer = data.writeToBuffer();
			final fromBuffer = SignatureDescriptor_Data.fromBuffer(buffer);
			expect(fromBuffer.hasSingle(), true);
			expect(fromBuffer.single.mode, SignMode.SIGN_MODE_LEGACY_AMINO_JSON);
			expect(fromBuffer.single.signature, [10, 20, 30]);
		});
	});
	
	group('cosmos.tx.signing.v1beta1 SignatureDescriptor', () {
		test('constructor with all parameters', () {
			final publicKey = Any(typeUrl: 'test', value: Uint8List.fromList([1, 2]));
			final data = SignatureDescriptor_Data();
			data.single = SignatureDescriptor_Data_Single();
			
			final descriptor = SignatureDescriptor(
				publicKey: publicKey,
				data: data,
				sequence: Int64(42),
			);
			
			expect(descriptor.publicKey.typeUrl, 'test');
			expect(descriptor.hasData(), true);
			expect(descriptor.sequence, Int64(42));
		});
		
		test('constructor with partial parameters', () {
			final descriptor = SignatureDescriptor(
				sequence: Int64(100),
			);
			
			expect(descriptor.hasPublicKey(), false);
			expect(descriptor.hasData(), false);
			expect(descriptor.sequence, Int64(100));
		});
		
		test('default constructor', () {
			final descriptor = SignatureDescriptor();
			
			expect(descriptor.hasPublicKey(), false);
			expect(descriptor.hasData(), false);
			expect(descriptor.sequence, Int64.ZERO);
		});
		
		test('has/clear/ensure operations for publicKey', () {
			final descriptor = SignatureDescriptor();
			
			expect(descriptor.hasPublicKey(), false);
			
			final publicKey = descriptor.ensurePublicKey();
			expect(descriptor.hasPublicKey(), true);
			expect(publicKey, isA<Any>());
			
			descriptor.clearPublicKey();
			expect(descriptor.hasPublicKey(), false);
		});
		
		test('has/clear/ensure operations for data', () {
			final descriptor = SignatureDescriptor();
			
			expect(descriptor.hasData(), false);
			
			final data = descriptor.ensureData();
			expect(descriptor.hasData(), true);
			expect(data, isA<SignatureDescriptor_Data>());
			
			descriptor.clearData();
			expect(descriptor.hasData(), false);
		});
		
		test('has/clear operations for sequence', () {
			final descriptor = SignatureDescriptor(sequence: Int64(123));
			
			expect(descriptor.hasSequence(), true);
			expect(descriptor.sequence, Int64(123));
			
			descriptor.clearSequence();
			expect(descriptor.hasSequence(), false);
			expect(descriptor.sequence, Int64.ZERO);
		});
		
		test('setting and getting values', () {
			final descriptor = SignatureDescriptor();
			
			descriptor.publicKey = Any(typeUrl: 'cosmos.crypto.secp256k1.PubKey');
			descriptor.data = SignatureDescriptor_Data();
			descriptor.sequence = Int64(999);
			
			expect(descriptor.publicKey.typeUrl, 'cosmos.crypto.secp256k1.PubKey');
			expect(descriptor.hasData(), true);
			expect(descriptor.sequence, Int64(999));
		});
		
		test('clone operation with nested objects', () {
			final original = SignatureDescriptor();
			original.publicKey = Any(typeUrl: 'test', value: Uint8List.fromList([1, 2]));
			original.data = SignatureDescriptor_Data();
			original.data.single = SignatureDescriptor_Data_Single(
				mode: SignMode.SIGN_MODE_DIRECT,
			);
			original.sequence = Int64(42);
			
			final cloned = original.clone();
			expect(cloned.publicKey.typeUrl, 'test');
			expect(cloned.data.hasSingle(), true);
			expect(cloned.data.single.mode, SignMode.SIGN_MODE_DIRECT);
			expect(cloned.sequence, Int64(42));
			
			// Verify independence
			cloned.publicKey.typeUrl = 'modified';
			cloned.data.single.mode = SignMode.SIGN_MODE_TEXTUAL;
			cloned.sequence = Int64(100);
			
			expect(cloned.publicKey.typeUrl, 'modified');
			expect(cloned.data.single.mode, SignMode.SIGN_MODE_TEXTUAL);
			expect(cloned.sequence, Int64(100));
			
			expect(original.publicKey.typeUrl, 'test');
			expect(original.data.single.mode, SignMode.SIGN_MODE_DIRECT);
			expect(original.sequence, Int64(42));
		});
		
		test('copyWith operation', () {
			final original = SignatureDescriptor(sequence: Int64(10));
			
			final copied = original.copyWith((descriptor) {
				descriptor.sequence = Int64(20);
			});
			
			expect(copied.sequence, Int64(20));
			expect(original.sequence, Int64(10)); // original unchanged
		});
		
		test('JSON and buffer serialization', () {
			final descriptor = SignatureDescriptor();
			descriptor.publicKey = Any(typeUrl: 'test.key');
			descriptor.data = SignatureDescriptor_Data();
			descriptor.data.single = SignatureDescriptor_Data_Single(
				mode: SignMode.SIGN_MODE_EIP_191,
			);
			descriptor.sequence = Int64(777);
			
			final json = jsonEncode(descriptor.writeToJsonMap());
			final fromJson = SignatureDescriptor.fromJson(json);
			expect(fromJson.publicKey.typeUrl, 'test.key');
			expect(fromJson.data.hasSingle(), true);
			expect(fromJson.data.single.mode, SignMode.SIGN_MODE_EIP_191);
			expect(fromJson.sequence, Int64(777));
			
			final buffer = descriptor.writeToBuffer();
			final fromBuffer = SignatureDescriptor.fromBuffer(buffer);
			expect(fromBuffer.publicKey.typeUrl, 'test.key');
			expect(fromBuffer.data.hasSingle(), true);
			expect(fromBuffer.data.single.mode, SignMode.SIGN_MODE_EIP_191);
			expect(fromBuffer.sequence, Int64(777));
		});
		
		test('large sequence values', () {
			final descriptor = SignatureDescriptor(
				sequence: Int64.parseInt('9223372036854775807'), // max int64
			);
			
			expect(descriptor.sequence.toString(), '9223372036854775807');
			
			final buffer = descriptor.writeToBuffer();
			final fromBuffer = SignatureDescriptor.fromBuffer(buffer);
			expect(fromBuffer.sequence.toString(), '9223372036854775807');
		});
	});
	
	group('cosmos.tx.signing.v1beta1 SignatureDescriptors', () {
		test('constructor with signatures', () {
			final sig1 = SignatureDescriptor(sequence: Int64(1));
			final sig2 = SignatureDescriptor(sequence: Int64(2));
			
			final descriptors = SignatureDescriptors(signatures: [sig1, sig2]);
			
			expect(descriptors.signatures.length, 2);
			expect(descriptors.signatures[0].sequence, Int64(1));
			expect(descriptors.signatures[1].sequence, Int64(2));
		});
		
		test('default constructor', () {
			final descriptors = SignatureDescriptors();
			
			expect(descriptors.signatures, isEmpty);
		});
		
		test('signatures list operations', () {
			final descriptors = SignatureDescriptors();
			
			expect(descriptors.signatures, isEmpty);
			
			final sig1 = SignatureDescriptor(sequence: Int64(10));
			final sig2 = SignatureDescriptor(sequence: Int64(20));
			final sig3 = SignatureDescriptor(sequence: Int64(30));
			
			descriptors.signatures.add(sig1);
			descriptors.signatures.addAll([sig2, sig3]);
			
			expect(descriptors.signatures.length, 3);
			expect(descriptors.signatures[0].sequence, Int64(10));
			expect(descriptors.signatures[1].sequence, Int64(20));
			expect(descriptors.signatures[2].sequence, Int64(30));
			
			descriptors.signatures.removeAt(1);
			expect(descriptors.signatures.length, 2);
			expect(descriptors.signatures[1].sequence, Int64(30));
			
			descriptors.signatures.clear();
			expect(descriptors.signatures, isEmpty);
		});
		
		test('clone operation', () {
			final original = SignatureDescriptors();
			original.signatures.add(SignatureDescriptor(sequence: Int64(42)));
			
			final cloned = original.clone();
			expect(cloned.signatures.length, 1);
			expect(cloned.signatures[0].sequence, Int64(42));
			
			// Verify independence
			cloned.signatures.add(SignatureDescriptor(sequence: Int64(100)));
			expect(cloned.signatures.length, 2);
			expect(original.signatures.length, 1);
		});
		
		test('copyWith operation', () {
			final original = SignatureDescriptors();
			original.signatures.add(SignatureDescriptor(sequence: Int64(1)));
			
			final copied = original.clone().copyWith((descriptors) {
				descriptors.signatures.add(SignatureDescriptor(sequence: Int64(2)));
			});
			
			expect(copied.signatures.length, 2);
			expect(original.signatures.length, 1); // original unchanged
		});
		
		test('JSON and buffer serialization', () {
			final descriptors = SignatureDescriptors();
			descriptors.signatures.add(SignatureDescriptor(sequence: Int64(123)));
			descriptors.signatures.add(SignatureDescriptor(sequence: Int64(456)));
			
			final json = jsonEncode(descriptors.writeToJsonMap());
			final fromJson = SignatureDescriptors.fromJson(json);
			expect(fromJson.signatures.length, 2);
			expect(fromJson.signatures[0].sequence, Int64(123));
			expect(fromJson.signatures[1].sequence, Int64(456));
			
			final buffer = descriptors.writeToBuffer();
			final fromBuffer = SignatureDescriptors.fromBuffer(buffer);
			expect(fromBuffer.signatures.length, 2);
			expect(fromBuffer.signatures[0].sequence, Int64(123));
			expect(fromBuffer.signatures[1].sequence, Int64(456));
		});
		
		test('getDefault and createRepeated', () {
			expect(identical(SignatureDescriptors.getDefault(), 
				SignatureDescriptors.getDefault()), isTrue);
			
			final list = SignatureDescriptors.createRepeated();
			expect(list, isA<pb.PbList<SignatureDescriptors>>());
		});
	});
	
	group('cosmos.tx.signing.v1beta1 error handling', () {
		test('invalid buffer deserialization', () {
			expect(() => SignatureDescriptors.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => SignatureDescriptor.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => SignatureDescriptor_Data.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => SignatureDescriptor_Data_Single.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => SignatureDescriptor_Data_Multi.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			expect(() => SignatureDescriptors.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => SignatureDescriptor.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => SignatureDescriptor_Data.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => SignatureDescriptor_Data_Single.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => SignatureDescriptor_Data_Multi.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('cosmos.tx.signing.v1beta1 comprehensive coverage', () {
		test('all message types have proper info_', () {
			expect(SignatureDescriptors().info_, isA<pb.BuilderInfo>());
			expect(SignatureDescriptor().info_, isA<pb.BuilderInfo>());
			expect(SignatureDescriptor_Data().info_, isA<pb.BuilderInfo>());
			expect(SignatureDescriptor_Data_Single().info_, isA<pb.BuilderInfo>());
			expect(SignatureDescriptor_Data_Multi().info_, isA<pb.BuilderInfo>());
		});
		
		test('all message types support createEmptyInstance', () {
			expect(SignatureDescriptors().createEmptyInstance(), isA<SignatureDescriptors>());
			expect(SignatureDescriptor().createEmptyInstance(), isA<SignatureDescriptor>());
			expect(SignatureDescriptor_Data().createEmptyInstance(), isA<SignatureDescriptor_Data>());
			expect(SignatureDescriptor_Data_Single().createEmptyInstance(), isA<SignatureDescriptor_Data_Single>());
			expect(SignatureDescriptor_Data_Multi().createEmptyInstance(), isA<SignatureDescriptor_Data_Multi>());
		});
		
		test('complex nested structure roundtrip', () {
			final descriptors = SignatureDescriptors();
			
			// Create a complex signature descriptor
			final descriptor = SignatureDescriptor();
			descriptor.publicKey = Any(
				typeUrl: 'cosmos.crypto.secp256k1.PubKey',
				value: Uint8List.fromList([1, 2, 3, 4, 5]),
			);
			descriptor.sequence = Int64(12345);
			
			// Set up single signature data
			descriptor.data = SignatureDescriptor_Data();
			descriptor.data.single = SignatureDescriptor_Data_Single(
				mode: SignMode.SIGN_MODE_DIRECT,
				signature: Uint8List.fromList([10, 20, 30, 40, 50]),
			);
			
			descriptors.signatures.add(descriptor);
			
			// Test JSON roundtrip
			final json = jsonEncode(descriptors.writeToJsonMap());
			final fromJson = SignatureDescriptors.fromJson(json);
			
			expect(fromJson.signatures.length, 1);
			final restoredDescriptor = fromJson.signatures[0];
			expect(restoredDescriptor.publicKey.typeUrl, 'cosmos.crypto.secp256k1.PubKey');
			expect(restoredDescriptor.publicKey.value, [1, 2, 3, 4, 5]);
			expect(restoredDescriptor.sequence, Int64(12345));
			expect(restoredDescriptor.data.hasSingle(), true);
			expect(restoredDescriptor.data.single.mode, SignMode.SIGN_MODE_DIRECT);
			expect(restoredDescriptor.data.single.signature, [10, 20, 30, 40, 50]);
			
			// Test buffer roundtrip
			final buffer = descriptors.writeToBuffer();
			final fromBuffer = SignatureDescriptors.fromBuffer(buffer);
			
			expect(fromBuffer.signatures.length, 1);
			final bufferDescriptor = fromBuffer.signatures[0];
			expect(bufferDescriptor.publicKey.typeUrl, 'cosmos.crypto.secp256k1.PubKey');
			expect(bufferDescriptor.publicKey.value, [1, 2, 3, 4, 5]);
			expect(bufferDescriptor.sequence, Int64(12345));
			expect(bufferDescriptor.data.hasSingle(), true);
			expect(bufferDescriptor.data.single.mode, SignMode.SIGN_MODE_DIRECT);
			expect(bufferDescriptor.data.single.signature, [10, 20, 30, 40, 50]);
		});
		
		test('oneof field behavior consistency', () {
			final data = SignatureDescriptor_Data();
			
			// Test that only one field can be set at a time
			data.single = SignatureDescriptor_Data_Single();
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.single);
			expect(data.hasSingle(), true);
			expect(data.hasMulti(), false);
			
			data.multi = SignatureDescriptor_Data_Multi();
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.multi);
			expect(data.hasSingle(), false);
			expect(data.hasMulti(), true);
			
			data.clearSum();
			expect(data.whichSum(), SignatureDescriptor_Data_Sum.notSet);
			expect(data.hasSingle(), false);
			expect(data.hasMulti(), false);
		});
	});
} 