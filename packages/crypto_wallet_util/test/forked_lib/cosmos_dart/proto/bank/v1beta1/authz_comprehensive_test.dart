import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/authz.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart' as coin;

void main() {
	group('cosmos.bank.v1beta1 SendAuthorization', () {
		test('constructor with spendLimit', () {
			final auth = SendAuthorization(spendLimit: [
				coin.CosmosCoin(denom: 'stake', amount: '1000'),
				coin.CosmosCoin(denom: 'atom', amount: '500')
			]);
			
			expect(auth.spendLimit.length, 2);
			expect(auth.spendLimit.first.denom, 'stake');
			expect(auth.spendLimit.first.amount, '1000');
			expect(auth.spendLimit.last.denom, 'atom');
			expect(auth.spendLimit.last.amount, '500');
		});
		
		test('constructor with empty spendLimit', () {
			final auth = SendAuthorization(spendLimit: []);
			expect(auth.spendLimit, isEmpty);
		});
		
		test('default constructor', () {
			final auth = SendAuthorization();
			expect(auth.spendLimit, isEmpty);
		});
		
		test('spendLimit list operations', () {
			final auth = SendAuthorization();
			
			// Add coins
			auth.spendLimit.add(coin.CosmosCoin(denom: 'stake', amount: '1000'));
			auth.spendLimit.add(coin.CosmosCoin(denom: 'atom', amount: '500'));
			expect(auth.spendLimit.length, 2);
			
			// Remove coin
			auth.spendLimit.removeAt(0);
			expect(auth.spendLimit.length, 1);
			expect(auth.spendLimit.first.denom, 'atom');
			
			// Clear all
			auth.spendLimit.clear();
			expect(auth.spendLimit, isEmpty);
		});
		
		test('spendLimit addAll operation', () {
			final auth = SendAuthorization();
			final coins = [
				coin.CosmosCoin(denom: 'stake', amount: '1000'),
				coin.CosmosCoin(denom: 'atom', amount: '500'),
				coin.CosmosCoin(denom: 'osmo', amount: '250')
			];
			
			auth.spendLimit.addAll(coins);
			expect(auth.spendLimit.length, 3);
			expect(auth.spendLimit.map((c) => c.denom), ['stake', 'atom', 'osmo']);
		});
		
		test('clone operation', () {
			final original = SendAuthorization(spendLimit: [
				coin.CosmosCoin(denom: 'stake', amount: '1000'),
				coin.CosmosCoin(denom: 'atom', amount: '500')
			]);
			
			final cloned = original.clone();
			expect(cloned.spendLimit.length, 2);
			expect(cloned.spendLimit.first.denom, 'stake');
			expect(cloned.spendLimit.first.amount, '1000');
			
			// Verify independence
			cloned.spendLimit.add(coin.CosmosCoin(denom: 'osmo', amount: '250'));
			expect(cloned.spendLimit.length, 3);
			expect(original.spendLimit.length, 2);
		});
		
		test('copyWith operation', () {
			final original = SendAuthorization(spendLimit: [
				coin.CosmosCoin(denom: 'stake', amount: '1000')
			]);
			
			final copied = original.copyWith((auth) {
				auth.spendLimit.add(coin.CosmosCoin(denom: 'atom', amount: '500'));
			});
			
			expect(copied.spendLimit.length, 2);
			expect(copied.spendLimit.last.denom, 'atom');
			expect(original.spendLimit.length, 1); // original unchanged
		});
		
		test('JSON serialization and deserialization', () {
			final auth = SendAuthorization(spendLimit: [
				coin.CosmosCoin(denom: 'stake', amount: '1000'),
				coin.CosmosCoin(denom: 'atom', amount: '500')
			]);
			
			final json = jsonEncode(auth.writeToJsonMap());
			final fromJson = SendAuthorization.fromJson(json);
			
			expect(fromJson.spendLimit.length, 2);
			expect(fromJson.spendLimit.first.denom, 'stake');
			expect(fromJson.spendLimit.first.amount, '1000');
			expect(fromJson.spendLimit.last.denom, 'atom');
			expect(fromJson.spendLimit.last.amount, '500');
		});
		
		test('binary serialization and deserialization', () {
			final auth = SendAuthorization(spendLimit: [
				coin.CosmosCoin(denom: 'stake', amount: '1000'),
				coin.CosmosCoin(denom: 'atom', amount: '500')
			]);
			
			final buffer = auth.writeToBuffer();
			final fromBuffer = SendAuthorization.fromBuffer(buffer);
			
			expect(fromBuffer.spendLimit.length, 2);
			expect(fromBuffer.spendLimit.first.denom, 'stake');
			expect(fromBuffer.spendLimit.first.amount, '1000');
			expect(fromBuffer.spendLimit.last.denom, 'atom');
			expect(fromBuffer.spendLimit.last.amount, '500');
		});
		
		test('getDefault returns same instance', () {
			final default1 = SendAuthorization.getDefault();
			final default2 = SendAuthorization.getDefault();
			expect(identical(default1, default2), isTrue);
		});
		
		test('createEmptyInstance creates new instance', () {
			final auth = SendAuthorization();
			final empty = auth.createEmptyInstance();
			expect(empty.spendLimit, isEmpty);
			expect(identical(auth, empty), isFalse);
		});
		
		test('createRepeated creates PbList', () {
			final list = SendAuthorization.createRepeated();
			expect(list, isA<pb.PbList<SendAuthorization>>());
			expect(list, isEmpty);
			
			list.add(SendAuthorization(spendLimit: [
				coin.CosmosCoin(denom: 'stake', amount: '1000')
			]));
			expect(list.length, 1);
		});
		
		test('info_ returns BuilderInfo', () {
			final auth = SendAuthorization();
			final info = auth.info_;
			expect(info, isA<pb.BuilderInfo>());
			expect(info.qualifiedMessageName, contains('SendAuthorization'));
		});
		
		test('empty authorization serialization', () {
			final auth = SendAuthorization();
			
			final json = jsonEncode(auth.writeToJsonMap());
			final fromJson = SendAuthorization.fromJson(json);
			expect(fromJson.spendLimit, isEmpty);
			
			final buffer = auth.writeToBuffer();
			final fromBuffer = SendAuthorization.fromBuffer(buffer);
			expect(fromBuffer.spendLimit, isEmpty);
		});
		
		test('large number of coins in spendLimit', () {
			final coins = List.generate(100, (i) => 
				coin.CosmosCoin(denom: 'coin$i', amount: '${i * 100}')
			);
			
			final auth = SendAuthorization(spendLimit: coins);
			expect(auth.spendLimit.length, 100);
			expect(auth.spendLimit.first.denom, 'coin0');
			expect(auth.spendLimit.last.denom, 'coin99');
			expect(auth.spendLimit.last.amount, '9900');
			
			// Test serialization with large list
			final buffer = auth.writeToBuffer();
			final fromBuffer = SendAuthorization.fromBuffer(buffer);
			expect(fromBuffer.spendLimit.length, 100);
		});
		
		test('spendLimit with zero amounts', () {
			final auth = SendAuthorization(spendLimit: [
				coin.CosmosCoin(denom: 'stake', amount: '0'),
				coin.CosmosCoin(denom: 'atom', amount: '0')
			]);
			
			expect(auth.spendLimit.length, 2);
			expect(auth.spendLimit.every((c) => c.amount == '0'), isTrue);
			
			final json = jsonEncode(auth.writeToJsonMap());
			final fromJson = SendAuthorization.fromJson(json);
			expect(fromJson.spendLimit.every((c) => c.amount == '0'), isTrue);
		});
		
		test('error handling for invalid buffer', () {
			expect(() => SendAuthorization.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('error handling for invalid JSON', () {
			expect(() => SendAuthorization.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
		
		test('spendLimit list modification after construction', () {
			final auth = SendAuthorization(spendLimit: [
				coin.CosmosCoin(denom: 'stake', amount: '1000')
			]);
			
			// Modify existing coin
			auth.spendLimit.first.amount = '2000';
			expect(auth.spendLimit.first.amount, '2000');
			
			// Replace coin
			auth.spendLimit[0] = coin.CosmosCoin(denom: 'atom', amount: '500');
			expect(auth.spendLimit.first.denom, 'atom');
			expect(auth.spendLimit.first.amount, '500');
		});
	});
} 