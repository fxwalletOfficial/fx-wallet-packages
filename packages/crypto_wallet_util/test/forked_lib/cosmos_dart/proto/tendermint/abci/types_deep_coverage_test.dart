import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/abci/types.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/timestamp.pb.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  group('ABCI Types Deep Coverage Tests', () {
    group('RequestXXX Clone Methods Coverage', () {
      test('should cover RequestInitChain clone method', () {
        final original = RequestInitChain()
          ..time = (Timestamp()..seconds = Int64(1234567890))
          ..chainId = 'test-chain'
          ..initialHeight = Int64(1);
        
        final cloned = original.clone();
        
        expect(cloned.time.seconds, equals(Int64(1234567890)));
        expect(cloned.chainId, equals('test-chain'));
        expect(cloned.initialHeight, equals(Int64(1)));
        
        // Modify original to ensure they're separate
        original.chainId = 'modified-chain';
        expect(cloned.chainId, equals('test-chain')); // Should remain unchanged
      });

      test('should cover RequestQuery clone method', () {
        final original = RequestQuery()
          ..data = Uint8List.fromList([1, 2, 3])
          ..path = '/test/path'
          ..height = Int64(100)
          ..prove = true;
        
        final cloned = original.clone();
        
        expect(cloned.data, equals(Uint8List.fromList([1, 2, 3])));
        expect(cloned.path, equals('/test/path'));
        expect(cloned.height, equals(Int64(100)));
        expect(cloned.prove, equals(true));
        
        // Modify original
        original.path = '/modified/path';
        expect(cloned.path, equals('/test/path')); // Should remain unchanged
      });

      test('should cover RequestBeginBlock clone method', () {
        final original = RequestBeginBlock()
          ..hash = Uint8List.fromList([0xAA, 0xBB, 0xCC]);
        
        final cloned = original.clone();
        
        expect(cloned.hash, equals(Uint8List.fromList([0xAA, 0xBB, 0xCC])));
      });

      test('should cover RequestCheckTx clone method', () {
        final original = RequestCheckTx()
          ..tx = Uint8List.fromList([0x01, 0x02, 0x03])
          ..type = CheckTxType.NEW;
        
        final cloned = original.clone();
        
        expect(cloned.tx, equals(Uint8List.fromList([0x01, 0x02, 0x03])));
        expect(cloned.type, equals(CheckTxType.NEW));
      });

      test('should cover RequestDeliverTx clone method', () {
        final original = RequestDeliverTx()
          ..tx = Uint8List.fromList([0xFF, 0xEE, 0xDD]);
        
        final cloned = original.clone();
        
        expect(cloned.tx, equals(Uint8List.fromList([0xFF, 0xEE, 0xDD])));
      });

      test('should cover RequestEndBlock clone method', () {
        final original = RequestEndBlock()..height = Int64(456);
        
        final cloned = original.clone();
        
        expect(cloned.height, equals(Int64(456)));
      });

      test('should cover RequestSetOption clone method', () {
        final original = RequestSetOption()
          ..key = 'test-key'
          ..value = 'test-value';
        
        final cloned = original.clone();
        
        expect(cloned.key, equals('test-key'));
        expect(cloned.value, equals('test-value'));
      });
    });

    group('RequestXXX CopyWith Methods Coverage', () {
      test('should cover RequestInitChain copyWith method', () {
        final original = RequestInitChain()
          ..chainId = 'original-chain'
          ..initialHeight = Int64(1);
        
        final modified = original.copyWith((request) {
          request.chainId = 'modified-chain';
        });
        
        expect(modified.chainId, equals('modified-chain'));
        expect(modified.initialHeight, equals(Int64(1)));
      });

      test('should cover RequestQuery copyWith method', () {
        final original = RequestQuery()
          ..path = '/original/path'
          ..height = Int64(100);
        
        final modified = original.copyWith((request) {
          request.path = '/modified/path';
        });
        
        expect(modified.path, equals('/modified/path'));
        expect(modified.height, equals(Int64(100)));
      });

      test('should cover RequestBeginBlock copyWith method', () {
        final original = RequestBeginBlock()
          ..hash = Uint8List.fromList([0xAA, 0xBB]);
        
        final modified = original.copyWith((request) {
          request.hash = Uint8List.fromList([0xCC, 0xDD]);
        });
        
        expect(modified.hash, equals(Uint8List.fromList([0xCC, 0xDD])));
      });

      test('should cover RequestCheckTx copyWith method', () {
        final original = RequestCheckTx()
          ..tx = Uint8List.fromList([0x01])
          ..type = CheckTxType.NEW;
        
        final modified = original.copyWith((request) {
          request.type = CheckTxType.RECHECK;
        });
        
        expect(modified.tx, equals(Uint8List.fromList([0x01])));
        expect(modified.type, equals(CheckTxType.RECHECK));
      });

      test('should cover RequestDeliverTx copyWith method', () {
        final original = RequestDeliverTx()
          ..tx = Uint8List.fromList([0xFF]);
        
        final modified = original.copyWith((request) {
          request.tx = Uint8List.fromList([0xEE]);
        });
        
        expect(modified.tx, equals(Uint8List.fromList([0xEE])));
      });

      test('should cover RequestEndBlock copyWith method', () {
        final original = RequestEndBlock()..height = Int64(100);
        
        final modified = original.copyWith((request) {
          request.height = Int64(200);
        });
        
        expect(modified.height, equals(Int64(200)));
      });

      test('should cover RequestSetOption copyWith method', () {
        final original = RequestSetOption()
          ..key = 'original-key'
          ..value = 'original-value';
        
        final modified = original.copyWith((request) {
          request.value = 'modified-value';
        });
        
        expect(modified.key, equals('original-key'));
        expect(modified.value, equals('modified-value'));
      });
    });

    group('RequestXXX CreateRepeated Methods Coverage', () {
      test('should cover RequestInitChain createRepeated', () {
        final list = RequestInitChain.createRepeated();
        expect(list, isA<List<RequestInitChain>>());
        expect(list.isEmpty, isTrue);
        
        list.add(RequestInitChain()..chainId = 'test');
        expect(list.length, equals(1));
        expect(list.first.chainId, equals('test'));
      });

      test('should cover RequestQuery createRepeated', () {
        final list = RequestQuery.createRepeated();
        expect(list, isA<List<RequestQuery>>());
        expect(list.isEmpty, isTrue);
        
        list.add(RequestQuery()..path = '/test');
        expect(list.length, equals(1));
      });

      test('should cover RequestBeginBlock createRepeated', () {
        final list = RequestBeginBlock.createRepeated();
        expect(list, isA<List<RequestBeginBlock>>());
        expect(list.isEmpty, isTrue);
      });

      test('should cover RequestCheckTx createRepeated', () {
        final list = RequestCheckTx.createRepeated();
        expect(list, isA<List<RequestCheckTx>>());
        expect(list.isEmpty, isTrue);
      });

      test('should cover RequestDeliverTx createRepeated', () {
        final list = RequestDeliverTx.createRepeated();
        expect(list, isA<List<RequestDeliverTx>>());
        expect(list.isEmpty, isTrue);
      });

      test('should cover RequestEndBlock createRepeated', () {
        final list = RequestEndBlock.createRepeated();
        expect(list, isA<List<RequestEndBlock>>());
        expect(list.isEmpty, isTrue);
      });

      test('should cover RequestSetOption createRepeated', () {
        final list = RequestSetOption.createRepeated();
        expect(list, isA<List<RequestSetOption>>());
        expect(list.isEmpty, isTrue);
      });

      test('should cover RequestEcho createRepeated', () {
        final list = RequestEcho.createRepeated();
        expect(list, isA<List<RequestEcho>>());
        expect(list.isEmpty, isTrue);
      });

      test('should cover RequestFlush createRepeated', () {
        final list = RequestFlush.createRepeated();
        expect(list, isA<List<RequestFlush>>());
        expect(list.isEmpty, isTrue);
      });

      test('should cover RequestInfo createRepeated', () {
        final list = RequestInfo.createRepeated();
        expect(list, isA<List<RequestInfo>>());
        expect(list.isEmpty, isTrue);
      });
    });

    group('Field Has/Clear Methods Coverage', () {
      test('should cover RequestInitChain field has/clear methods', () {
        final request = RequestInitChain()
          ..chainId = 'test-chain'
          ..appStateBytes = Uint8List.fromList([0x01, 0x02])
          ..initialHeight = Int64(100);
        
        // Test hasXxx methods
        expect(request.hasChainId(), isTrue);
        expect(request.hasAppStateBytes(), isTrue);
        expect(request.hasInitialHeight(), isTrue);
        
        // Test clearXxx methods
        request.clearChainId();
        expect(request.hasChainId(), isFalse);
        expect(request.hasAppStateBytes(), isTrue); // Should remain
        
        request.clearAppStateBytes();
        expect(request.hasAppStateBytes(), isFalse);
        expect(request.hasInitialHeight(), isTrue); // Should remain
        
        request.clearInitialHeight();
        expect(request.hasInitialHeight(), isFalse);
      });

      test('should cover RequestQuery field has/clear methods', () {
        final request = RequestQuery()
          ..data = Uint8List.fromList([0x01])
          ..path = '/test'
          ..height = Int64(100)
          ..prove = true;
        
        expect(request.hasData(), isTrue);
        expect(request.hasPath(), isTrue);
        expect(request.hasHeight(), isTrue);
        expect(request.hasProve(), isTrue);
        
        request.clearData();
        request.clearPath();
        request.clearHeight();
        request.clearProve();
        
        expect(request.hasData(), isFalse);
        expect(request.hasPath(), isFalse);
        expect(request.hasHeight(), isFalse);
        expect(request.hasProve(), isFalse);
      });

      test('should cover RequestBeginBlock field has/clear methods', () {
        final request = RequestBeginBlock()
          ..hash = Uint8List.fromList([0xAA, 0xBB]);
        
        expect(request.hasHash(), isTrue);
        
        request.clearHash();
        expect(request.hasHash(), isFalse);
      });

      test('should cover RequestCheckTx field has/clear methods', () {
        final request = RequestCheckTx()
          ..tx = Uint8List.fromList([0x01])
          ..type = CheckTxType.NEW;
        
        expect(request.hasTx(), isTrue);
        expect(request.hasType(), isTrue);
        
        request.clearTx();
        request.clearType();
        
        expect(request.hasTx(), isFalse);
        expect(request.hasType(), isFalse);
      });

      test('should cover RequestSetOption field has/clear methods', () {
        final request = RequestSetOption()
          ..key = 'test'
          ..value = 'value';
        
        expect(request.hasKey(), isTrue);
        expect(request.hasValue(), isTrue);
        
        request.clearKey();
        request.clearValue();
        
        expect(request.hasKey(), isFalse);
        expect(request.hasValue(), isFalse);
      });
    });

    group('Getter Methods Default Values Coverage', () {
      test('should cover RequestInitChain getter methods for unset fields', () {
        final request = RequestInitChain();
        
        // These getters should return default values when fields are not set
        expect(() => request.time, returnsNormally);
        expect(() => request.consensusParams, returnsNormally);
        expect(() => request.appStateBytes, returnsNormally);
        expect(() => request.initialHeight, returnsNormally);
        
        // Verify default values
        expect(request.chainId, isEmpty); // String default is empty
        expect(request.initialHeight, equals(Int64.ZERO)); // Int64 default is 0
        expect(request.appStateBytes, isEmpty); // List default is empty
      });

      test('should cover RequestQuery getter methods for unset fields', () {
        final request = RequestQuery();
        
        expect(() => request.data, returnsNormally);
        expect(() => request.path, returnsNormally);
        expect(() => request.height, returnsNormally);
        expect(() => request.prove, returnsNormally);
        
        // Verify default values
        expect(request.path, isEmpty);
        expect(request.height, equals(Int64.ZERO));
        expect(request.prove, isFalse); // bool default is false
      });

      test('should cover RequestBeginBlock getter methods for unset fields', () {
        final request = RequestBeginBlock();
        
        expect(() => request.hash, returnsNormally);
        expect(() => request.header, returnsNormally);
        expect(() => request.lastCommitInfo, returnsNormally);
        expect(() => request.byzantineValidators, returnsNormally);
      });

      test('should cover RequestEndBlock getter methods for unset fields', () {
        final request = RequestEndBlock();
        
        expect(() => request.height, returnsNormally);
        expect(request.height, equals(Int64.ZERO));
      });
    });

    group('Additional RequestXXX Classes Coverage', () {
      test('should cover RequestEcho clone and copyWith', () {
        final original = RequestEcho()..message = 'original';
        
        final cloned = original.clone();
        expect(cloned.message, equals('original'));
        
        final modified = original.copyWith((request) {
          request.message = 'modified';
        });
        expect(modified.message, equals('modified'));
      });

      test('should cover RequestFlush clone and copyWith', () {
        final original = RequestFlush();
        
        final cloned = original.clone();
        expect(cloned, isA<RequestFlush>());
        
        final modified = original.copyWith((request) {
          // RequestFlush has no fields, just test the method works
        });
        expect(modified, isA<RequestFlush>());
      });

      test('should cover RequestInfo clone and copyWith', () {
        final original = RequestInfo()
          ..version = 'v1.0.0'
          ..blockVersion = Int64(1);
        
        final cloned = original.clone();
        expect(cloned.version, equals('v1.0.0'));
        expect(cloned.blockVersion, equals(Int64(1)));
        
        final modified = original.copyWith((request) {
          request.version = 'v2.0.0';
        });
        expect(modified.version, equals('v2.0.0'));
      });

      test('should cover RequestCommit clone and copyWith', () {
        final original = RequestCommit();
        
        final cloned = original.clone();
        expect(cloned, isA<RequestCommit>());
        
        final modified = original.copyWith((request) {
          // RequestCommit has no fields
        });
        expect(modified, isA<RequestCommit>());
      });
    });
  });
} 