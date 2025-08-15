import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/abci/types.pb.dart';

void main() {
	group('tendermint.abci ResponseEcho', () {
		test('constructor and basic operations', () {
			final response = ResponseEcho(message: 'echo response');
			
			expect(response.message, 'echo response');
			expect(response.hasMessage(), true);
			
			response.clearMessage();
			expect(response.hasMessage(), false);
			expect(response.message, '');
		});
		
		test('JSON and buffer serialization', () {
			final response = ResponseEcho(message: 'test echo');
			
			final json = jsonEncode(response.writeToJsonMap());
			final fromJson = ResponseEcho.fromJson(json);
			expect(fromJson.message, 'test echo');
			
			final buffer = response.writeToBuffer();
			final fromBuffer = ResponseEcho.fromBuffer(buffer);
			expect(fromBuffer.message, 'test echo');
		});
	});
	
	group('tendermint.abci ResponseFlush', () {
		test('empty message operations', () {
			final response = ResponseFlush();
			
			expect(response, isA<ResponseFlush>());
			
			final json = jsonEncode(response.writeToJsonMap());
			final fromJson = ResponseFlush.fromJson(json);
			expect(fromJson, isA<ResponseFlush>());
			
			final buffer = response.writeToBuffer();
			final fromBuffer = ResponseFlush.fromBuffer(buffer);
			expect(fromBuffer, isA<ResponseFlush>());
		});
	});
	
	group('tendermint.abci ResponseInfo', () {
		test('constructor with all parameters', () {
			final response = ResponseInfo(
				data: 'test application',
				version: '1.0.0',
				appVersion: Int64(1),
				lastBlockHeight: Int64(1000),
				lastBlockAppHash: Uint8List.fromList([1, 2, 3, 4, 5]),
			);
			
			expect(response.data, 'test application');
			expect(response.version, '1.0.0');
			expect(response.appVersion, Int64(1));
			expect(response.lastBlockHeight, Int64(1000));
			expect(response.lastBlockAppHash, [1, 2, 3, 4, 5]);
		});
		
		test('has/clear operations', () {
			final response = ResponseInfo(
				data: 'app data',
				version: '2.0.0',
				appVersion: Int64(2),
			);
			
			expect(response.hasData(), true);
			expect(response.hasVersion(), true);
			expect(response.hasAppVersion(), true);
			
			response.clearData();
			response.clearVersion();
			response.clearAppVersion();
			
			expect(response.hasData(), false);
			expect(response.hasVersion(), false);
			expect(response.hasAppVersion(), false);
		});
	});
	
	group('tendermint.abci ResponseSetOption', () {
		test('constructor with success', () {
			final response = ResponseSetOption(
				code: 0,
				log: 'option set successfully',
				info: 'consensus.timeout_commit updated',
			);
			
			expect(response.code, 0);
			expect(response.log, 'option set successfully');
			expect(response.info, 'consensus.timeout_commit updated');
		});
		
		test('constructor with error', () {
			final response = ResponseSetOption(
				code: 1,
				log: 'invalid option key',
				info: 'key not recognized',
			);
			
			expect(response.code, 1);
			expect(response.log, 'invalid option key');
			expect(response.info, 'key not recognized');
		});
	});
	
	group('tendermint.abci ResponseInitChain', () {
		test('constructor with validators', () {
			final validators = [
				ValidatorUpdate(power: Int64(1000000)),
				ValidatorUpdate(power: Int64(2000000)),
			];
			
			final response = ResponseInitChain(
				consensusParams: ConsensusParams(),
				validators: validators,
				appHash: Uint8List.fromList([10, 20, 30]),
			);
			
			expect(response.hasConsensusParams(), true);
			expect(response.validators.length, 2);
			expect(response.appHash, [10, 20, 30]);
		});
		
		test('validators management', () {
			final response = ResponseInitChain();
			
			expect(response.validators, isEmpty);
			
			final validator1 = ValidatorUpdate(power: Int64(500000));
			response.validators.add(validator1);
			expect(response.validators.length, 1);
			
			response.validators.clear();
			expect(response.validators, isEmpty);
		});
	});
	
	group('tendermint.abci ResponseQuery', () {
		test('constructor with success', () {
			final response = ResponseQuery(
				code: 0,
				log: 'query successful',
				key: Uint8List.fromList([1, 2, 3]),
				value: Uint8List.fromList([10, 20, 30]),
				height: Int64(1000),
			);
			
			expect(response.code, 0);
			expect(response.log, 'query successful');
			expect(response.key, [1, 2, 3]);
			expect(response.value, [10, 20, 30]);
			expect(response.height, Int64(1000));
		});
		
		test('has/clear operations', () {
			final response = ResponseQuery(
				key: Uint8List.fromList([1, 2]),
				value: Uint8List.fromList([3, 4]),
			);
			
			expect(response.hasKey(), true);
			expect(response.hasValue(), true);
			
			response.clearKey();
			response.clearValue();
			
			expect(response.hasKey(), false);
			expect(response.hasValue(), false);
		});
	});
	
	group('tendermint.abci ResponseBeginBlock', () {
		test('constructor with events', () {
			final events = [
				Event(type: 'begin_block'),
				Event(type: 'validator_updates'),
			];
			
			final response = ResponseBeginBlock(events: events);
			
			expect(response.events.length, 2);
			expect(response.events[0].type, 'begin_block');
			expect(response.events[1].type, 'validator_updates');
		});
		
		test('events management', () {
			final response = ResponseBeginBlock();
			
			expect(response.events, isEmpty);
			
			final event = Event(type: 'test_event');
			response.events.add(event);
			expect(response.events.length, 1);
			
			response.events.clear();
			expect(response.events, isEmpty);
		});
	});
	
	group('tendermint.abci ResponseCheckTx', () {
		test('constructor with success', () {
			final events = [
				Event(type: 'check_tx'),
			];
			
			final response = ResponseCheckTx(
				code: 0,
				data: Uint8List.fromList([1, 2, 3]),
				log: 'transaction valid',
				gasWanted: Int64(100000),
				gasUsed: Int64(75000),
				events: events,
			);
			
			expect(response.code, 0);
			expect(response.data, [1, 2, 3]);
			expect(response.log, 'transaction valid');
			expect(response.gasWanted, Int64(100000));
			expect(response.gasUsed, Int64(75000));
			expect(response.events.length, 1);
		});
		
		test('constructor with error', () {
			final response = ResponseCheckTx(
				code: 1,
				log: 'insufficient funds',
				gasWanted: Int64(100000),
				gasUsed: Int64(5000),
				codespace: 'sdk',
			);
			
			expect(response.code, 1);
			expect(response.log, 'insufficient funds');
			expect(response.gasWanted, Int64(100000));
			expect(response.gasUsed, Int64(5000));
			expect(response.codespace, 'sdk');
		});
		
		test('gas calculations', () {
			final gasScenarios = [
				{'wanted': 100000, 'used': 75000},
				{'wanted': 50000, 'used': 60000},
				{'wanted': 0, 'used': 0},
			];
			
			for (final scenario in gasScenarios) {
				final response = ResponseCheckTx(
					gasWanted: Int64(scenario['wanted']!),
					gasUsed: Int64(scenario['used']!),
				);
				
				expect(response.gasWanted, Int64(scenario['wanted']!));
				expect(response.gasUsed, Int64(scenario['used']!));
				
				final buffer = response.writeToBuffer();
				final restored = ResponseCheckTx.fromBuffer(buffer);
				expect(restored.gasWanted, Int64(scenario['wanted']!));
				expect(restored.gasUsed, Int64(scenario['used']!));
			}
		});
	});
	
	group('tendermint.abci ResponseDeliverTx', () {
		test('constructor with success', () {
			final events = [
				Event(type: 'transfer'),
				Event(type: 'message'),
			];
			
			final response = ResponseDeliverTx(
				code: 0,
				data: Uint8List.fromList([100, 101, 102]),
				log: 'transaction executed successfully',
				gasWanted: Int64(200000),
				gasUsed: Int64(150000),
				events: events,
			);
			
			expect(response.code, 0);
			expect(response.data, [100, 101, 102]);
			expect(response.log, 'transaction executed successfully');
			expect(response.gasWanted, Int64(200000));
			expect(response.gasUsed, Int64(150000));
			expect(response.events.length, 2);
		});
		
		test('events management', () {
			final response = ResponseDeliverTx();
			
			expect(response.events, isEmpty);
			
			final transferEvent = Event(type: 'transfer');
			final messageEvent = Event(type: 'message');
			
			response.events.addAll([transferEvent, messageEvent]);
			expect(response.events.length, 2);
			expect(response.events[0].type, 'transfer');
			expect(response.events[1].type, 'message');
			
			response.events.clear();
			expect(response.events, isEmpty);
		});
		
		test('error scenarios', () {
			final errorScenarios = [
				{'code': 0, 'codespace': '', 'log': 'success'},
				{'code': 1, 'codespace': 'sdk', 'log': 'generic error'},
				{'code': 2, 'codespace': 'bank', 'log': 'insufficient funds'},
				{'code': 3, 'codespace': 'staking', 'log': 'validator not found'},
			];
			
			for (final scenario in errorScenarios) {
				final response = ResponseDeliverTx(
					code: scenario['code'] as int,
					log: scenario['log'] as String,
					codespace: scenario['codespace'] as String,
				);
				
				expect(response.code, scenario['code']);
				expect(response.log, scenario['log']);
				expect(response.codespace, scenario['codespace']);
			}
		});
	});
	
	group('tendermint.abci ResponseEndBlock', () {
		test('constructor with validator updates', () {
			final validatorUpdates = [
				ValidatorUpdate(power: Int64(1000000)),
				ValidatorUpdate(power: Int64(0)), // Remove validator
			];
			
			final events = [
				Event(type: 'end_block'),
			];
			
			final response = ResponseEndBlock(
				validatorUpdates: validatorUpdates,
				events: events,
			);
			
			expect(response.validatorUpdates.length, 2);
			expect(response.validatorUpdates[0].power, Int64(1000000));
			expect(response.validatorUpdates[1].power, Int64.ZERO);
			expect(response.events.length, 1);
		});
		
		test('validator updates management', () {
			final response = ResponseEndBlock();
			
			expect(response.validatorUpdates, isEmpty);
			
			final validator = ValidatorUpdate(power: Int64(500000));
			response.validatorUpdates.add(validator);
			expect(response.validatorUpdates.length, 1);
			
			response.validatorUpdates.clear();
			expect(response.validatorUpdates, isEmpty);
		});
	});
	
	group('tendermint.abci ResponseCommit', () {
		test('constructor with app hash', () {
			final response = ResponseCommit(
				data: Uint8List.fromList([1, 2, 3, 4, 5]),
				retainHeight: Int64(500),
			);
			
			expect(response.data, [1, 2, 3, 4, 5]);
			expect(response.retainHeight, Int64(500));
		});
		
		test('has/clear operations', () {
			final response = ResponseCommit(
				data: Uint8List.fromList([10, 20]),
				retainHeight: Int64(1000),
			);
			
			expect(response.hasData(), true);
			expect(response.hasRetainHeight(), true);
			
			response.clearData();
			response.clearRetainHeight();
			
			expect(response.hasData(), false);
			expect(response.hasRetainHeight(), false);
		});
		
		test('retain height scenarios', () {
			final retainHeights = [
				Int64.ZERO,
				Int64(1000),
				Int64.MAX_VALUE,
			];
			
			for (final retainHeight in retainHeights) {
				final response = ResponseCommit(
					data: Uint8List.fromList([1, 2, 3]),
					retainHeight: retainHeight,
				);
				
				expect(response.retainHeight, retainHeight);
				
				final buffer = response.writeToBuffer();
				final restored = ResponseCommit.fromBuffer(buffer);
				expect(restored.retainHeight, retainHeight);
			}
		});
	});
	
	group('tendermint.abci error handling', () {
		test('invalid buffer deserialization', () {
			final invalidBuffer = [0xFF, 0xFF, 0xFF];
			
			expect(() => ResponseEcho.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => ResponseInfo.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => ResponseCheckTx.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => ResponseDeliverTx.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => ResponseCommit.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			const invalidJson = 'invalid json';
			
			expect(() => ResponseEcho.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => ResponseInfo.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => ResponseCheckTx.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => ResponseDeliverTx.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => ResponseCommit.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('tendermint.abci comprehensive Response coverage', () {
		test('all Response types have proper info_', () {
			expect(ResponseEcho().info_, isA<pb.BuilderInfo>());
			expect(ResponseFlush().info_, isA<pb.BuilderInfo>());
			expect(ResponseInfo().info_, isA<pb.BuilderInfo>());
			expect(ResponseSetOption().info_, isA<pb.BuilderInfo>());
			expect(ResponseInitChain().info_, isA<pb.BuilderInfo>());
			expect(ResponseQuery().info_, isA<pb.BuilderInfo>());
			expect(ResponseBeginBlock().info_, isA<pb.BuilderInfo>());
			expect(ResponseCheckTx().info_, isA<pb.BuilderInfo>());
			expect(ResponseDeliverTx().info_, isA<pb.BuilderInfo>());
			expect(ResponseEndBlock().info_, isA<pb.BuilderInfo>());
			expect(ResponseCommit().info_, isA<pb.BuilderInfo>());
		});
		
		test('all Response types support createEmptyInstance', () {
			expect(ResponseEcho().createEmptyInstance(), isA<ResponseEcho>());
			expect(ResponseFlush().createEmptyInstance(), isA<ResponseFlush>());
			expect(ResponseInfo().createEmptyInstance(), isA<ResponseInfo>());
			expect(ResponseSetOption().createEmptyInstance(), isA<ResponseSetOption>());
			expect(ResponseInitChain().createEmptyInstance(), isA<ResponseInitChain>());
			expect(ResponseQuery().createEmptyInstance(), isA<ResponseQuery>());
			expect(ResponseBeginBlock().createEmptyInstance(), isA<ResponseBeginBlock>());
			expect(ResponseCheckTx().createEmptyInstance(), isA<ResponseCheckTx>());
			expect(ResponseDeliverTx().createEmptyInstance(), isA<ResponseDeliverTx>());
			expect(ResponseEndBlock().createEmptyInstance(), isA<ResponseEndBlock>());
			expect(ResponseCommit().createEmptyInstance(), isA<ResponseCommit>());
		});
		
		test('getDefault returns same instance', () {
			expect(identical(ResponseEcho.getDefault(), ResponseEcho.getDefault()), true);
			expect(identical(ResponseFlush.getDefault(), ResponseFlush.getDefault()), true);
			expect(identical(ResponseInfo.getDefault(), ResponseInfo.getDefault()), true);
			expect(identical(ResponseSetOption.getDefault(), ResponseSetOption.getDefault()), true);
			expect(identical(ResponseInitChain.getDefault(), ResponseInitChain.getDefault()), true);
			expect(identical(ResponseQuery.getDefault(), ResponseQuery.getDefault()), true);
			expect(identical(ResponseBeginBlock.getDefault(), ResponseBeginBlock.getDefault()), true);
			expect(identical(ResponseCheckTx.getDefault(), ResponseCheckTx.getDefault()), true);
			expect(identical(ResponseDeliverTx.getDefault(), ResponseDeliverTx.getDefault()), true);
			expect(identical(ResponseEndBlock.getDefault(), ResponseEndBlock.getDefault()), true);
			expect(identical(ResponseCommit.getDefault(), ResponseCommit.getDefault()), true);
		});
	});
} 