import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/query.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/bank.pb.dart' as bank;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart' as coin;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/query/v1beta1/pagination.pb.dart' as pagination;
import 'package:fixnum/fixnum.dart';

void main() {
	group('cosmos.bank.v1beta1 QueryBalanceRequest', () {
		test('constructor with address and denom', () {
			final request = QueryBalanceRequest(
				address: 'cosmos1abc123',
				denom: 'stake'
			);
			
			expect(request.address, 'cosmos1abc123');
			expect(request.denom, 'stake');
		});
		
		test('has/clear operations', () {
			final request = QueryBalanceRequest(
				address: 'cosmos1test',
				denom: 'atom'
			);
			
			expect(request.hasAddress(), isTrue);
			expect(request.hasDenom(), isTrue);
			
			request.clearAddress();
			request.clearDenom();
			
			expect(request.hasAddress(), isFalse);
			expect(request.hasDenom(), isFalse);
		});
		
		test('JSON and buffer serialization', () {
			final request = QueryBalanceRequest(
				address: 'cosmos1json',
				denom: 'stake'
			);
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = QueryBalanceRequest.fromJson(json);
			expect(fromJson.address, 'cosmos1json');
			expect(fromJson.denom, 'stake');
			
			final buffer = request.writeToBuffer();
			final fromBuffer = QueryBalanceRequest.fromBuffer(buffer);
			expect(fromBuffer.address, 'cosmos1json');
			expect(fromBuffer.denom, 'stake');
		});
		
		test('clone and copyWith operations', () {
			final original = QueryBalanceRequest(
				address: 'cosmos1original',
				denom: 'stake'
			);
			
			final cloned = original.clone();
			expect(cloned.address, 'cosmos1original');
			expect(cloned.denom, 'stake');
			
			final copied = original.copyWith((req) {
				req.address = 'cosmos1copied';
				req.denom = 'atom';
			});
			expect(copied.address, 'cosmos1copied');
			expect(copied.denom, 'atom');
			expect(original.address, 'cosmos1original'); // original unchanged
		});
	});
	
	group('cosmos.bank.v1beta1 QueryBalanceResponse', () {
		test('constructor with balance', () {
			final response = QueryBalanceResponse(
				balance: coin.CosmosCoin(denom: 'stake', amount: '1000')
			);
			
			expect(response.balance.denom, 'stake');
			expect(response.balance.amount, '1000');
		});
		
		test('has/clear/ensure balance operations', () {
			final response = QueryBalanceResponse(
				balance: coin.CosmosCoin(denom: 'atom', amount: '500')
			);
			
			expect(response.hasBalance(), isTrue);
			
			// Ensure returns same instance
			final ensuredBalance = response.ensureBalance();
			expect(identical(ensuredBalance, response.balance), isTrue);
			
			response.clearBalance();
			expect(response.hasBalance(), isFalse);
			
			// Ensure creates new instance when cleared
			final newBalance = response.ensureBalance();
			expect(response.hasBalance(), isTrue);
			expect(newBalance, isA<coin.CosmosCoin>());
		});
		
		test('JSON and buffer serialization', () {
			final response = QueryBalanceResponse(
				balance: coin.CosmosCoin(denom: 'osmo', amount: '2500')
			);
			
			final json = jsonEncode(response.writeToJsonMap());
			final fromJson = QueryBalanceResponse.fromJson(json);
			expect(fromJson.balance.denom, 'osmo');
			expect(fromJson.balance.amount, '2500');
			
			final buffer = response.writeToBuffer();
			final fromBuffer = QueryBalanceResponse.fromBuffer(buffer);
			expect(fromBuffer.balance.denom, 'osmo');
			expect(fromBuffer.balance.amount, '2500');
		});
	});
	
	group('cosmos.bank.v1beta1 QueryAllBalancesRequest', () {
		test('constructor with address and pagination', () {
			final request = QueryAllBalancesRequest(
				address: 'cosmos1all',
				pagination: pagination.PageRequest(
					key: [1, 2, 3],
					offset: Int64(10),
					limit: Int64(100),
					countTotal: true
				)
			);
			
			expect(request.address, 'cosmos1all');
			expect(request.pagination.offset.toInt(), 10);
			expect(request.pagination.limit.toInt(), 100);
			expect(request.pagination.countTotal, true);
		});
		
		test('has/clear/ensure operations', () {
			final request = QueryAllBalancesRequest(
				address: 'cosmos1test',
				pagination: pagination.PageRequest(limit: Int64(50))
			);
			
			expect(request.hasAddress(), isTrue);
			expect(request.hasPagination(), isTrue);
			
			// Ensure returns same instance
			final ensuredPagination = request.ensurePagination();
			expect(identical(ensuredPagination, request.pagination), isTrue);
			
			request.clearAddress();
			request.clearPagination();
			
			expect(request.hasAddress(), isFalse);
			expect(request.hasPagination(), isFalse);
		});
		
		test('JSON and buffer serialization', () {
			final request = QueryAllBalancesRequest(
				address: 'cosmos1json',
				pagination: pagination.PageRequest(limit: Int64(25))
			);
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = QueryAllBalancesRequest.fromJson(json);
			expect(fromJson.address, 'cosmos1json');
			expect(fromJson.pagination.limit.toInt(), 25);
			
			final buffer = request.writeToBuffer();
			final fromBuffer = QueryAllBalancesRequest.fromBuffer(buffer);
			expect(fromBuffer.address, 'cosmos1json');
		});
	});
	
	group('cosmos.bank.v1beta1 QueryAllBalancesResponse', () {
		test('constructor with balances and pagination', () {
			final response = QueryAllBalancesResponse(
				balances: [
					coin.CosmosCoin(denom: 'stake', amount: '1000'),
					coin.CosmosCoin(denom: 'atom', amount: '500')
				],
				pagination: pagination.PageResponse(
					nextKey: [4, 5, 6],
					total: Int64(2)
				)
			);
			
			expect(response.balances.length, 2);
			expect(response.balances.first.denom, 'stake');
			expect(response.balances.last.denom, 'atom');
			expect(response.pagination.total.toInt(), 2);
		});
		
		test('balances list operations', () {
			final response = QueryAllBalancesResponse();
			
			response.balances.add(coin.CosmosCoin(denom: 'stake', amount: '1000'));
			response.balances.add(coin.CosmosCoin(denom: 'atom', amount: '500'));
			expect(response.balances.length, 2);
			
			response.balances.removeAt(0);
			expect(response.balances.length, 1);
			expect(response.balances.first.denom, 'atom');
			
			response.balances.clear();
			expect(response.balances, isEmpty);
		});
		
		test('has/clear/ensure pagination operations', () {
			final response = QueryAllBalancesResponse(
				pagination: pagination.PageResponse(total: Int64(10))
			);
			
			expect(response.hasPagination(), isTrue);
			
			response.clearPagination();
			expect(response.hasPagination(), isFalse);
			
			final newPagination = response.ensurePagination();
			expect(response.hasPagination(), isTrue);
			expect(newPagination, isA<pagination.PageResponse>());
		});
	});
	
	group('cosmos.bank.v1beta1 QueryTotalSupplyRequest', () {
		test('constructor with pagination', () {
			final request = QueryTotalSupplyRequest(
				pagination: pagination.PageRequest(
					offset: Int64(5),
					limit: Int64(20),
					countTotal: false
				)
			);
			
			expect(request.pagination.offset.toInt(), 5);
			expect(request.pagination.limit.toInt(), 20);
			expect(request.pagination.countTotal, false);
		});
		
		test('has/clear/ensure pagination operations', () {
			final request = QueryTotalSupplyRequest(
				pagination: pagination.PageRequest(limit: Int64(10))
			);
			
			expect(request.hasPagination(), isTrue);
			
			request.clearPagination();
			expect(request.hasPagination(), isFalse);
			
			final newPagination = request.ensurePagination();
			expect(request.hasPagination(), isTrue);
			expect(newPagination, isA<pagination.PageRequest>());
		});
		
		test('JSON and buffer serialization', () {
			final request = QueryTotalSupplyRequest(
				pagination: pagination.PageRequest(limit: Int64(15))
			);
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = QueryTotalSupplyRequest.fromJson(json);
			expect(fromJson.pagination.limit.toInt(), 15);
			
			final buffer = request.writeToBuffer();
			final fromBuffer = QueryTotalSupplyRequest.fromBuffer(buffer);
			expect(fromBuffer.pagination.limit.toInt(), 15);
		});
	});
	
	group('cosmos.bank.v1beta1 QueryTotalSupplyResponse', () {
		test('constructor with supply and pagination', () {
			final response = QueryTotalSupplyResponse(
				supply: [
					coin.CosmosCoin(denom: 'stake', amount: '1000000'),
					coin.CosmosCoin(denom: 'atom', amount: '500000')
							],
			pagination: pagination.PageResponse(total: Int64(2))
		);
		
		expect(response.supply.length, 2);
			expect(response.supply.first.amount, '1000000');
			expect(response.pagination.total.toInt(), 2);
		});
		
		test('supply list operations', () {
			final response = QueryTotalSupplyResponse();
			
			response.supply.add(coin.CosmosCoin(denom: 'stake', amount: '1000000'));
			expect(response.supply.length, 1);
			
			response.supply.addAll([
				coin.CosmosCoin(denom: 'atom', amount: '500000'),
				coin.CosmosCoin(denom: 'osmo', amount: '250000')
			]);
			expect(response.supply.length, 3);
			
			response.supply.clear();
			expect(response.supply, isEmpty);
		});
	});
	
	group('cosmos.bank.v1beta1 QuerySupplyOfRequest', () {
		test('constructor with denom', () {
			final request = QuerySupplyOfRequest(denom: 'stake');
			expect(request.denom, 'stake');
		});
		
		test('has/clear denom operations', () {
			final request = QuerySupplyOfRequest(denom: 'atom');
			
			expect(request.hasDenom(), isTrue);
			request.clearDenom();
			expect(request.hasDenom(), isFalse);
		});
		
		test('JSON and buffer serialization', () {
			final request = QuerySupplyOfRequest(denom: 'osmo');
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = QuerySupplyOfRequest.fromJson(json);
			expect(fromJson.denom, 'osmo');
			
			final buffer = request.writeToBuffer();
			final fromBuffer = QuerySupplyOfRequest.fromBuffer(buffer);
			expect(fromBuffer.denom, 'osmo');
		});
	});
	
	group('cosmos.bank.v1beta1 QuerySupplyOfResponse', () {
		test('constructor with amount', () {
			final response = QuerySupplyOfResponse(
				amount: coin.CosmosCoin(denom: 'stake', amount: '1000000')
			);
			
			expect(response.amount.denom, 'stake');
			expect(response.amount.amount, '1000000');
		});
		
		test('has/clear/ensure amount operations', () {
			final response = QuerySupplyOfResponse(
				amount: coin.CosmosCoin(denom: 'atom', amount: '500000')
			);
			
			expect(response.hasAmount(), isTrue);
			
			response.clearAmount();
			expect(response.hasAmount(), isFalse);
			
			final newAmount = response.ensureAmount();
			expect(response.hasAmount(), isTrue);
			expect(newAmount, isA<coin.CosmosCoin>());
		});
	});
	
	group('cosmos.bank.v1beta1 QueryParamsRequest', () {
		test('default constructor', () {
			final request = QueryParamsRequest();
			expect(request, isA<QueryParamsRequest>());
		});
		
		test('JSON and buffer serialization', () {
			final request = QueryParamsRequest();
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = QueryParamsRequest.fromJson(json);
			expect(fromJson, isA<QueryParamsRequest>());
			
			final buffer = request.writeToBuffer();
			final fromBuffer = QueryParamsRequest.fromBuffer(buffer);
			expect(fromBuffer, isA<QueryParamsRequest>());
		});
	});
	
	group('cosmos.bank.v1beta1 QueryParamsResponse', () {
		test('constructor with params', () {
			final response = QueryParamsResponse(
				params: bank.Params(
					sendEnabled: [bank.SendEnabled(denom: 'stake', enabled: true)],
					defaultSendEnabled: true
				)
			);
			
			expect(response.params.defaultSendEnabled, true);
			expect(response.params.sendEnabled.first.denom, 'stake');
		});
		
		test('has/clear/ensure params operations', () {
			final response = QueryParamsResponse(
				params: bank.Params(defaultSendEnabled: false)
			);
			
			expect(response.hasParams(), isTrue);
			
			response.clearParams();
			expect(response.hasParams(), isFalse);
			
			final newParams = response.ensureParams();
			expect(response.hasParams(), isTrue);
			expect(newParams, isA<bank.Params>());
		});
	});
	
	group('cosmos.bank.v1beta1 QueryDenomsMetadataRequest', () {
		test('constructor with pagination', () {
			final request = QueryDenomsMetadataRequest(
				pagination: pagination.PageRequest(limit: Int64(30))
			);
			
			expect(request.pagination.limit.toInt(), 30);
		});
		
		test('has/clear/ensure pagination operations', () {
			final request = QueryDenomsMetadataRequest();
			
			expect(request.hasPagination(), isFalse);
			
			final newPagination = request.ensurePagination();
			expect(request.hasPagination(), isTrue);
			expect(newPagination, isA<pagination.PageRequest>());
		});
	});
	
	group('cosmos.bank.v1beta1 QueryDenomsMetadataResponse', () {
		test('constructor with metadatas and pagination', () {
			final response = QueryDenomsMetadataResponse(
				metadatas: [
					bank.Metadata(
						name: 'Stake Token',
						symbol: 'STAKE',
						base: 'ustake'
					),
					bank.Metadata(
						name: 'Atom Token',
						symbol: 'ATOM',
						base: 'uatom'
					)
				],
				pagination: pagination.PageResponse(total: Int64(2))
			);
			
			expect(response.metadatas.length, 2);
			expect(response.metadatas.first.name, 'Stake Token');
			expect(response.metadatas.last.symbol, 'ATOM');
		});
		
		test('metadatas list operations', () {
			final response = QueryDenomsMetadataResponse();
			
			response.metadatas.add(bank.Metadata(name: 'Test Token'));
			expect(response.metadatas.length, 1);
			
			response.metadatas.clear();
			expect(response.metadatas, isEmpty);
		});
	});
	
	group('cosmos.bank.v1beta1 QueryDenomMetadataRequest', () {
		test('constructor with denom', () {
			final request = QueryDenomMetadataRequest(denom: 'ustake');
			expect(request.denom, 'ustake');
		});
		
		test('has/clear denom operations', () {
			final request = QueryDenomMetadataRequest(denom: 'uatom');
			
			expect(request.hasDenom(), isTrue);
			request.clearDenom();
			expect(request.hasDenom(), isFalse);
		});
	});
	
	group('cosmos.bank.v1beta1 QueryDenomMetadataResponse', () {
		test('constructor with metadata', () {
			final response = QueryDenomMetadataResponse(
				metadata: bank.Metadata(
					name: 'Stake Token',
					symbol: 'STAKE',
					base: 'ustake',
					display: 'stake'
				)
			);
			
			expect(response.metadata.name, 'Stake Token');
			expect(response.metadata.symbol, 'STAKE');
			expect(response.metadata.base, 'ustake');
			expect(response.metadata.display, 'stake');
		});
		
		test('has/clear/ensure metadata operations', () {
			final response = QueryDenomMetadataResponse(
				metadata: bank.Metadata(name: 'Test')
			);
			
			expect(response.hasMetadata(), isTrue);
			
			response.clearMetadata();
			expect(response.hasMetadata(), isFalse);
			
			final newMetadata = response.ensureMetadata();
			expect(response.hasMetadata(), isTrue);
			expect(newMetadata, isA<bank.Metadata>());
		});
	});
	
	group('cosmos.bank.v1beta1 error handling', () {
		test('invalid buffer deserialization', () {
			expect(() => QueryBalanceRequest.fromBuffer([0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => QueryAllBalancesRequest.fromBuffer([0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => QueryTotalSupplyRequest.fromBuffer([0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			expect(() => QueryBalanceResponse.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => QueryParamsResponse.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => QueryDenomsMetadataResponse.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('cosmos.bank.v1beta1 getDefault and createRepeated', () {
		test('all query message types have getDefault', () {
			expect(identical(QueryBalanceRequest.getDefault(), QueryBalanceRequest.getDefault()), isTrue);
			expect(identical(QueryBalanceResponse.getDefault(), QueryBalanceResponse.getDefault()), isTrue);
			expect(identical(QueryAllBalancesRequest.getDefault(), QueryAllBalancesRequest.getDefault()), isTrue);
			expect(identical(QueryAllBalancesResponse.getDefault(), QueryAllBalancesResponse.getDefault()), isTrue);
			expect(identical(QueryTotalSupplyRequest.getDefault(), QueryTotalSupplyRequest.getDefault()), isTrue);
			expect(identical(QueryTotalSupplyResponse.getDefault(), QueryTotalSupplyResponse.getDefault()), isTrue);
		});
		
		test('all query message types can create repeated lists', () {
			expect(QueryBalanceRequest.createRepeated(), isA<pb.PbList<QueryBalanceRequest>>());
			expect(QueryBalanceResponse.createRepeated(), isA<pb.PbList<QueryBalanceResponse>>());
			expect(QueryParamsRequest.createRepeated(), isA<pb.PbList<QueryParamsRequest>>());
			expect(QueryParamsResponse.createRepeated(), isA<pb.PbList<QueryParamsResponse>>());
			expect(QueryDenomMetadataRequest.createRepeated(), isA<pb.PbList<QueryDenomMetadataRequest>>());
			expect(QueryDenomMetadataResponse.createRepeated(), isA<pb.PbList<QueryDenomMetadataResponse>>());
		});
	});
} 