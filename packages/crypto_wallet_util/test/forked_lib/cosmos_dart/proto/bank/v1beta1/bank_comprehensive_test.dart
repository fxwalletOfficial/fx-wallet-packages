import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/bank.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart' as coin;

void main() {
	group('cosmos.bank.v1beta1 Params', () {
		test('constructor with sendEnabled and defaultSendEnabled', () {
			final params = Params(
				sendEnabled: [
					SendEnabled(denom: 'stake', enabled: true),
					SendEnabled(denom: 'atom', enabled: false)
				],
				defaultSendEnabled: true
			);
			
			expect(params.sendEnabled.length, 2);
			expect(params.sendEnabled.first.denom, 'stake');
			expect(params.sendEnabled.first.enabled, true);
			expect(params.sendEnabled.last.denom, 'atom');
			expect(params.sendEnabled.last.enabled, false);
			expect(params.defaultSendEnabled, true);
		});
		
		test('has/clear operations', () {
			final params = Params(defaultSendEnabled: false);
			
			expect(params.hasDefaultSendEnabled(), isTrue);
			params.clearDefaultSendEnabled();
			expect(params.hasDefaultSendEnabled(), isFalse);
		});
		
		test('JSON and buffer serialization', () {
			final params = Params(
				sendEnabled: [SendEnabled(denom: 'stake', enabled: true)],
				defaultSendEnabled: true
			);
			
			final json = jsonEncode(params.writeToJsonMap());
			final fromJson = Params.fromJson(json);
			expect(fromJson.sendEnabled.length, 1);
			expect(fromJson.defaultSendEnabled, true);
			
			final buffer = params.writeToBuffer();
			final fromBuffer = Params.fromBuffer(buffer);
			expect(fromBuffer.sendEnabled.first.denom, 'stake');
		});
		
		test('getDefault and createRepeated', () {
			expect(identical(Params.getDefault(), Params.getDefault()), isTrue);
			final list = Params.createRepeated();
			expect(list, isA<pb.PbList<Params>>());
		});
	});
	
	group('cosmos.bank.v1beta1 SendEnabled', () {
		test('constructor with denom and enabled', () {
			final sendEnabled = SendEnabled(denom: 'stake', enabled: true);
			expect(sendEnabled.denom, 'stake');
			expect(sendEnabled.enabled, true);
		});
		
		test('has/clear operations for denom and enabled', () {
			final sendEnabled = SendEnabled(denom: 'atom', enabled: false);
			
			expect(sendEnabled.hasDenom(), isTrue);
			expect(sendEnabled.hasEnabled(), isTrue);
			
			sendEnabled.clearDenom();
			sendEnabled.clearEnabled();
			
			expect(sendEnabled.hasDenom(), isFalse);
			expect(sendEnabled.hasEnabled(), isFalse);
		});
		
		test('clone and copyWith operations', () {
			final original = SendEnabled(denom: 'stake', enabled: true);
			
			final cloned = original.clone();
			expect(cloned.denom, 'stake');
			expect(cloned.enabled, true);
			
			final copied = original.copyWith((se) => se.enabled = false);
			expect(copied.enabled, false);
			expect(original.enabled, true); // original unchanged
		});
		
		test('JSON and buffer serialization', () {
			final sendEnabled = SendEnabled(denom: 'atom', enabled: false);
			
			final json = jsonEncode(sendEnabled.writeToJsonMap());
			final fromJson = SendEnabled.fromJson(json);
			expect(fromJson.denom, 'atom');
			expect(fromJson.enabled, false);
			
			final buffer = sendEnabled.writeToBuffer();
			final fromBuffer = SendEnabled.fromBuffer(buffer);
			expect(fromBuffer.denom, 'atom');
			expect(fromBuffer.enabled, false);
		});
		
		test('empty SendEnabled', () {
			final sendEnabled = SendEnabled();
			expect(sendEnabled.hasDenom(), isFalse);
			expect(sendEnabled.hasEnabled(), isFalse);
		});
	});
	
	group('cosmos.bank.v1beta1 Input', () {
		test('constructor with address and coins', () {
			final input = Input(
				address: 'cosmos1abc123',
				coins: [
					coin.CosmosCoin(denom: 'stake', amount: '1000'),
					coin.CosmosCoin(denom: 'atom', amount: '500')
				]
			);
			
			expect(input.address, 'cosmos1abc123');
			expect(input.coins.length, 2);
			expect(input.coins.first.denom, 'stake');
			expect(input.coins.first.amount, '1000');
		});
		
		test('has/clear address operations', () {
			final input = Input(address: 'cosmos1test');
			
			expect(input.hasAddress(), isTrue);
			input.clearAddress();
			expect(input.hasAddress(), isFalse);
		});
		
		test('coins list operations', () {
			final input = Input();
			
			input.coins.add(coin.CosmosCoin(denom: 'stake', amount: '1000'));
			expect(input.coins.length, 1);
			
			input.coins.addAll([
				coin.CosmosCoin(denom: 'atom', amount: '500'),
				coin.CosmosCoin(denom: 'osmo', amount: '250')
			]);
			expect(input.coins.length, 3);
			
			input.coins.clear();
			expect(input.coins, isEmpty);
		});
		
		test('clone and copyWith operations', () {
			final original = Input(
				address: 'cosmos1original',
				coins: [coin.CosmosCoin(denom: 'stake', amount: '1000')]
			);
			
			final cloned = original.clone();
			expect(cloned.address, 'cosmos1original');
			expect(cloned.coins.length, 1);
			
			final copied = original.copyWith((input) {
				input.address = 'cosmos1copied';
				input.coins.add(coin.CosmosCoin(denom: 'atom', amount: '500'));
			});
			expect(copied.address, 'cosmos1copied');
			expect(copied.coins.length, 2);
			expect(original.address, 'cosmos1original'); // original unchanged
		});
		
		test('JSON and buffer serialization', () {
			final input = Input(
				address: 'cosmos1test',
				coins: [coin.CosmosCoin(denom: 'stake', amount: '1000')]
			);
			
			final json = jsonEncode(input.writeToJsonMap());
			final fromJson = Input.fromJson(json);
			expect(fromJson.address, 'cosmos1test');
			expect(fromJson.coins.first.denom, 'stake');
			
			final buffer = input.writeToBuffer();
			final fromBuffer = Input.fromBuffer(buffer);
			expect(fromBuffer.address, 'cosmos1test');
			expect(fromBuffer.coins.first.amount, '1000');
		});
	});
	
	group('cosmos.bank.v1beta1 Output', () {
		test('constructor with address and coins', () {
			final output = Output(
				address: 'cosmos1def456',
				coins: [
					coin.CosmosCoin(denom: 'stake', amount: '2000'),
					coin.CosmosCoin(denom: 'atom', amount: '1000')
				]
			);
			
			expect(output.address, 'cosmos1def456');
			expect(output.coins.length, 2);
			expect(output.coins.first.denom, 'stake');
			expect(output.coins.first.amount, '2000');
		});
		
		test('has/clear address operations', () {
			final output = Output(address: 'cosmos1output');
			
			expect(output.hasAddress(), isTrue);
			output.clearAddress();
			expect(output.hasAddress(), isFalse);
		});
		
		test('coins list operations', () {
			final output = Output();
			
			output.coins.add(coin.CosmosCoin(denom: 'stake', amount: '2000'));
			expect(output.coins.length, 1);
			
			output.coins.removeAt(0);
			expect(output.coins, isEmpty);
		});
		
		test('JSON and buffer serialization', () {
			final output = Output(
				address: 'cosmos1output',
				coins: [coin.CosmosCoin(denom: 'atom', amount: '1000')]
			);
			
			final json = jsonEncode(output.writeToJsonMap());
			final fromJson = Output.fromJson(json);
			expect(fromJson.address, 'cosmos1output');
			expect(fromJson.coins.first.denom, 'atom');
			
			final buffer = output.writeToBuffer();
			final fromBuffer = Output.fromBuffer(buffer);
			expect(fromBuffer.coins.first.amount, '1000');
		});
	});
	
	group('cosmos.bank.v1beta1 Supply', () {
		test('constructor with total coins', () {
			final supply = Supply(total: [
				coin.CosmosCoin(denom: 'stake', amount: '1000000'),
				coin.CosmosCoin(denom: 'atom', amount: '500000')
			]);
			
			expect(supply.total.length, 2);
			expect(supply.total.first.denom, 'stake');
			expect(supply.total.first.amount, '1000000');
		});
		
		test('total list operations', () {
			final supply = Supply();
			
			supply.total.add(coin.CosmosCoin(denom: 'stake', amount: '1000000'));
			expect(supply.total.length, 1);
			
			supply.total.addAll([
				coin.CosmosCoin(denom: 'atom', amount: '500000'),
				coin.CosmosCoin(denom: 'osmo', amount: '250000')
			]);
			expect(supply.total.length, 3);
			
			supply.total.clear();
			expect(supply.total, isEmpty);
		});
		
		test('clone and copyWith operations', () {
			final original = Supply(total: [
				coin.CosmosCoin(denom: 'stake', amount: '1000000')
			]);
			
			final cloned = original.clone();
			expect(cloned.total.length, 1);
			expect(cloned.total.first.denom, 'stake');
			
			final copied = original.copyWith((supply) {
				supply.total.add(coin.CosmosCoin(denom: 'atom', amount: '500000'));
			});
			expect(copied.total.length, 2);
			expect(original.total.length, 1); // original unchanged
		});
		
		test('JSON and buffer serialization', () {
			final supply = Supply(total: [
				coin.CosmosCoin(denom: 'stake', amount: '1000000')
			]);
			
			final json = jsonEncode(supply.writeToJsonMap());
			final fromJson = Supply.fromJson(json);
			expect(fromJson.total.first.denom, 'stake');
			expect(fromJson.total.first.amount, '1000000');
			
			final buffer = supply.writeToBuffer();
			final fromBuffer = Supply.fromBuffer(buffer);
			expect(fromBuffer.total.first.denom, 'stake');
		});
	});
	
	group('cosmos.bank.v1beta1 DenomUnit', () {
		test('constructor with denom, exponent, and aliases', () {
			final denomUnit = DenomUnit(
				denom: 'ustake',
				exponent: 6,
				aliases: ['microstake', 'µstake']
			);
			
			expect(denomUnit.denom, 'ustake');
			expect(denomUnit.exponent, 6);
			expect(denomUnit.aliases.length, 2);
			expect(denomUnit.aliases, ['microstake', 'µstake']);
		});
		
		test('has/clear operations', () {
			final denomUnit = DenomUnit(denom: 'ustake', exponent: 6);
			
			expect(denomUnit.hasDenom(), isTrue);
			expect(denomUnit.hasExponent(), isTrue);
			
			denomUnit.clearDenom();
			denomUnit.clearExponent();
			
			expect(denomUnit.hasDenom(), isFalse);
			expect(denomUnit.hasExponent(), isFalse);
		});
		
		test('aliases list operations', () {
			final denomUnit = DenomUnit();
			
			denomUnit.aliases.add('microstake');
			denomUnit.aliases.add('µstake');
			expect(denomUnit.aliases.length, 2);
			
			denomUnit.aliases.clear();
			expect(denomUnit.aliases, isEmpty);
		});
		
		test('JSON and buffer serialization', () {
			final denomUnit = DenomUnit(
				denom: 'ustake',
				exponent: 6,
				aliases: ['microstake']
			);
			
			final json = jsonEncode(denomUnit.writeToJsonMap());
			final fromJson = DenomUnit.fromJson(json);
			expect(fromJson.denom, 'ustake');
			expect(fromJson.exponent, 6);
			expect(fromJson.aliases.first, 'microstake');
			
			final buffer = denomUnit.writeToBuffer();
			final fromBuffer = DenomUnit.fromBuffer(buffer);
			expect(fromBuffer.denom, 'ustake');
			expect(fromBuffer.exponent, 6);
		});
	});
	
	group('cosmos.bank.v1beta1 Metadata', () {
		test('constructor with all fields', () {
			final metadata = Metadata(
				description: 'Staking token',
				denomUnits: [
					DenomUnit(denom: 'ustake', exponent: 6),
					DenomUnit(denom: 'stake', exponent: 0)
				],
				base: 'ustake',
				display: 'stake',
				name: 'Stake Token',
				symbol: 'STAKE'
			);
			
			expect(metadata.description, 'Staking token');
			expect(metadata.denomUnits.length, 2);
			expect(metadata.base, 'ustake');
			expect(metadata.display, 'stake');
			expect(metadata.name, 'Stake Token');
			expect(metadata.symbol, 'STAKE');
		});
		
		test('has/clear operations for all fields', () {
			final metadata = Metadata(
				description: 'Test token',
				base: 'utest',
				display: 'test',
				name: 'Test Token',
				symbol: 'TEST'
			);
			
			expect(metadata.hasDescription(), isTrue);
			expect(metadata.hasBase(), isTrue);
			expect(metadata.hasDisplay(), isTrue);
			expect(metadata.hasName(), isTrue);
			expect(metadata.hasSymbol(), isTrue);
			
			metadata.clearDescription();
			metadata.clearBase();
			metadata.clearDisplay();
			metadata.clearName();
			metadata.clearSymbol();
			
			expect(metadata.hasDescription(), isFalse);
			expect(metadata.hasBase(), isFalse);
			expect(metadata.hasDisplay(), isFalse);
			expect(metadata.hasName(), isFalse);
			expect(metadata.hasSymbol(), isFalse);
		});
		
		test('denomUnits list operations', () {
			final metadata = Metadata();
			
			metadata.denomUnits.add(DenomUnit(denom: 'ustake', exponent: 6));
			metadata.denomUnits.add(DenomUnit(denom: 'stake', exponent: 0));
			expect(metadata.denomUnits.length, 2);
			
			metadata.denomUnits.removeAt(0);
			expect(metadata.denomUnits.length, 1);
			expect(metadata.denomUnits.first.denom, 'stake');
		});
		
		test('JSON and buffer serialization', () {
			final metadata = Metadata(
				description: 'Test token',
				base: 'utest',
				display: 'test',
				name: 'Test Token',
				symbol: 'TEST',
				denomUnits: [DenomUnit(denom: 'utest', exponent: 6)]
			);
			
			final json = jsonEncode(metadata.writeToJsonMap());
			final fromJson = Metadata.fromJson(json);
			expect(fromJson.description, 'Test token');
			expect(fromJson.base, 'utest');
			expect(fromJson.denomUnits.first.denom, 'utest');
			
			final buffer = metadata.writeToBuffer();
			final fromBuffer = Metadata.fromBuffer(buffer);
			expect(fromBuffer.name, 'Test Token');
			expect(fromBuffer.symbol, 'TEST');
		});
	});
	
	group('cosmos.bank.v1beta1 error handling', () {
		test('invalid buffer deserialization', () {
			expect(() => Params.fromBuffer([0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => SendEnabled.fromBuffer([0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => Input.fromBuffer([0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => Output.fromBuffer([0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			expect(() => Params.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => Supply.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => DenomUnit.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => Metadata.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('cosmos.bank.v1beta1 getDefault and createRepeated', () {
		test('all message types have getDefault', () {
			expect(identical(SendEnabled.getDefault(), SendEnabled.getDefault()), isTrue);
			expect(identical(Input.getDefault(), Input.getDefault()), isTrue);
			expect(identical(Output.getDefault(), Output.getDefault()), isTrue);
			expect(identical(Supply.getDefault(), Supply.getDefault()), isTrue);
			expect(identical(DenomUnit.getDefault(), DenomUnit.getDefault()), isTrue);
			expect(identical(Metadata.getDefault(), Metadata.getDefault()), isTrue);
		});
		
		test('all message types can create repeated lists', () {
			expect(SendEnabled.createRepeated(), isA<pb.PbList<SendEnabled>>());
			expect(Input.createRepeated(), isA<pb.PbList<Input>>());
			expect(Output.createRepeated(), isA<pb.PbList<Output>>());
			expect(Supply.createRepeated(), isA<pb.PbList<Supply>>());
			expect(DenomUnit.createRepeated(), isA<pb.PbList<DenomUnit>>());
			expect(Metadata.createRepeated(), isA<pb.PbList<Metadata>>());
		});
	});
} 