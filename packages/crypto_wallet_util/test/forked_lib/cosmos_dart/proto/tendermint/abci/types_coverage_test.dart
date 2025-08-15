import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/abci/types.pb.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  group('ABCI Types Coverage Tests', () {
    group('Request Factory Constructor Missing Branches', () {
      test('should create Request with flush', () {
        final flush = RequestFlush();
        final request = Request(flush: flush);
        
        expect(request.hasFlush(), isTrue);
        expect(request.whichValue(), equals(Request_Value.flush));
      });

      test('should create Request with setOption', () {
        final setOption = RequestSetOption()
          ..key = 'test-key'
          ..value = 'test-value';
        final request = Request(setOption: setOption);
        
        expect(request.hasSetOption(), isTrue);
        expect(request.setOption.key, equals('test-key'));
        expect(request.whichValue(), equals(Request_Value.setOption));
      });

      test('should create Request with initChain', () {
        final initChain = RequestInitChain()
          ..chainId = 'test-chain';
        final request = Request(initChain: initChain);
        
        expect(request.hasInitChain(), isTrue);
        expect(request.initChain.chainId, equals('test-chain'));
        expect(request.whichValue(), equals(Request_Value.initChain));
      });

      test('should create Request with beginBlock', () {
        final beginBlock = RequestBeginBlock()
          ..hash = Uint8List.fromList([0xAA, 0xBB, 0xCC]);
        final request = Request(beginBlock: beginBlock);
        
        expect(request.hasBeginBlock(), isTrue);
        expect(request.whichValue(), equals(Request_Value.beginBlock));
      });

      test('should create Request with deliverTx', () {
        final deliverTx = RequestDeliverTx()
          ..tx = Uint8List.fromList([0xFF, 0xEE, 0xDD]);
        final request = Request(deliverTx: deliverTx);
        
        expect(request.hasDeliverTx(), isTrue);
        expect(request.whichValue(), equals(Request_Value.deliverTx));
      });

      test('should create Request with endBlock', () {
        final endBlock = RequestEndBlock()..height = Int64(456);
        final request = Request(endBlock: endBlock);
        
        expect(request.hasEndBlock(), isTrue);
        expect(request.endBlock.height, equals(Int64(456)));
        expect(request.whichValue(), equals(Request_Value.endBlock));
      });

      test('should create Request with commit', () {
        final commit = RequestCommit();
        final request = Request(commit: commit);
        
        expect(request.hasCommit(), isTrue);
        expect(request.whichValue(), equals(Request_Value.commit));
      });

      test('should create Request with listSnapshots', () {
        final listSnapshots = RequestListSnapshots();
        final request = Request(listSnapshots: listSnapshots);
        
        expect(request.hasListSnapshots(), isTrue);
        expect(request.whichValue(), equals(Request_Value.listSnapshots));
      });

      test('should create Request with offerSnapshot', () {
        final snapshot = Snapshot()
          ..height = Int64(789)
          ..format = 1
          ..chunks = 5;
        final offerSnapshot = RequestOfferSnapshot()
          ..snapshot = snapshot;
        final request = Request(offerSnapshot: offerSnapshot);
        
        expect(request.hasOfferSnapshot(), isTrue);
        expect(request.offerSnapshot.snapshot.height, equals(Int64(789)));
        expect(request.whichValue(), equals(Request_Value.offerSnapshot));
      });

      test('should create Request with loadSnapshotChunk', () {
        final loadSnapshotChunk = RequestLoadSnapshotChunk()
          ..height = Int64(999)
          ..format = 2
          ..chunk = 3;
        final request = Request(loadSnapshotChunk: loadSnapshotChunk);
        
        expect(request.hasLoadSnapshotChunk(), isTrue);
        expect(request.loadSnapshotChunk.height, equals(Int64(999)));
        expect(request.whichValue(), equals(Request_Value.loadSnapshotChunk));
      });

      test('should create Request with applySnapshotChunk', () {
        final applySnapshotChunk = RequestApplySnapshotChunk()
          ..index = 7
          ..chunk = Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD])
          ..sender = 'test-sender';
        final request = Request(applySnapshotChunk: applySnapshotChunk);
        
        expect(request.hasApplySnapshotChunk(), isTrue);
        expect(request.applySnapshotChunk.sender, equals('test-sender'));
        expect(request.whichValue(), equals(Request_Value.applySnapshotChunk));
      });
    });

    group('Response Factory Constructor Missing Branches', () {
      test('should create Response with exception', () {
        final exception = ResponseException()
          ..error = 'test error message';
        final response = Response(exception: exception);
        
        expect(response.hasException(), isTrue);
        expect(response.exception.error, equals('test error message'));
        expect(response.whichValue(), equals(Response_Value.exception));
      });

      test('should create Response with flush', () {
        final flush = ResponseFlush();
        final response = Response(flush: flush);
        
        expect(response.hasFlush(), isTrue);
        expect(response.whichValue(), equals(Response_Value.flush));
      });

      test('should create Response with setOption', () {
        final setOption = ResponseSetOption()
          ..code = 0
          ..log = 'success';
        final response = Response(setOption: setOption);
        
        expect(response.hasSetOption(), isTrue);
        expect(response.setOption.log, equals('success'));
        expect(response.whichValue(), equals(Response_Value.setOption));
      });

      test('should create Response with initChain', () {
        final initChain = ResponseInitChain();
        final response = Response(initChain: initChain);
        
        expect(response.hasInitChain(), isTrue);
        expect(response.whichValue(), equals(Response_Value.initChain));
      });

      test('should create Response with beginBlock', () {
        final beginBlock = ResponseBeginBlock();
        final response = Response(beginBlock: beginBlock);
        
        expect(response.hasBeginBlock(), isTrue);
        expect(response.whichValue(), equals(Response_Value.beginBlock));
      });

      test('should create Response with deliverTx', () {
        final deliverTx = ResponseDeliverTx()
          ..code = 0
          ..log = 'deliver successful';
        final response = Response(deliverTx: deliverTx);
        
        expect(response.hasDeliverTx(), isTrue);
        expect(response.deliverTx.log, equals('deliver successful'));
        expect(response.whichValue(), equals(Response_Value.deliverTx));
      });

      test('should create Response with endBlock', () {
        final endBlock = ResponseEndBlock();
        final response = Response(endBlock: endBlock);
        
        expect(response.hasEndBlock(), isTrue);
        expect(response.whichValue(), equals(Response_Value.endBlock));
      });

      test('should create Response with commit', () {
        final commit = ResponseCommit()
          ..data = Uint8List.fromList([0x90, 0x91, 0x92])
          ..retainHeight = Int64(500);
        final response = Response(commit: commit);
        
        expect(response.hasCommit(), isTrue);
        expect(response.commit.retainHeight, equals(Int64(500)));
        expect(response.whichValue(), equals(Response_Value.commit));
      });

      test('should create Response with listSnapshots', () {
        final listSnapshots = ResponseListSnapshots();
        final response = Response(listSnapshots: listSnapshots);
        
        expect(response.hasListSnapshots(), isTrue);
        expect(response.whichValue(), equals(Response_Value.listSnapshots));
      });

      test('should create Response with offerSnapshot', () {
        final offerSnapshot = ResponseOfferSnapshot()
          ..result = ResponseOfferSnapshot_Result.ACCEPT;
        final response = Response(offerSnapshot: offerSnapshot);
        
        expect(response.hasOfferSnapshot(), isTrue);
        expect(response.offerSnapshot.result, equals(ResponseOfferSnapshot_Result.ACCEPT));
        expect(response.whichValue(), equals(Response_Value.offerSnapshot));
      });

      test('should create Response with loadSnapshotChunk', () {
        final loadSnapshotChunk = ResponseLoadSnapshotChunk()
          ..chunk = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
        final response = Response(loadSnapshotChunk: loadSnapshotChunk);
        
        expect(response.hasLoadSnapshotChunk(), isTrue);
        expect(response.loadSnapshotChunk.chunk.length, equals(4));
        expect(response.whichValue(), equals(Response_Value.loadSnapshotChunk));
      });

      test('should create Response with applySnapshotChunk', () {
        final applySnapshotChunk = ResponseApplySnapshotChunk()
          ..result = ResponseApplySnapshotChunk_Result.ACCEPT;
        final response = Response(applySnapshotChunk: applySnapshotChunk);
        
        expect(response.hasApplySnapshotChunk(), isTrue);
        expect(response.applySnapshotChunk.result, equals(ResponseApplySnapshotChunk_Result.ACCEPT));
        expect(response.whichValue(), equals(Response_Value.applySnapshotChunk));
      });
    });

    group('BuilderInfo Access Tests', () {
      test('should access Request BuilderInfo', () {
        final request = Request();
        final builderInfo = request.info_;
        expect(builderInfo, isNotNull);
        expect(builderInfo.qualifiedMessageName, contains('Request'));
      });

      test('should access Response BuilderInfo', () {
        final response = Response();
        final builderInfo = response.info_;
        expect(builderInfo, isNotNull);
        expect(builderInfo.qualifiedMessageName, contains('Response'));
      });

      test('should access Event BuilderInfo', () {
        final event = Event();
        final builderInfo = event.info_;
        expect(builderInfo, isNotNull);
        expect(builderInfo.qualifiedMessageName, contains('Event'));
      });
    });

    group('Factory Methods Coverage', () {
      test('should create default instances', () {
        expect(Request.getDefault(), isA<Request>());
        expect(Response.getDefault(), isA<Response>());
        expect(Event.getDefault(), isA<Event>());
        expect(Validator.getDefault(), isA<Validator>());
        expect(ValidatorUpdate.getDefault(), isA<ValidatorUpdate>());
      });

      test('should create repeated lists', () {
        final requests = Request.createRepeated();
        final responses = Response.createRepeated();
        final events = Event.createRepeated();
        
        expect(requests, isA<List<Request>>());
        expect(responses, isA<List<Response>>());
        expect(events, isA<List<Event>>());
      });

      test('should create empty instances', () {
        final request = Request.create();
        final response = Response.create();
        final event = Event.create();
        
        expect(request, isA<Request>());
        expect(response, isA<Response>());
        expect(event, isA<Event>());
      });
    });
  });
} 