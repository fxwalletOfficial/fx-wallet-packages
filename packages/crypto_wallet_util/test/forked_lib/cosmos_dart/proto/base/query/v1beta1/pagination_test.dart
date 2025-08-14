import 'dart:convert';

import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/query/v1beta1/pagination.pb.dart';

void main() {
	group('cosmos.base.query.v1beta1 pagination', () {
		test('PageRequest has/clear/json/buffer/defaults', () {
			final pr = PageRequest(key: [1,2], offset: Int64(10), limit: Int64(50), countTotal: true, reverse: false);
			expect(pr.hasOffset(), isTrue);
			pr.clearOffset();
			expect(pr.hasOffset(), isFalse);
			final bz = pr.writeToBuffer();
			expect(PageRequest.fromBuffer(bz).limit.toInt(), 50);
			final jsonStr = jsonEncode(pr.writeToJsonMap());
			expect(PageRequest.fromJson(jsonStr).countTotal, isTrue);
			expect(PageRequest.getDefault(), isA<PageRequest>());
			expect(PageRequest().createEmptyInstance(), isA<PageRequest>());
			expect(PageRequest.createRepeated(), isA<pb.PbList<PageRequest>>());
		});

		test('PageResponse has/clear/json/buffer/defaults', () {
			final resp = PageResponse(nextKey: [3,4], total: Int64(123));
			expect(resp.hasTotal(), isTrue);
			resp.clearTotal();
			expect(resp.hasTotal(), isFalse);
			final bz = resp.writeToBuffer();
			expect(PageResponse.fromBuffer(bz).nextKey, isNotEmpty);
			final jsonStr = jsonEncode(resp.writeToJsonMap());
			expect(PageResponse.fromJson(jsonStr).nextKey, isA<List<int>>());
			expect(PageResponse.getDefault(), isA<PageResponse>());
			expect(PageResponse().createEmptyInstance(), isA<PageResponse>());
			expect(PageResponse.createRepeated(), isA<pb.PbList<PageResponse>>());
		});
	});
} 