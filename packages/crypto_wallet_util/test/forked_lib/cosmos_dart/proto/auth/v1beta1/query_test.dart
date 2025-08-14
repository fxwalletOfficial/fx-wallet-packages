import 'dart:convert';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/query.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/query/v1beta1/pagination.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/auth.pb.dart' as authpb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/any.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as pb;

void main() {
	group('proto cosmos.auth.v1beta1 query', () {
		test('QueryAccountsRequest/Response roundtrip', () {
			final req = QueryAccountsRequest(pagination: PageRequest(limit: Int64(10)));
			final reqBz = req.writeToBuffer();
			final req2 = QueryAccountsRequest.fromBuffer(reqBz);
			expect(req2.pagination.limit.toInt(), 10);

			final resp = QueryAccountsResponse(
				accounts: [Any(typeUrl: 't', value: [1])],
				pagination: PageResponse(total: Int64(1)),
			);
			final respBz = resp.writeToBuffer();
			final resp2 = QueryAccountsResponse.fromBuffer(respBz);
			expect(resp2.accounts.first.typeUrl, 't');
			expect(resp2.pagination.total.toInt(), 1);
		});

		test('QueryAccountRequest/Response has/clear/ensure/copyWith/json/errors', () {
			final req = QueryAccountRequest(address: 'cosmos1xyz');
			expect(req.hasAddress(), isTrue);
			req.clearAddress();
			expect(req.hasAddress(), isFalse);
			final reqCloned = req.deepCopy();
			expect(reqCloned.hasAddress(), isFalse);
			// Freeze the message before using rebuild
			final frozenReq = req.freeze();
			final reqCopied = frozenReq.rebuild((m) => (m as QueryAccountRequest).address = 'a');
			expect((reqCopied as QueryAccountRequest).address, 'a');
			final reqJson = jsonEncode(reqCopied.writeToJsonMap());
			expect(reqJson.contains('cosmos1') || reqJson.contains('"a"'), isTrue);
			expect(() => QueryAccountRequest.fromJson('not-json'), throwsA(isA<FormatException>()));
			expect(() => QueryAccountRequest.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));

			final resp = QueryAccountResponse(account: Any(typeUrl: 't', value: [1]));
			expect(resp.hasAccount(), isTrue);
			resp.clearAccount();
			expect(resp.hasAccount(), isFalse);
			final ensured = resp.ensureAccount();
			expect(ensured, isA<Any>());
			// Freeze the message before using rebuild
			final frozenResp = resp.freeze();
			final respCopied = frozenResp.rebuild((m) => (m as QueryAccountResponse).account = Any(typeUrl: 't2'));
			final respJson = jsonEncode(respCopied.writeToJsonMap());
			expect(respJson.contains('t2'), isTrue);
			expect(() => QueryAccountResponse.fromJson('not-json'), throwsA(isA<FormatException>()));
			expect(() => QueryAccountResponse.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
		});

		test('QueryParamsRequest/Response json/ensure/errors and defaults', () {
			final req = QueryParamsRequest();
			final reqJson = jsonEncode(req.writeToJsonMap());
			expect(reqJson.isNotEmpty, isTrue);
			final reqDef = QueryParamsRequest.getDefault();
			expect(reqDef, isA<QueryParamsRequest>());
			final reqEmpty = QueryParamsRequest().createEmptyInstance();
			expect(reqEmpty, isA<QueryParamsRequest>());
			final reqList = QueryParamsRequest.createRepeated();
			expect(reqList, isA<pb.PbList<QueryParamsRequest>>());
			expect(() => QueryParamsRequest.fromJson('not-json'), throwsA(isA<FormatException>()));
			expect(() => QueryParamsRequest.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));

			final params = authpb.Params();
			final resp = QueryParamsResponse(params: params);
			expect(resp.hasParams(), isTrue);
			resp.clearParams();
			expect(resp.hasParams(), isFalse);
			final ensured = resp.ensureParams();
			expect(ensured, isA<authpb.Params>());
			final respJson = jsonEncode(resp.writeToJsonMap());
			expect(respJson.isNotEmpty, isTrue);
			final respDef = QueryParamsResponse.getDefault();
			expect(respDef, isA<QueryParamsResponse>());
			final respEmpty = QueryParamsResponse().createEmptyInstance();
			expect(respEmpty, isA<QueryParamsResponse>());
			final respList = QueryParamsResponse.createRepeated();
			expect(respList, isA<pb.PbList<QueryParamsResponse>>());
			expect(() => QueryParamsResponse.fromJson('not-json'), throwsA(isA<FormatException>()));
			expect(() => QueryParamsResponse.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
		});

		test('QueryAccountsRequest/Response ensure/clear/clone/copyWith/defaults and accounts edge cases', () {
			final req = QueryAccountsRequest(pagination: PageRequest(limit: Int64(5)));
			expect(req.hasPagination(), isTrue);
			req.clearPagination();
			expect(req.hasPagination(), isFalse);
			final ensuredReq = req.ensurePagination();
			expect(ensuredReq, isA<PageRequest>());
			final clonedReq = req.deepCopy();
			expect(clonedReq.hasPagination(), isTrue);
			// Freeze the message before using rebuild
			final frozenReq = req.freeze();
			final copiedReq = frozenReq.rebuild((r) => (r as QueryAccountsRequest).pagination = PageRequest(limit: Int64(9)));
			expect((copiedReq as QueryAccountsRequest).pagination.limit.toInt(), 9);
			final reqDef = QueryAccountsRequest.getDefault();
			expect(reqDef, isA<QueryAccountsRequest>());
			final reqEmpty = QueryAccountsRequest().createEmptyInstance();
			expect(reqEmpty, isA<QueryAccountsRequest>());
			final reqList = QueryAccountsRequest.createRepeated();
			expect(reqList, isA<pb.PbList<QueryAccountsRequest>>());

			final resp = QueryAccountsResponse(
				accounts: [],
				pagination: PageResponse(total: Int64(0)),
			);
			expect(resp.accounts.isEmpty, isTrue);
			resp.accounts.addAll([Any(typeUrl: 'a'), Any(typeUrl: 'b')]);
			expect(resp.accounts.length, 2);
			resp.accounts.clear();
			expect(resp.accounts.isEmpty, isTrue);
			// Freeze the message before using rebuild
			final frozenResp = resp.freeze();
			final copiedRespBoth = frozenResp.rebuild((rr) {
				(rr as QueryAccountsResponse).accounts.add(Any(typeUrl: 'c'));
				(rr).pagination = PageResponse(total: Int64(3));
			});
			expect((copiedRespBoth as QueryAccountsResponse).accounts.first.typeUrl, 'c');
			expect((copiedRespBoth).pagination.total.toInt(), 3);
			// add has/clear/ensure for pagination on a mutable clone
			final mutableResp = copiedRespBoth.deepCopy();
			expect(mutableResp.hasPagination(), isTrue);
			mutableResp.clearPagination();
			expect(mutableResp.hasPagination(), isFalse);
			final ensuredResp2 = mutableResp.ensurePagination();
			expect(ensuredResp2, isA<PageResponse>());
			final respDef = QueryAccountsResponse.getDefault();
			expect(respDef, isA<QueryAccountsResponse>());
			final respEmpty2 = QueryAccountsResponse().createEmptyInstance();
			expect(respEmpty2, isA<QueryAccountsResponse>());
			final respList2 = QueryAccountsResponse.createRepeated();
			expect(respList2, isA<pb.PbList<QueryAccountsResponse>>());
		});

		test('QueryAccountRequest/Response defaults/creators', () {
			final reqDef = QueryAccountRequest.getDefault();
			expect(reqDef, isA<QueryAccountRequest>());
			final reqEmpty = QueryAccountRequest().createEmptyInstance();
			expect(reqEmpty, isA<QueryAccountRequest>());
			final reqList = QueryAccountRequest.createRepeated();
			expect(reqList, isA<pb.PbList<QueryAccountRequest>>());

			final respDef = QueryAccountResponse.getDefault();
			expect(respDef, isA<QueryAccountResponse>());
			final respEmpty = QueryAccountResponse().createEmptyInstance();
			expect(respEmpty, isA<QueryAccountResponse>());
			final respList = QueryAccountResponse.createRepeated();
			expect(respList, isA<pb.PbList<QueryAccountResponse>>());
		});
	});
}