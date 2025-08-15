import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/v1beta1/tx.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/any.pb.dart';

void main() {
  group('Cosmos Tx Coverage Tests', () {
    group('TxRaw Missing Methods Coverage', () {
      test('should cover TxRaw copyWith method', () {
        final original = TxRaw()
          ..bodyBytes = Uint8List.fromList([0x01, 0x02, 0x03])
          ..authInfoBytes = Uint8List.fromList([0x04, 0x05, 0x06])
          ..signatures.addAll([
            Uint8List.fromList([0x10, 0x11]),
            Uint8List.fromList([0x12, 0x13])
          ]);
        
        final modified = original.copyWith((txRaw) {
          txRaw.bodyBytes = Uint8List.fromList([0x07, 0x08, 0x09]);
          txRaw.authInfoBytes = Uint8List.fromList([0x0A, 0x0B, 0x0C]);
          txRaw.signatures.clear();
          txRaw.signatures.add(Uint8List.fromList([0x20, 0x21]));
        });
        
        expect(modified.bodyBytes, equals(Uint8List.fromList([0x07, 0x08, 0x09])));
        expect(modified.authInfoBytes, equals(Uint8List.fromList([0x0A, 0x0B, 0x0C])));
        expect(modified.signatures.length, equals(1));
        expect(modified.signatures.first, equals(Uint8List.fromList([0x20, 0x21])));
      });

      test('should cover TxRaw createRepeated method', () {
        final list = TxRaw.createRepeated();
        
        expect(list, isA<List<TxRaw>>());
        expect(list.isEmpty, isTrue);
        
        // Test adding to the list
        list.add(TxRaw()..bodyBytes = Uint8List.fromList([0x01]));
        list.add(TxRaw()..bodyBytes = Uint8List.fromList([0x02]));
        
        expect(list.length, equals(2));
        expect(list.first.bodyBytes, equals(Uint8List.fromList([0x01])));
        expect(list.last.bodyBytes, equals(Uint8List.fromList([0x02])));
      });

      test('should cover TxRaw getDefault method', () {
        final defaultInstance = TxRaw.getDefault();
        
        expect(defaultInstance, isA<TxRaw>());
        expect(defaultInstance.bodyBytes, isEmpty);
        expect(defaultInstance.authInfoBytes, isEmpty);
        expect(defaultInstance.signatures, isEmpty);
        
        // Test that getDefault returns the same instance
        final anotherDefault = TxRaw.getDefault();
        expect(identical(defaultInstance, anotherDefault), isTrue);
      });

      test('should cover TxRaw comprehensive field testing', () {
        final txRaw = TxRaw();
        
        // Test initially empty
        expect(txRaw.bodyBytes, isEmpty);
        expect(txRaw.authInfoBytes, isEmpty);
        expect(txRaw.signatures, isEmpty);
        expect(txRaw.hasBodyBytes(), isFalse);
        expect(txRaw.hasAuthInfoBytes(), isFalse);
        
        // Test setting fields
        txRaw.bodyBytes = Uint8List.fromList([0xAA, 0xBB, 0xCC]);
        txRaw.authInfoBytes = Uint8List.fromList([0xDD, 0xEE, 0xFF]);
        txRaw.signatures.addAll([
          Uint8List.fromList([0x11, 0x22]),
          Uint8List.fromList([0x33, 0x44])
        ]);
        
        expect(txRaw.hasBodyBytes(), isTrue);
        expect(txRaw.hasAuthInfoBytes(), isTrue);
        expect(txRaw.bodyBytes, equals(Uint8List.fromList([0xAA, 0xBB, 0xCC])));
        expect(txRaw.authInfoBytes, equals(Uint8List.fromList([0xDD, 0xEE, 0xFF])));
        expect(txRaw.signatures.length, equals(2));
        
        // Test clear methods
        txRaw.clearBodyBytes();
        txRaw.clearAuthInfoBytes();
        
        expect(txRaw.hasBodyBytes(), isFalse);
        expect(txRaw.hasAuthInfoBytes(), isFalse);
        expect(txRaw.bodyBytes, isEmpty);
        expect(txRaw.authInfoBytes, isEmpty);
      });

      test('should cover TxRaw serialization methods', () {
        final original = TxRaw()
          ..bodyBytes = Uint8List.fromList([0x01, 0x02, 0x03])
          ..authInfoBytes = Uint8List.fromList([0x04, 0x05, 0x06])
          ..signatures.add(Uint8List.fromList([0x10, 0x11, 0x12]));
        
        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = TxRaw.fromBuffer(buffer);
        expect(fromBuffer.bodyBytes, equals(Uint8List.fromList([0x01, 0x02, 0x03])));
        expect(fromBuffer.authInfoBytes, equals(Uint8List.fromList([0x04, 0x05, 0x06])));
        expect(fromBuffer.signatures.first, equals(Uint8List.fromList([0x10, 0x11, 0x12])));
        
        // Test fromJson
        final json = original.writeToJson();
        final fromJson = TxRaw.fromJson(json);
        expect(fromJson.bodyBytes, equals(Uint8List.fromList([0x01, 0x02, 0x03])));
        expect(fromJson.authInfoBytes, equals(Uint8List.fromList([0x04, 0x05, 0x06])));
      });
    });

    group('TxBody Missing Methods Coverage', () {
      test('should cover TxBody copyWith method', () {
        final originalMessage = Any()
          ..typeUrl = '/cosmos.bank.v1beta1.MsgSend'
          ..value = Uint8List.fromList([0x01, 0x02]);
        
        final original = TxBody()
          ..messages.add(originalMessage)
          ..memo = 'original memo'
          ..timeoutHeight = Int64(100);
        
        final modified = original.copyWith((txBody) {
          txBody.memo = 'modified memo';
          txBody.timeoutHeight = Int64(200);
          
          final newMessage = Any()
            ..typeUrl = '/cosmos.bank.v1beta1.MsgMultiSend'
            ..value = Uint8List.fromList([0x03, 0x04]);
          txBody.messages.clear();
          txBody.messages.add(newMessage);
        });
        
        expect(modified.memo, equals('modified memo'));
        expect(modified.timeoutHeight, equals(Int64(200)));
        expect(modified.messages.length, equals(1));
        expect(modified.messages.first.typeUrl, equals('/cosmos.bank.v1beta1.MsgMultiSend'));
        expect(modified.messages.first.value, equals(Uint8List.fromList([0x03, 0x04])));
      });

      test('should cover TxBody createRepeated method', () {
        final list = TxBody.createRepeated();
        
        expect(list, isA<List<TxBody>>());
        expect(list.isEmpty, isTrue);
        
        // Test adding to the list
        list.add(TxBody()..memo = 'first');
        list.add(TxBody()..memo = 'second');
        
        expect(list.length, equals(2));
        expect(list.first.memo, equals('first'));
        expect(list.last.memo, equals('second'));
      });

      test('should cover TxBody getDefault method', () {
        final defaultInstance = TxBody.getDefault();
        
        expect(defaultInstance, isA<TxBody>());
        expect(defaultInstance.messages, isEmpty);
        expect(defaultInstance.memo, isEmpty);
        expect(defaultInstance.timeoutHeight, equals(Int64.ZERO));
        expect(defaultInstance.extensionOptions, isEmpty);
        expect(defaultInstance.nonCriticalExtensionOptions, isEmpty);
        
        // Test that getDefault returns the same instance
        final anotherDefault = TxBody.getDefault();
        expect(identical(defaultInstance, anotherDefault), isTrue);
      });

      test('should cover TxBody comprehensive field testing', () {
        final txBody = TxBody();
        
        // Test initially empty
        expect(txBody.messages, isEmpty);
        expect(txBody.memo, isEmpty);
        expect(txBody.timeoutHeight, equals(Int64.ZERO));
        expect(txBody.extensionOptions, isEmpty);
        expect(txBody.nonCriticalExtensionOptions, isEmpty);
        expect(txBody.hasMemo(), isFalse);
        expect(txBody.hasTimeoutHeight(), isFalse);
        
        // Test setting fields
        final message = Any()
          ..typeUrl = '/cosmos.staking.v1beta1.MsgDelegate'
          ..value = Uint8List.fromList([0xAA, 0xBB]);
        txBody.messages.add(message);
        txBody.memo = 'test transaction memo';
        txBody.timeoutHeight = Int64(12345);
        
        expect(txBody.messages.length, equals(1));
        expect(txBody.messages.first.typeUrl, equals('/cosmos.staking.v1beta1.MsgDelegate'));
        expect(txBody.hasMemo(), isTrue);
        expect(txBody.memo, equals('test transaction memo'));
        expect(txBody.hasTimeoutHeight(), isTrue);
        expect(txBody.timeoutHeight, equals(Int64(12345)));
        
        // Test extension options
        final extensionOption = Any()
          ..typeUrl = '/cosmos.tx.v1beta1.TxExtension'
          ..value = Uint8List.fromList([0x01, 0x02]);
        txBody.extensionOptions.add(extensionOption);
        
        final nonCriticalOption = Any()
          ..typeUrl = '/cosmos.tx.v1beta1.NonCriticalExtension'
          ..value = Uint8List.fromList([0x03, 0x04]);
        txBody.nonCriticalExtensionOptions.add(nonCriticalOption);
        
        expect(txBody.extensionOptions.length, equals(1));
        expect(txBody.extensionOptions.first.typeUrl, equals('/cosmos.tx.v1beta1.TxExtension'));
        expect(txBody.nonCriticalExtensionOptions.length, equals(1));
        expect(txBody.nonCriticalExtensionOptions.first.typeUrl, equals('/cosmos.tx.v1beta1.NonCriticalExtension'));
        
        // Test clear methods
        txBody.clearMemo();
        txBody.clearTimeoutHeight();
        
        expect(txBody.hasMemo(), isFalse);
        expect(txBody.memo, isEmpty);
        expect(txBody.hasTimeoutHeight(), isFalse);
        expect(txBody.timeoutHeight, equals(Int64.ZERO));
      });

      test('should cover TxBody serialization methods', () {
        final message = Any()
          ..typeUrl = '/cosmos.bank.v1beta1.MsgSend'
          ..value = Uint8List.fromList([0x12, 0x34, 0x56]);
        
        final original = TxBody()
          ..messages.add(message)
          ..memo = 'serialization test'
          ..timeoutHeight = Int64(999);
        
        // Test fromBuffer
        final buffer = original.writeToBuffer();
        final fromBuffer = TxBody.fromBuffer(buffer);
        expect(fromBuffer.messages.length, equals(1));
        expect(fromBuffer.messages.first.typeUrl, equals('/cosmos.bank.v1beta1.MsgSend'));
        expect(fromBuffer.messages.first.value, equals(Uint8List.fromList([0x12, 0x34, 0x56])));
        expect(fromBuffer.memo, equals('serialization test'));
        expect(fromBuffer.timeoutHeight, equals(Int64(999)));
        
        // Test fromJson
        final json = original.writeToJson();
        final fromJson = TxBody.fromJson(json);
        expect(fromJson.messages.length, equals(1));
        expect(fromJson.memo, equals('serialization test'));
        expect(fromJson.timeoutHeight, equals(Int64(999)));
      });
    });

    group('Additional Tx Classes Coverage', () {
      test('should cover SignerInfo static methods', () {
        // Test createRepeated for SignerInfo
        final signerInfoList = SignerInfo.createRepeated();
        expect(signerInfoList, isA<List<SignerInfo>>());
        expect(signerInfoList.isEmpty, isTrue);
        
        signerInfoList.add(SignerInfo());
        expect(signerInfoList.length, equals(1));
        
        // Test getDefault
        final defaultSignerInfo = SignerInfo.getDefault();
        expect(defaultSignerInfo, isA<SignerInfo>());
      });

      test('should cover AuthInfo static methods if missing', () {
        // Test createRepeated for AuthInfo
        final authInfoList = AuthInfo.createRepeated();
        expect(authInfoList, isA<List<AuthInfo>>());
        expect(authInfoList.isEmpty, isTrue);
        
        // Test getDefault
        final defaultAuthInfo = AuthInfo.getDefault();
        expect(defaultAuthInfo, isA<AuthInfo>());
        expect(defaultAuthInfo.signerInfos, isEmpty);
      });

      test('should cover clone methods for all classes', () {
        // Test TxRaw clone
        final txRaw = TxRaw()
          ..bodyBytes = Uint8List.fromList([0x01])
          ..authInfoBytes = Uint8List.fromList([0x02]);
        final clonedTxRaw = txRaw.clone();
        expect(clonedTxRaw.bodyBytes, equals(Uint8List.fromList([0x01])));
        expect(clonedTxRaw.authInfoBytes, equals(Uint8List.fromList([0x02])));
        
        // Test TxBody clone
        final txBody = TxBody()..memo = 'clone test';
        final clonedTxBody = txBody.clone();
        expect(clonedTxBody.memo, equals('clone test'));
        
        // Test Tx clone (should already be covered, but let's ensure)
        final tx = Tx()
          ..body = (TxBody()..memo = 'tx clone test');
        final clonedTx = tx.clone();
        expect(clonedTx.hasBody(), isTrue);
        expect(clonedTx.body.memo, equals('tx clone test'));
      });

      test('should cover edge cases and complex scenarios', () {
        // Test empty TxBody with extensions
        final emptyTxBody = TxBody();
        expect(emptyTxBody.extensionOptions, isEmpty);
        expect(emptyTxBody.nonCriticalExtensionOptions, isEmpty);
        
        // Test TxRaw with multiple signatures
        final txRawWithMultipleSigs = TxRaw()
          ..signatures.addAll([
            Uint8List.fromList([0x01, 0x02]),
            Uint8List.fromList([0x03, 0x04]),
            Uint8List.fromList([0x05, 0x06])
          ]);
        expect(txRawWithMultipleSigs.signatures.length, equals(3));
        
        // Test copyWith on complex structures
        final modifiedTxRaw = txRawWithMultipleSigs.copyWith((raw) {
          raw.signatures.removeAt(1); // Remove middle signature
        });
        expect(modifiedTxRaw.signatures.length, equals(2));
        expect(modifiedTxRaw.signatures.first, equals(Uint8List.fromList([0x01, 0x02])));
        expect(modifiedTxRaw.signatures.last, equals(Uint8List.fromList([0x05, 0x06])));
      });
    });
  });
} 