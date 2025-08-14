import 'dart:convert';

import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/query.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/auth.pb.dart' as authpb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/any.pb.dart';

void main() {
	group('proto cosmos.auth.v1beta1 query extra', () {
		test('QueryAccountRequest/Response has/clear/ensure/clone/copyWith/json', () {
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

			final resp = QueryAccountResponse(account: Any(typeUrl: 't', value: [1]));
			expect(resp.hasAccount(), isTrue);
			resp.clearAccount();
			expect(resp.hasAccount(), isFalse);
			final ensured = resp.ensureAccount();
			expect(ensured, isA<Any>());
			// final respCloned = resp.clone();
			// Freeze the message before using rebuild
			final frozenResp = resp.freeze();
			final respCopied = frozenResp.rebuild((m) => (m as QueryAccountResponse).account = Any(typeUrl: 't2'));
			final respJson = jsonEncode(respCopied.writeToJsonMap());
			expect(respJson.contains('t2'), isTrue);
		});

		test('QueryParamsRequest/Response json and ensure', () {
			final req = QueryParamsRequest();
			final reqJson = jsonEncode(req.writeToJsonMap());
			expect(reqJson.isNotEmpty, isTrue);

			final params = authpb.Params();
			final resp = QueryParamsResponse(params: params);
			expect(resp.hasParams(), isTrue);
			resp.clearParams();
			expect(resp.hasParams(), isFalse);
			final ensured = resp.ensureParams();
			expect(ensured, isA<authpb.Params>());
			final respJson = jsonEncode(resp.writeToJsonMap());
			expect(respJson.isNotEmpty, isTrue);
		});
	});
}