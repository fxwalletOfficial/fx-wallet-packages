import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/v1beta1/service.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/v1beta1/tx.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/query/v1beta1/pagination.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/abci/v1beta1/abci.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/types/block.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/types/types.pb.dart';

void main() {
	group('cosmos.tx.v1beta1 GetTxsEventRequest', () {
		test('constructor with all parameters', () {
			final pagination = PageRequest(
				offset: Int64(10),
				limit: Int64(50),
			);
			
			final request = GetTxsEventRequest(
				events: ['tx.height=1000', 'message.sender=cosmos1abc'],
				pagination: pagination,
				orderBy: OrderBy.ORDER_BY_ASC,
			);
			
			expect(request.events, ['tx.height=1000', 'message.sender=cosmos1abc']);
			expect(request.hasPagination(), true);
			expect(request.pagination.offset, Int64(10));
			expect(request.pagination.limit, Int64(50));
			expect(request.orderBy, OrderBy.ORDER_BY_ASC);
		});
		
		test('constructor with partial parameters', () {
			final request = GetTxsEventRequest(
				events: ['tx.height=2000'],
			);
			
			expect(request.events, ['tx.height=2000']);
			expect(request.hasPagination(), false);
			expect(request.orderBy, OrderBy.ORDER_BY_UNSPECIFIED);
		});
		
		test('default constructor', () {
			final request = GetTxsEventRequest();
			
			expect(request.events, isEmpty);
			expect(request.hasPagination(), false);
			expect(request.orderBy, OrderBy.ORDER_BY_UNSPECIFIED);
		});
		
		test('events list operations', () {
			final request = GetTxsEventRequest();
			
			expect(request.events, isEmpty);
			
			request.events.addAll(['event1', 'event2', 'event3']);
			expect(request.events.length, 3);
			expect(request.events[0], 'event1');
			expect(request.events[1], 'event2');
			expect(request.events[2], 'event3');
			
			request.events.removeAt(1);
			expect(request.events.length, 2);
			expect(request.events[1], 'event3');
			
			request.events.clear();
			expect(request.events, isEmpty);
		});
		
		test('has/clear/ensure operations', () {
			final request = GetTxsEventRequest();
			
			expect(request.hasPagination(), false);
			
			final pagination = request.ensurePagination();
			expect(request.hasPagination(), true);
			expect(pagination, isA<PageRequest>());
			
			request.clearPagination();
			expect(request.hasPagination(), false);
		});
		
		test('orderBy enum values', () {
			final orders = [
				OrderBy.ORDER_BY_UNSPECIFIED,
				OrderBy.ORDER_BY_ASC,
				OrderBy.ORDER_BY_DESC,
			];
			
			for (final order in orders) {
				final request = GetTxsEventRequest(orderBy: order);
				expect(request.orderBy, order);
				
				final buffer = request.writeToBuffer();
				final fromBuffer = GetTxsEventRequest.fromBuffer(buffer);
				expect(fromBuffer.orderBy, order);
			}
		});
		
		test('JSON and buffer serialization', () {
			final request = GetTxsEventRequest(
				events: ['test.event=value'],
				orderBy: OrderBy.ORDER_BY_DESC,
			);
			request.ensurePagination();
			request.pagination.limit = Int64(100);
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = GetTxsEventRequest.fromJson(json);
			expect(fromJson.events, ['test.event=value']);
			expect(fromJson.orderBy, OrderBy.ORDER_BY_DESC);
			expect(fromJson.hasPagination(), true);
			expect(fromJson.pagination.limit, Int64(100));
			
			final buffer = request.writeToBuffer();
			final fromBuffer = GetTxsEventRequest.fromBuffer(buffer);
			expect(fromBuffer.events, ['test.event=value']);
			expect(fromBuffer.orderBy, OrderBy.ORDER_BY_DESC);
			expect(fromBuffer.pagination.limit, Int64(100));
		});
	});
	
	group('cosmos.tx.v1beta1 GetTxsEventResponse', () {
		test('constructor with all parameters', () {
			final tx1 = Tx();
			final tx2 = Tx();
			final txResponse1 = TxResponse();
			final txResponse2 = TxResponse();
			final pagination = PageResponse(total: Int64(200));
			
			final response = GetTxsEventResponse(
				txs: [tx1, tx2],
				txResponses: [txResponse1, txResponse2],
				pagination: pagination,
			);
			
			expect(response.txs.length, 2);
			expect(response.txResponses.length, 2);
			expect(response.hasPagination(), true);
			expect(response.pagination.total, Int64(200));
		});
		
		test('default constructor', () {
			final response = GetTxsEventResponse();
			
			expect(response.txs, isEmpty);
			expect(response.txResponses, isEmpty);
			expect(response.hasPagination(), false);
		});
		
		test('list operations', () {
			final response = GetTxsEventResponse();
			
			// Test txs
			final tx1 = Tx();
			final tx2 = Tx();
			
			response.txs.addAll([tx1, tx2]);
			expect(response.txs.length, 2);
			
			response.txs.removeAt(0);
			expect(response.txs.length, 1);
			
			// Test txResponses
			final txResp1 = TxResponse();
			final txResp2 = TxResponse();
			
			response.txResponses.addAll([txResp1, txResp2]);
			expect(response.txResponses.length, 2);
			
			response.txResponses.clear();
			expect(response.txResponses, isEmpty);
		});
		
		test('has/clear/ensure operations', () {
			final response = GetTxsEventResponse();
			
			expect(response.hasPagination(), false);
			
			final pagination = response.ensurePagination();
			expect(response.hasPagination(), true);
			expect(pagination, isA<PageResponse>());
			
			response.clearPagination();
			expect(response.hasPagination(), false);
		});
	});
	
	group('cosmos.tx.v1beta1 BroadcastTxRequest', () {
		test('constructor with all parameters', () {
			final txBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
			
			final request = BroadcastTxRequest(
				txBytes: txBytes,
				mode: BroadcastMode.BROADCAST_MODE_SYNC,
			);
			
			expect(request.txBytes, [1, 2, 3, 4, 5]);
			expect(request.mode, BroadcastMode.BROADCAST_MODE_SYNC);
		});
		
		test('default constructor', () {
			final request = BroadcastTxRequest();
			
			expect(request.txBytes, isEmpty);
			expect(request.mode, BroadcastMode.BROADCAST_MODE_UNSPECIFIED);
		});
		
		test('has/clear operations', () {
			final request = BroadcastTxRequest(
				txBytes: Uint8List.fromList([10, 20, 30]),
				mode: BroadcastMode.BROADCAST_MODE_ASYNC,
			);
			
			expect(request.hasTxBytes(), true);
			expect(request.hasMode(), true);
			
			request.clearTxBytes();
			request.clearMode();
			
			expect(request.hasTxBytes(), false);
			expect(request.hasMode(), false);
			expect(request.txBytes, isEmpty);
			expect(request.mode, BroadcastMode.BROADCAST_MODE_UNSPECIFIED);
		});
		
		test('broadcast mode enum values', () {
			final modes = [
				BroadcastMode.BROADCAST_MODE_UNSPECIFIED,
				BroadcastMode.BROADCAST_MODE_BLOCK,
				BroadcastMode.BROADCAST_MODE_SYNC,
				BroadcastMode.BROADCAST_MODE_ASYNC,
			];
			
			for (final mode in modes) {
				final request = BroadcastTxRequest(mode: mode);
				expect(request.mode, mode);
				
				final buffer = request.writeToBuffer();
				final fromBuffer = BroadcastTxRequest.fromBuffer(buffer);
				expect(fromBuffer.mode, mode);
			}
		});
		
		test('large tx bytes', () {
			final largeTxBytes = Uint8List(10000);
			for (int i = 0; i < 10000; i++) {
				largeTxBytes[i] = i % 256;
			}
			
			final request = BroadcastTxRequest(txBytes: largeTxBytes);
			
			expect(request.txBytes.length, 10000);
			expect(request.txBytes[0], 0);
			expect(request.txBytes[9999], 15);
			
			final buffer = request.writeToBuffer();
			final fromBuffer = BroadcastTxRequest.fromBuffer(buffer);
			expect(fromBuffer.txBytes.length, 10000);
			expect(fromBuffer.txBytes[0], 0);
			expect(fromBuffer.txBytes[9999], 15);
		});
	});
	
	group('cosmos.tx.v1beta1 BroadcastTxResponse', () {
		test('constructor with txResponse', () {
			final txResponse = TxResponse(
				txhash: 'ABC123DEF456',
				code: 0,
			);
			
			final response = BroadcastTxResponse(txResponse: txResponse);
			
			expect(response.hasTxResponse(), true);
			expect(response.txResponse.txhash, 'ABC123DEF456');
			expect(response.txResponse.code, 0);
		});
		
		test('default constructor', () {
			final response = BroadcastTxResponse();
			
			expect(response.hasTxResponse(), false);
		});
		
		test('has/clear/ensure operations', () {
			final response = BroadcastTxResponse();
			
			expect(response.hasTxResponse(), false);
			
			final txResponse = response.ensureTxResponse();
			expect(response.hasTxResponse(), true);
			expect(txResponse, isA<TxResponse>());
			
			response.clearTxResponse();
			expect(response.hasTxResponse(), false);
		});
	});
	
	group('cosmos.tx.v1beta1 SimulateRequest', () {
		test('constructor with tx', () {
			final tx = Tx();
			tx.ensureBody();
			
			final request = SimulateRequest(tx: tx);
			
			expect(request.hasTx(), true);
			expect(request.tx.hasBody(), true);
		});
		
		test('constructor with txBytes', () {
			final txBytes = Uint8List.fromList([100, 101, 102]);
			
			final request = SimulateRequest(txBytes: txBytes);
			
			expect(request.txBytes, [100, 101, 102]);
			expect(request.hasTx(), false);
		});
		
		test('default constructor', () {
			final request = SimulateRequest();
			
			expect(request.hasTx(), false);
			expect(request.txBytes, isEmpty);
		});
		
		test('has/clear/ensure operations', () {
			final request = SimulateRequest();
			
			expect(request.hasTx(), false);
			expect(request.hasTxBytes(), false);
			
			final tx = request.ensureTx();
			expect(request.hasTx(), true);
			expect(tx, isA<Tx>());
			
			request.clearTx();
			expect(request.hasTx(), false);
			
			request.txBytes = Uint8List.fromList([1, 2, 3]);
			expect(request.hasTxBytes(), true);
			
			request.clearTxBytes();
			expect(request.hasTxBytes(), false);
			expect(request.txBytes, isEmpty);
		});
	});
	
	group('cosmos.tx.v1beta1 SimulateResponse', () {
		test('constructor with all parameters', () {
			final gasInfo = GasInfo(
				gasWanted: Int64(200000),
				gasUsed: Int64(150000),
			);
			final result = Result();
			
			final response = SimulateResponse(
				gasInfo: gasInfo,
				result: result,
			);
			
			expect(response.hasGasInfo(), true);
			expect(response.gasInfo.gasWanted, Int64(200000));
			expect(response.gasInfo.gasUsed, Int64(150000));
			expect(response.hasResult(), true);
		});
		
		test('default constructor', () {
			final response = SimulateResponse();
			
			expect(response.hasGasInfo(), false);
			expect(response.hasResult(), false);
		});
		
		test('has/clear/ensure operations', () {
			final response = SimulateResponse();
			
			// Test gasInfo
			expect(response.hasGasInfo(), false);
			final gasInfo = response.ensureGasInfo();
			expect(response.hasGasInfo(), true);
			expect(gasInfo, isA<GasInfo>());
			
			response.clearGasInfo();
			expect(response.hasGasInfo(), false);
			
			// Test result
			expect(response.hasResult(), false);
			final result = response.ensureResult();
			expect(response.hasResult(), true);
			expect(result, isA<Result>());
			
			response.clearResult();
			expect(response.hasResult(), false);
		});
	});
	
	group('cosmos.tx.v1beta1 GetTxRequest', () {
		test('constructor with hash', () {
			final request = GetTxRequest(hash: 'ABCDEF1234567890');
			
			expect(request.hash, 'ABCDEF1234567890');
		});
		
		test('default constructor', () {
			final request = GetTxRequest();
			
			expect(request.hash, '');
		});
		
		test('has/clear operations', () {
			final request = GetTxRequest(hash: 'test-hash-123');
			
			expect(request.hasHash(), true);
			expect(request.hash, 'test-hash-123');
			
			request.clearHash();
			expect(request.hasHash(), false);
			expect(request.hash, '');
		});
		
		test('long hash values', () {
			final longHash = 'A' * 1000; // 1000 character hash
			final request = GetTxRequest(hash: longHash);
			
			expect(request.hash, longHash);
			expect(request.hash.length, 1000);
			
			final buffer = request.writeToBuffer();
			final fromBuffer = GetTxRequest.fromBuffer(buffer);
			expect(fromBuffer.hash, longHash);
			expect(fromBuffer.hash.length, 1000);
		});
	});
	
	group('cosmos.tx.v1beta1 GetTxResponse', () {
		test('constructor with all parameters', () {
			final tx = Tx();
			final txResponse = TxResponse();
			
			final response = GetTxResponse(
				tx: tx,
				txResponse: txResponse,
			);
			
			expect(response.hasTx(), true);
			expect(response.hasTxResponse(), true);
		});
		
		test('default constructor', () {
			final response = GetTxResponse();
			
			expect(response.hasTx(), false);
			expect(response.hasTxResponse(), false);
		});
		
		test('has/clear/ensure operations', () {
			final response = GetTxResponse();
			
			// Test tx
			expect(response.hasTx(), false);
			final tx = response.ensureTx();
			expect(response.hasTx(), true);
			expect(tx, isA<Tx>());
			
			response.clearTx();
			expect(response.hasTx(), false);
			
			// Test txResponse
			expect(response.hasTxResponse(), false);
			final txResponse = response.ensureTxResponse();
			expect(response.hasTxResponse(), true);
			expect(txResponse, isA<TxResponse>());
			
			response.clearTxResponse();
			expect(response.hasTxResponse(), false);
		});
	});
	
	group('cosmos.tx.v1beta1 GetBlockWithTxsRequest', () {
		test('constructor with all parameters', () {
			final pagination = PageRequest(limit: Int64(25));
			
			final request = GetBlockWithTxsRequest(
				height: Int64(1000000),
				pagination: pagination,
			);
			
			expect(request.height, Int64(1000000));
			expect(request.hasPagination(), true);
			expect(request.pagination.limit, Int64(25));
		});
		
		test('default constructor', () {
			final request = GetBlockWithTxsRequest();
			
			expect(request.height, Int64.ZERO);
			expect(request.hasPagination(), false);
		});
		
		test('has/clear operations', () {
			final request = GetBlockWithTxsRequest(
				height: Int64(500000),
			);
			
			expect(request.hasHeight(), true);
			expect(request.height, Int64(500000));
			
			request.clearHeight();
			expect(request.hasHeight(), false);
			expect(request.height, Int64.ZERO);
		});
		
		test('large height values', () {
			final request = GetBlockWithTxsRequest(
				height: Int64.parseInt('9223372036854775807'),
			);
			
			expect(request.height.toString(), '9223372036854775807');
			
			final buffer = request.writeToBuffer();
			final fromBuffer = GetBlockWithTxsRequest.fromBuffer(buffer);
			expect(fromBuffer.height.toString(), '9223372036854775807');
		});
	});
	
	group('cosmos.tx.v1beta1 GetBlockWithTxsResponse', () {
		test('constructor with all parameters', () {
			final tx1 = Tx();
			final tx2 = Tx();
			final blockId = BlockID();
			final block = Block();
			final pagination = PageResponse(total: Int64(50));
			
			final response = GetBlockWithTxsResponse(
				txs: [tx1, tx2],
				blockId: blockId,
				block: block,
				pagination: pagination,
			);
			
			expect(response.txs.length, 2);
			expect(response.hasBlockId(), true);
			expect(response.hasBlock(), true);
			expect(response.hasPagination(), true);
			expect(response.pagination.total, Int64(50));
		});
		
		test('default constructor', () {
			final response = GetBlockWithTxsResponse();
			
			expect(response.txs, isEmpty);
			expect(response.hasBlockId(), false);
			expect(response.hasBlock(), false);
			expect(response.hasPagination(), false);
		});
		
		test('list operations', () {
			final response = GetBlockWithTxsResponse();
			
			final tx1 = Tx();
			final tx2 = Tx();
			final tx3 = Tx();
			
			response.txs.addAll([tx1, tx2, tx3]);
			expect(response.txs.length, 3);
			
			response.txs.removeRange(1, 3);
			expect(response.txs.length, 1);
			
			response.txs.clear();
			expect(response.txs, isEmpty);
		});
		
		test('has/clear/ensure operations', () {
			final response = GetBlockWithTxsResponse();
			
			// Test blockId
			expect(response.hasBlockId(), false);
			final blockId = response.ensureBlockId();
			expect(response.hasBlockId(), true);
			expect(blockId, isA<BlockID>());
			
			response.clearBlockId();
			expect(response.hasBlockId(), false);
			
			// Test block
			expect(response.hasBlock(), false);
			final block = response.ensureBlock();
			expect(response.hasBlock(), true);
			expect(block, isA<Block>());
			
			response.clearBlock();
			expect(response.hasBlock(), false);
			
			// Test pagination
			expect(response.hasPagination(), false);
			final pagination = response.ensurePagination();
			expect(response.hasPagination(), true);
			expect(pagination, isA<PageResponse>());
			
			response.clearPagination();
			expect(response.hasPagination(), false);
		});
	});
	
	group('cosmos.tx.v1beta1 error handling', () {
		test('invalid buffer deserialization', () {
			expect(() => GetTxsEventRequest.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => GetTxsEventResponse.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => BroadcastTxRequest.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => BroadcastTxResponse.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => SimulateRequest.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => SimulateResponse.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => GetTxRequest.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => GetTxResponse.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => GetBlockWithTxsRequest.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => GetBlockWithTxsResponse.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			expect(() => GetTxsEventRequest.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => GetTxsEventResponse.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => BroadcastTxRequest.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => BroadcastTxResponse.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => SimulateRequest.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => SimulateResponse.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => GetTxRequest.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => GetTxResponse.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => GetBlockWithTxsRequest.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => GetBlockWithTxsResponse.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('cosmos.tx.v1beta1 comprehensive coverage', () {
		test('all message types have proper info_', () {
			expect(GetTxsEventRequest().info_, isA<pb.BuilderInfo>());
			expect(GetTxsEventResponse().info_, isA<pb.BuilderInfo>());
			expect(BroadcastTxRequest().info_, isA<pb.BuilderInfo>());
			expect(BroadcastTxResponse().info_, isA<pb.BuilderInfo>());
			expect(SimulateRequest().info_, isA<pb.BuilderInfo>());
			expect(SimulateResponse().info_, isA<pb.BuilderInfo>());
			expect(GetTxRequest().info_, isA<pb.BuilderInfo>());
			expect(GetTxResponse().info_, isA<pb.BuilderInfo>());
			expect(GetBlockWithTxsRequest().info_, isA<pb.BuilderInfo>());
			expect(GetBlockWithTxsResponse().info_, isA<pb.BuilderInfo>());
		});
		
		test('all message types support createEmptyInstance', () {
			expect(GetTxsEventRequest().createEmptyInstance(), isA<GetTxsEventRequest>());
			expect(GetTxsEventResponse().createEmptyInstance(), isA<GetTxsEventResponse>());
			expect(BroadcastTxRequest().createEmptyInstance(), isA<BroadcastTxRequest>());
			expect(BroadcastTxResponse().createEmptyInstance(), isA<BroadcastTxResponse>());
			expect(SimulateRequest().createEmptyInstance(), isA<SimulateRequest>());
			expect(SimulateResponse().createEmptyInstance(), isA<SimulateResponse>());
			expect(GetTxRequest().createEmptyInstance(), isA<GetTxRequest>());
			expect(GetTxResponse().createEmptyInstance(), isA<GetTxResponse>());
			expect(GetBlockWithTxsRequest().createEmptyInstance(), isA<GetBlockWithTxsRequest>());
			expect(GetBlockWithTxsResponse().createEmptyInstance(), isA<GetBlockWithTxsResponse>());
		});
		
		test('getDefault returns same instance for all types', () {
			expect(identical(GetTxsEventRequest.getDefault(), GetTxsEventRequest.getDefault()), isTrue);
			expect(identical(GetTxsEventResponse.getDefault(), GetTxsEventResponse.getDefault()), isTrue);
			expect(identical(BroadcastTxRequest.getDefault(), BroadcastTxRequest.getDefault()), isTrue);
			expect(identical(BroadcastTxResponse.getDefault(), BroadcastTxResponse.getDefault()), isTrue);
			expect(identical(SimulateRequest.getDefault(), SimulateRequest.getDefault()), isTrue);
			expect(identical(SimulateResponse.getDefault(), SimulateResponse.getDefault()), isTrue);
			expect(identical(GetTxRequest.getDefault(), GetTxRequest.getDefault()), isTrue);
			expect(identical(GetTxResponse.getDefault(), GetTxResponse.getDefault()), isTrue);
			expect(identical(GetBlockWithTxsRequest.getDefault(), GetBlockWithTxsRequest.getDefault()), isTrue);
			expect(identical(GetBlockWithTxsResponse.getDefault(), GetBlockWithTxsResponse.getDefault()), isTrue);
		});
		
		test('complex service interaction roundtrip', () {
			// Create a complex GetTxsEventRequest
			final request = GetTxsEventRequest();
			request.events.addAll([
				'tx.height>1000000',
				'message.sender=cosmos1abc123def456',
				'transfer.recipient=cosmos1xyz789',
			]);
			request.ensurePagination();
			request.pagination.offset = Int64(50);
			request.pagination.limit = Int64(25);
			request.pagination.countTotal = true;
			request.orderBy = OrderBy.ORDER_BY_DESC;
			
			// Test JSON roundtrip
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = GetTxsEventRequest.fromJson(json);
			
			expect(fromJson.events.length, 3);
			expect(fromJson.events[0], 'tx.height>1000000');
			expect(fromJson.events[1], 'message.sender=cosmos1abc123def456');
			expect(fromJson.events[2], 'transfer.recipient=cosmos1xyz789');
			expect(fromJson.hasPagination(), true);
			expect(fromJson.pagination.offset, Int64(50));
			expect(fromJson.pagination.limit, Int64(25));
			expect(fromJson.pagination.countTotal, true);
			expect(fromJson.orderBy, OrderBy.ORDER_BY_DESC);
			
			// Test buffer roundtrip
			final buffer = request.writeToBuffer();
			final fromBuffer = GetTxsEventRequest.fromBuffer(buffer);
			
			expect(fromBuffer.events.length, 3);
			expect(fromBuffer.events[0], 'tx.height>1000000');
			expect(fromBuffer.orderBy, OrderBy.ORDER_BY_DESC);
			expect(fromBuffer.pagination.offset, Int64(50));
			expect(fromBuffer.pagination.limit, Int64(25));
			expect(fromBuffer.pagination.countTotal, true);
		});
		
		test('broadcast transaction flow', () {
			// Create a broadcast request
			final txBytes = Uint8List(100);
			for (int i = 0; i < 100; i++) {
				txBytes[i] = i;
			}
			
			final broadcastRequest = BroadcastTxRequest(
				txBytes: txBytes,
				mode: BroadcastMode.BROADCAST_MODE_BLOCK,
			);
			
			// Simulate response
			final broadcastResponse = BroadcastTxResponse();
			broadcastResponse.ensureTxResponse();
			broadcastResponse.txResponse.txhash = 'ABCDEF123456789';
			broadcastResponse.txResponse.code = 0;
			broadcastResponse.txResponse.height = Int64(1234567);
			
			// Test serialization
			final requestBuffer = broadcastRequest.writeToBuffer();
			final responseBuffer = broadcastResponse.writeToBuffer();
			
			final restoredRequest = BroadcastTxRequest.fromBuffer(requestBuffer);
			final restoredResponse = BroadcastTxResponse.fromBuffer(responseBuffer);
			
			expect(restoredRequest.txBytes.length, 100);
			expect(restoredRequest.txBytes[0], 0);
			expect(restoredRequest.txBytes[99], 99);
			expect(restoredRequest.mode, BroadcastMode.BROADCAST_MODE_BLOCK);
			
			expect(restoredResponse.hasTxResponse(), true);
			expect(restoredResponse.txResponse.txhash, 'ABCDEF123456789');
			expect(restoredResponse.txResponse.code, 0);
			expect(restoredResponse.txResponse.height, Int64(1234567));
		});
		
		test('simulation flow', () {
			// Create simulation request with Tx
			final simulateRequest = SimulateRequest();
			simulateRequest.ensureTx();
			simulateRequest.tx.ensureBody();
			simulateRequest.tx.body.memo = 'Simulation test';
			simulateRequest.tx.ensureAuthInfo();
			
			// Create simulation response
			final simulateResponse = SimulateResponse();
			simulateResponse.ensureGasInfo();
			simulateResponse.gasInfo.gasWanted = Int64(300000);
			simulateResponse.gasInfo.gasUsed = Int64(250000);
			simulateResponse.ensureResult();
			
			// Test roundtrip
			final requestJson = jsonEncode(simulateRequest.writeToJsonMap());
			final responseJson = jsonEncode(simulateResponse.writeToJsonMap());
			
			final restoredRequest = SimulateRequest.fromJson(requestJson);
			final restoredResponse = SimulateResponse.fromJson(responseJson);
			
			expect(restoredRequest.hasTx(), true);
			expect(restoredRequest.tx.hasBody(), true);
			expect(restoredRequest.tx.body.memo, 'Simulation test');
			expect(restoredRequest.tx.hasAuthInfo(), true);
			
			expect(restoredResponse.hasGasInfo(), true);
			expect(restoredResponse.gasInfo.gasWanted, Int64(300000));
			expect(restoredResponse.gasInfo.gasUsed, Int64(250000));
			expect(restoredResponse.hasResult(), true);
		});
		
		test('enum value consistency', () {
			// Test OrderBy enum
			expect(OrderBy.valueOf(0), OrderBy.ORDER_BY_UNSPECIFIED);
			expect(OrderBy.valueOf(1), OrderBy.ORDER_BY_ASC);
			expect(OrderBy.valueOf(2), OrderBy.ORDER_BY_DESC);
			
			// Test BroadcastMode enum
			expect(BroadcastMode.valueOf(0), BroadcastMode.BROADCAST_MODE_UNSPECIFIED);
			expect(BroadcastMode.valueOf(1), BroadcastMode.BROADCAST_MODE_BLOCK);
			expect(BroadcastMode.valueOf(2), BroadcastMode.BROADCAST_MODE_SYNC);
			expect(BroadcastMode.valueOf(3), BroadcastMode.BROADCAST_MODE_ASYNC);
		});
	});
} 