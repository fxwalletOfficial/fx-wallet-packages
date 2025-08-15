import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/abci/types.pb.dart';

void main() {
	group('tendermint.abci ResponseListSnapshots', () {
		test('constructor with snapshots', () {
			final snapshots = [
				Snapshot(
					height: Int64(1000000),
					format: 1,
					chunks: 10,
					hash: Uint8List.fromList([1, 2, 3, 4]),
					metadata: Uint8List.fromList([10, 20]),
				),
				Snapshot(
					height: Int64(2000000),
					format: 2,
					chunks: 20,
					hash: Uint8List.fromList([5, 6, 7, 8]),
					metadata: Uint8List.fromList([30, 40]),
				),
			];
			
			final response = ResponseListSnapshots(snapshots: snapshots);
			
			expect(response.snapshots.length, 2);
			expect(response.snapshots[0].height, Int64(1000000));
			expect(response.snapshots[0].format, 1);
			expect(response.snapshots[0].chunks, 10);
			expect(response.snapshots[1].height, Int64(2000000));
			expect(response.snapshots[1].format, 2);
			expect(response.snapshots[1].chunks, 20);
		});
		
		test('default constructor', () {
			final response = ResponseListSnapshots();
			
			expect(response.snapshots, isEmpty);
		});
		
		test('snapshots list operations', () {
			final response = ResponseListSnapshots();
			
			expect(response.snapshots, isEmpty);
			
			final snapshot1 = Snapshot(height: Int64(500000), format: 1);
			final snapshot2 = Snapshot(height: Int64(600000), format: 2);
			
			response.snapshots.addAll([snapshot1, snapshot2]);
			expect(response.snapshots.length, 2);
			expect(response.snapshots[0].height, Int64(500000));
			expect(response.snapshots[1].height, Int64(600000));
			
			response.snapshots.removeAt(0);
			expect(response.snapshots.length, 1);
			expect(response.snapshots[0].height, Int64(600000));
			
			response.snapshots.clear();
			expect(response.snapshots, isEmpty);
		});
		
		test('large snapshots list', () {
			final largeSnapshotsList = List.generate(100, (i) => Snapshot(
				height: Int64(i * 10000),
				format: i % 3 + 1,
				chunks: i + 1,
			));
			
			final response = ResponseListSnapshots(snapshots: largeSnapshotsList);
			
			expect(response.snapshots.length, 100);
			expect(response.snapshots[50].height, Int64(500000));
			expect(response.snapshots[50].format, 3); // 50 % 3 + 1 = 3
			expect(response.snapshots[50].chunks, 51);
			
			final buffer = response.writeToBuffer();
			final restored = ResponseListSnapshots.fromBuffer(buffer);
			expect(restored.snapshots.length, 100);
			expect(restored.snapshots[25].height, Int64(250000));
			expect(restored.snapshots[75].chunks, 76);
		});
		
		test('JSON and buffer serialization', () {
			final response = ResponseListSnapshots(snapshots: [
				Snapshot(height: Int64(123456), format: 3, chunks: 5),
			]);
			
			final json = jsonEncode(response.writeToJsonMap());
			final fromJson = ResponseListSnapshots.fromJson(json);
			expect(fromJson.snapshots.length, 1);
			expect(fromJson.snapshots[0].height, Int64(123456));
			expect(fromJson.snapshots[0].format, 3);
			
			final buffer = response.writeToBuffer();
			final fromBuffer = ResponseListSnapshots.fromBuffer(buffer);
			expect(fromBuffer.snapshots.length, 1);
			expect(fromBuffer.snapshots[0].chunks, 5);
		});
	});
	
	group('tendermint.abci ResponseOfferSnapshot', () {
		test('constructor with ACCEPT result', () {
			final response = ResponseOfferSnapshot(
				result: ResponseOfferSnapshot_Result.ACCEPT,
			);
			
			expect(response.result, ResponseOfferSnapshot_Result.ACCEPT);
		});
		
		test('constructor with REJECT result', () {
			final response = ResponseOfferSnapshot(
				result: ResponseOfferSnapshot_Result.REJECT,
			);
			
			expect(response.result, ResponseOfferSnapshot_Result.REJECT);
		});
		
		test('constructor with ABORT result', () {
			final response = ResponseOfferSnapshot(
				result: ResponseOfferSnapshot_Result.ABORT,
			);
			
			expect(response.result, ResponseOfferSnapshot_Result.ABORT);
		});
		
		test('constructor with REJECT_FORMAT result', () {
			final response = ResponseOfferSnapshot(
				result: ResponseOfferSnapshot_Result.REJECT_FORMAT,
			);
			
			expect(response.result, ResponseOfferSnapshot_Result.REJECT_FORMAT);
		});
		
		test('constructor with REJECT_SENDER result', () {
			final response = ResponseOfferSnapshot(
				result: ResponseOfferSnapshot_Result.REJECT_SENDER,
			);
			
			expect(response.result, ResponseOfferSnapshot_Result.REJECT_SENDER);
		});
		
		test('default constructor', () {
			final response = ResponseOfferSnapshot();
			
			expect(response.result, ResponseOfferSnapshot_Result.UNKNOWN);
		});
		
		test('has/clear operations', () {
			final response = ResponseOfferSnapshot(
				result: ResponseOfferSnapshot_Result.ACCEPT,
			);
			
			expect(response.hasResult(), true);
			expect(response.result, ResponseOfferSnapshot_Result.ACCEPT);
			
			response.clearResult();
			expect(response.hasResult(), false);
			expect(response.result, ResponseOfferSnapshot_Result.UNKNOWN);
		});
		
		test('all result enum values', () {
			final results = [
				ResponseOfferSnapshot_Result.UNKNOWN,
				ResponseOfferSnapshot_Result.ACCEPT,
				ResponseOfferSnapshot_Result.ABORT,
				ResponseOfferSnapshot_Result.REJECT,
				ResponseOfferSnapshot_Result.REJECT_FORMAT,
				ResponseOfferSnapshot_Result.REJECT_SENDER,
			];
			
			for (int i = 0; i < results.length; i++) {
				final result = results[i];
				final response = ResponseOfferSnapshot(result: result);
				
				expect(response.result, result);
				expect(response.result.value, i);
				
				final buffer = response.writeToBuffer();
				final restored = ResponseOfferSnapshot.fromBuffer(buffer);
				expect(restored.result, result);
				expect(restored.result.value, i);
			}
		});
		
		test('JSON and buffer serialization', () {
			final response = ResponseOfferSnapshot(
				result: ResponseOfferSnapshot_Result.REJECT_FORMAT,
			);
			
			final json = jsonEncode(response.writeToJsonMap());
			final fromJson = ResponseOfferSnapshot.fromJson(json);
			expect(fromJson.result, ResponseOfferSnapshot_Result.REJECT_FORMAT);
			
			final buffer = response.writeToBuffer();
			final fromBuffer = ResponseOfferSnapshot.fromBuffer(buffer);
			expect(fromBuffer.result, ResponseOfferSnapshot_Result.REJECT_FORMAT);
		});
	});
	
	group('tendermint.abci ResponseLoadSnapshotChunk', () {
		test('constructor with chunk data', () {
			final chunkData = Uint8List(10000);
			for (int i = 0; i < 10000; i++) {
				chunkData[i] = (i * 7) % 256;
			}
			
			final response = ResponseLoadSnapshotChunk(chunk: chunkData);
			
			expect(response.chunk.length, 10000);
			expect(response.chunk[0], 0);
			expect(response.chunk[5000], 184); // (5000 * 7) % 256 = 184
			expect(response.chunk[9999], 105); // (9999 * 7) % 256 = 105
		});
		
		test('default constructor', () {
			final response = ResponseLoadSnapshotChunk();
			
			expect(response.chunk, isEmpty);
		});
		
		test('has/clear operations', () {
			final response = ResponseLoadSnapshotChunk(
				chunk: Uint8List.fromList([100, 101, 102, 103, 104]),
			);
			
			expect(response.hasChunk(), true);
			expect(response.chunk, [100, 101, 102, 103, 104]);
			
			response.clearChunk();
			expect(response.hasChunk(), false);
			expect(response.chunk, isEmpty);
		});
		
		test('various chunk sizes', () {
			final chunkSizes = [0, 1, 100, 1000, 50000];
			
			for (final size in chunkSizes) {
				final chunkData = Uint8List(size);
				for (int i = 0; i < size; i++) {
					chunkData[i] = (i * 11) % 256;
				}
				
				final response = ResponseLoadSnapshotChunk(chunk: chunkData);
				
				expect(response.chunk.length, size);
				
				if (size > 0) {
					expect(response.chunk[0], 0);
					if (size > 1) {
						expect(response.chunk[size - 1], ((size - 1) * 11) % 256);
					}
				}
				
				final buffer = response.writeToBuffer();
				final restored = ResponseLoadSnapshotChunk.fromBuffer(buffer);
				expect(restored.chunk.length, size);
				
				if (size > 100) {
					expect(restored.chunk[100], (100 * 11) % 256);
				}
			}
		});
		
		test('clone and copyWith operations', () {
			final original = ResponseLoadSnapshotChunk(
				chunk: Uint8List.fromList([1, 2, 3, 4, 5]),
			);
			
			final cloned = original.clone();
			expect(cloned.chunk, [1, 2, 3, 4, 5]);
			expect(identical(original, cloned), false);
			
			final copied = original.copyWith((message) {
				message.chunk = Uint8List.fromList([10, 20, 30]);
			});
			expect(copied.chunk, [10, 20, 30]);
			expect(original.chunk, [1, 2, 3, 4, 5]); // Original unchanged
		});
		
		test('JSON and buffer serialization', () {
			final response = ResponseLoadSnapshotChunk(
				chunk: Uint8List.fromList([255, 254, 253, 252, 251]),
			);
			
			final json = jsonEncode(response.writeToJsonMap());
			final fromJson = ResponseLoadSnapshotChunk.fromJson(json);
			expect(fromJson.chunk, [255, 254, 253, 252, 251]);
			
			final buffer = response.writeToBuffer();
			final fromBuffer = ResponseLoadSnapshotChunk.fromBuffer(buffer);
			expect(fromBuffer.chunk, [255, 254, 253, 252, 251]);
		});
	});
	
	group('tendermint.abci ResponseApplySnapshotChunk', () {
		test('constructor with ACCEPT result', () {
			final response = ResponseApplySnapshotChunk(
				result: ResponseApplySnapshotChunk_Result.ACCEPT,
				refetchChunks: [1, 2, 3],
				rejectSenders: ['peer1', 'peer2'],
			);
			
			expect(response.result, ResponseApplySnapshotChunk_Result.ACCEPT);
			expect(response.refetchChunks, [1, 2, 3]);
			expect(response.rejectSenders, ['peer1', 'peer2']);
		});
		
		test('constructor with ABORT result', () {
			final response = ResponseApplySnapshotChunk(
				result: ResponseApplySnapshotChunk_Result.ABORT,
			);
			
			expect(response.result, ResponseApplySnapshotChunk_Result.ABORT);
		});
		
		test('constructor with RETRY result', () {
			final response = ResponseApplySnapshotChunk(
				result: ResponseApplySnapshotChunk_Result.RETRY,
				refetchChunks: [5, 6, 7, 8],
			);
			
			expect(response.result, ResponseApplySnapshotChunk_Result.RETRY);
			expect(response.refetchChunks, [5, 6, 7, 8]);
		});
		
		test('constructor with RETRY_SNAPSHOT result', () {
			final response = ResponseApplySnapshotChunk(
				result: ResponseApplySnapshotChunk_Result.RETRY_SNAPSHOT,
			);
			
			expect(response.result, ResponseApplySnapshotChunk_Result.RETRY_SNAPSHOT);
		});
		
		test('constructor with REJECT_SNAPSHOT result', () {
			final response = ResponseApplySnapshotChunk(
				result: ResponseApplySnapshotChunk_Result.REJECT_SNAPSHOT,
			);
			
			expect(response.result, ResponseApplySnapshotChunk_Result.REJECT_SNAPSHOT);
		});
		
		test('default constructor', () {
			final response = ResponseApplySnapshotChunk();
			
			expect(response.result, ResponseApplySnapshotChunk_Result.UNKNOWN);
			expect(response.refetchChunks, isEmpty);
			expect(response.rejectSenders, isEmpty);
		});
		
		test('refetch chunks list operations', () {
			final response = ResponseApplySnapshotChunk();
			
			expect(response.refetchChunks, isEmpty);
			
			response.refetchChunks.addAll([10, 20, 30, 40]);
			expect(response.refetchChunks.length, 4);
			expect(response.refetchChunks[0], 10);
			expect(response.refetchChunks[3], 40);
			
			response.refetchChunks.removeAt(1);
			expect(response.refetchChunks.length, 3);
			expect(response.refetchChunks, [10, 30, 40]);
			
			response.refetchChunks.clear();
			expect(response.refetchChunks, isEmpty);
		});
		
		test('reject senders list operations', () {
			final response = ResponseApplySnapshotChunk();
			
			expect(response.rejectSenders, isEmpty);
			
			response.rejectSenders.addAll(['peer1', 'peer2', 'peer3']);
			expect(response.rejectSenders.length, 3);
			expect(response.rejectSenders[0], 'peer1');
			expect(response.rejectSenders[2], 'peer3');
			
			response.rejectSenders.removeWhere((sender) => sender == 'peer2');
			expect(response.rejectSenders.length, 2);
			expect(response.rejectSenders, ['peer1', 'peer3']);
			
			response.rejectSenders.clear();
			expect(response.rejectSenders, isEmpty);
		});
		
		test('all result enum values', () {
			final results = [
				ResponseApplySnapshotChunk_Result.UNKNOWN,
				ResponseApplySnapshotChunk_Result.ACCEPT,
				ResponseApplySnapshotChunk_Result.ABORT,
				ResponseApplySnapshotChunk_Result.RETRY,
				ResponseApplySnapshotChunk_Result.RETRY_SNAPSHOT,
				ResponseApplySnapshotChunk_Result.REJECT_SNAPSHOT,
			];
			
			for (int i = 0; i < results.length; i++) {
				final result = results[i];
				final response = ResponseApplySnapshotChunk(result: result);
				
				expect(response.result, result);
				expect(response.result.value, i);
				
				final buffer = response.writeToBuffer();
				final restored = ResponseApplySnapshotChunk.fromBuffer(buffer);
				expect(restored.result, result);
				expect(restored.result.value, i);
			}
		});
		
		test('large refetch chunks list', () {
			final largeChunksList = List.generate(1000, (i) => i * 2);
			
			final response = ResponseApplySnapshotChunk(
				result: ResponseApplySnapshotChunk_Result.RETRY,
				refetchChunks: largeChunksList,
			);
			
			expect(response.refetchChunks.length, 1000);
			expect(response.refetchChunks[500], 1000); // 500 * 2 = 1000
			expect(response.refetchChunks[999], 1998); // 999 * 2 = 1998
			
			final buffer = response.writeToBuffer();
			final restored = ResponseApplySnapshotChunk.fromBuffer(buffer);
			expect(restored.refetchChunks.length, 1000);
			expect(restored.refetchChunks[250], 500); // 250 * 2 = 500
		});
		
		test('JSON and buffer serialization', () {
			final response = ResponseApplySnapshotChunk(
				result: ResponseApplySnapshotChunk_Result.RETRY,
				refetchChunks: [100, 200, 300],
				rejectSenders: ['bad-peer-1', 'bad-peer-2'],
			);
			
			final json = jsonEncode(response.writeToJsonMap());
			final fromJson = ResponseApplySnapshotChunk.fromJson(json);
			expect(fromJson.result, ResponseApplySnapshotChunk_Result.RETRY);
			expect(fromJson.refetchChunks, [100, 200, 300]);
			expect(fromJson.rejectSenders, ['bad-peer-1', 'bad-peer-2']);
			
			final buffer = response.writeToBuffer();
			final fromBuffer = ResponseApplySnapshotChunk.fromBuffer(buffer);
			expect(fromBuffer.result, ResponseApplySnapshotChunk_Result.RETRY);
			expect(fromBuffer.refetchChunks, [100, 200, 300]);
			expect(fromBuffer.rejectSenders, ['bad-peer-1', 'bad-peer-2']);
		});
	});
	
	group('tendermint.abci snapshot response error handling', () {
		test('invalid buffer deserialization', () {
			final invalidBuffer = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF];
			
			expect(() => ResponseListSnapshots.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => ResponseOfferSnapshot.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => ResponseLoadSnapshotChunk.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => ResponseApplySnapshotChunk.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			const invalidJson = '{malformed json';
			
			expect(() => ResponseListSnapshots.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => ResponseOfferSnapshot.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => ResponseLoadSnapshotChunk.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => ResponseApplySnapshotChunk.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('tendermint.abci snapshot Response coverage', () {
		test('all snapshot Response types have proper info_', () {
			expect(ResponseListSnapshots().info_, isA<pb.BuilderInfo>());
			expect(ResponseOfferSnapshot().info_, isA<pb.BuilderInfo>());
			expect(ResponseLoadSnapshotChunk().info_, isA<pb.BuilderInfo>());
			expect(ResponseApplySnapshotChunk().info_, isA<pb.BuilderInfo>());
		});
		
		test('all snapshot Response types support createEmptyInstance', () {
			expect(ResponseListSnapshots().createEmptyInstance(), isA<ResponseListSnapshots>());
			expect(ResponseOfferSnapshot().createEmptyInstance(), isA<ResponseOfferSnapshot>());
			expect(ResponseLoadSnapshotChunk().createEmptyInstance(), isA<ResponseLoadSnapshotChunk>());
			expect(ResponseApplySnapshotChunk().createEmptyInstance(), isA<ResponseApplySnapshotChunk>());
		});
		
		test('getDefault returns same instance for all snapshot Response types', () {
			expect(identical(ResponseListSnapshots.getDefault(), ResponseListSnapshots.getDefault()), true);
			expect(identical(ResponseOfferSnapshot.getDefault(), ResponseOfferSnapshot.getDefault()), true);
			expect(identical(ResponseLoadSnapshotChunk.getDefault(), ResponseLoadSnapshotChunk.getDefault()), true);
			expect(identical(ResponseApplySnapshotChunk.getDefault(), ResponseApplySnapshotChunk.getDefault()), true);
		});
	});
} 