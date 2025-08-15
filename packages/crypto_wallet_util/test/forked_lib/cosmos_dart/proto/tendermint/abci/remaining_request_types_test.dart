import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/abci/types.pb.dart';

void main() {
	group('tendermint.abci RequestListSnapshots', () {
		test('default constructor', () {
			final request = RequestListSnapshots();
			
			// RequestListSnapshots has no fields
			expect(request, isA<RequestListSnapshots>());
		});
		
		test('clone and copyWith operations', () {
			final original = RequestListSnapshots();
			
			final cloned = original.clone();
			expect(cloned, isA<RequestListSnapshots>());
			expect(identical(original, cloned), false);
			
			final copied = original.copyWith((message) => {});
			expect(copied, isA<RequestListSnapshots>());
		});
		
		test('JSON and buffer serialization', () {
			final request = RequestListSnapshots();
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = RequestListSnapshots.fromJson(json);
			expect(fromJson, isA<RequestListSnapshots>());
			
			final buffer = request.writeToBuffer();
			final fromBuffer = RequestListSnapshots.fromBuffer(buffer);
			expect(fromBuffer, isA<RequestListSnapshots>());
		});
		
		test('getDefault and createEmptyInstance', () {
			final defaultInstance = RequestListSnapshots.getDefault();
			final emptyInstance = RequestListSnapshots().createEmptyInstance();
			
			expect(defaultInstance, isA<RequestListSnapshots>());
			expect(emptyInstance, isA<RequestListSnapshots>());
			expect(identical(RequestListSnapshots.getDefault(), RequestListSnapshots.getDefault()), true);
		});
	});
	
	group('tendermint.abci RequestOfferSnapshot', () {
		test('constructor with all parameters', () {
			final snapshot = Snapshot(
				height: Int64(1000000),
				format: 1,
				chunks: 10,
				hash: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
				metadata: Uint8List.fromList([10, 20, 30, 40]),
			);
			
			final request = RequestOfferSnapshot(
				snapshot: snapshot,
				appHash: Uint8List.fromList([100, 101, 102, 103]),
			);
			
			expect(request.hasSnapshot(), true);
			expect(request.snapshot.height, Int64(1000000));
			expect(request.snapshot.format, 1);
			expect(request.snapshot.chunks, 10);
			expect(request.snapshot.hash, [1, 2, 3, 4, 5, 6, 7, 8]);
			expect(request.appHash, [100, 101, 102, 103]);
		});
		
		test('default constructor', () {
			final request = RequestOfferSnapshot();
			
			expect(request.hasSnapshot(), false);
			expect(request.appHash, isEmpty);
		});
		
		test('has/clear/ensure operations', () {
			final request = RequestOfferSnapshot();
			
			expect(request.hasSnapshot(), false);
			
			final snapshot = request.ensureSnapshot();
			expect(request.hasSnapshot(), true);
			expect(snapshot, isA<Snapshot>());
			
			request.clearSnapshot();
			expect(request.hasSnapshot(), false);
		});
		
		test('app hash variations', () {
			final appHashes = [
				Uint8List(0), // Empty
				Uint8List.fromList([0]), // Single zero
				Uint8List.fromList(List.generate(32, (i) => i)), // SHA-256 size
				Uint8List.fromList(List.generate(64, (i) => i * 2 % 256)), // SHA-512 size
			];
			
			for (final appHash in appHashes) {
				final request = RequestOfferSnapshot(appHash: appHash);
				expect(request.appHash, appHash);
				
				final buffer = request.writeToBuffer();
				final restored = RequestOfferSnapshot.fromBuffer(buffer);
				expect(restored.appHash, appHash);
			}
		});
		
		test('JSON and buffer serialization', () {
			final request = RequestOfferSnapshot(
				snapshot: Snapshot(height: Int64(500), format: 2),
				appHash: Uint8List.fromList([200, 201, 202]),
			);
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = RequestOfferSnapshot.fromJson(json);
			expect(fromJson.hasSnapshot(), true);
			expect(fromJson.snapshot.height, Int64(500));
			expect(fromJson.appHash, [200, 201, 202]);
			
			final buffer = request.writeToBuffer();
			final fromBuffer = RequestOfferSnapshot.fromBuffer(buffer);
			expect(fromBuffer.hasSnapshot(), true);
			expect(fromBuffer.snapshot.format, 2);
			expect(fromBuffer.appHash, [200, 201, 202]);
		});
	});
	
	group('tendermint.abci RequestLoadSnapshotChunk', () {
		test('constructor with all parameters', () {
			final request = RequestLoadSnapshotChunk(
				height: Int64(2000000),
				format: 3,
				chunk: 5,
			);
			
			expect(request.height, Int64(2000000));
			expect(request.format, 3);
			expect(request.chunk, 5);
		});
		
		test('default constructor', () {
			final request = RequestLoadSnapshotChunk();
			
			expect(request.height, Int64.ZERO);
			expect(request.format, 0);
			expect(request.chunk, 0);
		});
		
		test('has/clear operations', () {
			final request = RequestLoadSnapshotChunk(
				height: Int64(1500000),
				format: 2,
				chunk: 8,
			);
			
			expect(request.hasHeight(), true);
			expect(request.hasFormat(), true);
			expect(request.hasChunk(), true);
			
			request.clearHeight();
			request.clearFormat();
			request.clearChunk();
			
			expect(request.hasHeight(), false);
			expect(request.hasFormat(), false);
			expect(request.hasChunk(), false);
			expect(request.height, Int64.ZERO);
			expect(request.format, 0);
			expect(request.chunk, 0);
		});
		
		test('chunk index variations', () {
			final chunkScenarios = [
				{'height': 1000000, 'format': 1, 'chunk': 0}, // First chunk
				{'height': 1000000, 'format': 1, 'chunk': 5}, // Middle chunk
				{'height': 1000000, 'format': 1, 'chunk': 99}, // Last chunk (assuming 100 chunks)
				{'height': 2000000, 'format': 2, 'chunk': 0}, // Different snapshot
			];
			
			for (final scenario in chunkScenarios) {
				final request = RequestLoadSnapshotChunk(
					height: Int64(scenario['height']!),
					format: scenario['format']!,
					chunk: scenario['chunk']!,
				);
				
				expect(request.height, Int64(scenario['height']!));
				expect(request.format, scenario['format']);
				expect(request.chunk, scenario['chunk']);
				
				final buffer = request.writeToBuffer();
				final restored = RequestLoadSnapshotChunk.fromBuffer(buffer);
				expect(restored.height, Int64(scenario['height']!));
				expect(restored.format, scenario['format']);
				expect(restored.chunk, scenario['chunk']);
			}
		});
		
		test('large values', () {
			final request = RequestLoadSnapshotChunk(
				height: Int64.MAX_VALUE,
				format: 4294967295, // Max uint32
				chunk: 4294967295, // Max uint32
			);
			
			expect(request.height, Int64.MAX_VALUE);
			expect(request.format, 4294967295);
			expect(request.chunk, 4294967295);
			
			final buffer = request.writeToBuffer();
			final restored = RequestLoadSnapshotChunk.fromBuffer(buffer);
			expect(restored.height, Int64.MAX_VALUE);
			expect(restored.format, 4294967295);
			expect(restored.chunk, 4294967295);
		});
	});
	
	group('tendermint.abci RequestApplySnapshotChunk', () {
		test('constructor with all parameters', () {
			final chunkData = Uint8List(5000);
			for (int i = 0; i < 5000; i++) {
				chunkData[i] = i % 256;
			}
			
			final request = RequestApplySnapshotChunk(
				index: 7,
				chunk: chunkData,
				sender: 'peer-123',
			);
			
			expect(request.index, 7);
			expect(request.chunk.length, 5000);
			expect(request.chunk[0], 0);
			expect(request.chunk[4999], 135); // 4999 % 256 = 135
			expect(request.sender, 'peer-123');
		});
		
		test('default constructor', () {
			final request = RequestApplySnapshotChunk();
			
			expect(request.index, 0);
			expect(request.chunk, isEmpty);
			expect(request.sender, '');
		});
		
		test('has/clear operations', () {
			final request = RequestApplySnapshotChunk(
				index: 3,
				chunk: Uint8List.fromList([1, 2, 3, 4, 5]),
				sender: 'test-peer',
			);
			
			expect(request.hasIndex(), true);
			expect(request.hasChunk(), true);
			expect(request.hasSender(), true);
			
			request.clearIndex();
			request.clearChunk();
			request.clearSender();
			
			expect(request.hasIndex(), false);
			expect(request.hasChunk(), false);
			expect(request.hasSender(), false);
			expect(request.index, 0);
			expect(request.chunk, isEmpty);
			expect(request.sender, '');
		});
		
		test('various chunk sizes', () {
			final chunkSizes = [0, 1, 100, 1000, 10000];
			
			for (int i = 0; i < chunkSizes.length; i++) {
				final size = chunkSizes[i];
				final chunkData = Uint8List(size);
				for (int j = 0; j < size; j++) {
					chunkData[j] = (j * 3) % 256;
				}
				
				final request = RequestApplySnapshotChunk(
					index: i,
					chunk: chunkData,
					sender: 'peer-$i',
				);
				
				expect(request.index, i);
				expect(request.chunk.length, size);
				expect(request.sender, 'peer-$i');
				
				if (size > 0) {
					expect(request.chunk[0], 0);
					if (size > 1) {
						expect(request.chunk[size - 1], ((size - 1) * 3) % 256);
					}
				}
				
				final buffer = request.writeToBuffer();
				final restored = RequestApplySnapshotChunk.fromBuffer(buffer);
				expect(restored.index, i);
				expect(restored.chunk.length, size);
				expect(restored.sender, 'peer-$i');
			}
		});
		
		test('peer sender variations', () {
			final senders = [
				'',
				'peer-1',
				'validator-node-abc123',
				'192.168.1.100:26656',
				'very-long-peer-identifier-with-special-chars_123-456',
			];
			
			for (int i = 0; i < senders.length; i++) {
				final sender = senders[i];
				final request = RequestApplySnapshotChunk(
					index: i,
					chunk: Uint8List.fromList([i, i + 1, i + 2]),
					sender: sender,
				);
				
				expect(request.sender, sender);
				
				final buffer = request.writeToBuffer();
				final restored = RequestApplySnapshotChunk.fromBuffer(buffer);
				expect(restored.sender, sender);
			}
		});
		
		test('JSON and buffer serialization', () {
			final request = RequestApplySnapshotChunk(
				index: 15,
				chunk: Uint8List.fromList([255, 254, 253, 252, 251]),
				sender: 'test-serialization-peer',
			);
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = RequestApplySnapshotChunk.fromJson(json);
			expect(fromJson.index, 15);
			expect(fromJson.chunk, [255, 254, 253, 252, 251]);
			expect(fromJson.sender, 'test-serialization-peer');
			
			final buffer = request.writeToBuffer();
			final fromBuffer = RequestApplySnapshotChunk.fromBuffer(buffer);
			expect(fromBuffer.index, 15);
			expect(fromBuffer.chunk, [255, 254, 253, 252, 251]);
			expect(fromBuffer.sender, 'test-serialization-peer');
		});
	});
	
	group('tendermint.abci snapshot-related error handling', () {
		test('invalid buffer deserialization', () {
			final invalidBuffer = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF];
			
			expect(() => RequestListSnapshots.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => RequestOfferSnapshot.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => RequestLoadSnapshotChunk.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => RequestApplySnapshotChunk.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			const invalidJson = '{broken json}';
			
			expect(() => RequestListSnapshots.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => RequestOfferSnapshot.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => RequestLoadSnapshotChunk.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => RequestApplySnapshotChunk.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('tendermint.abci snapshot Request coverage', () {
		test('all snapshot Request types have proper info_', () {
			expect(RequestListSnapshots().info_, isA<pb.BuilderInfo>());
			expect(RequestOfferSnapshot().info_, isA<pb.BuilderInfo>());
			expect(RequestLoadSnapshotChunk().info_, isA<pb.BuilderInfo>());
			expect(RequestApplySnapshotChunk().info_, isA<pb.BuilderInfo>());
		});
		
		test('all snapshot Request types support createEmptyInstance', () {
			expect(RequestListSnapshots().createEmptyInstance(), isA<RequestListSnapshots>());
			expect(RequestOfferSnapshot().createEmptyInstance(), isA<RequestOfferSnapshot>());
			expect(RequestLoadSnapshotChunk().createEmptyInstance(), isA<RequestLoadSnapshotChunk>());
			expect(RequestApplySnapshotChunk().createEmptyInstance(), isA<RequestApplySnapshotChunk>());
		});
		
		test('getDefault returns same instance for all snapshot Request types', () {
			expect(identical(RequestListSnapshots.getDefault(), RequestListSnapshots.getDefault()), true);
			expect(identical(RequestOfferSnapshot.getDefault(), RequestOfferSnapshot.getDefault()), true);
			expect(identical(RequestLoadSnapshotChunk.getDefault(), RequestLoadSnapshotChunk.getDefault()), true);
			expect(identical(RequestApplySnapshotChunk.getDefault(), RequestApplySnapshotChunk.getDefault()), true);
		});
	});
} 