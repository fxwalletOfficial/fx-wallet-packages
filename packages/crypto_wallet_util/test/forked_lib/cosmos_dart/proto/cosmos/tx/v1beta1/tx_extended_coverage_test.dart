import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/v1beta1/tx.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/signing/v1beta1/signing.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/crypto/multisig/v1beta1/multisig.pb.dart';

void main() {
  group('Cosmos Tx Extended Coverage Tests', () {
    group('ModeInfo_Single Missing Methods Coverage', () {
      test('should cover ModeInfo_Single fromJson method', () {
        final original = ModeInfo_Single()
          ..mode = SignMode.SIGN_MODE_DIRECT;
        
        final json = original.writeToJson();
        final fromJson = ModeInfo_Single.fromJson(json);
        
        expect(fromJson.mode, equals(SignMode.SIGN_MODE_DIRECT));
        expect(fromJson.hasMode(), isTrue);
      });

      test('should cover ModeInfo_Single clone method', () {
        final original = ModeInfo_Single()
          ..mode = SignMode.SIGN_MODE_TEXTUAL;
        
        final cloned = original.clone();
        
        expect(cloned.mode, equals(SignMode.SIGN_MODE_TEXTUAL));
        expect(cloned.hasMode(), isTrue);
        
        // Modify original to ensure separation
        original.mode = SignMode.SIGN_MODE_DIRECT;
        expect(cloned.mode, equals(SignMode.SIGN_MODE_TEXTUAL));
      });

      test('should cover ModeInfo_Single copyWith method', () {
        final original = ModeInfo_Single()
          ..mode = SignMode.SIGN_MODE_DIRECT;
        
        final modified = original.copyWith((single) {
          single.mode = SignMode.SIGN_MODE_LEGACY_AMINO_JSON;
        });
        
        expect(modified.mode, equals(SignMode.SIGN_MODE_LEGACY_AMINO_JSON));
        expect(original.mode, equals(SignMode.SIGN_MODE_DIRECT)); // Original unchanged
      });

      test('should cover ModeInfo_Single createRepeated method', () {
        final list = ModeInfo_Single.createRepeated();
        
        expect(list, isA<List<ModeInfo_Single>>());
        expect(list.isEmpty, isTrue);
        
        list.add(ModeInfo_Single()..mode = SignMode.SIGN_MODE_DIRECT);
        list.add(ModeInfo_Single()..mode = SignMode.SIGN_MODE_TEXTUAL);
        
        expect(list.length, equals(2));
        expect(list.first.mode, equals(SignMode.SIGN_MODE_DIRECT));
        expect(list.last.mode, equals(SignMode.SIGN_MODE_TEXTUAL));
      });

      test('should cover ModeInfo_Single getDefault method', () {
        final defaultInstance = ModeInfo_Single.getDefault();
        
        expect(defaultInstance, isA<ModeInfo_Single>());
        expect(defaultInstance.mode, equals(SignMode.SIGN_MODE_UNSPECIFIED));
        
        // Test that getDefault returns the same instance
        final anotherDefault = ModeInfo_Single.getDefault();
        expect(identical(defaultInstance, anotherDefault), isTrue);
      });

      test('should cover ModeInfo_Single comprehensive field testing', () {
        final single = ModeInfo_Single();
        
        // Test initially 
        expect(single.hasMode(), isFalse);
        expect(single.mode, equals(SignMode.SIGN_MODE_UNSPECIFIED));
        
        // Test setting mode
        single.mode = SignMode.SIGN_MODE_DIRECT;
        expect(single.hasMode(), isTrue);
        expect(single.mode, equals(SignMode.SIGN_MODE_DIRECT));
        
        // Test clear
        single.clearMode();
        expect(single.hasMode(), isFalse);
        expect(single.mode, equals(SignMode.SIGN_MODE_UNSPECIFIED));
      });
    });

    group('ModeInfo_Multi Missing Methods Coverage', () {
      test('should cover ModeInfo_Multi fromBuffer method', () {
        final bitArray = CompactBitArray()
          ..extraBitsStored = 3
          ..elems = Uint8List.fromList([0xFF, 0x00, 0xAA]);
        
        final original = ModeInfo_Multi()
          ..bitarray = bitArray
          ..modeInfos.add(ModeInfo()..single = (ModeInfo_Single()..mode = SignMode.SIGN_MODE_DIRECT));
        
        final buffer = original.writeToBuffer();
        final fromBuffer = ModeInfo_Multi.fromBuffer(buffer);
        
        expect(fromBuffer.hasBitarray(), isTrue);
        expect(fromBuffer.bitarray.extraBitsStored, equals(3));
        expect(fromBuffer.bitarray.elems, equals(Uint8List.fromList([0xFF, 0x00, 0xAA])));
        expect(fromBuffer.modeInfos.length, equals(1));
      });

      test('should cover ModeInfo_Multi fromJson method', () {
        final original = ModeInfo_Multi()
          ..bitarray = (CompactBitArray()..extraBitsStored = 5)
          ..modeInfos.add(ModeInfo()..single = (ModeInfo_Single()..mode = SignMode.SIGN_MODE_TEXTUAL));
        
        final json = original.writeToJson();
        final fromJson = ModeInfo_Multi.fromJson(json);
        
        expect(fromJson.hasBitarray(), isTrue);
        expect(fromJson.bitarray.extraBitsStored, equals(5));
        expect(fromJson.modeInfos.length, equals(1));
      });

      test('should cover ModeInfo_Multi clone method', () {
        final bitArray = CompactBitArray()
          ..extraBitsStored = 7
          ..elems = Uint8List.fromList([0x12, 0x34]);
        
        final original = ModeInfo_Multi()
          ..bitarray = bitArray
          ..modeInfos.add(ModeInfo()..single = (ModeInfo_Single()..mode = SignMode.SIGN_MODE_DIRECT));
        
        final cloned = original.clone();
        
        expect(cloned.hasBitarray(), isTrue);
        expect(cloned.bitarray.extraBitsStored, equals(7));
        expect(cloned.bitarray.elems, equals(Uint8List.fromList([0x12, 0x34])));
        expect(cloned.modeInfos.length, equals(1));
        
        // Modify original to ensure separation
        original.bitarray.extraBitsStored = 9;
        expect(cloned.bitarray.extraBitsStored, equals(7));
      });

      test('should cover ModeInfo_Multi copyWith method', () {
        final original = ModeInfo_Multi()
          ..bitarray = (CompactBitArray()..extraBitsStored = 2);
        
        final modified = original.copyWith((multi) {
          multi.bitarray.extraBitsStored = 4;
          multi.modeInfos.add(ModeInfo()..single = (ModeInfo_Single()..mode = SignMode.SIGN_MODE_LEGACY_AMINO_JSON));
        });
        
        expect(modified.bitarray.extraBitsStored, equals(4));
        expect(modified.modeInfos.length, equals(1));
        expect(modified.modeInfos.first.single.mode, equals(SignMode.SIGN_MODE_LEGACY_AMINO_JSON));
      });

      test('should cover ModeInfo_Multi createRepeated method', () {
        final list = ModeInfo_Multi.createRepeated();
        
        expect(list, isA<List<ModeInfo_Multi>>());
        expect(list.isEmpty, isTrue);
        
        list.add(ModeInfo_Multi()..bitarray = (CompactBitArray()..extraBitsStored = 1));
        list.add(ModeInfo_Multi()..bitarray = (CompactBitArray()..extraBitsStored = 2));
        
        expect(list.length, equals(2));
        expect(list.first.bitarray.extraBitsStored, equals(1));
        expect(list.last.bitarray.extraBitsStored, equals(2));
      });

      test('should cover ModeInfo_Multi getDefault method', () {
        final defaultInstance = ModeInfo_Multi.getDefault();
        
        expect(defaultInstance, isA<ModeInfo_Multi>());
        expect(defaultInstance.hasBitarray(), isFalse);
        expect(defaultInstance.modeInfos, isEmpty);
        
        // Test that getDefault returns the same instance
        final anotherDefault = ModeInfo_Multi.getDefault();
        expect(identical(defaultInstance, anotherDefault), isTrue);
      });

      test('should cover ModeInfo_Multi bitarray getter and comprehensive field testing', () {
        final multi = ModeInfo_Multi();
        
        // Test initially empty
        expect(multi.hasBitarray(), isFalse);
        expect(multi.modeInfos, isEmpty);
        
        // Test bitarray getter - this line was not covered before
        final defaultBitArray = multi.bitarray; // This triggers the getter
        expect(defaultBitArray, isA<CompactBitArray>());
        
        // Test setting bitarray
        final customBitArray = CompactBitArray()
          ..extraBitsStored = 8
          ..elems = Uint8List.fromList([0xFF, 0xEE, 0xDD]);
        multi.bitarray = customBitArray;
        
        expect(multi.hasBitarray(), isTrue);
        expect(multi.bitarray.extraBitsStored, equals(8));
        expect(multi.bitarray.elems, equals(Uint8List.fromList([0xFF, 0xEE, 0xDD])));
        
        // Test modeInfos
        multi.modeInfos.add(ModeInfo()..single = (ModeInfo_Single()..mode = SignMode.SIGN_MODE_DIRECT));
        multi.modeInfos.add(ModeInfo()..single = (ModeInfo_Single()..mode = SignMode.SIGN_MODE_TEXTUAL));
        
        expect(multi.modeInfos.length, equals(2));
        expect(multi.modeInfos.first.single.mode, equals(SignMode.SIGN_MODE_DIRECT));
        expect(multi.modeInfos.last.single.mode, equals(SignMode.SIGN_MODE_TEXTUAL));
        
        // Test clear and ensure
        multi.clearBitarray();
        expect(multi.hasBitarray(), isFalse);
        
        final ensuredBitArray = multi.ensureBitarray();
        expect(ensuredBitArray, isA<CompactBitArray>());
        expect(multi.hasBitarray(), isTrue);
      });
    });

    group('ModeInfo Missing Methods Coverage', () {
      test('should cover ModeInfo clone method', () {
        final original = ModeInfo()
          ..single = (ModeInfo_Single()..mode = SignMode.SIGN_MODE_DIRECT);
        
        final cloned = original.clone();
        
        expect(cloned.hasSingle(), isTrue);
        expect(cloned.single.mode, equals(SignMode.SIGN_MODE_DIRECT));
        expect(cloned.whichSum(), equals(ModeInfo_Sum.single));
        
        // Modify original to ensure separation
        original.single.mode = SignMode.SIGN_MODE_TEXTUAL;
        expect(cloned.single.mode, equals(SignMode.SIGN_MODE_DIRECT));
      });

      test('should cover ModeInfo copyWith method', () {
        final original = ModeInfo()
          ..single = (ModeInfo_Single()..mode = SignMode.SIGN_MODE_DIRECT);
        
        final modified = original.copyWith((modeInfo) {
          modeInfo.clearSum();
          modeInfo.multi = ModeInfo_Multi()
            ..bitarray = (CompactBitArray()..extraBitsStored = 3);
        });
        
        expect(modified.hasMulti(), isTrue);
        expect(modified.multi.bitarray.extraBitsStored, equals(3));
        expect(modified.whichSum(), equals(ModeInfo_Sum.multi));
      });

      test('should cover ModeInfo createRepeated method', () {
        final list = ModeInfo.createRepeated();
        
        expect(list, isA<List<ModeInfo>>());
        expect(list.isEmpty, isTrue);
        
        list.add(ModeInfo()..single = (ModeInfo_Single()..mode = SignMode.SIGN_MODE_DIRECT));
        list.add(ModeInfo()..multi = (ModeInfo_Multi()..bitarray = (CompactBitArray()..extraBitsStored = 2)));
        
        expect(list.length, equals(2));
        expect(list.first.whichSum(), equals(ModeInfo_Sum.single));
        expect(list.last.whichSum(), equals(ModeInfo_Sum.multi));
      });

      test('should cover ModeInfo getDefault method', () {
        final defaultInstance = ModeInfo.getDefault();
        
        expect(defaultInstance, isA<ModeInfo>());
        expect(defaultInstance.whichSum(), equals(ModeInfo_Sum.notSet));
        
        // Test that getDefault returns the same instance
        final anotherDefault = ModeInfo.getDefault();
        expect(identical(defaultInstance, anotherDefault), isTrue);
      });

      test('should cover ModeInfo oneof field operations', () {
        final modeInfo = ModeInfo();
        
        // Test initially not set
        expect(modeInfo.whichSum(), equals(ModeInfo_Sum.notSet));
        expect(modeInfo.hasSingle(), isFalse);
        expect(modeInfo.hasMulti(), isFalse);
        
        // Test setting single
        modeInfo.single = ModeInfo_Single()..mode = SignMode.SIGN_MODE_DIRECT;
        expect(modeInfo.whichSum(), equals(ModeInfo_Sum.single));
        expect(modeInfo.hasSingle(), isTrue);
        expect(modeInfo.hasMulti(), isFalse);
        
        // Test switching to multi
        modeInfo.multi = ModeInfo_Multi()..bitarray = (CompactBitArray()..extraBitsStored = 5);
        expect(modeInfo.whichSum(), equals(ModeInfo_Sum.multi));
        expect(modeInfo.hasSingle(), isFalse);
        expect(modeInfo.hasMulti(), isTrue);
        
        // Test clearing
        modeInfo.clearSum();
        expect(modeInfo.whichSum(), equals(ModeInfo_Sum.notSet));
        expect(modeInfo.hasSingle(), isFalse);
        expect(modeInfo.hasMulti(), isFalse);
        
        // Test ensure methods
        final ensuredSingle = modeInfo.ensureSingle();
        expect(ensuredSingle, isA<ModeInfo_Single>());
        expect(modeInfo.hasSingle(), isTrue);
        expect(modeInfo.whichSum(), equals(ModeInfo_Sum.single));
        
        final ensuredMulti = modeInfo.ensureMulti();
        expect(ensuredMulti, isA<ModeInfo_Multi>());
        expect(modeInfo.hasMulti(), isTrue);
        expect(modeInfo.whichSum(), equals(ModeInfo_Sum.multi));
      });
    });

    group('Fee Missing Methods Coverage', () {
      test('should cover Fee clone method', () {
        final coin = CosmosCoin()
          ..denom = 'uatom'
          ..amount = '1000';
        
        final original = Fee()
          ..amount.add(coin)
          ..gasLimit = Int64(200000)
          ..payer = 'cosmos1abc123'
          ..granter = 'cosmos1def456';
        
        final cloned = original.clone();
        
        expect(cloned.amount.length, equals(1));
        expect(cloned.amount.first.denom, equals('uatom'));
        expect(cloned.amount.first.amount, equals('1000'));
        expect(cloned.gasLimit, equals(Int64(200000)));
        expect(cloned.payer, equals('cosmos1abc123'));
        expect(cloned.granter, equals('cosmos1def456'));
        
        // Modify original to ensure separation
        original.gasLimit = Int64(300000);
        expect(cloned.gasLimit, equals(Int64(200000)));
      });

      test('should cover Fee copyWith method', () {
        final original = Fee()
          ..gasLimit = Int64(100000)
          ..payer = 'original_payer';
        
        final modified = original.copyWith((fee) {
          fee.gasLimit = Int64(500000);
          fee.payer = 'modified_payer';
          fee.granter = 'new_granter';
          
          final newCoin = CosmosCoin()
            ..denom = 'stake'
            ..amount = '2000';
          fee.amount.add(newCoin);
        });
        
        expect(modified.gasLimit, equals(Int64(500000)));
        expect(modified.payer, equals('modified_payer'));
        expect(modified.granter, equals('new_granter'));
        expect(modified.amount.length, equals(1));
        expect(modified.amount.first.denom, equals('stake'));
        expect(modified.amount.first.amount, equals('2000'));
      });

      test('should cover Fee createRepeated method', () {
        final list = Fee.createRepeated();
        
        expect(list, isA<List<Fee>>());
        expect(list.isEmpty, isTrue);
        
        list.add(Fee()..gasLimit = Int64(100000));
        list.add(Fee()..gasLimit = Int64(200000));
        
        expect(list.length, equals(2));
        expect(list.first.gasLimit, equals(Int64(100000)));
        expect(list.last.gasLimit, equals(Int64(200000)));
      });

      test('should cover Fee getDefault method', () {
        final defaultInstance = Fee.getDefault();
        
        expect(defaultInstance, isA<Fee>());
        expect(defaultInstance.amount, isEmpty);
        expect(defaultInstance.gasLimit, equals(Int64.ZERO));
        expect(defaultInstance.payer, isEmpty);
        expect(defaultInstance.granter, isEmpty);
        
        // Test that getDefault returns the same instance
        final anotherDefault = Fee.getDefault();
        expect(identical(defaultInstance, anotherDefault), isTrue);
      });

      test('should cover Fee comprehensive field testing', () {
        final fee = Fee();
        
        // Test initially empty
        expect(fee.amount, isEmpty);
        expect(fee.gasLimit, equals(Int64.ZERO));
        expect(fee.payer, isEmpty);
        expect(fee.granter, isEmpty);
        expect(fee.hasGasLimit(), isFalse);
        expect(fee.hasPayer(), isFalse);
        expect(fee.hasGranter(), isFalse);
        
        // Test setting fields
        final coin1 = CosmosCoin()..denom = 'uatom'..amount = '1000';
        final coin2 = CosmosCoin()..denom = 'stake'..amount = '2000';
        fee.amount.addAll([coin1, coin2]);
        fee.gasLimit = Int64(250000);
        fee.payer = 'cosmos1test123';
        fee.granter = 'cosmos1grant456';
        
        expect(fee.amount.length, equals(2));
        expect(fee.amount.first.denom, equals('uatom'));
        expect(fee.amount.last.denom, equals('stake'));
        expect(fee.hasGasLimit(), isTrue);
        expect(fee.gasLimit, equals(Int64(250000)));
        expect(fee.hasPayer(), isTrue);
        expect(fee.payer, equals('cosmos1test123'));
        expect(fee.hasGranter(), isTrue);
        expect(fee.granter, equals('cosmos1grant456'));
        
        // Test clear methods
        fee.clearGasLimit();
        fee.clearPayer();
        fee.clearGranter();
        
        expect(fee.hasGasLimit(), isFalse);
        expect(fee.gasLimit, equals(Int64.ZERO));
        expect(fee.hasPayer(), isFalse);
        expect(fee.payer, isEmpty);
        expect(fee.hasGranter(), isFalse);
        expect(fee.granter, isEmpty);
      });
    });

    group('Additional Coverage and Edge Cases', () {
      test('should cover serialization for all missing methods', () {
        // Test ModeInfo_Single serialization
        final single = ModeInfo_Single()..mode = SignMode.SIGN_MODE_TEXTUAL;
        final singleBuffer = single.writeToBuffer();
        final singleFromBuffer = ModeInfo_Single.fromBuffer(singleBuffer);
        expect(singleFromBuffer.mode, equals(SignMode.SIGN_MODE_TEXTUAL));
        
        // Test complex ModeInfo_Multi serialization
        final multi = ModeInfo_Multi()
          ..bitarray = (CompactBitArray()
            ..extraBitsStored = 4
            ..elems = Uint8List.fromList([0xAB, 0xCD]))
          ..modeInfos.add(ModeInfo()..single = (ModeInfo_Single()..mode = SignMode.SIGN_MODE_DIRECT));
        
        final multiJson = multi.writeToJson();
        final multiFromJson = ModeInfo_Multi.fromJson(multiJson);
        expect(multiFromJson.bitarray.extraBitsStored, equals(4));
        expect(multiFromJson.modeInfos.length, equals(1));
      });

      test('should cover complex oneof scenarios in ModeInfo', () {
        final modeInfo = ModeInfo();
        
        // Test rapid switching between single and multi
        modeInfo.single = ModeInfo_Single()..mode = SignMode.SIGN_MODE_DIRECT;
        expect(modeInfo.whichSum(), equals(ModeInfo_Sum.single));
        
        modeInfo.multi = ModeInfo_Multi()..bitarray = (CompactBitArray()..extraBitsStored = 1);
        expect(modeInfo.whichSum(), equals(ModeInfo_Sum.multi));
        expect(modeInfo.hasSingle(), isFalse); // Should be cleared when multi is set
        
        // Test clearing the current field
        modeInfo.clearMulti();
        expect(modeInfo.whichSum(), equals(ModeInfo_Sum.notSet));
        expect(modeInfo.hasMulti(), isFalse);
        
        // Test that clearing a non-active oneof field doesn't change the state
        modeInfo.single = ModeInfo_Single()..mode = SignMode.SIGN_MODE_DIRECT;
        expect(modeInfo.whichSum(), equals(ModeInfo_Sum.single));
        
        // Test clearSum method
        modeInfo.clearSum();
        expect(modeInfo.whichSum(), equals(ModeInfo_Sum.notSet));
      });

      test('should cover edge cases for Fee with empty and max values', () {
        final fee = Fee();
        
        // Test with no coins
        expect(fee.amount, isEmpty);
        
        // Test with maximum gas limit
        fee.gasLimit = Int64.MAX_VALUE;
        expect(fee.gasLimit, equals(Int64.MAX_VALUE));
        
        // Test with very long strings
        final longString = 'a' * 1000;
        fee.payer = longString;
        fee.granter = longString;
        expect(fee.payer.length, equals(1000));
        expect(fee.granter.length, equals(1000));
        
        // Test cloning with these extreme values
        final clonedFee = fee.clone();
        expect(clonedFee.gasLimit, equals(Int64.MAX_VALUE));
        expect(clonedFee.payer.length, equals(1000));
      });
    });
  });
} 