import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/vesting/v1beta1/tx.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';

void main() {
	group('cosmos.vesting.v1beta1 MsgCreateVestingAccount', () {
		test('constructor with all parameters', () {
			final amount = [
				CosmosCoin(denom: 'stake', amount: '10000000'),
				CosmosCoin(denom: 'atom', amount: '5000000'),
			];
			
			final msg = MsgCreateVestingAccount(
				fromAddress: 'cosmos1fromaddress123',
				toAddress: 'cosmos1toaddress456',
				amount: amount,
				endTime: Int64(1735689600), // 2025-01-01 00:00:00 UTC
				delayed: false,
			);
			
			expect(msg.fromAddress, 'cosmos1fromaddress123');
			expect(msg.toAddress, 'cosmos1toaddress456');
			expect(msg.amount.length, 2);
			expect(msg.amount[0].denom, 'stake');
			expect(msg.amount[0].amount, '10000000');
			expect(msg.amount[1].denom, 'atom');
			expect(msg.amount[1].amount, '5000000');
			expect(msg.endTime, Int64(1735689600));
			expect(msg.delayed, false);
		});
		
		test('constructor with partial parameters', () {
			final msg = MsgCreateVestingAccount(
				fromAddress: 'cosmos1from',
				toAddress: 'cosmos1to',
				endTime: Int64(1640995200),
			);
			
			expect(msg.fromAddress, 'cosmos1from');
			expect(msg.toAddress, 'cosmos1to');
			expect(msg.amount, isEmpty);
			expect(msg.endTime, Int64(1640995200));
			expect(msg.hasDelayed(), false);
		});
		
		test('default constructor', () {
			final msg = MsgCreateVestingAccount();
			
			expect(msg.fromAddress, '');
			expect(msg.toAddress, '');
			expect(msg.amount, isEmpty);
			expect(msg.endTime, Int64.ZERO);
			expect(msg.delayed, false);
		});
		
		test('has/clear operations for fromAddress', () {
			final msg = MsgCreateVestingAccount(fromAddress: 'cosmos1test');
			
			expect(msg.hasFromAddress(), true);
			expect(msg.fromAddress, 'cosmos1test');
			
			msg.clearFromAddress();
			expect(msg.hasFromAddress(), false);
			expect(msg.fromAddress, '');
		});
		
		test('has/clear operations for toAddress', () {
			final msg = MsgCreateVestingAccount(toAddress: 'cosmos1recipient');
			
			expect(msg.hasToAddress(), true);
			expect(msg.toAddress, 'cosmos1recipient');
			
			msg.clearToAddress();
			expect(msg.hasToAddress(), false);
			expect(msg.toAddress, '');
		});
		
		test('has/clear operations for endTime', () {
			final msg = MsgCreateVestingAccount(endTime: Int64(1609459200));
			
			expect(msg.hasEndTime(), true);
			expect(msg.endTime, Int64(1609459200));
			
			msg.clearEndTime();
			expect(msg.hasEndTime(), false);
			expect(msg.endTime, Int64.ZERO);
		});
		
		test('has/clear operations for delayed', () {
			final msg = MsgCreateVestingAccount(delayed: true);
			
			expect(msg.hasDelayed(), true);
			expect(msg.delayed, true);
			
			msg.clearDelayed();
			expect(msg.hasDelayed(), false);
			expect(msg.delayed, false);
		});
		
		test('setting and getting values', () {
			final msg = MsgCreateVestingAccount();
			
			msg.fromAddress = 'cosmos1setter';
			msg.toAddress = 'cosmos1getter';
			msg.endTime = Int64(2000000000);
			msg.delayed = true;
			
			expect(msg.fromAddress, 'cosmos1setter');
			expect(msg.toAddress, 'cosmos1getter');
			expect(msg.endTime, Int64(2000000000));
			expect(msg.delayed, true);
		});
		
		test('amount list operations', () {
			final msg = MsgCreateVestingAccount();
			
			expect(msg.amount, isEmpty);
			
			final coin1 = CosmosCoin(denom: 'stake', amount: '1000000');
			final coin2 = CosmosCoin(denom: 'atom', amount: '500000');
			final coin3 = CosmosCoin(denom: 'osmo', amount: '250000');
			
			msg.amount.addAll([coin1, coin2, coin3]);
			expect(msg.amount.length, 3);
			expect(msg.amount[0].denom, 'stake');
			expect(msg.amount[1].denom, 'atom');
			expect(msg.amount[2].denom, 'osmo');
			
			msg.amount.removeAt(1); // Remove atom
			expect(msg.amount.length, 2);
			expect(msg.amount[0].denom, 'stake');
			expect(msg.amount[1].denom, 'osmo');
			
			msg.amount.clear();
			expect(msg.amount, isEmpty);
		});
		
		test('clone operation', () {
			final original = MsgCreateVestingAccount(
				fromAddress: 'cosmos1original',
				toAddress: 'cosmos1target',
				endTime: Int64(1234567890),
				delayed: true,
			);
			original.amount.add(CosmosCoin(denom: 'test', amount: '12345'));
			
			final cloned = original.clone();
			expect(cloned.fromAddress, 'cosmos1original');
			expect(cloned.toAddress, 'cosmos1target');
			expect(cloned.endTime, Int64(1234567890));
			expect(cloned.delayed, true);
			expect(cloned.amount.length, 1);
			expect(cloned.amount[0].denom, 'test');
			expect(cloned.amount[0].amount, '12345');
			
			// Verify independence
			cloned.fromAddress = 'cosmos1cloned';
			cloned.amount.add(CosmosCoin(denom: 'new', amount: '67890'));
			cloned.delayed = false;
			
			expect(cloned.fromAddress, 'cosmos1cloned');
			expect(cloned.amount.length, 2);
			expect(cloned.delayed, false);
			
			expect(original.fromAddress, 'cosmos1original');
			expect(original.amount.length, 1);
			expect(original.delayed, true);
		});
		
		test('copyWith operation', () {
			final original = MsgCreateVestingAccount(
				fromAddress: 'cosmos1original',
				toAddress: 'cosmos1target',
				endTime: Int64(1000000),
				delayed: false,
			);
			
			final copied = original.clone().copyWith((msg) {
				msg.fromAddress = 'cosmos1copied';
				msg.endTime = Int64(2000000);
				msg.delayed = true;
			});
			
			expect(copied.fromAddress, 'cosmos1copied');
			expect(copied.endTime, Int64(2000000));
			expect(copied.delayed, true);
			
			// original unchanged
			expect(original.fromAddress, 'cosmos1original');
			expect(original.endTime, Int64(1000000));
			expect(original.delayed, false);
		});
		
		test('JSON serialization and deserialization', () {
			final msg = MsgCreateVestingAccount(
				fromAddress: 'cosmos1jsontest',
				toAddress: 'cosmos1jsonrecipient',
				endTime: Int64(1577836800),
				delayed: true,
			);
			msg.amount.addAll([
				CosmosCoin(denom: 'stake', amount: '3000000'),
				CosmosCoin(denom: 'atom', amount: '1500000'),
			]);
			
			final json = jsonEncode(msg.writeToJsonMap());
			final fromJson = MsgCreateVestingAccount.fromJson(json);
			
			expect(fromJson.fromAddress, 'cosmos1jsontest');
			expect(fromJson.toAddress, 'cosmos1jsonrecipient');
			expect(fromJson.amount.length, 2);
			expect(fromJson.amount[0].denom, 'stake');
			expect(fromJson.amount[0].amount, '3000000');
			expect(fromJson.amount[1].denom, 'atom');
			expect(fromJson.amount[1].amount, '1500000');
			expect(fromJson.endTime, Int64(1577836800));
			expect(fromJson.delayed, true);
		});
		
		test('binary serialization and deserialization', () {
			final msg = MsgCreateVestingAccount(
				fromAddress: 'cosmos1buffertest',
				toAddress: 'cosmos1bufferrecipient',
				endTime: Int64(1609459200),
				delayed: false,
			);
			msg.amount.add(CosmosCoin(denom: 'buffer', amount: '7500000'));
			
			final buffer = msg.writeToBuffer();
			final fromBuffer = MsgCreateVestingAccount.fromBuffer(buffer);
			
			expect(fromBuffer.fromAddress, 'cosmos1buffertest');
			expect(fromBuffer.toAddress, 'cosmos1bufferrecipient');
			expect(fromBuffer.amount.length, 1);
			expect(fromBuffer.amount[0].denom, 'buffer');
			expect(fromBuffer.amount[0].amount, '7500000');
			expect(fromBuffer.endTime, Int64(1609459200));
			expect(fromBuffer.delayed, false);
		});
		
		test('getDefault returns same instance', () {
			final default1 = MsgCreateVestingAccount.getDefault();
			final default2 = MsgCreateVestingAccount.getDefault();
			expect(identical(default1, default2), isTrue);
		});
		
		test('createEmptyInstance creates new instance', () {
			final msg = MsgCreateVestingAccount();
			final empty = msg.createEmptyInstance();
			expect(empty.fromAddress, '');
			expect(empty.toAddress, '');
			expect(empty.amount, isEmpty);
			expect(empty.endTime, Int64.ZERO);
			expect(identical(msg, empty), isFalse);
		});
		
		test('createRepeated creates PbList', () {
			final list = MsgCreateVestingAccount.createRepeated();
			expect(list, isA<pb.PbList<MsgCreateVestingAccount>>());
			expect(list, isEmpty);
			
			list.add(MsgCreateVestingAccount(fromAddress: 'cosmos1test'));
			expect(list.length, 1);
		});
		
		test('info_ returns BuilderInfo', () {
			final msg = MsgCreateVestingAccount();
			final info = msg.info_;
			expect(info, isA<pb.BuilderInfo>());
			expect(info.qualifiedMessageName, contains('MsgCreateVestingAccount'));
		});
		
		test('large endTime values', () {
			final msg = MsgCreateVestingAccount(
				endTime: Int64.parseInt('9223372036854775807'), // max int64
			);
			
			expect(msg.endTime.toString(), '9223372036854775807');
			
			final buffer = msg.writeToBuffer();
			final fromBuffer = MsgCreateVestingAccount.fromBuffer(buffer);
			expect(fromBuffer.endTime.toString(), '9223372036854775807');
		});
		
		test('zero endTime', () {
			final msg = MsgCreateVestingAccount(endTime: Int64.ZERO);
			
			expect(msg.endTime, Int64.ZERO);
			expect(msg.hasEndTime(), true);
		});
		
		test('boolean delayed field variations', () {
			// Test both true and false values
			final msgTrue = MsgCreateVestingAccount(delayed: true);
			final msgFalse = MsgCreateVestingAccount(delayed: false);
			
			expect(msgTrue.delayed, true);
			expect(msgTrue.hasDelayed(), true);
			expect(msgFalse.delayed, false);
			expect(msgFalse.hasDelayed(), true);
			
			// Test serialization of boolean values
			final bufferTrue = msgTrue.writeToBuffer();
			final bufferFalse = msgFalse.writeToBuffer();
			
			final fromBufferTrue = MsgCreateVestingAccount.fromBuffer(bufferTrue);
			final fromBufferFalse = MsgCreateVestingAccount.fromBuffer(bufferFalse);
			
			expect(fromBufferTrue.delayed, true);
			expect(fromBufferFalse.delayed, false);
		});
		
		test('long addresses', () {
			final longFromAddress = 'cosmos1' + 'a' * 100; // Very long address
			final longToAddress = 'cosmos1' + 'b' * 100;
			
			final msg = MsgCreateVestingAccount(
				fromAddress: longFromAddress,
				toAddress: longToAddress,
			);
			
			expect(msg.fromAddress.length, 107); // cosmos1 + 100 chars
			expect(msg.toAddress.length, 107);
			
			final buffer = msg.writeToBuffer();
			final fromBuffer = MsgCreateVestingAccount.fromBuffer(buffer);
			expect(fromBuffer.fromAddress, longFromAddress);
			expect(fromBuffer.toAddress, longToAddress);
		});
		
		test('large amount list', () {
			final msg = MsgCreateVestingAccount();
			
			// Add many different denominations
			for (int i = 0; i < 50; i++) {
				msg.amount.add(CosmosCoin(
					denom: 'denom$i',
					amount: '${(i + 1) * 1000000}',
				));
			}
			
			expect(msg.amount.length, 50);
			expect(msg.amount[0].denom, 'denom0');
			expect(msg.amount[0].amount, '1000000');
			expect(msg.amount[49].denom, 'denom49');
			expect(msg.amount[49].amount, '50000000');
			
			final buffer = msg.writeToBuffer();
			final fromBuffer = MsgCreateVestingAccount.fromBuffer(buffer);
			expect(fromBuffer.amount.length, 50);
			expect(fromBuffer.amount[25].denom, 'denom25');
			expect(fromBuffer.amount[25].amount, '26000000');
		});
		
		test('edge case coin amounts', () {
			final msg = MsgCreateVestingAccount();
			
			// Test various edge case amounts
			msg.amount.addAll([
				CosmosCoin(denom: 'zero', amount: '0'),
				CosmosCoin(denom: 'one', amount: '1'),
				CosmosCoin(denom: 'max', amount: '999999999999999999999999999999'),
				CosmosCoin(denom: 'decimal', amount: '123.456789'),
				CosmosCoin(denom: 'scientific', amount: '1.23e+18'),
			]);
			
			final buffer = msg.writeToBuffer();
			final fromBuffer = MsgCreateVestingAccount.fromBuffer(buffer);
			
			expect(fromBuffer.amount.length, 5);
			expect(fromBuffer.amount[0].amount, '0');
			expect(fromBuffer.amount[1].amount, '1');
			expect(fromBuffer.amount[2].amount, '999999999999999999999999999999');
			expect(fromBuffer.amount[3].amount, '123.456789');
			expect(fromBuffer.amount[4].amount, '1.23e+18');
		});
	});
	
	group('cosmos.vesting.v1beta1 MsgCreateVestingAccountResponse', () {
		test('default constructor', () {
			final response = MsgCreateVestingAccountResponse();
			
			// Response message has no fields, so just test basic functionality
			expect(response, isA<MsgCreateVestingAccountResponse>());
		});
		
		test('clone operation', () {
			final original = MsgCreateVestingAccountResponse();
			final cloned = original.clone();
			
			expect(cloned, isA<MsgCreateVestingAccountResponse>());
			expect(identical(original, cloned), isFalse);
		});
		
		test('copyWith operation', () {
			final original = MsgCreateVestingAccountResponse();
			final copied = original.copyWith((response) {
				// No fields to modify, but test the operation works
			});
			
			expect(copied, isA<MsgCreateVestingAccountResponse>());
			expect(identical(original, copied), isFalse);
		});
		
		test('JSON serialization and deserialization', () {
			final response = MsgCreateVestingAccountResponse();
			
			final json = jsonEncode(response.writeToJsonMap());
			final fromJson = MsgCreateVestingAccountResponse.fromJson(json);
			
			expect(fromJson, isA<MsgCreateVestingAccountResponse>());
		});
		
		test('binary serialization and deserialization', () {
			final response = MsgCreateVestingAccountResponse();
			
			final buffer = response.writeToBuffer();
			final fromBuffer = MsgCreateVestingAccountResponse.fromBuffer(buffer);
			
			expect(fromBuffer, isA<MsgCreateVestingAccountResponse>());
		});
		
		test('getDefault returns same instance', () {
			final default1 = MsgCreateVestingAccountResponse.getDefault();
			final default2 = MsgCreateVestingAccountResponse.getDefault();
			expect(identical(default1, default2), isTrue);
		});
		
		test('createEmptyInstance creates new instance', () {
			final response = MsgCreateVestingAccountResponse();
			final empty = response.createEmptyInstance();
			expect(empty, isA<MsgCreateVestingAccountResponse>());
			expect(identical(response, empty), isFalse);
		});
		
		test('createRepeated creates PbList', () {
			final list = MsgCreateVestingAccountResponse.createRepeated();
			expect(list, isA<pb.PbList<MsgCreateVestingAccountResponse>>());
			expect(list, isEmpty);
			
			list.add(MsgCreateVestingAccountResponse());
			expect(list.length, 1);
		});
		
		test('info_ returns BuilderInfo', () {
			final response = MsgCreateVestingAccountResponse();
			final info = response.info_;
			expect(info, isA<pb.BuilderInfo>());
			expect(info.qualifiedMessageName, contains('MsgCreateVestingAccountResponse'));
		});
	});
	
	group('cosmos.vesting.v1beta1 error handling', () {
		test('invalid buffer deserialization', () {
			expect(() => MsgCreateVestingAccount.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => MsgCreateVestingAccountResponse.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			expect(() => MsgCreateVestingAccount.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => MsgCreateVestingAccountResponse.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('cosmos.vesting.v1beta1 comprehensive coverage', () {
		test('all message types have proper info_', () {
			expect(MsgCreateVestingAccount().info_, isA<pb.BuilderInfo>());
			expect(MsgCreateVestingAccountResponse().info_, isA<pb.BuilderInfo>());
		});
		
		test('all message types support createEmptyInstance', () {
			expect(MsgCreateVestingAccount().createEmptyInstance(), isA<MsgCreateVestingAccount>());
			expect(MsgCreateVestingAccountResponse().createEmptyInstance(), isA<MsgCreateVestingAccountResponse>());
		});
		
		test('getDefault returns same instance for all types', () {
			expect(identical(MsgCreateVestingAccount.getDefault(), MsgCreateVestingAccount.getDefault()), isTrue);
			expect(identical(MsgCreateVestingAccountResponse.getDefault(), MsgCreateVestingAccountResponse.getDefault()), isTrue);
		});
		
		test('complete vesting account creation flow', () {
			// Test a complete flow of creating a vesting account
			
			// 1. Continuous vesting account (delayed = false)
			final continuousMsg = MsgCreateVestingAccount(
				fromAddress: 'cosmos1creator123456789abcdef',
				toAddress: 'cosmos1recipient987654321fedcba',
				amount: [
					CosmosCoin(denom: 'stake', amount: '10000000000'), // 10,000 STAKE
					CosmosCoin(denom: 'atom', amount: '5000000000'),   // 5,000 ATOM
				],
				endTime: Int64(1735689600), // 2025-01-01 00:00:00 UTC
				delayed: false, // Continuous vesting
			);
			
			// 2. Delayed vesting account (delayed = true)
			final delayedMsg = MsgCreateVestingAccount(
				fromAddress: 'cosmos1delayedcreator',
				toAddress: 'cosmos1delayedrecipient',
				amount: [
					CosmosCoin(denom: 'stake', amount: '1000000000'), // 1,000 STAKE
				],
				endTime: Int64(1767225600), // 2026-01-01 00:00:00 UTC
				delayed: true, // Delayed vesting
			);
			
			// Test JSON roundtrip for both
			final continuousJson = jsonEncode(continuousMsg.writeToJsonMap());
			final delayedJson = jsonEncode(delayedMsg.writeToJsonMap());
			
			final continuousFromJson = MsgCreateVestingAccount.fromJson(continuousJson);
			final delayedFromJson = MsgCreateVestingAccount.fromJson(delayedJson);
			
			// Verify continuous vesting
			expect(continuousFromJson.fromAddress, 'cosmos1creator123456789abcdef');
			expect(continuousFromJson.toAddress, 'cosmos1recipient987654321fedcba');
			expect(continuousFromJson.amount.length, 2);
			expect(continuousFromJson.amount[0].denom, 'stake');
			expect(continuousFromJson.amount[0].amount, '10000000000');
			expect(continuousFromJson.amount[1].denom, 'atom');
			expect(continuousFromJson.amount[1].amount, '5000000000');
			expect(continuousFromJson.endTime, Int64(1735689600));
			expect(continuousFromJson.delayed, false);
			
			// Verify delayed vesting
			expect(delayedFromJson.fromAddress, 'cosmos1delayedcreator');
			expect(delayedFromJson.toAddress, 'cosmos1delayedrecipient');
			expect(delayedFromJson.amount.length, 1);
			expect(delayedFromJson.amount[0].denom, 'stake');
			expect(delayedFromJson.amount[0].amount, '1000000000');
			expect(delayedFromJson.endTime, Int64(1767225600));
			expect(delayedFromJson.delayed, true);
			
			// Test buffer roundtrip
			final continuousBuffer = continuousMsg.writeToBuffer();
			final delayedBuffer = delayedMsg.writeToBuffer();
			
			final continuousFromBuffer = MsgCreateVestingAccount.fromBuffer(continuousBuffer);
			final delayedFromBuffer = MsgCreateVestingAccount.fromBuffer(delayedBuffer);
			
			expect(continuousFromBuffer.fromAddress, 'cosmos1creator123456789abcdef');
			expect(continuousFromBuffer.amount.length, 2);
			expect(continuousFromBuffer.delayed, false);
			
			expect(delayedFromBuffer.fromAddress, 'cosmos1delayedcreator');
			expect(delayedFromBuffer.amount.length, 1);
			expect(delayedFromBuffer.delayed, true);
			
			// Test response messages
			final continuousResponse = MsgCreateVestingAccountResponse();
			final delayedResponse = MsgCreateVestingAccountResponse();
			
			expect(continuousResponse, isA<MsgCreateVestingAccountResponse>());
			expect(delayedResponse, isA<MsgCreateVestingAccountResponse>());
			
			// Test response serialization
			final responseBuffer = continuousResponse.writeToBuffer();
			final responseFromBuffer = MsgCreateVestingAccountResponse.fromBuffer(responseBuffer);
			expect(responseFromBuffer, isA<MsgCreateVestingAccountResponse>());
		});
		
		test('field presence and default behavior', () {
			final msg = MsgCreateVestingAccount();
			
			// Test initial state (no fields set)
			expect(msg.hasFromAddress(), false);
			expect(msg.hasToAddress(), false);
			expect(msg.hasEndTime(), false);
			expect(msg.hasDelayed(), false);
			
			// Test default values
			expect(msg.fromAddress, '');
			expect(msg.toAddress, '');
			expect(msg.endTime, Int64.ZERO);
			expect(msg.delayed, false);
			expect(msg.amount, isEmpty);
			
			// Set fields and verify presence
			msg.fromAddress = 'cosmos1test';
			msg.toAddress = 'cosmos1recipient';
			msg.endTime = Int64(1);
			msg.delayed = true;
			
			expect(msg.hasFromAddress(), true);
			expect(msg.hasToAddress(), true);
			expect(msg.hasEndTime(), true);
			expect(msg.hasDelayed(), true);
			
			// Clear fields and verify absence
			msg.clearFromAddress();
			msg.clearToAddress();
			msg.clearEndTime();
			msg.clearDelayed();
			
			expect(msg.hasFromAddress(), false);
			expect(msg.hasToAddress(), false);
			expect(msg.hasEndTime(), false);
			expect(msg.hasDelayed(), false);
			
			// Values should return to defaults
			expect(msg.fromAddress, '');
			expect(msg.toAddress, '');
			expect(msg.endTime, Int64.ZERO);
			expect(msg.delayed, false);
		});
		
		test('timestamp edge cases', () {
			final timestamps = [
				Int64(0),                        // Unix epoch
				Int64(1),                        // One second after epoch
				Int64(1577836800),               // 2020-01-01 00:00:00 UTC
				Int64(1735689600),               // 2025-01-01 00:00:00 UTC
				Int64(2147483647),               // Year 2038 problem (32-bit)
				Int64.parseInt('9223372036854775807'), // Max Int64
			];
			
			for (final timestamp in timestamps) {
				final msg = MsgCreateVestingAccount(
					fromAddress: 'cosmos1test',
					toAddress: 'cosmos1recipient',
					endTime: timestamp,
				);
				
				final buffer = msg.writeToBuffer();
				final restored = MsgCreateVestingAccount.fromBuffer(buffer);
				
				expect(restored.endTime, timestamp);
				expect(restored.endTime.toString(), timestamp.toString());
			}
		});
	});
} 