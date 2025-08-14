import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/query.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/query/v1beta1/pagination.pb.dart';

void main() {
	group('proto cosmos.bank.v1beta1 query spendable', () {
		test('QuerySpendableBalancesRequest has/clear/ensure/clone/copyWith', () {
			final req = QuerySpendableBalancesRequest(address: 'cosmos1x', pagination: PageRequest(limit: Int64(5)));
			expect(req.hasPagination(), isTrue);
			final clone = req.clone();
			expect(clone.pagination.limit.toInt(), 5);
			clone.clearPagination();
			expect(clone.hasPagination(), isFalse);
			final ensured = clone.ensurePagination();
			expect(ensured, isA<PageRequest>());
			final copied = req.copyWith((r) => r.pagination = PageRequest(limit: Int64(9)));
			expect(copied.pagination.limit.toInt(), 9);
		});

		test('QuerySpendableBalancesResponse list ops/json/errors/defaults', () {
			final resp = QuerySpendableBalancesResponse(balances: [CosmosCoin(denom: 'uatom', amount: '1')], pagination: PageResponse(total: Int64(1)));
			expect(resp.hasPagination(), isTrue);
			resp.balances.add(CosmosCoin(denom: 'uiris', amount: '2'));
			expect(resp.balances.length, 2);
			final jsonStr = jsonEncode(resp.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			expect(() => QuerySpendableBalancesRequest.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => QuerySpendableBalancesResponse.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(QuerySpendableBalancesRequest.getDefault(), isA<QuerySpendableBalancesRequest>());
			expect(QuerySpendableBalancesResponse.getDefault(), isA<QuerySpendableBalancesResponse>());
		});
	});
} 