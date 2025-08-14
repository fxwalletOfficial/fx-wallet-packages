       import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/query.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/bank.pb.dart' as bankpb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/query/v1beta1/pagination.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';

void main() {
	group('proto cosmos.bank.v1beta1 query', () {
		test('QueryBalanceRequest/Response end-to-end and errors', () {
			final req = QueryBalanceRequest(address: 'cosmos1abc', denom: 'uatom');
			expect(req.hasAddress(), isTrue);
			expect(req.hasDenom(), isTrue);
			final reqBz = req.writeToBuffer();
			final req2 = QueryBalanceRequest.fromBuffer(reqBz);
			expect(req2.address, 'cosmos1abc');
			expect(req2.denom, 'uatom');
			req2.clearAddress();
			expect(req2.hasAddress(), isFalse);
			final reqJson = jsonEncode(req.writeToJsonMap());
			expect(reqJson.contains('uatom'), isTrue);
			expect(() => QueryBalanceRequest.fromJson('not-json'), throwsA(isA<FormatException>()));
			expect(() => QueryBalanceRequest.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));

			final resp = QueryBalanceResponse(balance: CosmosCoin(denom: 'uatom', amount: '1'));
			expect(resp.hasBalance(), isTrue);
			final respBz = resp.writeToBuffer();
			final resp2 = QueryBalanceResponse.fromBuffer(respBz);
			expect(resp2.balance.denom, 'uatom');
			resp2.clearBalance();
			expect(resp2.hasBalance(), isFalse);
			final respJson = jsonEncode(resp.writeToJsonMap());
			expect(respJson.isNotEmpty, isTrue);
			expect(() => QueryBalanceResponse.fromJson('not-json'), throwsA(isA<FormatException>()));
			expect(() => QueryBalanceResponse.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
		});

		test('QueryAllBalancesRequest/Response with pagination and list ops', () {
			final req = QueryAllBalancesRequest(
				address: 'cosmos1xyz',
				pagination: PageRequest(limit: Int64(10)),
			); 
			expect(req.hasPagination(), isTrue);
			final reqClone = req.clone();
			expect(reqClone.pagination.limit.toInt(), 10);
			reqClone.clearPagination();
			expect(reqClone.hasPagination(), isFalse);
			final reqEnsured = reqClone.ensurePagination();
			expect(reqEnsured, isA<PageRequest>());
			final reqCopy = req.copyWith((r) => r.pagination = PageRequest(limit: Int64(5)));
			expect(reqCopy.pagination.limit.toInt(), 5);

			final resp = QueryAllBalancesResponse(
				balances: [CosmosCoin(denom: 'uatom', amount: '2')],
				pagination: PageResponse(total: Int64(1)),
			);
			expect(resp.hasPagination(), isTrue);
			final respClone = resp.clone();
			expect(respClone.pagination.total.toInt(), 1);
			respClone.clearPagination();
			expect(respClone.hasPagination(), isFalse);
			final ensured = respClone.ensurePagination();
			expect(ensured, isA<PageResponse>());
			resp.balances.add(CosmosCoin(denom: 'uiris', amount: '3'));
			expect(resp.balances.length, 2);
			final respCopy = resp.copyWith((rr) => rr.pagination = PageResponse(total: Int64(2)));
			expect(respCopy.pagination.total.toInt(), 2);
		});

		test('QueryTotalSupplyRequest/Response and QuerySupplyOfRequest/Response', () {
			final req1 = QueryTotalSupplyRequest(pagination: PageRequest(limit: Int64(1)));
			expect(req1.hasPagination(), isTrue);
			final resp1 = QueryTotalSupplyResponse(supply: [CosmosCoin(denom: 'uatom', amount: '100')]);
			expect(resp1.supply.first.amount, '100');
			resp1.supply.add(CosmosCoin(denom: 'uiris', amount: '1'));
			expect(resp1.supply.length, 2);

			final req2 = QuerySupplyOfRequest(denom: 'uatom');
			expect(req2.hasDenom(), isTrue);
			final resp2 = QuerySupplyOfResponse(amount: CosmosCoin(denom: 'uatom', amount: '100'));
			expect(resp2.amount.amount, '100');
			resp2.clearAmount();
			expect(resp2.hasAmount(), isFalse);
		});

		test('QueryParamsRequest/Response, QueryDenomsMetadataRequest/Response', () {
			final resp = QueryParamsResponse(params: bankpb.Params(defaultSendEnabled: true));
			expect(resp.params.defaultSendEnabled, isTrue);

			final md = bankpb.Metadata(base: 'uatom', display: 'ATOM');
			final resp2 = QueryDenomsMetadataResponse(metadatas: [md], pagination: PageResponse(total: Int64(1)));
			expect(resp2.metadatas.first.base, 'uatom');
			expect(resp2.hasPagination(), isTrue);
			resp2.clearPagination();
			expect(resp2.hasPagination(), isFalse);
			expect(resp2.ensurePagination(), isA<PageResponse>());
		});

			test('QueryDenomMetadataRequest/Response', () {
			final req = QueryDenomMetadataRequest(denom: 'uatom');
			expect(req.hasDenom(), isTrue);
			final resp = QueryDenomMetadataResponse(metadata: bankpb.Metadata(base: 'uatom'));
			expect(resp.hasMetadata(), isTrue);
			resp.clearMetadata();
			expect(resp.hasMetadata(), isFalse);
		});

		test('defaults/createEmptyInstance/createRepeated and error paths', () {
			expect(QueryBalanceRequest.getDefault(), isA<QueryBalanceRequest>());
			expect(QueryBalanceRequest().createEmptyInstance(), isA<QueryBalanceRequest>());
			expect(QueryBalanceRequest.createRepeated(), isA<pb.PbList<QueryBalanceRequest>>());
			expect(() => QueryBalanceRequest.fromJson('bad'), throwsA(isA<FormatException>()));

			expect(QueryBalanceResponse.getDefault(), isA<QueryBalanceResponse>());
			expect(QueryBalanceResponse().createEmptyInstance(), isA<QueryBalanceResponse>());
			expect(QueryBalanceResponse.createRepeated(), isA<pb.PbList<QueryBalanceResponse>>());
			expect(() => QueryBalanceResponse.fromJson('bad'), throwsA(isA<FormatException>()));

			expect(QueryAllBalancesRequest.getDefault(), isA<QueryAllBalancesRequest>());
			expect(QueryAllBalancesRequest().createEmptyInstance(), isA<QueryAllBalancesRequest>());
			expect(QueryAllBalancesRequest.createRepeated(), isA<pb.PbList<QueryAllBalancesRequest>>());

			expect(QueryAllBalancesResponse.getDefault(), isA<QueryAllBalancesResponse>());
			expect(QueryAllBalancesResponse().createEmptyInstance(), isA<QueryAllBalancesResponse>());
			expect(QueryAllBalancesResponse.createRepeated(), isA<pb.PbList<QueryAllBalancesResponse>>());

			expect(QueryTotalSupplyRequest.getDefault(), isA<QueryTotalSupplyRequest>());
			expect(QueryTotalSupplyResponse.getDefault(), isA<QueryTotalSupplyResponse>());
			expect(QuerySupplyOfRequest.getDefault(), isA<QuerySupplyOfRequest>());
			expect(QuerySupplyOfResponse.getDefault(), isA<QuerySupplyOfResponse>());

			expect(QueryParamsRequest.getDefault(), isA<QueryParamsRequest>());
			expect(QueryParamsResponse.getDefault(), isA<QueryParamsResponse>());

			expect(QueryDenomsMetadataRequest.getDefault(), isA<QueryDenomsMetadataRequest>());
			expect(QueryDenomsMetadataResponse.getDefault(), isA<QueryDenomsMetadataResponse>());
			expect(QueryDenomMetadataRequest.getDefault(), isA<QueryDenomMetadataRequest>());
			expect(QueryDenomMetadataResponse.getDefault(), isA<QueryDenomMetadataResponse>());
		});
	});

	group('proto cosmos.bank.v1beta1 query more', () {
		test('QueryBalanceRequest has/clear/json/buffer/info_', () {
			final req = QueryBalanceRequest(address: 'addr', denom: 'uatom');
			expect(req.hasAddress(), isTrue);
			expect(req.hasDenom(), isTrue);
			req.clearAddress();
			expect(req.hasAddress(), isFalse);
			req.address = 'addr2';
			expect(req.address, 'addr2');
			final jsonStr = jsonEncode(req.writeToJsonMap());
			final req2 = QueryBalanceRequest.fromJson(jsonStr);
			expect(req2.address, 'addr2');
			expect(QueryBalanceRequest.getDefault().info_.messageName, contains('QueryBalanceRequest'));
		});

		test('QueryBalanceResponse ensure/clone/buffer/errors', () {
			final resp = QueryBalanceResponse();
			final bal = resp.ensureBalance();
			expect(bal.denom, isEmpty);
			resp.balance = CosmosCoin(denom: 'uatom', amount: '1');
			final clone = resp.clone();
			expect(clone.balance.denom, 'uatom');
			final bz = resp.writeToBuffer();
			final resp2 = QueryBalanceResponse.fromBuffer(bz);
			expect(resp2.balance.amount, '1');
			expect(() => QueryBalanceResponse.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => QueryBalanceResponse.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
		});

		test('QueryAllBalancesRequest ensure/clear/copyWith', () {
			final req = QueryAllBalancesRequest(address: 'a');
			expect(req.hasPagination(), isFalse);
			req.ensurePagination().limit = Int64(5);
			expect(req.pagination.limit.toInt(), 5);
			final copied = req.copyWith((r) {
				r.address = 'b';
				r.pagination = PageRequest(limit: Int64(10));
			});
			expect(copied.address, 'b');
			expect(copied.pagination.limit.toInt(), 10);
			final clone = req.clone();
			clone.clearPagination();
			expect(clone.hasPagination(), isFalse);
		});

		test('QueryAllBalancesResponse lists/ensure/copyWith', () {
			final resp = QueryAllBalancesResponse();
			resp.balances.addAll([
				CosmosCoin(denom: 'x', amount: '1'),
				CosmosCoin(denom: 'y', amount: '2'),
			]);
			expect(resp.balances.length, 2);
			final ensured = resp.ensurePagination();
			expect(ensured, isA<PageResponse>());
			final copied = resp.copyWith((r) => r.pagination = PageResponse(total: Int64(2)));
			expect(copied.pagination.total.toInt(), 2);
			resp.balances.clear();
			expect(resp.balances, isEmpty);
		});

		test('QuerySpendableBalancesRequest/Response ensure/info_/errors', () {
			expect(QuerySpendableBalancesRequest.getDefault().info_.messageName, contains('QuerySpendableBalancesRequest'));
			expect(QuerySpendableBalancesResponse.getDefault().info_.messageName, contains('QuerySpendableBalancesResponse'));
			final req = QuerySpendableBalancesRequest(address: 'a');
			expect(req.ensurePagination(), isA<PageRequest>());
			final resp = QuerySpendableBalancesResponse();
			expect(resp.ensurePagination(), isA<PageResponse>());
			expect(() => QuerySpendableBalancesRequest.fromJson('bad'), throwsA(isA<FormatException>()));
		});

		test('QueryTotalSupplyRequest/Response createEmptyInstance/createRepeated', () {
			expect(QueryTotalSupplyRequest.getDefault().createEmptyInstance(), isA<QueryTotalSupplyRequest>());
			expect(QueryTotalSupplyRequest.createRepeated(), isA<pb.PbList<QueryTotalSupplyRequest>>());
			expect(QueryTotalSupplyResponse.getDefault().createEmptyInstance(), isA<QueryTotalSupplyResponse>());
			expect(QueryTotalSupplyResponse.createRepeated(), isA<pb.PbList<QueryTotalSupplyResponse>>());
		});

		test('QueryTotalSupplyResponse supply list ops', () {
			final resp = QueryTotalSupplyResponse();
			resp.supply.add(CosmosCoin(denom: 'uatom', amount: '3'));
			resp.supply.add(CosmosCoin(denom: 'ustake', amount: '4'));
			expect(resp.supply.first.denom, 'uatom');
			resp.supply.clear();
			expect(resp.supply, isEmpty);
		});

		test('QuerySupplyOfRequest/Response has/clear/ensure/json', () {
			final req = QuerySupplyOfRequest(denom: 'uatom');
			expect(req.hasDenom(), isTrue);
			req.clearDenom();
			expect(req.hasDenom(), isFalse);
			final resp = QuerySupplyOfResponse();
			final amount = resp.ensureAmount();
			expect(amount.amount, isEmpty);
			resp.amount = CosmosCoin(denom: 'uatom', amount: '5');
			final jsonStr = jsonEncode(resp.writeToJsonMap());
			final resp2 = QuerySupplyOfResponse.fromJson(jsonStr);
			expect(resp2.amount.amount, '5');
		});

		test('QueryParamsRequest/Response defaults/ensure/info_/errors', () {
			expect(QueryParamsRequest.getDefault(), isA<QueryParamsRequest>());
			expect(QueryParamsResponse.getDefault(), isA<QueryParamsResponse>());
			final resp = QueryParamsResponse();
			expect(resp.hasParams(), isFalse);
			final ensured = resp.ensureParams();
			expect(ensured, isA<bankpb.Params>());
			expect(QueryParamsResponse.getDefault().info_.messageName, contains('QueryParamsResponse'));
			expect(() => QueryParamsResponse.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
	});

	group('proto cosmos.bank.v1beta1 query extra coverage', () {
		test('clear/has pagination for SpendableBalancesResponse and TotalSupplyResponse', () {
			final sbr = QuerySpendableBalancesResponse(pagination: PageResponse());
			expect(sbr.hasPagination(), isTrue);
			sbr.clearPagination();
			expect(sbr.hasPagination(), isFalse);

			final tsr = QueryTotalSupplyResponse(pagination: PageResponse());
			expect(tsr.hasPagination(), isTrue);
			tsr.clearPagination();
			expect(tsr.hasPagination(), isFalse);
		});

		test('createRepeated/getDefault/info_ for multiple Query* types', () {
			expect(QuerySpendableBalancesRequest.createRepeated(), isA<pb.PbList<QuerySpendableBalancesRequest>>());
			expect(QuerySpendableBalancesResponse.createRepeated(), isA<pb.PbList<QuerySpendableBalancesResponse>>());
			expect(QueryDenomsMetadataRequest.createRepeated(), isA<pb.PbList<QueryDenomsMetadataRequest>>());
			expect(QueryDenomsMetadataResponse.createRepeated(), isA<pb.PbList<QueryDenomsMetadataResponse>>());
			expect(QueryDenomMetadataRequest.createRepeated(), isA<pb.PbList<QueryDenomMetadataRequest>>());
			expect(QueryDenomMetadataResponse.createRepeated(), isA<pb.PbList<QueryDenomMetadataResponse>>());
			expect(QuerySpendableBalancesRequest.getDefault().info_.messageName, contains('QuerySpendableBalancesRequest'));
			expect(QueryDenomMetadataResponse.getDefault().info_.messageName, contains('QueryDenomMetadataResponse'));
		});

		test('ensure returns existing instance (identity) for responses', () {
			final pr = PageResponse();
			final sbr = QuerySpendableBalancesResponse(pagination: pr);
			expect(identical(sbr.ensurePagination(), pr), isTrue);
			final tspr = PageResponse();
			final tsr = QueryTotalSupplyResponse(pagination: tspr);
			expect(identical(tsr.ensurePagination(), tspr), isTrue);
			final dmpr = PageResponse();
			final dmr = QueryDenomsMetadataResponse(pagination: dmpr);
			expect(identical(dmr.ensurePagination(), dmpr), isTrue);
		});

		test('responses invalid buffer and invalid json paths', () {
			expect(() => QuerySpendableBalancesResponse.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => QuerySpendableBalancesResponse.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => QueryTotalSupplyResponse.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => QueryTotalSupplyResponse.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => QueryDenomsMetadataResponse.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => QueryDenomsMetadataResponse.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => QueryDenomMetadataResponse.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => QueryDenomMetadataResponse.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => QueryParamsResponse.fromJson('bad'), throwsA(isA<FormatException>()));
		});
	});

	group('proto cosmos.bank.v1beta1 query exhaust coverage', () {
		test('createRepeated/getDefault/createEmptyInstance/info_ for all Query* types', () {
			// Requests
			expect(QueryBalanceRequest.createRepeated(), isA<pb.PbList<QueryBalanceRequest>>());
			expect(QueryBalanceRequest.getDefault().createEmptyInstance(), isA<QueryBalanceRequest>());
			expect(QueryBalanceRequest.getDefault().info_.messageName, contains('QueryBalanceRequest'));

			expect(QueryAllBalancesRequest.createRepeated(), isA<pb.PbList<QueryAllBalancesRequest>>());
			expect(QueryAllBalancesRequest.getDefault().createEmptyInstance(), isA<QueryAllBalancesRequest>());
			expect(QueryAllBalancesRequest.getDefault().info_.messageName, contains('QueryAllBalancesRequest'));

			expect(QuerySpendableBalancesRequest.createRepeated(), isA<pb.PbList<QuerySpendableBalancesRequest>>());
			expect(QuerySpendableBalancesRequest.getDefault().createEmptyInstance(), isA<QuerySpendableBalancesRequest>());
			expect(QuerySpendableBalancesRequest.getDefault().info_.messageName, contains('QuerySpendableBalancesRequest'));

			expect(QueryTotalSupplyRequest.createRepeated(), isA<pb.PbList<QueryTotalSupplyRequest>>());
			expect(QueryTotalSupplyRequest.getDefault().createEmptyInstance(), isA<QueryTotalSupplyRequest>());
			expect(QueryTotalSupplyRequest.getDefault().info_.messageName, contains('QueryTotalSupplyRequest'));

			expect(QuerySupplyOfRequest.createRepeated(), isA<pb.PbList<QuerySupplyOfRequest>>());
			expect(QuerySupplyOfRequest.getDefault().createEmptyInstance(), isA<QuerySupplyOfRequest>());
			expect(QuerySupplyOfRequest.getDefault().info_.messageName, contains('QuerySupplyOfRequest'));

			expect(QueryParamsRequest.createRepeated(), isA<pb.PbList<QueryParamsRequest>>());
			expect(QueryParamsRequest.getDefault().createEmptyInstance(), isA<QueryParamsRequest>());
			expect(QueryParamsRequest.getDefault().info_.messageName, contains('QueryParamsRequest'));

			expect(QueryDenomsMetadataRequest.createRepeated(), isA<pb.PbList<QueryDenomsMetadataRequest>>());
			expect(QueryDenomsMetadataRequest.getDefault().createEmptyInstance(), isA<QueryDenomsMetadataRequest>());
			expect(QueryDenomsMetadataRequest.getDefault().info_.messageName, contains('QueryDenomsMetadataRequest'));

			expect(QueryDenomMetadataRequest.createRepeated(), isA<pb.PbList<QueryDenomMetadataRequest>>());
			expect(QueryDenomMetadataRequest.getDefault().createEmptyInstance(), isA<QueryDenomMetadataRequest>());
			expect(QueryDenomMetadataRequest.getDefault().info_.messageName, contains('QueryDenomMetadataRequest'));

			// Responses
			expect(QueryBalanceResponse.createRepeated(), isA<pb.PbList<QueryBalanceResponse>>());
			expect(QueryBalanceResponse.getDefault().createEmptyInstance(), isA<QueryBalanceResponse>());
			expect(QueryBalanceResponse.getDefault().info_.messageName, contains('QueryBalanceResponse'));

			expect(QueryAllBalancesResponse.createRepeated(), isA<pb.PbList<QueryAllBalancesResponse>>());
			expect(QueryAllBalancesResponse.getDefault().createEmptyInstance(), isA<QueryAllBalancesResponse>());
			expect(QueryAllBalancesResponse.getDefault().info_.messageName, contains('QueryAllBalancesResponse'));

			expect(QuerySpendableBalancesResponse.createRepeated(), isA<pb.PbList<QuerySpendableBalancesResponse>>());
			expect(QuerySpendableBalancesResponse.getDefault().createEmptyInstance(), isA<QuerySpendableBalancesResponse>());
			expect(QuerySpendableBalancesResponse.getDefault().info_.messageName, contains('QuerySpendableBalancesResponse'));

			expect(QueryTotalSupplyResponse.createRepeated(), isA<pb.PbList<QueryTotalSupplyResponse>>());
			expect(QueryTotalSupplyResponse.getDefault().createEmptyInstance(), isA<QueryTotalSupplyResponse>());
			expect(QueryTotalSupplyResponse.getDefault().info_.messageName, contains('QueryTotalSupplyResponse'));

			expect(QuerySupplyOfResponse.createRepeated(), isA<pb.PbList<QuerySupplyOfResponse>>());
			expect(QuerySupplyOfResponse.getDefault().createEmptyInstance(), isA<QuerySupplyOfResponse>());
			expect(QuerySupplyOfResponse.getDefault().info_.messageName, contains('QuerySupplyOfResponse'));

			expect(QueryParamsResponse.createRepeated(), isA<pb.PbList<QueryParamsResponse>>());
			expect(QueryParamsResponse.getDefault().createEmptyInstance(), isA<QueryParamsResponse>());
			expect(QueryParamsResponse.getDefault().info_.messageName, contains('QueryParamsResponse'));

			expect(QueryDenomsMetadataResponse.createRepeated(), isA<pb.PbList<QueryDenomsMetadataResponse>>());
			expect(QueryDenomsMetadataResponse.getDefault().createEmptyInstance(), isA<QueryDenomsMetadataResponse>());
			expect(QueryDenomsMetadataResponse.getDefault().info_.messageName, contains('QueryDenomsMetadataResponse'));

			expect(QueryDenomMetadataResponse.createRepeated(), isA<pb.PbList<QueryDenomMetadataResponse>>());
			expect(QueryDenomMetadataResponse.getDefault().createEmptyInstance(), isA<QueryDenomMetadataResponse>());
			expect(QueryDenomMetadataResponse.getDefault().info_.messageName, contains('QueryDenomMetadataResponse'));
		});

		test('clone/copyWith on responses to drive field setters', () {
			final qbr = QueryBalanceResponse(balance: CosmosCoin(denom: 'x', amount: '1'));
			final qbrClone = qbr.clone();
			final qbrCopy = qbrClone.copyWith((m) => m.balance = CosmosCoin(denom: 'y', amount: '2'));
			expect(qbrCopy.balance.denom, 'y');

			final qab = QueryAllBalancesResponse(balances: [CosmosCoin(denom: 'x', amount: '1')], pagination: PageResponse());
			final qabClone = qab.clone();
			final qabCopy = qabClone.copyWith((m) {
				m.pagination = PageResponse();
				m.balances.clear();
				m.balances.add(CosmosCoin(denom: 'z', amount: '3'));
			});
			expect(qabCopy.balances.first.denom, 'z');

			final qss = QuerySpendableBalancesResponse(balances: [CosmosCoin(denom: 'x', amount: '1')], pagination: PageResponse());
			final qssCopy = qss.copyWith((m) => m.pagination = PageResponse());
			expect(qssCopy.hasPagination(), isTrue);

			final qts = QueryTotalSupplyResponse(supply: [CosmosCoin(denom: 'x', amount: '1')], pagination: PageResponse());
			final qtsCopy = qts.copyWith((m) => m.pagination = PageResponse());
			expect(qtsCopy.hasPagination(), isTrue);
		});
	});

	group('proto cosmos.bank.v1beta1 query fine-grained', () {
		test('QueryParamsResponse has/clear/ensure/clone identity', () {
			final resp = QueryParamsResponse();
			expect(resp.hasParams(), isFalse);
			final ensured = resp.ensureParams();
			expect(resp.hasParams(), isTrue);
			final ensured2 = resp.ensureParams();
			expect(identical(ensured, ensured2), isTrue);
			resp.clearParams();
			expect(resp.hasParams(), isFalse);
			final clone = resp.clone();
			expect(clone.hasParams(), isFalse);
		});

		test('QueryBalanceRequest copyWith updates both fields', () {
			final req = QueryBalanceRequest(address: 'a', denom: 'x');
			final copied = req.copyWith((r) {
				r.address = 'b';
				r.denom = 'y';
			});
			expect(copied.address, 'b');
			expect(copied.denom, 'y');
			final bz = copied.writeToBuffer();
			expect(QueryBalanceRequest.fromBuffer(bz).denom, 'y');
		});

		test('QuerySpendableBalancesResponse list ops and clone deep copy', () {
			final resp = QuerySpendableBalancesResponse();
			resp.balances.addAll([
				CosmosCoin(denom: 'a', amount: '1'),
				CosmosCoin(denom: 'b', amount: '2'),
				CosmosCoin(denom: 'c', amount: '3'),
			]);
			expect(resp.balances.length, 3);
			final clone = resp.clone();
			resp.balances[0] = CosmosCoin(denom: 'z', amount: '9');
			expect(clone.balances.first.denom, isNot('z'));
		});

		test('QueryDenomsMetadataResponse metadatas list add/remove', () {
			final resp = QueryDenomsMetadataResponse();
			resp.metadatas.add(bankpb.Metadata(base: 'u1'));
			resp.metadatas.add(bankpb.Metadata(base: 'u2'));
			expect(resp.metadatas.length, 2);
			resp.metadatas.removeAt(0);
			expect(resp.metadatas.first.base, 'u2');
		});

		test('QuerySupplyOfResponse has/clear/ensure flow', () {
			final resp = QuerySupplyOfResponse(amount: CosmosCoin(denom: 'x', amount: '1'));
			expect(resp.hasAmount(), isTrue);
			resp.clearAmount();
			expect(resp.hasAmount(), isFalse);
			resp.ensureAmount().denom = 'y';
			expect(resp.amount.denom, 'y');
		});

		test('QueryTotalSupplyRequest ensurePagination new and identity', () {
			final req = QueryTotalSupplyRequest();
			final p1 = req.ensurePagination();
			final p2 = req.ensurePagination();
			expect(identical(p1, p2), isTrue);
		});
	});

	group('proto cosmos.bank.v1beta1 query micro', () {
		test('QueryBalanceResponse ensureBalance returns existing instance', () {
			final c = CosmosCoin(denom: 'x', amount: '1');
			final resp = QueryBalanceResponse(balance: c);
			final ensured = resp.ensureBalance();
			expect(identical(ensured, c), isTrue);
		});

		test('QueryAllBalancesResponse clone deep copy for balances list', () {
			final resp = QueryAllBalancesResponse(balances: [
				CosmosCoin(denom: 'u1', amount: '1'),
				CosmosCoin(denom: 'u2', amount: '2'),
			]);
			final cloned = resp.clone();
			resp.balances[0] = CosmosCoin(denom: 'zz', amount: '9');
			expect(cloned.balances.first.denom, isNot('zz'));
		});

		test('QuerySupplyOfRequest createEmptyInstance and clearDenom', () {
			final empty = QuerySupplyOfRequest.getDefault().createEmptyInstance();
			expect(empty.denom, isEmpty);
			empty.denom = 'uatom';
			expect(empty.hasDenom(), isTrue);
			empty.clearDenom();
			expect(empty.hasDenom(), isFalse);
		});
	});
} 