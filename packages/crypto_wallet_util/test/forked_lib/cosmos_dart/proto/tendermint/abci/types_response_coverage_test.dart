import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/abci/types.pb.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  group('ABCI Response & Missing Methods Coverage Tests', () {
    group('Response Clone & CopyWith Methods Coverage', () {
      test('should cover Response clone method', () {
        final original = Response()
          ..echo = (ResponseEcho()..message = 'test-message');
        
        final cloned = original.clone();
        
        expect(cloned.hasEcho(), isTrue);
        expect(cloned.echo.message, equals('test-message'));
        
        // Test with info (oneof behavior - only one field can be set)
        final originalWithInfo = Response()
          ..info = (ResponseInfo()..version = 'v1.0.0');
        
        final clonedWithInfo = originalWithInfo.clone();
        expect(clonedWithInfo.hasInfo(), isTrue);
        expect(clonedWithInfo.info.version, equals('v1.0.0'));
        expect(clonedWithInfo.hasEcho(), isFalse); // oneof behavior
      });

      test('should cover Response copyWith method', () {
        final original = Response()
          ..echo = (ResponseEcho()..message = 'original');
        
        final modified = original.copyWith((response) {
          response.echo = ResponseEcho()..message = 'modified';
        });
        
        expect(modified.echo.message, equals('modified'));
        
        // Test with different field type
        final originalWithInfo = Response()
          ..info = (ResponseInfo()..version = 'v1.0');
        
        final modifiedInfo = originalWithInfo.copyWith((response) {
          response.info = ResponseInfo()..version = 'v2.0';
        });
        
        expect(modifiedInfo.info.version, equals('v2.0'));
      });

      test('should cover Response with exception', () {
        final original = Response()
          ..exception = (ResponseException()..error = 'test error');
        
        final cloned = original.clone();
        expect(cloned.hasException(), isTrue);
        expect(cloned.exception.error, equals('test error'));
        
        final modified = original.copyWith((response) {
          response.exception.error = 'modified error';
        });
        expect(modified.exception.error, equals('modified error'));
      });
    });

    group('Response Factory Constructor Missing Branches', () {
      test('should cover Response with query parameter', () {
        final queryResponse = ResponseQuery()
          ..code = 0
          ..value = Uint8List.fromList([0x01, 0x02, 0x03]);
        final response = Response(query: queryResponse);
        
        expect(response.hasQuery(), isTrue);
        expect(response.query.code, equals(0));
        expect(response.query.value, equals(Uint8List.fromList([0x01, 0x02, 0x03])));
        expect(response.whichValue(), equals(Response_Value.query));
      });

      test('should cover Response with beginBlock parameter', () {
        final beginBlockResponse = ResponseBeginBlock();
        final response = Response(beginBlock: beginBlockResponse);
        
        expect(response.hasBeginBlock(), isTrue);
        expect(response.whichValue(), equals(Response_Value.beginBlock));
      });

      test('should cover Response with checkTx parameter', () {
        final checkTxResponse = ResponseCheckTx()
          ..code = 0
          ..gasWanted = Int64(1000);
        final response = Response(checkTx: checkTxResponse);
        
        expect(response.hasCheckTx(), isTrue);
        expect(response.checkTx.code, equals(0));
        expect(response.whichValue(), equals(Response_Value.checkTx));
      });

      test('should cover Response with deliverTx parameter', () {
        final deliverTxResponse = ResponseDeliverTx()
          ..code = 0
          ..gasUsed = Int64(500);
        final response = Response(deliverTx: deliverTxResponse);
        
        expect(response.hasDeliverTx(), isTrue);
        expect(response.deliverTx.code, equals(0));
        expect(response.whichValue(), equals(Response_Value.deliverTx));
      });

      test('should cover Response with endBlock parameter', () {
        final endBlockResponse = ResponseEndBlock();
        final response = Response(endBlock: endBlockResponse);
        
        expect(response.hasEndBlock(), isTrue);
        expect(response.whichValue(), equals(Response_Value.endBlock));
      });
    });

    group('Response Field Clear/Ensure Methods Coverage', () {
      test('should cover Response exception clear/ensure methods', () {
        final response = Response()
          ..exception = (ResponseException()..error = 'test error');
        
        expect(response.hasException(), isTrue);
        
        response.clearException();
        expect(response.hasException(), isFalse);
        
        // Test ensureException
        final ensuredException = response.ensureException();
        expect(ensuredException, isA<ResponseException>());
        expect(response.hasException(), isTrue);
      });

      test('should cover Response echo clear/ensure methods', () {
        final response = Response()
          ..echo = (ResponseEcho()..message = 'test');
        
        expect(response.hasEcho(), isTrue);
        
        response.clearEcho();
        expect(response.hasEcho(), isFalse);
        
        final ensuredEcho = response.ensureEcho();
        expect(ensuredEcho, isA<ResponseEcho>());
        expect(response.hasEcho(), isTrue);
      });

      test('should cover Response flush clear/ensure methods', () {
        final response = Response()
          ..flush = ResponseFlush();
        
        expect(response.hasFlush(), isTrue);
        
        response.clearFlush();
        expect(response.hasFlush(), isFalse);
        
        final ensuredFlush = response.ensureFlush();
        expect(ensuredFlush, isA<ResponseFlush>());
        expect(response.hasFlush(), isTrue);
      });

      test('should cover Response info clear/ensure methods', () {
        final response = Response()
          ..info = (ResponseInfo()..version = 'v1.0.0');
        
        expect(response.hasInfo(), isTrue);
        
        response.clearInfo();
        expect(response.hasInfo(), isFalse);
        
        final ensuredInfo = response.ensureInfo();
        expect(ensuredInfo, isA<ResponseInfo>());
        expect(response.hasInfo(), isTrue);
      });

      test('should cover Response setOption clear/ensure methods', () {
        final response = Response()
          ..setOption = (ResponseSetOption()..code = 0);
        
        expect(response.hasSetOption(), isTrue);
        
        response.clearSetOption();
        expect(response.hasSetOption(), isFalse);
        
        final ensuredSetOption = response.ensureSetOption();
        expect(ensuredSetOption, isA<ResponseSetOption>());
        expect(response.hasSetOption(), isTrue);
      });

      test('should cover Response initChain clear/ensure methods', () {
        final response = Response()
          ..initChain = ResponseInitChain();
        
        expect(response.hasInitChain(), isTrue);
        
        response.clearInitChain();
        expect(response.hasInitChain(), isFalse);
        
        final ensuredInitChain = response.ensureInitChain();
        expect(ensuredInitChain, isA<ResponseInitChain>());
        expect(response.hasInitChain(), isTrue);
      });

      test('should cover Response query clear/ensure methods', () {
        final response = Response()
          ..query = (ResponseQuery()..code = 0);
        
        expect(response.hasQuery(), isTrue);
        
        response.clearQuery();
        expect(response.hasQuery(), isFalse);
        
        final ensuredQuery = response.ensureQuery();
        expect(ensuredQuery, isA<ResponseQuery>());
        expect(response.hasQuery(), isTrue);
      });

      test('should cover Response beginBlock clear/ensure methods', () {
        final response = Response()
          ..beginBlock = ResponseBeginBlock();
        
        expect(response.hasBeginBlock(), isTrue);
        
        response.clearBeginBlock();
        expect(response.hasBeginBlock(), isFalse);
        
        final ensuredBeginBlock = response.ensureBeginBlock();
        expect(ensuredBeginBlock, isA<ResponseBeginBlock>());
        expect(response.hasBeginBlock(), isTrue);
      });

      test('should cover Response checkTx clear/ensure methods', () {
        final response = Response()
          ..checkTx = (ResponseCheckTx()..code = 0);
        
        expect(response.hasCheckTx(), isTrue);
        
        response.clearCheckTx();
        expect(response.hasCheckTx(), isFalse);
        
        final ensuredCheckTx = response.ensureCheckTx();
        expect(ensuredCheckTx, isA<ResponseCheckTx>());
        expect(response.hasCheckTx(), isTrue);
      });

      test('should cover Response deliverTx clear/ensure methods', () {
        final response = Response()
          ..deliverTx = (ResponseDeliverTx()..code = 0);
        
        expect(response.hasDeliverTx(), isTrue);
        
        response.clearDeliverTx();
        expect(response.hasDeliverTx(), isFalse);
        
        final ensuredDeliverTx = response.ensureDeliverTx();
        expect(ensuredDeliverTx, isA<ResponseDeliverTx>());
        expect(response.hasDeliverTx(), isTrue);
      });

      test('should cover Response endBlock clear/ensure methods', () {
        final response = Response()
          ..endBlock = ResponseEndBlock();
        
        expect(response.hasEndBlock(), isTrue);
        
        response.clearEndBlock();
        expect(response.hasEndBlock(), isFalse);
        
        final ensuredEndBlock = response.ensureEndBlock();
        expect(ensuredEndBlock, isA<ResponseEndBlock>());
        expect(response.hasEndBlock(), isTrue);
      });

      test('should cover Response commit clear/ensure methods', () {
        final response = Response()
          ..commit = ResponseCommit();
        
        expect(response.hasCommit(), isTrue);
        
        response.clearCommit();
        expect(response.hasCommit(), isFalse);
        
        final ensuredCommit = response.ensureCommit();
        expect(ensuredCommit, isA<ResponseCommit>());
        expect(response.hasCommit(), isTrue);
      });

      test('should cover Response listSnapshots clear/ensure methods', () {
        final response = Response()
          ..listSnapshots = ResponseListSnapshots();
        
        expect(response.hasListSnapshots(), isTrue);
        
        response.clearListSnapshots();
        expect(response.hasListSnapshots(), isFalse);
        
        final ensuredListSnapshots = response.ensureListSnapshots();
        expect(ensuredListSnapshots, isA<ResponseListSnapshots>());
        expect(response.hasListSnapshots(), isTrue);
      });

      test('should cover Response offerSnapshot clear/ensure methods', () {
        final response = Response()
          ..offerSnapshot = ResponseOfferSnapshot();
        
        expect(response.hasOfferSnapshot(), isTrue);
        
        response.clearOfferSnapshot();
        expect(response.hasOfferSnapshot(), isFalse);
        
        final ensuredOfferSnapshot = response.ensureOfferSnapshot();
        expect(ensuredOfferSnapshot, isA<ResponseOfferSnapshot>());
        expect(response.hasOfferSnapshot(), isTrue);
      });
    });

    group('Response Getter Methods for Unset Fields', () {
      test('should cover Response getter methods for unset fields', () {
        final response = Response();
        
        // These should return default values when fields are not set
        expect(() => response.flush, returnsNormally);
        expect(() => response.initChain, returnsNormally);
        expect(() => response.query, returnsNormally);
        expect(() => response.beginBlock, returnsNormally);
        expect(() => response.endBlock, returnsNormally);
      });
    });

    group('Missing RequestXXX CreateRepeated Methods Coverage', () {
      test('should cover RequestCommit createRepeated', () {
        final list = RequestCommit.createRepeated();
        expect(list, isA<List<RequestCommit>>());
        expect(list.isEmpty, isTrue);
        
        list.add(RequestCommit());
        expect(list.length, equals(1));
      });

      test('should cover RequestListSnapshots createRepeated', () {
        final list = RequestListSnapshots.createRepeated();
        expect(list, isA<List<RequestListSnapshots>>());
        expect(list.isEmpty, isTrue);
        
        list.add(RequestListSnapshots());
        expect(list.length, equals(1));
      });

      test('should cover RequestOfferSnapshot createRepeated', () {
        final list = RequestOfferSnapshot.createRepeated();
        expect(list, isA<List<RequestOfferSnapshot>>());
        expect(list.isEmpty, isTrue);
        
        list.add(RequestOfferSnapshot());
        expect(list.length, equals(1));
      });

      test('should cover RequestLoadSnapshotChunk createRepeated', () {
        final list = RequestLoadSnapshotChunk.createRepeated();
        expect(list, isA<List<RequestLoadSnapshotChunk>>());
        expect(list.isEmpty, isTrue);
      });

      test('should cover RequestApplySnapshotChunk createRepeated', () {
        final list = RequestApplySnapshotChunk.createRepeated();
        expect(list, isA<List<RequestApplySnapshotChunk>>());
        expect(list.isEmpty, isTrue);
      });
    });

    group('Missing RequestXXX Clone/CopyWith Methods Coverage', () {
      test('should cover RequestOfferSnapshot clone and copyWith', () {
        final original = RequestOfferSnapshot()
          ..snapshot = (Snapshot()..height = Int64(100))
          ..appHash = Uint8List.fromList([0xAA, 0xBB]);
        
        final cloned = original.clone();
        expect(cloned.hasSnapshot(), isTrue);
        expect(cloned.snapshot.height, equals(Int64(100)));
        expect(cloned.hasAppHash(), isTrue);
        
        final modified = original.copyWith((request) {
          request.snapshot.height = Int64(200);
        });
        expect(modified.snapshot.height, equals(Int64(200)));
      });

      test('should cover RequestOfferSnapshot field has/clear methods', () {
        final request = RequestOfferSnapshot()
          ..appHash = Uint8List.fromList([0x01, 0x02]);
        
        expect(request.hasAppHash(), isTrue);
        
        request.clearAppHash();
        expect(request.hasAppHash(), isFalse);
      });

      test('should cover RequestLoadSnapshotChunk clone and copyWith', () {
        final original = RequestLoadSnapshotChunk()
          ..height = Int64(100)
          ..format = 1
          ..chunk = 5;
        
        final cloned = original.clone();
        expect(cloned.height, equals(Int64(100)));
        expect(cloned.format, equals(1));
        expect(cloned.chunk, equals(5));
        
        final modified = original.copyWith((request) {
          request.chunk = 10;
        });
        expect(modified.chunk, equals(10));
      });

      test('should cover RequestApplySnapshotChunk clone and copyWith', () {
        final original = RequestApplySnapshotChunk()
          ..index = 1
          ..chunk = Uint8List.fromList([0xFF, 0xEE])
          ..sender = 'test-sender';
        
        final cloned = original.clone();
        expect(cloned.index, equals(1));
        expect(cloned.chunk, equals(Uint8List.fromList([0xFF, 0xEE])));
        expect(cloned.sender, equals('test-sender'));
        
        final modified = original.copyWith((request) {
          request.sender = 'modified-sender';
        });
        expect(modified.sender, equals('modified-sender'));
      });
    });

    group('Additional Comprehensive Tests', () {
      test('should cover Response createRepeated method', () {
        final list = Response.createRepeated();
        expect(list, isA<List<Response>>());
        expect(list.isEmpty, isTrue);
        
        list.add(Response()..echo = (ResponseEcho()..message = 'test'));
        expect(list.length, equals(1));
        expect(list.first.hasEcho(), isTrue);
      });

      test('should cover complex Response oneof switching', () {
        final response = Response()..echo = (ResponseEcho()..message = 'echo');
        
        expect(response.whichValue(), equals(Response_Value.echo));
        expect(response.hasEcho(), isTrue);
        
        // Switch to info - should clear echo
        response.info = ResponseInfo()..version = 'v1.0';
        expect(response.whichValue(), equals(Response_Value.info));
        expect(response.hasInfo(), isTrue);
        expect(response.hasEcho(), isFalse);
        
        // Clear all fields
        response.clearValue();
        expect(response.whichValue(), equals(Response_Value.notSet));
      });

      test('should cover Request factory constructor edge cases', () {
        // Test Request with multiple parameters set simultaneously
        final request = Request()
          ..echo = (RequestEcho()..message = 'test')
          ..info = (RequestInfo()..version = 'v1.0');
        
        expect(request.hasEcho(), isFalse); // oneof behavior - only last one remains
        expect(request.hasInfo(), isTrue); // last one set remains
        expect(request.whichValue(), equals(Request_Value.info));
      });
    });
  });
} 