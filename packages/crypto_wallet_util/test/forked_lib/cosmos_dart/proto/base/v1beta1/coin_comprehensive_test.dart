import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';

void main() {
	group('cosmos.base.v1beta1 CosmosCoin', () {
		test('constructor with denom and amount', () {
			final coin = CosmosCoin(denom: 'stake', amount: '1000');
			
			expect(coin.denom, 'stake');
			expect(coin.amount, '1000');
		});
		
		test('constructor with empty values', () {
			final coin = CosmosCoin(denom: '', amount: '');
			
			expect(coin.denom, '');
			expect(coin.amount, '');
		});
		
		test('default constructor', () {
			final coin = CosmosCoin();
			
			expect(coin.denom, '');
			expect(coin.amount, '');
		});
		
		test('has/clear operations for denom', () {
			final coin = CosmosCoin(denom: 'atom');
			
			expect(coin.hasDenom(), isTrue);
			coin.clearDenom();
			expect(coin.hasDenom(), isFalse);
			expect(coin.denom, '');
		});
		
		test('has/clear operations for amount', () {
			final coin = CosmosCoin(amount: '500');
			
			expect(coin.hasAmount(), isTrue);
			coin.clearAmount();
			expect(coin.hasAmount(), isFalse);
			expect(coin.amount, '');
		});
		
		test('setting and getting values', () {
			final coin = CosmosCoin();
			
			coin.denom = 'osmo';
			coin.amount = '2500';
			
			expect(coin.denom, 'osmo');
			expect(coin.amount, '2500');
		});
		
		test('clone operation', () {
			final original = CosmosCoin(denom: 'stake', amount: '1000');
			
			final cloned = original.clone();
			expect(cloned.denom, 'stake');
			expect(cloned.amount, '1000');
			
			// Verify independence
			cloned.denom = 'atom';
			cloned.amount = '500';
			
			expect(cloned.denom, 'atom');
			expect(cloned.amount, '500');
			expect(original.denom, 'stake');
			expect(original.amount, '1000');
		});
		
		test('copyWith operation', () {
			final original = CosmosCoin(denom: 'stake', amount: '1000');
			
			final copied = original.copyWith((coin) {
				coin.denom = 'atom';
				coin.amount = '2000';
			});
			
			expect(copied.denom, 'atom');
			expect(copied.amount, '2000');
			expect(original.denom, 'stake'); // original unchanged
			expect(original.amount, '1000');
		});
		
		test('JSON serialization and deserialization', () {
			final coin = CosmosCoin(denom: 'stake', amount: '1000');
			
			final json = jsonEncode(coin.writeToJsonMap());
			final fromJson = CosmosCoin.fromJson(json);
			
			expect(fromJson.denom, 'stake');
			expect(fromJson.amount, '1000');
		});
		
		test('binary serialization and deserialization', () {
			final coin = CosmosCoin(denom: 'atom', amount: '500');
			
			final buffer = coin.writeToBuffer();
			final fromBuffer = CosmosCoin.fromBuffer(buffer);
			
			expect(fromBuffer.denom, 'atom');
			expect(fromBuffer.amount, '500');
		});
		
		test('getDefault returns same instance', () {
			final default1 = CosmosCoin.getDefault();
			final default2 = CosmosCoin.getDefault();
			expect(identical(default1, default2), isTrue);
		});
		
		test('createEmptyInstance creates new instance', () {
			final coin = CosmosCoin();
			final empty = coin.createEmptyInstance();
			expect(empty.denom, '');
			expect(empty.amount, '');
			expect(identical(coin, empty), isFalse);
		});
		
		test('createRepeated creates PbList', () {
			final list = CosmosCoin.createRepeated();
			expect(list, isA<pb.PbList<CosmosCoin>>());
			expect(list, isEmpty);
			
			list.add(CosmosCoin(denom: 'stake', amount: '1000'));
			expect(list.length, 1);
		});
		
		test('info_ returns BuilderInfo', () {
			final coin = CosmosCoin();
			final info = coin.info_;
			expect(info, isA<pb.BuilderInfo>());
			expect(info.qualifiedMessageName, contains('Coin'));
		});
		
		test('large amounts', () {
			final coin = CosmosCoin(
				denom: 'stake',
				amount: '999999999999999999999999999999'
			);
			
			expect(coin.amount, '999999999999999999999999999999');
			
			final json = jsonEncode(coin.writeToJsonMap());
			final fromJson = CosmosCoin.fromJson(json);
			expect(fromJson.amount, '999999999999999999999999999999');
		});
		
		test('zero amount', () {
			final coin = CosmosCoin(denom: 'stake', amount: '0');
			
			expect(coin.amount, '0');
			expect(coin.hasAmount(), isTrue);
		});
		
		test('negative amount string', () {
			final coin = CosmosCoin(denom: 'stake', amount: '-100');
			
			expect(coin.amount, '-100');
		});
		
		test('decimal amount string', () {
			final coin = CosmosCoin(denom: 'stake', amount: '123.456789');
			
			expect(coin.amount, '123.456789');
		});
		
		test('special characters in denom', () {
			final coin = CosmosCoin(denom: 'ibc/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2', amount: '1000');
			
			expect(coin.denom, 'ibc/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2');
			
			final buffer = coin.writeToBuffer();
			final fromBuffer = CosmosCoin.fromBuffer(buffer);
			expect(fromBuffer.denom, 'ibc/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2');
		});
	});
	
	group('cosmos.base.v1beta1 DecCoin', () {
		test('constructor with denom and amount', () {
			final coin = DecCoin(denom: 'stake', amount: '1000.123456789');
			
			expect(coin.denom, 'stake');
			expect(coin.amount, '1000.123456789');
		});
		
		test('has/clear operations', () {
			final coin = DecCoin(denom: 'atom', amount: '500.5');
			
			expect(coin.hasDenom(), isTrue);
			expect(coin.hasAmount(), isTrue);
			
			coin.clearDenom();
			coin.clearAmount();
			
			expect(coin.hasDenom(), isFalse);
			expect(coin.hasAmount(), isFalse);
		});
		
		test('clone and copyWith operations', () {
			final original = DecCoin(denom: 'stake', amount: '1000.5');
			
			final cloned = original.clone();
			expect(cloned.denom, 'stake');
			expect(cloned.amount, '1000.5');
			
			final copied = original.copyWith((coin) {
				coin.amount = '2000.75';
			});
			expect(copied.amount, '2000.75');
			expect(original.amount, '1000.5'); // original unchanged
		});
		
		test('JSON and buffer serialization', () {
			final coin = DecCoin(denom: 'atom', amount: '123.456789012345678901');
			
			final json = jsonEncode(coin.writeToJsonMap());
			final fromJson = DecCoin.fromJson(json);
			expect(fromJson.denom, 'atom');
			expect(fromJson.amount, '123.456789012345678901');
			
			final buffer = coin.writeToBuffer();
			final fromBuffer = DecCoin.fromBuffer(buffer);
			expect(fromBuffer.denom, 'atom');
			expect(fromBuffer.amount, '123.456789012345678901');
		});
		
		test('getDefault and createRepeated', () {
			expect(identical(DecCoin.getDefault(), DecCoin.getDefault()), isTrue);
			
			final list = DecCoin.createRepeated();
			expect(list, isA<pb.PbList<DecCoin>>());
		});
		
		test('very precise decimal amounts', () {
			final coin = DecCoin(
				denom: 'precise',
				amount: '0.000000000000000001'
			);
			
			expect(coin.amount, '0.000000000000000001');
			
			final buffer = coin.writeToBuffer();
			final fromBuffer = DecCoin.fromBuffer(buffer);
			expect(fromBuffer.amount, '0.000000000000000001');
		});
	});
	
	group('cosmos.base.v1beta1 IntProto', () {
		test('constructor with int value', () {
			final intProto = IntProto(int_1: '123456789');
			
			expect(intProto.int_1, '123456789');
		});
		
		test('has/clear operations', () {
			final intProto = IntProto(int_1: '999');
			
			expect(intProto.hasInt_1(), isTrue);
			intProto.clearInt_1();
			expect(intProto.hasInt_1(), isFalse);
			expect(intProto.int_1, '');
		});
		
		test('setting and getting values', () {
			final intProto = IntProto();
			
			intProto.int_1 = '42';
			expect(intProto.int_1, '42');
		});
		
		test('clone and copyWith operations', () {
			final original = IntProto(int_1: '123');
			
			final cloned = original.clone();
			expect(cloned.int_1, '123');
			
			final copied = original.copyWith((proto) {
				proto.int_1 = '456';
			});
			expect(copied.int_1, '456');
			expect(original.int_1, '123'); // original unchanged
		});
		
		test('JSON and buffer serialization', () {
			final intProto = IntProto(int_1: '987654321');
			
			final json = jsonEncode(intProto.writeToJsonMap());
			final fromJson = IntProto.fromJson(json);
			expect(fromJson.int_1, '987654321');
			
			final buffer = intProto.writeToBuffer();
			final fromBuffer = IntProto.fromBuffer(buffer);
			expect(fromBuffer.int_1, '987654321');
		});
		
		test('getDefault and createRepeated', () {
			expect(identical(IntProto.getDefault(), IntProto.getDefault()), isTrue);
			
			final list = IntProto.createRepeated();
			expect(list, isA<pb.PbList<IntProto>>());
		});
		
		test('large integer values', () {
			final intProto = IntProto(int_1: '999999999999999999999999999999');
			
			expect(intProto.int_1, '999999999999999999999999999999');
			
			final buffer = intProto.writeToBuffer();
			final fromBuffer = IntProto.fromBuffer(buffer);
			expect(fromBuffer.int_1, '999999999999999999999999999999');
		});
		
		test('negative integer values', () {
			final intProto = IntProto(int_1: '-123456789');
			
			expect(intProto.int_1, '-123456789');
		});
		
		test('zero value', () {
			final intProto = IntProto(int_1: '0');
			
			expect(intProto.int_1, '0');
			expect(intProto.hasInt_1(), isTrue);
		});
	});
	
	group('cosmos.base.v1beta1 DecProto', () {
		test('constructor with dec value', () {
			final decProto = DecProto(dec: '123.456789');
			
			expect(decProto.dec, '123.456789');
		});
		
		test('has/clear operations', () {
			final decProto = DecProto(dec: '999.999');
			
			expect(decProto.hasDec(), isTrue);
			decProto.clearDec();
			expect(decProto.hasDec(), isFalse);
			expect(decProto.dec, '');
		});
		
		test('setting and getting values', () {
			final decProto = DecProto();
			
			decProto.dec = '3.14159';
			expect(decProto.dec, '3.14159');
		});
		
		test('clone and copyWith operations', () {
			final original = DecProto(dec: '1.23');
			
			final cloned = original.clone();
			expect(cloned.dec, '1.23');
			
			final copied = original.copyWith((proto) {
				proto.dec = '4.56';
			});
			expect(copied.dec, '4.56');
			expect(original.dec, '1.23'); // original unchanged
		});
		
		test('JSON and buffer serialization', () {
			final decProto = DecProto(dec: '987.654321');
			
			final json = jsonEncode(decProto.writeToJsonMap());
			final fromJson = DecProto.fromJson(json);
			expect(fromJson.dec, '987.654321');
			
			final buffer = decProto.writeToBuffer();
			final fromBuffer = DecProto.fromBuffer(buffer);
			expect(fromBuffer.dec, '987.654321');
		});
		
		test('getDefault and createRepeated', () {
			expect(identical(DecProto.getDefault(), DecProto.getDefault()), isTrue);
			
			final list = DecProto.createRepeated();
			expect(list, isA<pb.PbList<DecProto>>());
		});
		
		test('high precision decimal values', () {
			final decProto = DecProto(dec: '0.123456789012345678901234567890');
			
			expect(decProto.dec, '0.123456789012345678901234567890');
			
			final buffer = decProto.writeToBuffer();
			final fromBuffer = DecProto.fromBuffer(buffer);
			expect(fromBuffer.dec, '0.123456789012345678901234567890');
		});
		
		test('negative decimal values', () {
			final decProto = DecProto(dec: '-123.456');
			
			expect(decProto.dec, '-123.456');
		});
		
		test('scientific notation values', () {
			final decProto = DecProto(dec: '1.23e-10');
			
			expect(decProto.dec, '1.23e-10');
		});
	});
	
	group('cosmos.base.v1beta1 error handling', () {
		test('invalid buffer deserialization', () {
			expect(() => CosmosCoin.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => DecCoin.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => IntProto.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => DecProto.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			expect(() => CosmosCoin.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => DecCoin.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => IntProto.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => DecProto.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('cosmos.base.v1beta1 comprehensive coverage', () {
		test('all message types have proper info_', () {
			expect(CosmosCoin().info_, isA<pb.BuilderInfo>());
			expect(DecCoin().info_, isA<pb.BuilderInfo>());
			expect(IntProto().info_, isA<pb.BuilderInfo>());
			expect(DecProto().info_, isA<pb.BuilderInfo>());
		});
		
		test('all message types support createEmptyInstance', () {
			expect(CosmosCoin().createEmptyInstance(), isA<CosmosCoin>());
			expect(DecCoin().createEmptyInstance(), isA<DecCoin>());
			expect(IntProto().createEmptyInstance(), isA<IntProto>());
			expect(DecProto().createEmptyInstance(), isA<DecProto>());
		});
		
		test('roundtrip consistency for all types', () {
			final coin = CosmosCoin(denom: 'test', amount: '123');
			final decCoin = DecCoin(denom: 'test', amount: '123.456');
			final intProto = IntProto(int_1: '789');
			final decProto = DecProto(dec: '12.34');
			
			// JSON roundtrip
			expect(CosmosCoin.fromJson(jsonEncode(coin.writeToJsonMap())).denom, coin.denom);
			expect(DecCoin.fromJson(jsonEncode(decCoin.writeToJsonMap())).amount, decCoin.amount);
			expect(IntProto.fromJson(jsonEncode(intProto.writeToJsonMap())).int_1, intProto.int_1);
			expect(DecProto.fromJson(jsonEncode(decProto.writeToJsonMap())).dec, decProto.dec);
			
			// Buffer roundtrip
			expect(CosmosCoin.fromBuffer(coin.writeToBuffer()).denom, coin.denom);
			expect(DecCoin.fromBuffer(decCoin.writeToBuffer()).amount, decCoin.amount);
			expect(IntProto.fromBuffer(intProto.writeToBuffer()).int_1, intProto.int_1);
			expect(DecProto.fromBuffer(decProto.writeToBuffer()).dec, decProto.dec);
		});
	});
} 