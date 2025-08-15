import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/vesting/v1beta1/vesting.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/auth.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';

void main() {
	group('cosmos.vesting.v1beta1 BaseVestingAccount', () {
		test('constructor with all parameters', () {
			final baseAccount = BaseAccount(
				address: 'cosmos1abc123',
				accountNumber: Int64(42),
				sequence: Int64(1),
			);
			final originalVesting = [
				CosmosCoin(denom: 'stake', amount: '1000000'),
				CosmosCoin(denom: 'atom', amount: '500000'),
			];
			final delegatedFree = [CosmosCoin(denom: 'stake', amount: '100000')];
			final delegatedVesting = [CosmosCoin(denom: 'atom', amount: '50000')];
			
			final vestingAccount = BaseVestingAccount(
				baseAccount: baseAccount,
				originalVesting: originalVesting,
				delegatedFree: delegatedFree,
				delegatedVesting: delegatedVesting,
				endTime: Int64(1735689600), // 2025-01-01 00:00:00 UTC
			);
			
			expect(vestingAccount.hasBaseAccount(), true);
			expect(vestingAccount.baseAccount.address, 'cosmos1abc123');
			expect(vestingAccount.baseAccount.accountNumber, Int64(42));
			expect(vestingAccount.baseAccount.sequence, Int64(1));
			
			expect(vestingAccount.originalVesting.length, 2);
			expect(vestingAccount.originalVesting[0].denom, 'stake');
			expect(vestingAccount.originalVesting[0].amount, '1000000');
			expect(vestingAccount.originalVesting[1].denom, 'atom');
			expect(vestingAccount.originalVesting[1].amount, '500000');
			
			expect(vestingAccount.delegatedFree.length, 1);
			expect(vestingAccount.delegatedFree[0].denom, 'stake');
			expect(vestingAccount.delegatedFree[0].amount, '100000');
			
			expect(vestingAccount.delegatedVesting.length, 1);
			expect(vestingAccount.delegatedVesting[0].denom, 'atom');
			expect(vestingAccount.delegatedVesting[0].amount, '50000');
			
			expect(vestingAccount.endTime, Int64(1735689600));
		});
		
		test('constructor with partial parameters', () {
			final baseAccount = BaseAccount(address: 'cosmos1partial');
			
			final vestingAccount = BaseVestingAccount(
				baseAccount: baseAccount,
				endTime: Int64(1640995200), // 2022-01-01 00:00:00 UTC
			);
			
			expect(vestingAccount.hasBaseAccount(), true);
			expect(vestingAccount.baseAccount.address, 'cosmos1partial');
			expect(vestingAccount.originalVesting, isEmpty);
			expect(vestingAccount.delegatedFree, isEmpty);
			expect(vestingAccount.delegatedVesting, isEmpty);
			expect(vestingAccount.endTime, Int64(1640995200));
		});
		
		test('default constructor', () {
			final vestingAccount = BaseVestingAccount();
			
			expect(vestingAccount.hasBaseAccount(), false);
			expect(vestingAccount.originalVesting, isEmpty);
			expect(vestingAccount.delegatedFree, isEmpty);
			expect(vestingAccount.delegatedVesting, isEmpty);
			expect(vestingAccount.endTime, Int64.ZERO);
		});
		
		test('has/clear/ensure operations', () {
			final vestingAccount = BaseVestingAccount();
			
			// Test baseAccount
			expect(vestingAccount.hasBaseAccount(), false);
			final baseAccount = vestingAccount.ensureBaseAccount();
			expect(vestingAccount.hasBaseAccount(), true);
			expect(baseAccount, isA<BaseAccount>());
			
			vestingAccount.clearBaseAccount();
			expect(vestingAccount.hasBaseAccount(), false);
			
			// Test endTime
			vestingAccount.endTime = Int64(1609459200);
			expect(vestingAccount.hasEndTime(), true);
			expect(vestingAccount.endTime, Int64(1609459200));
			
			vestingAccount.clearEndTime();
			expect(vestingAccount.hasEndTime(), false);
			expect(vestingAccount.endTime, Int64.ZERO);
		});
		
		test('coin lists operations', () {
			final vestingAccount = BaseVestingAccount();
			
			// Test originalVesting
			expect(vestingAccount.originalVesting, isEmpty);
			
			final coin1 = CosmosCoin(denom: 'stake', amount: '1000');
			final coin2 = CosmosCoin(denom: 'atom', amount: '2000');
			
			vestingAccount.originalVesting.addAll([coin1, coin2]);
			expect(vestingAccount.originalVesting.length, 2);
			expect(vestingAccount.originalVesting[0].denom, 'stake');
			expect(vestingAccount.originalVesting[1].denom, 'atom');
			
			vestingAccount.originalVesting.removeAt(0);
			expect(vestingAccount.originalVesting.length, 1);
			expect(vestingAccount.originalVesting[0].denom, 'atom');
			
			// Test delegatedFree
			final freeCoin = CosmosCoin(denom: 'free', amount: '500');
			vestingAccount.delegatedFree.add(freeCoin);
			expect(vestingAccount.delegatedFree.length, 1);
			expect(vestingAccount.delegatedFree[0].denom, 'free');
			
			// Test delegatedVesting
			final vestingCoin = CosmosCoin(denom: 'vesting', amount: '300');
			vestingAccount.delegatedVesting.add(vestingCoin);
			expect(vestingAccount.delegatedVesting.length, 1);
			expect(vestingAccount.delegatedVesting[0].denom, 'vesting');
			
			// Clear all lists
			vestingAccount.originalVesting.clear();
			vestingAccount.delegatedFree.clear();
			vestingAccount.delegatedVesting.clear();
			
			expect(vestingAccount.originalVesting, isEmpty);
			expect(vestingAccount.delegatedFree, isEmpty);
			expect(vestingAccount.delegatedVesting, isEmpty);
		});
		
		test('clone operation', () {
			final original = BaseVestingAccount();
			original.ensureBaseAccount();
			original.baseAccount.address = 'cosmos1original';
			original.originalVesting.add(CosmosCoin(denom: 'stake', amount: '1000'));
			original.endTime = Int64(1234567890);
			
			final cloned = original.clone();
			expect(cloned.hasBaseAccount(), true);
			expect(cloned.baseAccount.address, 'cosmos1original');
			expect(cloned.originalVesting.length, 1);
			expect(cloned.originalVesting[0].denom, 'stake');
			expect(cloned.endTime, Int64(1234567890));
			
			// Verify independence
			cloned.baseAccount.address = 'cosmos1cloned';
			cloned.originalVesting.add(CosmosCoin(denom: 'atom', amount: '2000'));
			cloned.endTime = Int64(9876543210);
			
			expect(cloned.baseAccount.address, 'cosmos1cloned');
			expect(cloned.originalVesting.length, 2);
			expect(cloned.endTime, Int64(9876543210));
			
			expect(original.baseAccount.address, 'cosmos1original');
			expect(original.originalVesting.length, 1);
			expect(original.endTime, Int64(1234567890));
		});
		
		test('copyWith operation', () {
			final original = BaseVestingAccount();
			original.ensureBaseAccount();
			original.baseAccount.address = 'cosmos1test';
			original.endTime = Int64(1000000);
			
			final copied = original.clone().copyWith((account) {
				account.baseAccount.address = 'cosmos1copied';
				account.endTime = Int64(2000000);
			});
			
			expect(copied.baseAccount.address, 'cosmos1copied');
			expect(copied.endTime, Int64(2000000));
			expect(original.baseAccount.address, 'cosmos1test'); // original unchanged
			expect(original.endTime, Int64(1000000));
		});
		
		test('JSON and buffer serialization', () {
			final vestingAccount = BaseVestingAccount();
			vestingAccount.ensureBaseAccount();
			vestingAccount.baseAccount.address = 'cosmos1json';
			vestingAccount.originalVesting.add(CosmosCoin(denom: 'stake', amount: '5000'));
			vestingAccount.endTime = Int64(1577836800); // 2020-01-01 00:00:00 UTC
			
			final json = jsonEncode(vestingAccount.writeToJsonMap());
			final fromJson = BaseVestingAccount.fromJson(json);
			expect(fromJson.hasBaseAccount(), true);
			expect(fromJson.baseAccount.address, 'cosmos1json');
			expect(fromJson.originalVesting.length, 1);
			expect(fromJson.originalVesting[0].denom, 'stake');
			expect(fromJson.originalVesting[0].amount, '5000');
			expect(fromJson.endTime, Int64(1577836800));
			
			final buffer = vestingAccount.writeToBuffer();
			final fromBuffer = BaseVestingAccount.fromBuffer(buffer);
			expect(fromBuffer.hasBaseAccount(), true);
			expect(fromBuffer.baseAccount.address, 'cosmos1json');
			expect(fromBuffer.originalVesting.length, 1);
			expect(fromBuffer.originalVesting[0].denom, 'stake');
			expect(fromBuffer.endTime, Int64(1577836800));
		});
		
		test('large endTime values', () {
			final vestingAccount = BaseVestingAccount(
				endTime: Int64.parseInt('9223372036854775807'), // max int64
			);
			
			expect(vestingAccount.endTime.toString(), '9223372036854775807');
			
			final buffer = vestingAccount.writeToBuffer();
			final fromBuffer = BaseVestingAccount.fromBuffer(buffer);
			expect(fromBuffer.endTime.toString(), '9223372036854775807');
		});
	});
	
	group('cosmos.vesting.v1beta1 ContinuousVestingAccount', () {
		test('constructor with all parameters', () {
			final baseVestingAccount = BaseVestingAccount();
			baseVestingAccount.ensureBaseAccount();
			baseVestingAccount.baseAccount.address = 'cosmos1continuous';
			baseVestingAccount.endTime = Int64(1735689600);
			
			final continuousAccount = ContinuousVestingAccount(
				baseVestingAccount: baseVestingAccount,
				startTime: Int64(1672531200), // 2023-01-01 00:00:00 UTC
			);
			
			expect(continuousAccount.hasBaseVestingAccount(), true);
			expect(continuousAccount.baseVestingAccount.baseAccount.address, 'cosmos1continuous');
			expect(continuousAccount.baseVestingAccount.endTime, Int64(1735689600));
			expect(continuousAccount.startTime, Int64(1672531200));
		});
		
		test('default constructor', () {
			final continuousAccount = ContinuousVestingAccount();
			
			expect(continuousAccount.hasBaseVestingAccount(), false);
			expect(continuousAccount.startTime, Int64.ZERO);
		});
		
		test('has/clear/ensure operations', () {
			final continuousAccount = ContinuousVestingAccount();
			
			// Test baseVestingAccount
			expect(continuousAccount.hasBaseVestingAccount(), false);
			final baseVesting = continuousAccount.ensureBaseVestingAccount();
			expect(continuousAccount.hasBaseVestingAccount(), true);
			expect(baseVesting, isA<BaseVestingAccount>());
			
			continuousAccount.clearBaseVestingAccount();
			expect(continuousAccount.hasBaseVestingAccount(), false);
			
			// Test startTime
			continuousAccount.startTime = Int64(1640995200);
			expect(continuousAccount.hasStartTime(), true);
			expect(continuousAccount.startTime, Int64(1640995200));
			
			continuousAccount.clearStartTime();
			expect(continuousAccount.hasStartTime(), false);
			expect(continuousAccount.startTime, Int64.ZERO);
		});
		
		test('JSON and buffer serialization', () {
			final continuousAccount = ContinuousVestingAccount();
			continuousAccount.ensureBaseVestingAccount();
			continuousAccount.baseVestingAccount.ensureBaseAccount();
			continuousAccount.baseVestingAccount.baseAccount.address = 'cosmos1test';
			continuousAccount.startTime = Int64(1609459200);
			
			final json = jsonEncode(continuousAccount.writeToJsonMap());
			final fromJson = ContinuousVestingAccount.fromJson(json);
			expect(fromJson.hasBaseVestingAccount(), true);
			expect(fromJson.baseVestingAccount.baseAccount.address, 'cosmos1test');
			expect(fromJson.startTime, Int64(1609459200));
			
			final buffer = continuousAccount.writeToBuffer();
			final fromBuffer = ContinuousVestingAccount.fromBuffer(buffer);
			expect(fromBuffer.hasBaseVestingAccount(), true);
			expect(fromBuffer.startTime, Int64(1609459200));
		});
	});
	
	group('cosmos.vesting.v1beta1 DelayedVestingAccount', () {
		test('constructor with baseVestingAccount', () {
			final baseVestingAccount = BaseVestingAccount();
			baseVestingAccount.ensureBaseAccount();
			baseVestingAccount.baseAccount.address = 'cosmos1delayed';
			baseVestingAccount.endTime = Int64(1735689600);
			
			final delayedAccount = DelayedVestingAccount(
				baseVestingAccount: baseVestingAccount,
			);
			
			expect(delayedAccount.hasBaseVestingAccount(), true);
			expect(delayedAccount.baseVestingAccount.baseAccount.address, 'cosmos1delayed');
			expect(delayedAccount.baseVestingAccount.endTime, Int64(1735689600));
		});
		
		test('default constructor', () {
			final delayedAccount = DelayedVestingAccount();
			
			expect(delayedAccount.hasBaseVestingAccount(), false);
		});
		
		test('has/clear/ensure operations', () {
			final delayedAccount = DelayedVestingAccount();
			
			expect(delayedAccount.hasBaseVestingAccount(), false);
			final baseVesting = delayedAccount.ensureBaseVestingAccount();
			expect(delayedAccount.hasBaseVestingAccount(), true);
			expect(baseVesting, isA<BaseVestingAccount>());
			
			delayedAccount.clearBaseVestingAccount();
			expect(delayedAccount.hasBaseVestingAccount(), false);
		});
	});
	
	group('cosmos.vesting.v1beta1 Period', () {
		test('constructor with all parameters', () {
			final amount = [
				CosmosCoin(denom: 'stake', amount: '1000000'),
				CosmosCoin(denom: 'atom', amount: '500000'),
			];
			
			final period = Period(
				length: Int64(2592000), // 30 days in seconds
				amount: amount,
			);
			
			expect(period.length, Int64(2592000));
			expect(period.amount.length, 2);
			expect(period.amount[0].denom, 'stake');
			expect(period.amount[0].amount, '1000000');
			expect(period.amount[1].denom, 'atom');
			expect(period.amount[1].amount, '500000');
		});
		
		test('default constructor', () {
			final period = Period();
			
			expect(period.length, Int64.ZERO);
			expect(period.amount, isEmpty);
		});
		
		test('has/clear operations', () {
			final period = Period(length: Int64(86400)); // 1 day
			
			expect(period.hasLength(), true);
			expect(period.length, Int64(86400));
			
			period.clearLength();
			expect(period.hasLength(), false);
			expect(period.length, Int64.ZERO);
		});
		
		test('amount list operations', () {
			final period = Period();
			
			expect(period.amount, isEmpty);
			
			final coin1 = CosmosCoin(denom: 'period1', amount: '1000');
			final coin2 = CosmosCoin(denom: 'period2', amount: '2000');
			
			period.amount.addAll([coin1, coin2]);
			expect(period.amount.length, 2);
			expect(period.amount[0].denom, 'period1');
			expect(period.amount[1].denom, 'period2');
			
			period.amount.removeAt(0);
			expect(period.amount.length, 1);
			expect(period.amount[0].denom, 'period2');
			
			period.amount.clear();
			expect(period.amount, isEmpty);
		});
		
		test('JSON and buffer serialization', () {
			final period = Period(
				length: Int64(604800), // 1 week
				amount: [CosmosCoin(denom: 'test', amount: '12345')],
			);
			
			final json = jsonEncode(period.writeToJsonMap());
			final fromJson = Period.fromJson(json);
			expect(fromJson.length, Int64(604800));
			expect(fromJson.amount.length, 1);
			expect(fromJson.amount[0].denom, 'test');
			expect(fromJson.amount[0].amount, '12345');
			
			final buffer = period.writeToBuffer();
			final fromBuffer = Period.fromBuffer(buffer);
			expect(fromBuffer.length, Int64(604800));
			expect(fromBuffer.amount.length, 1);
			expect(fromBuffer.amount[0].denom, 'test');
		});
	});
	
	group('cosmos.vesting.v1beta1 PeriodicVestingAccount', () {
		test('constructor with all parameters', () {
			final baseVestingAccount = BaseVestingAccount();
			baseVestingAccount.ensureBaseAccount();
			baseVestingAccount.baseAccount.address = 'cosmos1periodic';
			
			final periods = [
				Period(length: Int64(2592000), amount: [CosmosCoin(denom: 'stake', amount: '500000')]),
				Period(length: Int64(2592000), amount: [CosmosCoin(denom: 'stake', amount: '500000')]),
			];
			
			final periodicAccount = PeriodicVestingAccount(
				baseVestingAccount: baseVestingAccount,
				startTime: Int64(1672531200),
				vestingPeriods: periods,
			);
			
			expect(periodicAccount.hasBaseVestingAccount(), true);
			expect(periodicAccount.baseVestingAccount.baseAccount.address, 'cosmos1periodic');
			expect(periodicAccount.startTime, Int64(1672531200));
			expect(periodicAccount.vestingPeriods.length, 2);
			expect(periodicAccount.vestingPeriods[0].length, Int64(2592000));
			expect(periodicAccount.vestingPeriods[0].amount[0].denom, 'stake');
			expect(periodicAccount.vestingPeriods[1].length, Int64(2592000));
		});
		
		test('default constructor', () {
			final periodicAccount = PeriodicVestingAccount();
			
			expect(periodicAccount.hasBaseVestingAccount(), false);
			expect(periodicAccount.startTime, Int64.ZERO);
			expect(periodicAccount.vestingPeriods, isEmpty);
		});
		
		test('has/clear/ensure operations', () {
			final periodicAccount = PeriodicVestingAccount();
			
			// Test baseVestingAccount
			expect(periodicAccount.hasBaseVestingAccount(), false);
			final baseVesting = periodicAccount.ensureBaseVestingAccount();
			expect(periodicAccount.hasBaseVestingAccount(), true);
			expect(baseVesting, isA<BaseVestingAccount>());
			
			periodicAccount.clearBaseVestingAccount();
			expect(periodicAccount.hasBaseVestingAccount(), false);
			
			// Test startTime
			periodicAccount.startTime = Int64(1640995200);
			expect(periodicAccount.hasStartTime(), true);
			expect(periodicAccount.startTime, Int64(1640995200));
			
			periodicAccount.clearStartTime();
			expect(periodicAccount.hasStartTime(), false);
			expect(periodicAccount.startTime, Int64.ZERO);
		});
		
		test('vestingPeriods list operations', () {
			final periodicAccount = PeriodicVestingAccount();
			
			expect(periodicAccount.vestingPeriods, isEmpty);
			
			final period1 = Period(length: Int64(86400), amount: [CosmosCoin(denom: 'day1', amount: '1000')]);
			final period2 = Period(length: Int64(172800), amount: [CosmosCoin(denom: 'day2', amount: '2000')]);
			
			periodicAccount.vestingPeriods.addAll([period1, period2]);
			expect(periodicAccount.vestingPeriods.length, 2);
			expect(periodicAccount.vestingPeriods[0].length, Int64(86400));
			expect(periodicAccount.vestingPeriods[1].length, Int64(172800));
			
			periodicAccount.vestingPeriods.removeAt(0);
			expect(periodicAccount.vestingPeriods.length, 1);
			expect(periodicAccount.vestingPeriods[0].length, Int64(172800));
			
			periodicAccount.vestingPeriods.clear();
			expect(periodicAccount.vestingPeriods, isEmpty);
		});
		
		test('complex periodic vesting structure', () {
			final periodicAccount = PeriodicVestingAccount();
			
			// Setup base vesting account
			periodicAccount.ensureBaseVestingAccount();
			periodicAccount.baseVestingAccount.ensureBaseAccount();
			periodicAccount.baseVestingAccount.baseAccount.address = 'cosmos1complex';
			periodicAccount.baseVestingAccount.originalVesting.add(
				CosmosCoin(denom: 'stake', amount: '10000000')
			);
			periodicAccount.baseVestingAccount.endTime = Int64(1735689600);
			
			// Setup periodic vesting
			periodicAccount.startTime = Int64(1672531200);
			
			// Create 12 monthly periods
			for (int i = 0; i < 12; i++) {
				final period = Period(
					length: Int64(2592000), // ~30 days
					amount: [CosmosCoin(denom: 'stake', amount: '833333')], // ~10M/12
				);
				periodicAccount.vestingPeriods.add(period);
			}
			
			expect(periodicAccount.vestingPeriods.length, 12);
			expect(periodicAccount.vestingPeriods[0].amount[0].amount, '833333');
			expect(periodicAccount.vestingPeriods[11].amount[0].amount, '833333');
			
			// Test serialization of complex structure
			final buffer = periodicAccount.writeToBuffer();
			final fromBuffer = PeriodicVestingAccount.fromBuffer(buffer);
			
			expect(fromBuffer.hasBaseVestingAccount(), true);
			expect(fromBuffer.baseVestingAccount.baseAccount.address, 'cosmos1complex');
			expect(fromBuffer.baseVestingAccount.originalVesting.length, 1);
			expect(fromBuffer.baseVestingAccount.originalVesting[0].amount, '10000000');
			expect(fromBuffer.startTime, Int64(1672531200));
			expect(fromBuffer.vestingPeriods.length, 12);
			expect(fromBuffer.vestingPeriods[5].amount[0].amount, '833333');
		});
	});
	
	group('cosmos.vesting.v1beta1 PermanentLockedAccount', () {
		test('constructor with baseVestingAccount', () {
			final baseVestingAccount = BaseVestingAccount();
			baseVestingAccount.ensureBaseAccount();
			baseVestingAccount.baseAccount.address = 'cosmos1locked';
			baseVestingAccount.originalVesting.add(CosmosCoin(denom: 'stake', amount: '1000000'));
			
			final lockedAccount = PermanentLockedAccount(
				baseVestingAccount: baseVestingAccount,
			);
			
			expect(lockedAccount.hasBaseVestingAccount(), true);
			expect(lockedAccount.baseVestingAccount.baseAccount.address, 'cosmos1locked');
			expect(lockedAccount.baseVestingAccount.originalVesting.length, 1);
			expect(lockedAccount.baseVestingAccount.originalVesting[0].denom, 'stake');
		});
		
		test('default constructor', () {
			final lockedAccount = PermanentLockedAccount();
			
			expect(lockedAccount.hasBaseVestingAccount(), false);
		});
		
		test('has/clear/ensure operations', () {
			final lockedAccount = PermanentLockedAccount();
			
			expect(lockedAccount.hasBaseVestingAccount(), false);
			final baseVesting = lockedAccount.ensureBaseVestingAccount();
			expect(lockedAccount.hasBaseVestingAccount(), true);
			expect(baseVesting, isA<BaseVestingAccount>());
			
			lockedAccount.clearBaseVestingAccount();
			expect(lockedAccount.hasBaseVestingAccount(), false);
		});
		
		test('JSON and buffer serialization', () {
			final lockedAccount = PermanentLockedAccount();
			lockedAccount.ensureBaseVestingAccount();
			lockedAccount.baseVestingAccount.ensureBaseAccount();
			lockedAccount.baseVestingAccount.baseAccount.address = 'cosmos1permanent';
			lockedAccount.baseVestingAccount.originalVesting.add(
				CosmosCoin(denom: 'locked', amount: '5000000')
			);
			
			final json = jsonEncode(lockedAccount.writeToJsonMap());
			final fromJson = PermanentLockedAccount.fromJson(json);
			expect(fromJson.hasBaseVestingAccount(), true);
			expect(fromJson.baseVestingAccount.baseAccount.address, 'cosmos1permanent');
			expect(fromJson.baseVestingAccount.originalVesting.length, 1);
			expect(fromJson.baseVestingAccount.originalVesting[0].denom, 'locked');
			
			final buffer = lockedAccount.writeToBuffer();
			final fromBuffer = PermanentLockedAccount.fromBuffer(buffer);
			expect(fromBuffer.hasBaseVestingAccount(), true);
			expect(fromBuffer.baseVestingAccount.originalVesting[0].amount, '5000000');
		});
	});
	
	group('cosmos.vesting.v1beta1 error handling', () {
		test('invalid buffer deserialization', () {
			expect(() => BaseVestingAccount.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => ContinuousVestingAccount.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => DelayedVestingAccount.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => Period.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => PeriodicVestingAccount.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => PermanentLockedAccount.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			expect(() => BaseVestingAccount.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => ContinuousVestingAccount.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => DelayedVestingAccount.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => Period.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => PeriodicVestingAccount.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => PermanentLockedAccount.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('cosmos.vesting.v1beta1 comprehensive coverage', () {
		test('all message types have proper info_', () {
			expect(BaseVestingAccount().info_, isA<pb.BuilderInfo>());
			expect(ContinuousVestingAccount().info_, isA<pb.BuilderInfo>());
			expect(DelayedVestingAccount().info_, isA<pb.BuilderInfo>());
			expect(Period().info_, isA<pb.BuilderInfo>());
			expect(PeriodicVestingAccount().info_, isA<pb.BuilderInfo>());
			expect(PermanentLockedAccount().info_, isA<pb.BuilderInfo>());
		});
		
		test('all message types support createEmptyInstance', () {
			expect(BaseVestingAccount().createEmptyInstance(), isA<BaseVestingAccount>());
			expect(ContinuousVestingAccount().createEmptyInstance(), isA<ContinuousVestingAccount>());
			expect(DelayedVestingAccount().createEmptyInstance(), isA<DelayedVestingAccount>());
			expect(Period().createEmptyInstance(), isA<Period>());
			expect(PeriodicVestingAccount().createEmptyInstance(), isA<PeriodicVestingAccount>());
			expect(PermanentLockedAccount().createEmptyInstance(), isA<PermanentLockedAccount>());
		});
		
		test('getDefault returns same instance for all types', () {
			expect(identical(BaseVestingAccount.getDefault(), BaseVestingAccount.getDefault()), isTrue);
			expect(identical(ContinuousVestingAccount.getDefault(), ContinuousVestingAccount.getDefault()), isTrue);
			expect(identical(DelayedVestingAccount.getDefault(), DelayedVestingAccount.getDefault()), isTrue);
			expect(identical(Period.getDefault(), Period.getDefault()), isTrue);
			expect(identical(PeriodicVestingAccount.getDefault(), PeriodicVestingAccount.getDefault()), isTrue);
			expect(identical(PermanentLockedAccount.getDefault(), PermanentLockedAccount.getDefault()), isTrue);
		});
		
		test('complete vesting scenario roundtrip', () {
			// Create a complete vesting scenario with all account types
			
			// 1. Base vesting account
			final baseVesting = BaseVestingAccount();
			baseVesting.ensureBaseAccount();
			baseVesting.baseAccount.address = 'cosmos1vesting123';
			baseVesting.baseAccount.accountNumber = Int64(100);
			baseVesting.baseAccount.sequence = Int64(5);
			baseVesting.originalVesting.addAll([
				CosmosCoin(denom: 'stake', amount: '10000000'),
				CosmosCoin(denom: 'atom', amount: '5000000'),
			]);
			baseVesting.delegatedFree.add(CosmosCoin(denom: 'stake', amount: '1000000'));
			baseVesting.delegatedVesting.add(CosmosCoin(denom: 'atom', amount: '500000'));
			baseVesting.endTime = Int64(1735689600);
			
			// 2. Continuous vesting account
			final continuousVesting = ContinuousVestingAccount();
			continuousVesting.baseVestingAccount = baseVesting.clone();
			continuousVesting.startTime = Int64(1672531200);
			
			// 3. Periodic vesting account with multiple periods
			final periodicVesting = PeriodicVestingAccount();
			periodicVesting.baseVestingAccount = baseVesting.clone();
			periodicVesting.startTime = Int64(1672531200);
			
			// Add quarterly vesting periods
			for (int i = 0; i < 4; i++) {
				final period = Period(
					length: Int64(7776000), // ~90 days
					amount: [
						CosmosCoin(denom: 'stake', amount: '2500000'),
						CosmosCoin(denom: 'atom', amount: '1250000'),
					],
				);
				periodicVesting.vestingPeriods.add(period);
			}
			
			// Test JSON roundtrip for all account types
			final baseJson = jsonEncode(baseVesting.writeToJsonMap());
			final continuousJson = jsonEncode(continuousVesting.writeToJsonMap());
			final periodicJson = jsonEncode(periodicVesting.writeToJsonMap());
			
			final baseFromJson = BaseVestingAccount.fromJson(baseJson);
			final continuousFromJson = ContinuousVestingAccount.fromJson(continuousJson);
			final periodicFromJson = PeriodicVestingAccount.fromJson(periodicJson);
			
			// Verify base vesting account
			expect(baseFromJson.baseAccount.address, 'cosmos1vesting123');
			expect(baseFromJson.baseAccount.accountNumber, Int64(100));
			expect(baseFromJson.originalVesting.length, 2);
			expect(baseFromJson.originalVesting[0].denom, 'stake');
			expect(baseFromJson.originalVesting[0].amount, '10000000');
			expect(baseFromJson.delegatedFree.length, 1);
			expect(baseFromJson.delegatedVesting.length, 1);
			expect(baseFromJson.endTime, Int64(1735689600));
			
			// Verify continuous vesting account
			expect(continuousFromJson.hasBaseVestingAccount(), true);
			expect(continuousFromJson.baseVestingAccount.baseAccount.address, 'cosmos1vesting123');
			expect(continuousFromJson.startTime, Int64(1672531200));
			
			// Verify periodic vesting account
			expect(periodicFromJson.hasBaseVestingAccount(), true);
			expect(periodicFromJson.vestingPeriods.length, 4);
			expect(periodicFromJson.vestingPeriods[0].length, Int64(7776000));
			expect(periodicFromJson.vestingPeriods[0].amount.length, 2);
			expect(periodicFromJson.vestingPeriods[3].amount[0].amount, '2500000');
			
			// Test buffer roundtrip
			final baseBuffer = baseVesting.writeToBuffer();
			final periodicBuffer = periodicVesting.writeToBuffer();
			
			final baseFromBuffer = BaseVestingAccount.fromBuffer(baseBuffer);
			final periodicFromBuffer = PeriodicVestingAccount.fromBuffer(periodicBuffer);
			
			expect(baseFromBuffer.baseAccount.address, 'cosmos1vesting123');
			expect(baseFromBuffer.originalVesting.length, 2);
			expect(periodicFromBuffer.vestingPeriods.length, 4);
			expect(periodicFromBuffer.vestingPeriods[2].amount[1].denom, 'atom');
		});
		
		test('timestamp and duration edge cases', () {
			// Test various timestamp scenarios
			final scenarios = [
				{'start': Int64(0), 'end': Int64(1)}, // Unix epoch start
				{'start': Int64(1577836800), 'end': Int64(1609459200)}, // 2020-2021
				{'start': Int64(1672531200), 'end': Int64(2147483647)}, // Year 2038 problem
			];
			
			for (final scenario in scenarios) {
				final continuousAccount = ContinuousVestingAccount();
				continuousAccount.ensureBaseVestingAccount();
				continuousAccount.baseVestingAccount.endTime = scenario['end']!;
				continuousAccount.startTime = scenario['start']!;
				
				final buffer = continuousAccount.writeToBuffer();
				final restored = ContinuousVestingAccount.fromBuffer(buffer);
				
				expect(restored.startTime, scenario['start']);
				expect(restored.baseVestingAccount.endTime, scenario['end']);
			}
		});
		
		test('coin amount precision and edge cases', () {
			final baseVesting = BaseVestingAccount();
			
			// Test various coin amounts
			final testCoins = [
				CosmosCoin(denom: 'zero', amount: '0'),
				CosmosCoin(denom: 'one', amount: '1'),
				CosmosCoin(denom: 'large', amount: '999999999999999999999999999999'),
				CosmosCoin(denom: 'decimal', amount: '123.456789'),
				CosmosCoin(denom: 'scientific', amount: '1.23e+18'),
			];
			
			baseVesting.originalVesting.addAll(testCoins);
			
			final buffer = baseVesting.writeToBuffer();
			final restored = BaseVestingAccount.fromBuffer(buffer);
			
			expect(restored.originalVesting.length, 5);
			expect(restored.originalVesting[0].amount, '0');
			expect(restored.originalVesting[1].amount, '1');
			expect(restored.originalVesting[2].amount, '999999999999999999999999999999');
			expect(restored.originalVesting[3].amount, '123.456789');
			expect(restored.originalVesting[4].amount, '1.23e+18');
		});
	});
} 