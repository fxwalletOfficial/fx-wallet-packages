import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/query.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/bank.pb.dart' as bankpb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/query/v1beta1/pagination.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';

void main() {
	group('proto cosmos.bank.v1beta1 query wide', () {
		test('QueryBalanceRequest/Response json/buffer/defaults/info_', () {
			final req = QueryBalanceRequest(address: 'a', denom: 'uatom');
			final reqJson = jsonEncode(req.writeToJsonMap());
			final req2 = QueryBalanceRequest.fromJson(reqJson);
			expect(req2.address, 'a');
			expect(req2.denom, 'uatom');
			expect(QueryBalanceRequest.getDefault().info_.messageName, contains('QueryBalanceRequest'));

			final resp = QueryBalanceResponse(balance: CosmosCoin(denom: 'uatom', amount: '1'));
			final bz = resp.writeToBuffer();
			final resp2 = QueryBalanceResponse.fromBuffer(bz);
			expect(resp2.balance.amount, '1');
			expect(QueryBalanceResponse.getDefault().info_.messageName, contains('QueryBalanceResponse'));
		});

		test('QueryAllBalancesRequest/Response copyWith/ensure/clear', () {
			final req = QueryAllBalancesRequest(address: 'addr', pagination: PageRequest(limit: Int64(3)));

			final reqClone = req.deepCopy();
			reqClone.clearPagination();
			expect(reqClone.hasPagination(), isFalse);
			expect(reqClone.ensurePagination(), isA<PageRequest>());
			expect(QueryAllBalancesRequest.getDefault().info_.messageName, contains('QueryAllBalancesRequest'));

      req.freeze();
			final copiedReq = req.rebuild((r) {
				r.address = 'addr2';
				r.pagination = PageRequest(limit: Int64(5));
			});
			expect(copiedReq.address, 'addr2');
			expect(copiedReq.pagination.limit.toInt(), 5);

			final resp = QueryAllBalancesResponse(balances: [CosmosCoin(denom: 'x', amount: '0')], pagination: PageResponse(total: Int64(1)));
			final respClone = resp.deepCopy();
			respClone.clearPagination();
			expect(respClone.hasPagination(), isFalse);
			final ensured = respClone.ensurePagination();
			expect(ensured, isA<PageResponse>());
			resp.balances.add(CosmosCoin(denom: 'y', amount: '2'));
			expect(resp.balances.length, 2);

      resp.freeze();
			final copiedResp = resp.rebuild((rr) => rr.pagination = PageResponse(total: Int64(3)));
			expect(copiedResp.pagination.total.toInt(), 3);
			expect(QueryAllBalancesResponse.getDefault().info_.messageName, contains('QueryAllBalancesResponse'));
		});

		test('QuerySpendableBalancesRequest/Response defaults/info_', () {
			expect(QuerySpendableBalancesRequest.getDefault().info_.messageName, contains('QuerySpendableBalancesRequest'));
			expect(QuerySpendableBalancesResponse.getDefault().info_.messageName, contains('QuerySpendableBalancesResponse'));
		});

		test('QueryTotalSupplyRequest/Response json/copyWith', () {
			final req = QueryTotalSupplyRequest(pagination: PageRequest(limit: Int64(1)));
			final reqJson = jsonEncode(req.writeToJsonMap());
			final req2 = QueryTotalSupplyRequest.fromJson(reqJson);
			expect(req2.pagination.limit.toInt(), 1);
			final resp = QueryTotalSupplyResponse(supply: [CosmosCoin(denom: 'uatom', amount: '100')]);
			resp.supply.add(CosmosCoin(denom: 'uiris', amount: '1'));
			expect(resp.supply.length, 2);
			expect(QueryTotalSupplyRequest.getDefault().info_.messageName, contains('QueryTotalSupplyRequest'));
			expect(QueryTotalSupplyResponse.getDefault().info_.messageName, contains('QueryTotalSupplyResponse'));
		});

		test('QuerySupplyOfRequest/Response roundtrip/info_', () {
			final req = QuerySupplyOfRequest(denom: 'uatom');
			final reqBz = req.writeToBuffer();
			final req2 = QuerySupplyOfRequest.fromBuffer(reqBz);
			expect(req2.denom, 'uatom');
			final resp = QuerySupplyOfResponse(amount: CosmosCoin(denom: 'uatom', amount: '100'));
			final respJson = jsonEncode(resp.writeToJsonMap());
			final resp2 = QuerySupplyOfResponse.fromJson(respJson);
			expect(resp2.amount.amount, '100');
			expect(QuerySupplyOfRequest.getDefault().info_.messageName, contains('QuerySupplyOfRequest'));
			expect(QuerySupplyOfResponse.getDefault().info_.messageName, contains('QuerySupplyOfResponse'));
		});

		test('QueryParamsRequest/Response roundtrip/info_', () {
			final req = QueryParamsRequest();
			final reqJson = jsonEncode(req.writeToJsonMap());
			expect(QueryParamsRequest.fromJson(reqJson), isA<QueryParamsRequest>());
			final resp = QueryParamsResponse(params: bankpb.BankParams(defaultSendEnabled: true));
			final respBz = resp.writeToBuffer();
			expect(QueryParamsResponse.fromBuffer(respBz).params.defaultSendEnabled, isTrue);
			expect(QueryParamsRequest.getDefault().info_.messageName, contains('QueryParamsRequest'));
			expect(QueryParamsResponse.getDefault().info_.messageName, contains('QueryParamsResponse'));
		});

		test('QueryDenomsMetadataRequest/Response roundtrip/info_', () {
			final md = bankpb.Metadata(base: 'uatom');
			final req = QueryDenomsMetadataRequest(pagination: PageRequest(limit: Int64(1)));
			final json1 = jsonEncode(req.writeToJsonMap());
			expect(QueryDenomsMetadataRequest.fromJson(json1).pagination.limit.toInt(), 1);
			final resp = QueryDenomsMetadataResponse(metadatas: [md], pagination: PageResponse(total: Int64(1)));
			final bz = resp.writeToBuffer();
			final resp2 = QueryDenomsMetadataResponse.fromBuffer(bz);
			expect(resp2.metadatas.first.base, 'uatom');
			expect(QueryDenomsMetadataRequest.getDefault().info_.messageName, contains('QueryDenomsMetadataRequest'));
			expect(QueryDenomsMetadataResponse.getDefault().info_.messageName, contains('QueryDenomsMetadataResponse'));
		});

		test('QueryDenomMetadataRequest/Response roundtrip/info_', () {
			final req = QueryDenomMetadataRequest(denom: 'uatom');
			final reqJson = jsonEncode(req.writeToJsonMap());
			expect(QueryDenomMetadataRequest.fromJson(reqJson).denom, 'uatom');
			final resp = QueryDenomMetadataResponse(metadata: bankpb.Metadata(base: 'uatom'));
			final respJson = jsonEncode(resp.writeToJsonMap());
			expect(QueryDenomMetadataResponse.fromJson(respJson).metadata.base, 'uatom');
			expect(QueryDenomMetadataRequest.getDefault().info_.messageName, contains('QueryDenomMetadataRequest'));
			expect(QueryDenomMetadataResponse.getDefault().info_.messageName, contains('QueryDenomMetadataResponse'));
		});

		test('Error paths on fromJson/fromBuffer for all requests', () {
			expect(() => QueryBalanceRequest.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => QueryAllBalancesRequest.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => QuerySpendableBalancesRequest.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => QueryTotalSupplyRequest.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => QuerySupplyOfRequest.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => QueryParamsRequest.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => QueryDenomsMetadataRequest.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => QueryDenomMetadataRequest.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
		});

		test('Additional ensure/identity and createRepeated/info_ coverage', () {
			// QueryDenomsMetadataRequest ensurePagination identity
			final pr = PageRequest();
			final qdmr = QueryDenomsMetadataRequest(pagination: pr);
			expect(identical(qdmr.ensurePagination(), pr), isTrue);
			expect(QueryDenomsMetadataRequest.createRepeated(), isA<pb.PbList<QueryDenomsMetadataRequest>>());
			expect(QueryDenomsMetadataRequest.getDefault().info_.messageName, contains('QueryDenomsMetadataRequest'));

			// QuerySpendableBalancesRequest copyWith to update pagination
			final qsr = QuerySpendableBalancesRequest(address: 'a', pagination: PageRequest(limit: Int64(1)));
      qsr.freeze();
			final qsr2 = qsr.rebuild((r) => r.pagination = PageRequest(limit: Int64(2)));
			expect(qsr2.pagination.limit.toInt(), 2);
			expect(QuerySpendableBalancesResponse.createRepeated(), isA<pb.PbList<QuerySpendableBalancesResponse>>());

			// QueryDenomMetadataRequest has/clear before/after set
			final qdm = QueryDenomMetadataRequest();
			expect(qdm.hasDenom(), isFalse);
			qdm.denom = 'uatom';
			expect(qdm.hasDenom(), isTrue);
			qdm.clearDenom();
			expect(qdm.hasDenom(), isFalse);
			expect(QueryDenomMetadataRequest.createRepeated(), isA<pb.PbList<QueryDenomMetadataRequest>>());
			expect(QueryDenomMetadataRequest.getDefault().info_.messageName, contains('QueryDenomMetadataRequest'));

			// QueryDenomMetadataResponse ensureMetadata identity
			final md = bankpb.Metadata(base: 'x');
			final qdmresp = QueryDenomMetadataResponse(metadata: md);
			expect(identical(qdmresp.ensureMetadata(), md), isTrue);
			expect(QueryDenomMetadataResponse.createRepeated(), isA<pb.PbList<QueryDenomMetadataResponse>>());
		});

					test('Error paths empty inputs on fromBuffer/fromJson', () {
				final emptyReq = QueryBalanceRequest.fromBuffer(const []);
				expect(emptyReq, isA<QueryBalanceRequest>());
				expect(() => QueryBalanceResponse.fromJson(''), throwsA(isA<FormatException>()));
				expect(() => QueryAllBalancesResponse.fromJson(''), throwsA(isA<FormatException>()));
				final emptySpendReq = QuerySpendableBalancesRequest.fromBuffer(const []);
				expect(emptySpendReq, isA<QuerySpendableBalancesRequest>());
				expect(() => QueryTotalSupplyRequest.fromJson(''), throwsA(isA<FormatException>()));
				expect(() => QueryParamsResponse.fromJson(''), throwsA(isA<FormatException>()));
			});
	});
}