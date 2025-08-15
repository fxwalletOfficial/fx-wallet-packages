import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/genesis.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/bank.pb.dart' as bank;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart' as coin;

void main() {
	group('cosmos.bank.v1beta1 GenesisState', () {
		test('constructor with all fields', () {
			final params = bank.Params(
				sendEnabled: [bank.SendEnabled(denom: 'stake', enabled: true)],
				defaultSendEnabled: true
			);
			
			final balances = [
				Balance(
					address: 'cosmos1abc123',
					coins: [coin.CosmosCoin(denom: 'stake', amount: '1000')]
				),
				Balance(
					address: 'cosmos1def456',
					coins: [coin.CosmosCoin(denom: 'atom', amount: '500')]
				)
			];
			
			final supply = [
				coin.CosmosCoin(denom: 'stake', amount: '1000000'),
				coin.CosmosCoin(denom: 'atom', amount: '500000')
			];
			
			final denomMetadata = [
				bank.Metadata(
					description: 'Stake token',
					base: 'ustake',
					display: 'stake',
					name: 'Stake',
					symbol: 'STAKE'
				)
			];
			
			final genesisState = GenesisState(
				params: params,
				balances: balances,
				supply: supply,
				denomMetadata: denomMetadata
			);
			
			expect(genesisState.params.defaultSendEnabled, true);
			expect(genesisState.balances.length, 2);
			expect(genesisState.balances.first.address, 'cosmos1abc123');
			expect(genesisState.supply.length, 2);
			expect(genesisState.supply.first.denom, 'stake');
			expect(genesisState.denomMetadata.length, 1);
			expect(genesisState.denomMetadata.first.name, 'Stake');
		});
		
		test('has/clear/ensure params operations', () {
			final genesisState = GenesisState(
				params: bank.Params(defaultSendEnabled: true)
			);
			
			expect(genesisState.hasParams(), isTrue);
			
			// Ensure returns same instance
			final ensuredParams = genesisState.ensureParams();
			expect(identical(ensuredParams, genesisState.params), isTrue);
			
			genesisState.clearParams();
			expect(genesisState.hasParams(), isFalse);
			
			// Ensure creates new instance when cleared
			final newParams = genesisState.ensureParams();
			expect(genesisState.hasParams(), isTrue);
			expect(newParams, isA<bank.Params>());
		});
		
		test('list operations for balances, supply, and denomMetadata', () {
			final genesisState = GenesisState();
			
			// Balances operations
			genesisState.balances.add(Balance(
				address: 'cosmos1test',
				coins: [coin.CosmosCoin(denom: 'stake', amount: '1000')]
			));
			expect(genesisState.balances.length, 1);
			
			// Supply operations
			genesisState.supply.add(coin.CosmosCoin(denom: 'stake', amount: '1000000'));
			genesisState.supply.add(coin.CosmosCoin(denom: 'atom', amount: '500000'));
			expect(genesisState.supply.length, 2);
			
			// DenomMetadata operations
			genesisState.denomMetadata.add(bank.Metadata(
				name: 'Test Token',
				symbol: 'TEST'
			));
			expect(genesisState.denomMetadata.length, 1);
			
			// Clear all lists
			genesisState.balances.clear();
			genesisState.supply.clear();
			genesisState.denomMetadata.clear();
			
			expect(genesisState.balances, isEmpty);
			expect(genesisState.supply, isEmpty);
			expect(genesisState.denomMetadata, isEmpty);
		});
		
		test('clone operation', () {
			final original = GenesisState(
				params: bank.Params(defaultSendEnabled: true),
				balances: [Balance(address: 'cosmos1original')],
				supply: [coin.CosmosCoin(denom: 'stake', amount: '1000')]
			);
			
			final cloned = original.clone();
			expect(cloned.params.defaultSendEnabled, true);
			expect(cloned.balances.first.address, 'cosmos1original');
			expect(cloned.supply.first.denom, 'stake');
			
			// Verify independence
			cloned.balances.add(Balance(address: 'cosmos1cloned'));
			expect(cloned.balances.length, 2);
			expect(original.balances.length, 1);
		});
		
		test('copyWith operation', () {
			final original = GenesisState(
				params: bank.Params(defaultSendEnabled: false),
				balances: [Balance(address: 'cosmos1original')]
			);
			
			final copied = original.clone().copyWith((gs) {
				gs.params.defaultSendEnabled = true;
				gs.balances.add(Balance(address: 'cosmos1copied'));
			});
			
			expect(copied.params.defaultSendEnabled, true);
			expect(copied.balances.length, 2);
			expect(original.params.defaultSendEnabled, false); // original unchanged
			expect(original.balances.length, 1);
		});
		
		test('JSON serialization and deserialization', () {
			final genesisState = GenesisState(
				params: bank.Params(defaultSendEnabled: true),
				balances: [Balance(
					address: 'cosmos1test',
					coins: [coin.CosmosCoin(denom: 'stake', amount: '1000')]
				)],
				supply: [coin.CosmosCoin(denom: 'stake', amount: '1000000')]
			);
			
			final json = jsonEncode(genesisState.writeToJsonMap());
			final fromJson = GenesisState.fromJson(json);
			
			expect(fromJson.params.defaultSendEnabled, true);
			expect(fromJson.balances.first.address, 'cosmos1test');
			expect(fromJson.balances.first.coins.first.denom, 'stake');
			expect(fromJson.supply.first.amount, '1000000');
		});
		
		test('binary serialization and deserialization', () {
			final genesisState = GenesisState(
				params: bank.Params(defaultSendEnabled: false),
				balances: [Balance(address: 'cosmos1binary')],
				supply: [coin.CosmosCoin(denom: 'atom', amount: '500000')]
			);
			
			final buffer = genesisState.writeToBuffer();
			final fromBuffer = GenesisState.fromBuffer(buffer);
			
			expect(fromBuffer.params.defaultSendEnabled, false);
			expect(fromBuffer.balances.first.address, 'cosmos1binary');
			expect(fromBuffer.supply.first.denom, 'atom');
		});
		
		test('getDefault and createRepeated', () {
			expect(identical(GenesisState.getDefault(), GenesisState.getDefault()), isTrue);
			
			final list = GenesisState.createRepeated();
			expect(list, isA<pb.PbList<GenesisState>>());
			expect(list, isEmpty);
		});
		
		test('empty GenesisState', () {
			final genesisState = GenesisState();
			
			expect(genesisState.hasParams(), isFalse);
			expect(genesisState.balances, isEmpty);
			expect(genesisState.supply, isEmpty);
			expect(genesisState.denomMetadata, isEmpty);
		});
	});
	
	group('cosmos.bank.v1beta1 Balance', () {
		test('constructor with address and coins', () {
			final balance = Balance(
				address: 'cosmos1test123',
				coins: [
					coin.CosmosCoin(denom: 'stake', amount: '1000'),
					coin.CosmosCoin(denom: 'atom', amount: '500')
				]
			);
			
			expect(balance.address, 'cosmos1test123');
			expect(balance.coins.length, 2);
			expect(balance.coins.first.denom, 'stake');
			expect(balance.coins.first.amount, '1000');
			expect(balance.coins.last.denom, 'atom');
			expect(balance.coins.last.amount, '500');
		});
		
		test('has/clear address operations', () {
			final balance = Balance(address: 'cosmos1hastest');
			
			expect(balance.hasAddress(), isTrue);
			balance.clearAddress();
			expect(balance.hasAddress(), isFalse);
			expect(balance.address, isEmpty);
		});
		
		test('coins list operations', () {
			final balance = Balance();
			
			// Add coins
			balance.coins.add(coin.CosmosCoin(denom: 'stake', amount: '1000'));
			balance.coins.add(coin.CosmosCoin(denom: 'atom', amount: '500'));
			expect(balance.coins.length, 2);
			
			// AddAll coins
			balance.coins.addAll([
				coin.CosmosCoin(denom: 'osmo', amount: '250'),
				coin.CosmosCoin(denom: 'juno', amount: '125')
			]);
			expect(balance.coins.length, 4);
			
			// Remove coins
			balance.coins.removeAt(0);
			expect(balance.coins.length, 3);
			expect(balance.coins.first.denom, 'atom');
			
			// Clear all coins
			balance.coins.clear();
			expect(balance.coins, isEmpty);
		});
		
		test('clone operation', () {
			final original = Balance(
				address: 'cosmos1original',
				coins: [
					coin.CosmosCoin(denom: 'stake', amount: '1000'),
					coin.CosmosCoin(denom: 'atom', amount: '500')
				]
			);
			
			final cloned = original.clone();
			expect(cloned.address, 'cosmos1original');
			expect(cloned.coins.length, 2);
			expect(cloned.coins.first.denom, 'stake');
			
			// Verify independence
			cloned.address = 'cosmos1cloned';
			cloned.coins.add(coin.CosmosCoin(denom: 'osmo', amount: '250'));
			
			expect(cloned.address, 'cosmos1cloned');
			expect(cloned.coins.length, 3);
			expect(original.address, 'cosmos1original');
			expect(original.coins.length, 2);
		});
		
		test('copyWith operation', () {
			final original = Balance(
				address: 'cosmos1original',
				coins: [coin.CosmosCoin(denom: 'stake', amount: '1000')]
			);
			
			final copied = original.copyWith((balance) {
				balance.address = 'cosmos1copied';
				balance.coins.add(coin.CosmosCoin(denom: 'atom', amount: '500'));
			});
			
			expect(copied.address, 'cosmos1copied');
			expect(copied.coins.length, 2);
			expect(copied.coins.last.denom, 'atom');
			
			expect(original.address, 'cosmos1original'); // original unchanged
			expect(original.coins.length, 1);
		});
		
		test('JSON serialization and deserialization', () {
			final balance = Balance(
				address: 'cosmos1json',
				coins: [
					coin.CosmosCoin(denom: 'stake', amount: '1000'),
					coin.CosmosCoin(denom: 'atom', amount: '500')
				]
			);
			
			final json = jsonEncode(balance.writeToJsonMap());
			final fromJson = Balance.fromJson(json);
			
			expect(fromJson.address, 'cosmos1json');
			expect(fromJson.coins.length, 2);
			expect(fromJson.coins.first.denom, 'stake');
			expect(fromJson.coins.first.amount, '1000');
			expect(fromJson.coins.last.denom, 'atom');
			expect(fromJson.coins.last.amount, '500');
		});
		
		test('binary serialization and deserialization', () {
			final balance = Balance(
				address: 'cosmos1binary',
				coins: [coin.CosmosCoin(denom: 'atom', amount: '2000')]
			);
			
			final buffer = balance.writeToBuffer();
			final fromBuffer = Balance.fromBuffer(buffer);
			
			expect(fromBuffer.address, 'cosmos1binary');
			expect(fromBuffer.coins.length, 1);
			expect(fromBuffer.coins.first.denom, 'atom');
			expect(fromBuffer.coins.first.amount, '2000');
		});
		
		test('getDefault and createRepeated', () {
			expect(identical(Balance.getDefault(), Balance.getDefault()), isTrue);
			
			final list = Balance.createRepeated();
			expect(list, isA<pb.PbList<Balance>>());
			expect(list, isEmpty);
			
			list.add(Balance(address: 'cosmos1list'));
			expect(list.length, 1);
		});
		
		test('empty Balance', () {
			final balance = Balance();
			
			expect(balance.hasAddress(), isFalse);
			expect(balance.address, isEmpty);
			expect(balance.coins, isEmpty);
		});
		
		test('large number of coins', () {
			final balance = Balance(address: 'cosmos1large');
			
			// Add 100 different coins
			for (int i = 0; i < 100; i++) {
				balance.coins.add(coin.CosmosCoin(
					denom: 'token$i',
					amount: '${i * 1000}'
				));
			}
			
			expect(balance.coins.length, 100);
			expect(balance.coins.first.denom, 'token0');
			expect(balance.coins.last.denom, 'token99');
			expect(balance.coins.last.amount, '99000');
			
			// Test serialization with large list
			final buffer = balance.writeToBuffer();
			final fromBuffer = Balance.fromBuffer(buffer);
			expect(fromBuffer.coins.length, 100);
			expect(fromBuffer.coins.first.denom, 'token0');
		});
	});
	
	group('cosmos.bank.v1beta1 error handling', () {
		test('invalid buffer deserialization', () {
			expect(() => GenesisState.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => Balance.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			expect(() => GenesisState.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => Balance.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
	});
} 