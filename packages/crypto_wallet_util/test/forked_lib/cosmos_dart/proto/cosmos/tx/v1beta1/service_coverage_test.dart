import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/v1beta1/service.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/query/v1beta1/pagination.pb.dart';

void main() {
  group('Cosmos Tx Service Coverage Tests', () {
    group('GetTxsEventRequest Missing Methods Coverage', () {
      test('should cover GetTxsEventRequest clone method', () {
        final original = GetTxsEventRequest()
          ..events.addAll(['transfer', 'mint'])
          ..pagination = (PageRequest()
            ..limit = Int64(10)
            ..offset = Int64(20))
          ..orderBy = OrderBy.ORDER_BY_ASC;
        
        final cloned = original.clone();
        
        expect(cloned.events.length, equals(2));
        expect(cloned.events, containsAll(['transfer', 'mint']));
        expect(cloned.hasPagination(), isTrue);
        expect(cloned.pagination.limit, equals(Int64(10)));
        expect(cloned.pagination.offset, equals(Int64(20)));
        expect(cloned.orderBy, equals(OrderBy.ORDER_BY_ASC));
        
        // Modify original to ensure separation
        original.events.add('burn');
        expect(cloned.events.length, equals(2)); // Should remain unchanged
      });

      test('should cover GetTxsEventRequest copyWith method', () {
        final original = GetTxsEventRequest()
          ..events.add('original-event')
          ..orderBy = OrderBy.ORDER_BY_DESC;
        
        final modified = original.copyWith((request) {
          request.events.clear();
          request.events.add('modified-event');
          request.orderBy = OrderBy.ORDER_BY_ASC;
          request.pagination = PageRequest()..limit = Int64(50);
        });
        
        expect(modified.events.length, equals(1));
        expect(modified.events.first, equals('modified-event'));
        expect(modified.orderBy, equals(OrderBy.ORDER_BY_ASC));
        expect(modified.hasPagination(), isTrue);
        expect(modified.pagination.limit, equals(Int64(50)));
      });

      test('should cover GetTxsEventRequest comprehensive field testing', () {
        final request = GetTxsEventRequest();
        
        // Test initially empty
        expect(request.events, isEmpty);
        expect(request.hasPagination(), isFalse);
        expect(request.hasOrderBy(), isFalse);
        
        // Test adding events
        request.events.addAll(['event1', 'event2', 'event3']);
        expect(request.events.length, equals(3));
        expect(request.events, contains('event2'));
        
        // Test pagination
        request.pagination = PageRequest()
          ..limit = Int64(100)
          ..key = Uint8List.fromList([0x01, 0x02, 0x03]);
        expect(request.hasPagination(), isTrue);
        expect(request.pagination.limit, equals(Int64(100)));
        expect(request.pagination.key, equals(Uint8List.fromList([0x01, 0x02, 0x03])));
        
        // Test orderBy
        request.orderBy = OrderBy.ORDER_BY_DESC;
        expect(request.hasOrderBy(), isTrue);
        expect(request.orderBy, equals(OrderBy.ORDER_BY_DESC));
        
        // Test clear methods
        request.clearPagination();
        expect(request.hasPagination(), isFalse);
        
        request.clearOrderBy();
        expect(request.hasOrderBy(), isFalse);
        
        // Test ensure methods
        final ensuredPagination = request.ensurePagination();
        expect(ensuredPagination, isA<PageRequest>());
        expect(request.hasPagination(), isTrue);
      });
    });

    group('GetTxsEventResponse Missing Methods Coverage', () {
      test('should cover GetTxsEventResponse clone method', () {
        final original = GetTxsEventResponse()
          ..pagination = (PageResponse()
            ..nextKey = Uint8List.fromList([0xAA, 0xBB])
            ..total = Int64(1000));
        
        final cloned = original.clone();
        
        expect(cloned.hasPagination(), isTrue);
        expect(cloned.pagination.nextKey, equals(Uint8List.fromList([0xAA, 0xBB])));
        expect(cloned.pagination.total, equals(Int64(1000)));
        expect(cloned.txs, isEmpty); // Lists should be empty initially
        expect(cloned.txResponses, isEmpty);
        
        // Modify original to ensure separation
        original.pagination.total = Int64(2000);
        expect(cloned.pagination.total, equals(Int64(1000))); // Should remain unchanged
      });

      test('should cover GetTxsEventResponse copyWith method', () {
        final original = GetTxsEventResponse()
          ..pagination = (PageResponse()..total = Int64(500));
        
        final modified = original.copyWith((response) {
          response.pagination = PageResponse()
            ..total = Int64(1500)
            ..nextKey = Uint8List.fromList([0xFF, 0xEE]);
        });
        
        expect(modified.hasPagination(), isTrue);
        expect(modified.pagination.total, equals(Int64(1500)));
        expect(modified.pagination.nextKey, equals(Uint8List.fromList([0xFF, 0xEE])));
      });

      test('should cover GetTxsEventResponse createRepeated method', () {
        final list = GetTxsEventResponse.createRepeated();
        
        expect(list, isA<List<GetTxsEventResponse>>());
        expect(list.isEmpty, isTrue);
        
        // Test adding to the list
        list.add(GetTxsEventResponse()
          ..pagination = (PageResponse()..total = Int64(10)));
        list.add(GetTxsEventResponse()
          ..pagination = (PageResponse()..total = Int64(20)));
        
        expect(list.length, equals(2));
        expect(list.first.pagination.total, equals(Int64(10)));
        expect(list.last.pagination.total, equals(Int64(20)));
      });

      test('should cover GetTxsEventResponse comprehensive field testing', () {
        final response = GetTxsEventResponse();
        
        // Test initially empty
        expect(response.txs, isEmpty);
        expect(response.txResponses, isEmpty);
        expect(response.hasPagination(), isFalse);
        
        // Test pagination
        response.pagination = PageResponse()
          ..total = Int64(42)
          ..nextKey = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
        
        expect(response.hasPagination(), isTrue);
        expect(response.pagination.total, equals(Int64(42)));
        expect(response.pagination.nextKey, equals(Uint8List.fromList([0x01, 0x02, 0x03, 0x04])));
        
        // Test clear methods
        response.clearPagination();
        expect(response.hasPagination(), isFalse);
        
        // Test ensure methods
        final ensuredPagination = response.ensurePagination();
        expect(ensuredPagination, isA<PageResponse>());
        expect(response.hasPagination(), isTrue);
      });

      test('should cover GetTxsEventResponse serialization', () {
        final original = GetTxsEventResponse()
          ..pagination = (PageResponse()
            ..total = Int64(123)
            ..nextKey = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]));
        
        // Test fromBuffer serialization
        final buffer = original.writeToBuffer();
        final fromBuffer = GetTxsEventResponse.fromBuffer(buffer);
        expect(fromBuffer.hasPagination(), isTrue);
        expect(fromBuffer.pagination.total, equals(Int64(123)));
        expect(fromBuffer.pagination.nextKey, equals(Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF])));
        
        // Test fromJson serialization
        final json = original.writeToJson();
        final fromJson = GetTxsEventResponse.fromJson(json);
        expect(fromJson.hasPagination(), isTrue);
        expect(fromJson.pagination.total, equals(Int64(123)));
      });
    });

    group('Static Methods Coverage', () {
      test('should cover GetTxsEventRequest static methods', () {
        // Test createRepeated
        final list = GetTxsEventRequest.createRepeated();
        expect(list, isA<List<GetTxsEventRequest>>());
        expect(list.isEmpty, isTrue);
        
        list.add(GetTxsEventRequest()..events.add('item1'));
        list.add(GetTxsEventRequest()..events.add('item2'));
        
        expect(list.length, equals(2));
        expect(list.first.events.first, equals('item1'));
        expect(list.last.events.first, equals('item2'));
        
        // Test getDefault
        final defaultInstance = GetTxsEventRequest.getDefault();
        expect(defaultInstance, isA<GetTxsEventRequest>());
        expect(defaultInstance.events, isEmpty);
        
        // Test create and createEmptyInstance
        final created = GetTxsEventRequest.create();
        expect(created, isA<GetTxsEventRequest>());
        
        final emptyInstance = created.createEmptyInstance();
        expect(emptyInstance, isA<GetTxsEventRequest>());
      });

      test('should cover GetTxsEventResponse static methods', () {
        // Test getDefault
        final defaultInstance = GetTxsEventResponse.getDefault();
        expect(defaultInstance, isA<GetTxsEventResponse>());
        expect(defaultInstance.txs, isEmpty);
        expect(defaultInstance.txResponses, isEmpty);
        
        // Test create and createEmptyInstance
        final created = GetTxsEventResponse.create();
        expect(created, isA<GetTxsEventResponse>());
        
        final emptyInstance = created.createEmptyInstance();
        expect(emptyInstance, isA<GetTxsEventResponse>());
      });
    });

    group('Enum and Edge Cases Coverage', () {
      test('should cover OrderBy enum usage', () {
        final request = GetTxsEventRequest();
        
        // Test different OrderBy values
        request.orderBy = OrderBy.ORDER_BY_UNSPECIFIED;
        expect(request.orderBy, equals(OrderBy.ORDER_BY_UNSPECIFIED));
        
        request.orderBy = OrderBy.ORDER_BY_ASC;
        expect(request.orderBy, equals(OrderBy.ORDER_BY_ASC));
        
        request.orderBy = OrderBy.ORDER_BY_DESC;
        expect(request.orderBy, equals(OrderBy.ORDER_BY_DESC));
        
        // Test has/clear for orderBy
        expect(request.hasOrderBy(), isTrue);
        request.clearOrderBy();
        expect(request.hasOrderBy(), isFalse);
      });

      test('should cover serialization methods', () {
        final original = GetTxsEventRequest()
          ..events.addAll(['test-event-1', 'test-event-2'])
          ..pagination = (PageRequest()..limit = Int64(25))
          ..orderBy = OrderBy.ORDER_BY_ASC;
        
        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = GetTxsEventRequest.fromBuffer(buffer);
        expect(fromBuffer.events.length, equals(2));
        expect(fromBuffer.events, containsAll(['test-event-1', 'test-event-2']));
        expect(fromBuffer.hasPagination(), isTrue);
        expect(fromBuffer.pagination.limit, equals(Int64(25)));
        expect(fromBuffer.orderBy, equals(OrderBy.ORDER_BY_ASC));
        
        // Test fromJson
        final json = original.writeToJson();
        final fromJson = GetTxsEventRequest.fromJson(json);
        expect(fromJson.events.length, equals(2));
        expect(fromJson.orderBy, equals(OrderBy.ORDER_BY_ASC));
      });
    });
  });
} 