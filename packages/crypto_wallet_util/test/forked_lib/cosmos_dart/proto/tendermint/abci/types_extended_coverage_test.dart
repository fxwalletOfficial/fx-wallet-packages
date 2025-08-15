import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/abci/types.pb.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  group('ABCI Types Extended Coverage Tests', () {
    group('Serialization Methods Coverage', () {
      test('should cover Request fromBuffer constructor', () {
        final request = Request()..echo = (RequestEcho()..message = 'test');
        final buffer = request.writeToBuffer();
        
        final reconstructed = Request.fromBuffer(buffer);
        expect(reconstructed.hasEcho(), isTrue);
        expect(reconstructed.echo.message, equals('test'));
      });

      test('should cover Request fromJson constructor', () {
        final request = Request()..echo = (RequestEcho()..message = 'test');
        final json = request.writeToJson();
        
        final reconstructed = Request.fromJson(json);
        expect(reconstructed.hasEcho(), isTrue);
        expect(reconstructed.echo.message, equals('test'));
      });

      test('should cover Response fromBuffer constructor', () {
        final response = Response()..echo = (ResponseEcho()..message = 'test');
        final buffer = response.writeToBuffer();
        
        final reconstructed = Response.fromBuffer(buffer);
        expect(reconstructed.hasEcho(), isTrue);
        expect(reconstructed.echo.message, equals('test'));
      });

      test('should cover ResponseInfo fromBuffer constructor', () {
        final responseInfo = ResponseInfo()
          ..data = 'test data'
          ..version = 'v1.0.0';
        final buffer = responseInfo.writeToBuffer();
        
        final reconstructed = ResponseInfo.fromBuffer(buffer);
        expect(reconstructed.data, equals('test data'));
        expect(reconstructed.version, equals('v1.0.0'));
      });

      test('should cover ResponseSetOption fromBuffer constructor', () {
        final responseSetOption = ResponseSetOption()
          ..code = 0
          ..log = 'success';
        final buffer = responseSetOption.writeToBuffer();
        
        final reconstructed = ResponseSetOption.fromBuffer(buffer);
        expect(reconstructed.code, equals(0));
        expect(reconstructed.log, equals('success'));
      });
    });

    group('Clone Methods Coverage', () {
      test('should cover Request clone method', () {
        final original = Request()..echo = (RequestEcho()..message = 'original');
        final cloned = original.clone();
        
        expect(cloned.hasEcho(), isTrue);
        expect(cloned.echo.message, equals('original'));
        
        // Modify original to ensure they're separate
        original.echo.message = 'modified';
        expect(cloned.echo.message, equals('original')); // Should remain unchanged
      });

      test('should cover ResponseInfo clone method', () {
        final original = ResponseInfo()
          ..data = 'original data'
          ..version = 'v1.0.0';
        final cloned = original.clone();
        
        expect(cloned.data, equals('original data'));
        expect(cloned.version, equals('v1.0.0'));
        
        // Modify original
        original.data = 'modified data';
        expect(cloned.data, equals('original data')); // Should remain unchanged
      });

      test('should cover ResponseSetOption clone method', () {
        final original = ResponseSetOption()
          ..code = 0
          ..log = 'success';
        final cloned = original.clone();
        
        expect(cloned.code, equals(0));
        expect(cloned.log, equals('success'));
      });

      test('should cover ResponseInitChain clone method', () {
        final original = ResponseInitChain();
        final cloned = original.clone();
        
        expect(cloned, isNotNull);
      });
    });

    group('CopyWith Methods Coverage', () {
      test('should cover Request copyWith method', () {
        final original = Request()..echo = (RequestEcho()..message = 'original');
        
        final modified = original.copyWith((request) {
          request.echo.message = 'modified';
        });
        
        expect(modified.echo.message, equals('modified'));
      });

      test('should cover ResponseInfo copyWith method', () {
        final original = ResponseInfo()
          ..data = 'original'
          ..version = 'v1.0.0';
        
        final modified = original.copyWith((response) {
          response.data = 'modified';
        });
        
        expect(modified.data, equals('modified'));
        expect(modified.version, equals('v1.0.0'));
      });

      test('should cover ResponseSetOption copyWith method', () {
        final original = ResponseSetOption()
          ..code = 0
          ..log = 'original';
        
        final modified = original.copyWith((response) {
          response.log = 'modified';
        });
        
        expect(modified.log, equals('modified'));
        expect(modified.code, equals(0));
      });

      test('should cover ResponseInitChain copyWith method', () {
        final original = ResponseInitChain();
        
        final modified = original.copyWith((response) {
          // Just test that the method works
        });
        
        expect(modified, isNotNull);
      });
    });

    group('CreateRepeated Methods Coverage', () {
      test('should cover ResponseInfo createRepeated', () {
        final list = ResponseInfo.createRepeated();
        expect(list, isA<List<ResponseInfo>>());
        expect(list.isEmpty, isTrue);
        
        list.add(ResponseInfo()..data = 'test');
        expect(list.length, equals(1));
      });

      test('should cover ResponseSetOption createRepeated', () {
        final list = ResponseSetOption.createRepeated();
        expect(list, isA<List<ResponseSetOption>>());
        expect(list.isEmpty, isTrue);
        
        list.add(ResponseSetOption()..code = 0);
        expect(list.length, equals(1));
      });

      test('should cover Event createRepeated', () {
        final list = Event.createRepeated();
        expect(list, isA<List<Event>>());
        expect(list.isEmpty, isTrue);
        
        list.add(Event()..type = 'test-event');
        expect(list.length, equals(1));
      });

      test('should cover Validator createRepeated', () {
        final list = Validator.createRepeated();
        expect(list, isA<List<Validator>>());
        expect(list.isEmpty, isTrue);
      });
    });

    group('Field Methods Coverage - Has/Clear/Ensure', () {
      test('should cover Request ensure methods', () {
        final request = Request();
        
        // Test ensureEcho
        final echo = request.ensureEcho();
        expect(echo, isA<RequestEcho>());
        expect(request.hasEcho(), isTrue);
        
        // Test ensureInfo
        final info = request.ensureInfo();
        expect(info, isA<RequestInfo>());
        expect(request.hasInfo(), isTrue);
      });

      test('should cover Request clear methods', () {
        final request = Request()
          ..echo = (RequestEcho()..message = 'test');
        
        expect(request.hasEcho(), isTrue);
        
        request.clearEcho();
        expect(request.hasEcho(), isFalse);
        
        // Test another clear method
        request.info = (RequestInfo()..version = 'v1.0.0');
        expect(request.hasInfo(), isTrue);
        
        request.clearInfo();
        expect(request.hasInfo(), isFalse);
      });

      test('should cover Request getter methods when fields not set', () {
        final request = Request();
        
        // These should not throw and return default values
        expect(() => request.flush, returnsNormally);
        expect(() => request.beginBlock, returnsNormally);
        expect(() => request.deliverTx, returnsNormally);
        expect(() => request.commit, returnsNormally);
        expect(() => request.listSnapshots, returnsNormally);
      });

      test('should cover ResponseInfo has/clear methods', () {
        final responseInfo = ResponseInfo()
          ..data = 'test'
          ..lastBlockHeight = Int64(100);
        
        expect(responseInfo.hasData(), isTrue);
        expect(responseInfo.hasLastBlockHeight(), isTrue);
        
        responseInfo.clearData();
        expect(responseInfo.hasData(), isFalse);
        expect(responseInfo.hasLastBlockHeight(), isTrue);
        
        responseInfo.clearLastBlockHeight();
        expect(responseInfo.hasLastBlockHeight(), isFalse);
      });

      test('should cover ResponseSetOption has/clear methods', () {
        final response = ResponseSetOption()
          ..code = 0
          ..log = 'test'
          ..info = 'test info';
        
        expect(response.hasCode(), isTrue);
        expect(response.hasLog(), isTrue);
        expect(response.hasInfo(), isTrue);
        
        response.clearCode();
        response.clearLog();
        response.clearInfo();
        
        expect(response.hasCode(), isFalse);
        expect(response.hasLog(), isFalse);
        expect(response.hasInfo(), isFalse);
      });
    });

    group('Oneof Field Switching Coverage', () {
      test('should cover Request oneof field switching and clearing', () {
        final request = Request()..echo = (RequestEcho()..message = 'echo');
        
        expect(request.whichValue(), equals(Request_Value.echo));
        expect(request.hasEcho(), isTrue);
        
        // Switch to different oneof value
        request.info = RequestInfo()..version = 'v1.0.0';
        expect(request.whichValue(), equals(Request_Value.info));
        expect(request.hasEcho(), isFalse); // Should be cleared due to oneof
        expect(request.hasInfo(), isTrue);
        
        // Clear oneof value
        request.clearValue();
        expect(request.whichValue(), equals(Request_Value.notSet));
        expect(request.hasInfo(), isFalse);
      });

      test('should cover Response oneof field switching', () {
        final response = Response()..echo = (ResponseEcho()..message = 'echo');
        
        expect(response.whichValue(), equals(Response_Value.echo));
        expect(response.hasEcho(), isTrue);
        
        // Switch to different value
        response.info = ResponseInfo()..data = 'test';
        expect(response.whichValue(), equals(Response_Value.info));
        expect(response.hasEcho(), isFalse);
        expect(response.hasInfo(), isTrue);
        
        // Clear oneof
        response.clearValue();
        expect(response.whichValue(), equals(Response_Value.notSet));
        expect(response.hasInfo(), isFalse);
      });
    });

    group('Additional Factory Methods', () {
      test('should cover createEmptyInstance methods', () {
        final request = Request().createEmptyInstance();
        expect(request, isA<Request>());
        expect(request.whichValue(), equals(Request_Value.notSet));
        
        final response = Response().createEmptyInstance();
        expect(response, isA<Response>());
        expect(response.whichValue(), equals(Response_Value.notSet));
        
        final responseInfo = ResponseInfo().createEmptyInstance();
        expect(responseInfo, isA<ResponseInfo>());
        expect(responseInfo.data, isEmpty);
      });
    });
  });
} 