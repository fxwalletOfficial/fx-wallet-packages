import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/query/v1beta1/pagination.pb.dart';

void main() {
	group('cosmos.base.query.v1beta1 PageRequest', () {
		test('constructor with all parameters', () {
			final pageRequest = PageRequest(
				key: Uint8List.fromList([1, 2, 3, 4]),
				offset: Int64(10),
				limit: Int64(100),
				countTotal: true,
				reverse: false,
			);
			
			expect(pageRequest.key, [1, 2, 3, 4]);
			expect(pageRequest.offset, Int64(10));
			expect(pageRequest.limit, Int64(100));
			expect(pageRequest.countTotal, true);
			expect(pageRequest.reverse, false);
		});
		
		test('constructor with partial parameters', () {
			final pageRequest = PageRequest(
				offset: Int64(5),
				limit: Int64(50),
			);
			
			expect(pageRequest.hasKey(), false);
			expect(pageRequest.offset, Int64(5));
			expect(pageRequest.limit, Int64(50));
			expect(pageRequest.hasCountTotal(), false);
			expect(pageRequest.hasReverse(), false);
		});
		
		test('default constructor', () {
			final pageRequest = PageRequest();
			
			expect(pageRequest.key, isEmpty);
			expect(pageRequest.offset, Int64.ZERO);
			expect(pageRequest.limit, Int64.ZERO);
			expect(pageRequest.countTotal, false);
			expect(pageRequest.reverse, false);
		});
		
		test('has/clear operations for key', () {
			final pageRequest = PageRequest(key: Uint8List.fromList([1, 2, 3]));
			
			expect(pageRequest.hasKey(), isTrue);
			expect(pageRequest.key, [1, 2, 3]);
			
			pageRequest.clearKey();
			expect(pageRequest.hasKey(), isFalse);
			expect(pageRequest.key, isEmpty);
		});
		
		test('has/clear operations for offset', () {
			final pageRequest = PageRequest(offset: Int64(100));
			
			expect(pageRequest.hasOffset(), isTrue);
			expect(pageRequest.offset, Int64(100));
			
			pageRequest.clearOffset();
			expect(pageRequest.hasOffset(), isFalse);
			expect(pageRequest.offset, Int64.ZERO);
		});
		
		test('has/clear operations for limit', () {
			final pageRequest = PageRequest(limit: Int64(50));
			
			expect(pageRequest.hasLimit(), isTrue);
			expect(pageRequest.limit, Int64(50));
			
			pageRequest.clearLimit();
			expect(pageRequest.hasLimit(), isFalse);
			expect(pageRequest.limit, Int64.ZERO);
		});
		
		test('has/clear operations for countTotal', () {
			final pageRequest = PageRequest(countTotal: true);
			
			expect(pageRequest.hasCountTotal(), isTrue);
			expect(pageRequest.countTotal, true);
			
			pageRequest.clearCountTotal();
			expect(pageRequest.hasCountTotal(), isFalse);
			expect(pageRequest.countTotal, false);
		});
		
		test('has/clear operations for reverse', () {
			final pageRequest = PageRequest(reverse: true);
			
			expect(pageRequest.hasReverse(), isTrue);
			expect(pageRequest.reverse, true);
			
			pageRequest.clearReverse();
			expect(pageRequest.hasReverse(), isFalse);
			expect(pageRequest.reverse, false);
		});
		
		test('setting and getting values', () {
			final pageRequest = PageRequest();
			
			pageRequest.key = Uint8List.fromList([10, 20, 30]);
			pageRequest.offset = Int64(25);
			pageRequest.limit = Int64(75);
			pageRequest.countTotal = true;
			pageRequest.reverse = true;
			
			expect(pageRequest.key, [10, 20, 30]);
			expect(pageRequest.offset, Int64(25));
			expect(pageRequest.limit, Int64(75));
			expect(pageRequest.countTotal, true);
			expect(pageRequest.reverse, true);
		});
		
		test('clone operation', () {
			final original = PageRequest(
				key: Uint8List.fromList([1, 2, 3]),
				offset: Int64(10),
				limit: Int64(100),
				countTotal: true,
				reverse: false,
			);
			
			final cloned = original.clone();
			expect(cloned.key, [1, 2, 3]);
			expect(cloned.offset, Int64(10));
			expect(cloned.limit, Int64(100));
			expect(cloned.countTotal, true);
			expect(cloned.reverse, false);
			
			// Verify independence
			cloned.key = Uint8List.fromList([4, 5, 6]);
			cloned.offset = Int64(20);
			cloned.limit = Int64(200);
			cloned.countTotal = false;
			cloned.reverse = true;
			
			expect(cloned.key, [4, 5, 6]);
			expect(cloned.offset, Int64(20));
			expect(cloned.limit, Int64(200));
			expect(cloned.countTotal, false);
			expect(cloned.reverse, true);
			
			expect(original.key, [1, 2, 3]);
			expect(original.offset, Int64(10));
			expect(original.limit, Int64(100));
			expect(original.countTotal, true);
			expect(original.reverse, false);
		});
		
		test('copyWith operation', () {
			final original = PageRequest(
				key: Uint8List.fromList([1, 2, 3]),
				offset: Int64(10),
				limit: Int64(100),
				countTotal: true,
				reverse: false,
			);
			
			final copied = original.copyWith((request) {
				request.offset = Int64(20);
				request.limit = Int64(200);
				request.countTotal = false;
			});
			
			expect(copied.offset, Int64(20));
			expect(copied.limit, Int64(200));
			expect(copied.countTotal, false);
			
			// original unchanged
			expect(original.offset, Int64(10));
			expect(original.limit, Int64(100));
			expect(original.countTotal, true);
		});
		
		test('JSON serialization and deserialization', () {
			final pageRequest = PageRequest(
				key: Uint8List.fromList([1, 2, 3, 4]),
				offset: Int64(15),
				limit: Int64(150),
				countTotal: true,
				reverse: false,
			);
			
			final json = jsonEncode(pageRequest.writeToJsonMap());
			final fromJson = PageRequest.fromJson(json);
			
			expect(fromJson.key, [1, 2, 3, 4]);
			expect(fromJson.offset, Int64(15));
			expect(fromJson.limit, Int64(150));
			expect(fromJson.countTotal, true);
			expect(fromJson.reverse, false);
		});
		
		test('binary serialization and deserialization', () {
			final pageRequest = PageRequest(
				key: Uint8List.fromList([5, 6, 7, 8]),
				offset: Int64(25),
				limit: Int64(250),
				countTotal: false,
				reverse: true,
			);
			
			final buffer = pageRequest.writeToBuffer();
			final fromBuffer = PageRequest.fromBuffer(buffer);
			
			expect(fromBuffer.key, [5, 6, 7, 8]);
			expect(fromBuffer.offset, Int64(25));
			expect(fromBuffer.limit, Int64(250));
			expect(fromBuffer.countTotal, false);
			expect(fromBuffer.reverse, true);
		});
		
		test('getDefault returns same instance', () {
			final default1 = PageRequest.getDefault();
			final default2 = PageRequest.getDefault();
			expect(identical(default1, default2), isTrue);
		});
		
		test('createEmptyInstance creates new instance', () {
			final pageRequest = PageRequest();
			final empty = pageRequest.createEmptyInstance();
			expect(empty.key, isEmpty);
			expect(empty.offset, Int64.ZERO);
			expect(empty.limit, Int64.ZERO);
			expect(identical(pageRequest, empty), isFalse);
		});
		
		test('createRepeated creates PbList', () {
			final list = PageRequest.createRepeated();
			expect(list, isA<pb.PbList<PageRequest>>());
			expect(list, isEmpty);
			
			list.add(PageRequest(offset: Int64(10), limit: Int64(100)));
			expect(list.length, 1);
		});
		
		test('info_ returns BuilderInfo', () {
			final pageRequest = PageRequest();
			final info = pageRequest.info_;
			expect(info, isA<pb.BuilderInfo>());
			expect(info.qualifiedMessageName, contains('PageRequest'));
		});
		
		test('large offset and limit values', () {
			final pageRequest = PageRequest(
				offset: Int64.parseInt('9223372036854775807'), // max int64
				limit: Int64.parseInt('9223372036854775806'),
			);
			
			expect(pageRequest.offset.toString(), '9223372036854775807');
			expect(pageRequest.limit.toString(), '9223372036854775806');
			
			final buffer = pageRequest.writeToBuffer();
			final fromBuffer = PageRequest.fromBuffer(buffer);
			expect(fromBuffer.offset.toString(), '9223372036854775807');
			expect(fromBuffer.limit.toString(), '9223372036854775806');
		});
		
		test('zero offset and limit', () {
			final pageRequest = PageRequest(
				offset: Int64.ZERO,
				limit: Int64.ZERO,
			);
			
			expect(pageRequest.offset, Int64.ZERO);
			expect(pageRequest.limit, Int64.ZERO);
		});
		
		test('empty key', () {
			final pageRequest = PageRequest(key: Uint8List(0));
			
			expect(pageRequest.key, isEmpty);
			expect(pageRequest.hasKey(), false);
		});
		
		test('large key', () {
			final largeKey = Uint8List(1000);
			for (int i = 0; i < 1000; i++) {
				largeKey[i] = i % 256;
			}
			
			final pageRequest = PageRequest(key: largeKey);
			
			expect(pageRequest.key.length, 1000);
			expect(pageRequest.key[0], 0);
			expect(pageRequest.key[999], 231);
			
			final buffer = pageRequest.writeToBuffer();
			final fromBuffer = PageRequest.fromBuffer(buffer);
			expect(fromBuffer.key.length, 1000);
			expect(fromBuffer.key[0], 0);
			expect(fromBuffer.key[999], 231);
		});
		
		test('boolean edge cases', () {
			final pageRequest1 = PageRequest(countTotal: true, reverse: false);
			final pageRequest2 = PageRequest(countTotal: false, reverse: true);
			
			expect(pageRequest1.countTotal, true);
			expect(pageRequest1.reverse, false);
			expect(pageRequest2.countTotal, false);
			expect(pageRequest2.reverse, true);
		});
	});
	
	group('cosmos.base.query.v1beta1 PageResponse', () {
		test('constructor with all parameters', () {
			final pageResponse = PageResponse(
				nextKey: Uint8List.fromList([10, 20, 30]),
				total: Int64(500),
			);
			
			expect(pageResponse.nextKey, [10, 20, 30]);
			expect(pageResponse.total, Int64(500));
		});
		
		test('constructor with partial parameters', () {
			final pageResponse = PageResponse(total: Int64(100));
			
			expect(pageResponse.hasNextKey(), false);
			expect(pageResponse.total, Int64(100));
		});
		
		test('default constructor', () {
			final pageResponse = PageResponse();
			
			expect(pageResponse.nextKey, isEmpty);
			expect(pageResponse.total, Int64.ZERO);
		});
		
		test('has/clear operations for nextKey', () {
			final pageResponse = PageResponse(nextKey: Uint8List.fromList([1, 2, 3]));
			
			expect(pageResponse.hasNextKey(), isTrue);
			expect(pageResponse.nextKey, [1, 2, 3]);
			
			pageResponse.clearNextKey();
			expect(pageResponse.hasNextKey(), isFalse);
			expect(pageResponse.nextKey, isEmpty);
		});
		
		test('has/clear operations for total', () {
			final pageResponse = PageResponse(total: Int64(200));
			
			expect(pageResponse.hasTotal(), isTrue);
			expect(pageResponse.total, Int64(200));
			
			pageResponse.clearTotal();
			expect(pageResponse.hasTotal(), isFalse);
			expect(pageResponse.total, Int64.ZERO);
		});
		
		test('setting and getting values', () {
			final pageResponse = PageResponse();
			
			pageResponse.nextKey = Uint8List.fromList([40, 50, 60]);
			pageResponse.total = Int64(300);
			
			expect(pageResponse.nextKey, [40, 50, 60]);
			expect(pageResponse.total, Int64(300));
		});
		
		test('clone operation', () {
			final original = PageResponse(
				nextKey: Uint8List.fromList([1, 2, 3]),
				total: Int64(100),
			);
			
			final cloned = original.clone();
			expect(cloned.nextKey, [1, 2, 3]);
			expect(cloned.total, Int64(100));
			
			// Verify independence
			cloned.nextKey = Uint8List.fromList([4, 5, 6]);
			cloned.total = Int64(200);
			
			expect(cloned.nextKey, [4, 5, 6]);
			expect(cloned.total, Int64(200));
			expect(original.nextKey, [1, 2, 3]);
			expect(original.total, Int64(100));
		});
		
		test('copyWith operation', () {
			final original = PageResponse(
				nextKey: Uint8List.fromList([1, 2, 3]),
				total: Int64(100),
			);
			
			final copied = original.copyWith((response) {
				response.total = Int64(200);
			});
			
			expect(copied.total, Int64(200));
			expect(original.total, Int64(100)); // original unchanged
		});
		
		test('JSON serialization and deserialization', () {
			final pageResponse = PageResponse(
				nextKey: Uint8List.fromList([7, 8, 9]),
				total: Int64(350),
			);
			
			final json = jsonEncode(pageResponse.writeToJsonMap());
			final fromJson = PageResponse.fromJson(json);
			
			expect(fromJson.nextKey, [7, 8, 9]);
			expect(fromJson.total, Int64(350));
		});
		
		test('binary serialization and deserialization', () {
			final pageResponse = PageResponse(
				nextKey: Uint8List.fromList([11, 12, 13]),
				total: Int64(450),
			);
			
			final buffer = pageResponse.writeToBuffer();
			final fromBuffer = PageResponse.fromBuffer(buffer);
			
			expect(fromBuffer.nextKey, [11, 12, 13]);
			expect(fromBuffer.total, Int64(450));
		});
		
		test('getDefault returns same instance', () {
			final default1 = PageResponse.getDefault();
			final default2 = PageResponse.getDefault();
			expect(identical(default1, default2), isTrue);
		});
		
		test('createEmptyInstance creates new instance', () {
			final pageResponse = PageResponse();
			final empty = pageResponse.createEmptyInstance();
			expect(empty.nextKey, isEmpty);
			expect(empty.total, Int64.ZERO);
			expect(identical(pageResponse, empty), isFalse);
		});
		
		test('createRepeated creates PbList', () {
			final list = PageResponse.createRepeated();
			expect(list, isA<pb.PbList<PageResponse>>());
			expect(list, isEmpty);
			
			list.add(PageResponse(total: Int64(100)));
			expect(list.length, 1);
		});
		
		test('info_ returns BuilderInfo', () {
			final pageResponse = PageResponse();
			final info = pageResponse.info_;
			expect(info, isA<pb.BuilderInfo>());
			expect(info.qualifiedMessageName, contains('PageResponse'));
		});
		
		test('large total value', () {
			final pageResponse = PageResponse(
				total: Int64.parseInt('9223372036854775807'), // max int64
			);
			
			expect(pageResponse.total.toString(), '9223372036854775807');
			
			final buffer = pageResponse.writeToBuffer();
			final fromBuffer = PageResponse.fromBuffer(buffer);
			expect(fromBuffer.total.toString(), '9223372036854775807');
		});
		
		test('zero total', () {
			final pageResponse = PageResponse(total: Int64.ZERO);
			
			expect(pageResponse.total, Int64.ZERO);
		});
		
		test('empty nextKey', () {
			final pageResponse = PageResponse(nextKey: Uint8List(0));
			
			expect(pageResponse.nextKey, isEmpty);
			expect(pageResponse.hasNextKey(), false);
		});
		
		test('large nextKey', () {
			final largeKey = Uint8List(500);
			for (int i = 0; i < 500; i++) {
				largeKey[i] = (i * 2) % 256;
			}
			
			final pageResponse = PageResponse(nextKey: largeKey);
			
			expect(pageResponse.nextKey.length, 500);
			expect(pageResponse.nextKey[0], 0);
			expect(pageResponse.nextKey[499], 230);
			
			final buffer = pageResponse.writeToBuffer();
			final fromBuffer = PageResponse.fromBuffer(buffer);
			expect(fromBuffer.nextKey.length, 500);
			expect(fromBuffer.nextKey[0], 0);
			expect(fromBuffer.nextKey[499], 230);
		});
	});
	
	group('cosmos.base.query.v1beta1 error handling', () {
		test('invalid buffer deserialization', () {
			expect(() => PageRequest.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => PageResponse.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			expect(() => PageRequest.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => PageResponse.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('cosmos.base.query.v1beta1 comprehensive coverage', () {
		test('all message types have proper info_', () {
			expect(PageRequest().info_, isA<pb.BuilderInfo>());
			expect(PageResponse().info_, isA<pb.BuilderInfo>());
		});
		
		test('all message types support createEmptyInstance', () {
			expect(PageRequest().createEmptyInstance(), isA<PageRequest>());
			expect(PageResponse().createEmptyInstance(), isA<PageResponse>());
		});
		
		test('roundtrip consistency for all types', () {
			final request = PageRequest(
				key: Uint8List.fromList([1, 2, 3]),
				offset: Int64(10),
				limit: Int64(100),
				countTotal: true,
				reverse: false,
			);
			final response = PageResponse(
				nextKey: Uint8List.fromList([4, 5, 6]),
				total: Int64(200),
			);
			
			// JSON roundtrip
			final requestFromJson = PageRequest.fromJson(jsonEncode(request.writeToJsonMap()));
			final responseFromJson = PageResponse.fromJson(jsonEncode(response.writeToJsonMap()));
			
			expect(requestFromJson.key, request.key);
			expect(requestFromJson.offset, request.offset);
			expect(requestFromJson.limit, request.limit);
			expect(requestFromJson.countTotal, request.countTotal);
			expect(requestFromJson.reverse, request.reverse);
			
			expect(responseFromJson.nextKey, response.nextKey);
			expect(responseFromJson.total, response.total);
			
			// Buffer roundtrip
			final requestFromBuffer = PageRequest.fromBuffer(request.writeToBuffer());
			final responseFromBuffer = PageResponse.fromBuffer(response.writeToBuffer());
			
			expect(requestFromBuffer.key, request.key);
			expect(requestFromBuffer.offset, request.offset);
			expect(requestFromBuffer.limit, request.limit);
			expect(requestFromBuffer.countTotal, request.countTotal);
			expect(requestFromBuffer.reverse, request.reverse);
			
			expect(responseFromBuffer.nextKey, response.nextKey);
			expect(responseFromBuffer.total, response.total);
		});
		
		test('default values consistency', () {
			final request = PageRequest();
			final response = PageResponse();
			
			expect(request.offset, Int64.ZERO);
			expect(request.limit, Int64.ZERO);
			expect(request.countTotal, false);
			expect(request.reverse, false);
			expect(request.key, isEmpty);
			
			expect(response.total, Int64.ZERO);
			expect(response.nextKey, isEmpty);
		});
		
		test('field presence detection', () {
			final request = PageRequest();
			final response = PageResponse();
			
			// Initially no fields are set
			expect(request.hasKey(), false);
			expect(request.hasOffset(), false);
			expect(request.hasLimit(), false);
			expect(request.hasCountTotal(), false);
			expect(request.hasReverse(), false);
			
			expect(response.hasNextKey(), false);
			expect(response.hasTotal(), false);
			
			// Set fields and verify presence
			request.key = Uint8List.fromList([1]);
			request.offset = Int64(1);
			request.limit = Int64(1);
			request.countTotal = true;
			request.reverse = true;
			
			response.nextKey = Uint8List.fromList([2]);
			response.total = Int64(1);
			
			expect(request.hasKey(), true);
			expect(request.hasOffset(), true);
			expect(request.hasLimit(), true);
			expect(request.hasCountTotal(), true);
			expect(request.hasReverse(), true);
			
			expect(response.hasNextKey(), true);
			expect(response.hasTotal(), true);
		});
	});
} 