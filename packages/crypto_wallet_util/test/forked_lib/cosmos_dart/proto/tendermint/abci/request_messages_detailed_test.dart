import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/abci/types.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/timestamp.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/types/types.pb.dart' as tm_types;

void main() {
	group('tendermint.abci RequestEcho', () {
		test('constructor with message', () {
			final request = RequestEcho(message: 'hello world');
			
			expect(request.message, 'hello world');
		});
		
		test('default constructor', () {
			final request = RequestEcho();
			
			expect(request.message, '');
		});
		
		test('has/clear operations', () {
			final request = RequestEcho(message: 'test message');
			
			expect(request.hasMessage(), true);
			expect(request.message, 'test message');
			
			request.clearMessage();
			expect(request.hasMessage(), false);
			expect(request.message, '');
		});
		
		test('clone and copyWith operations', () {
			final original = RequestEcho(message: 'original message');
			
			final cloned = original.clone();
			expect(cloned.message, 'original message');
			expect(identical(original, cloned), false);
			
			final copied = original.copyWith((message) => message.message = 'modified message');
			expect(copied.message, 'modified message');
			expect(original.message, 'original message'); // Original unchanged
		});
		
		test('JSON and buffer serialization', () {
			final request = RequestEcho(message: 'serialization test');
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = RequestEcho.fromJson(json);
			expect(fromJson.message, 'serialization test');
			
			final buffer = request.writeToBuffer();
			final fromBuffer = RequestEcho.fromBuffer(buffer);
			expect(fromBuffer.message, 'serialization test');
		});
		
		test('empty and large messages', () {
			// Empty message
			final empty = RequestEcho(message: '');
			expect(empty.message, '');
			expect(empty.hasMessage(), true); // Empty string is still considered "has" the field
			
			// Large message
			final largeMessage = 'x' * 10000;
			final large = RequestEcho(message: largeMessage);
			expect(large.message, largeMessage);
			expect(large.message.length, 10000);
			
			final buffer = large.writeToBuffer();
			final restored = RequestEcho.fromBuffer(buffer);
			expect(restored.message.length, 10000);
		});
		
		test('special characters in message', () {
			final specialChars = 'Hello 世界! 🌍 \n\t\r\0';
			final request = RequestEcho(message: specialChars);
			
			expect(request.message, specialChars);
			
			final buffer = request.writeToBuffer();
			final restored = RequestEcho.fromBuffer(buffer);
			expect(restored.message, specialChars);
		});
	});
	
	group('tendermint.abci RequestFlush', () {
		test('default constructor', () {
			final request = RequestFlush();
			
			// RequestFlush has no fields, just verify it exists
			expect(request, isA<RequestFlush>());
		});
		
		test('clone and copyWith operations', () {
			final original = RequestFlush();
			
			final cloned = original.clone();
			expect(cloned, isA<RequestFlush>());
			expect(identical(original, cloned), false);
			
			final copied = original.copyWith((message) => {});
			expect(copied, isA<RequestFlush>());
		});
		
		test('JSON and buffer serialization', () {
			final request = RequestFlush();
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = RequestFlush.fromJson(json);
			expect(fromJson, isA<RequestFlush>());
			
			final buffer = request.writeToBuffer();
			final fromBuffer = RequestFlush.fromBuffer(buffer);
			expect(fromBuffer, isA<RequestFlush>());
		});
		
		test('getDefault and createEmptyInstance', () {
			final defaultInstance = RequestFlush.getDefault();
			final emptyInstance = RequestFlush().createEmptyInstance();
			
			expect(defaultInstance, isA<RequestFlush>());
			expect(emptyInstance, isA<RequestFlush>());
			expect(identical(RequestFlush.getDefault(), RequestFlush.getDefault()), true);
		});
	});
	
	group('tendermint.abci RequestInfo', () {
		test('constructor with all parameters', () {
			final request = RequestInfo(
				version: '0.34.0',
				blockVersion: Int64(11),
				p2pVersion: Int64(8),
			);
			
			expect(request.version, '0.34.0');
			expect(request.blockVersion, Int64(11));
			expect(request.p2pVersion, Int64(8));
		});
		
		test('default constructor', () {
			final request = RequestInfo();
			
			expect(request.version, '');
			expect(request.blockVersion, Int64.ZERO);
			expect(request.p2pVersion, Int64.ZERO);
		});
		
		test('has/clear operations', () {
			final request = RequestInfo(
				version: '1.0.0',
				blockVersion: Int64(20),
				p2pVersion: Int64(10),
			);
			
			expect(request.hasVersion(), true);
			expect(request.hasBlockVersion(), true);
			expect(request.hasP2pVersion(), true);
			
			request.clearVersion();
			request.clearBlockVersion();
			request.clearP2pVersion();
			
			expect(request.hasVersion(), false);
			expect(request.hasBlockVersion(), false);
			expect(request.hasP2pVersion(), false);
			expect(request.version, '');
			expect(request.blockVersion, Int64.ZERO);
			expect(request.p2pVersion, Int64.ZERO);
		});
		
		test('clone and copyWith operations', () {
			final original = RequestInfo(
				version: '0.35.0',
				blockVersion: Int64(12),
				p2pVersion: Int64(9),
			);
			
			final cloned = original.clone();
			expect(cloned.version, '0.35.0');
			expect(cloned.blockVersion, Int64(12));
			expect(cloned.p2pVersion, Int64(9));
			expect(identical(original, cloned), false);
			
			final copied = original.copyWith((message) {
				message.version = '0.36.0';
				message.blockVersion = Int64(13);
			});
			expect(copied.version, '0.36.0');
			expect(copied.blockVersion, Int64(13));
			expect(copied.p2pVersion, Int64(9)); // Unchanged
			expect(original.version, '0.35.0'); // Original unchanged
		});
		
		test('version string variations', () {
			final versions = [
				'',
				'0.34.0',
				'v0.34.0-rc1',
				'1.0.0-beta.1',
				'2.0.0+build.123',
			];
			
			for (final version in versions) {
				final request = RequestInfo(version: version);
				expect(request.version, version);
				
				final buffer = request.writeToBuffer();
				final restored = RequestInfo.fromBuffer(buffer);
				expect(restored.version, version);
			}
		});
		
		test('large version numbers', () {
			final request = RequestInfo(
				blockVersion: Int64.MAX_VALUE,
				p2pVersion: Int64.MIN_VALUE,
			);
			
			expect(request.blockVersion, Int64.MAX_VALUE);
			expect(request.p2pVersion, Int64.MIN_VALUE);
			
			final buffer = request.writeToBuffer();
			final restored = RequestInfo.fromBuffer(buffer);
			expect(restored.blockVersion, Int64.MAX_VALUE);
			expect(restored.p2pVersion, Int64.MIN_VALUE);
		});
	});
	
	group('tendermint.abci RequestSetOption', () {
		test('constructor with all parameters', () {
			final request = RequestSetOption(
				key: 'consensus.timeout_commit',
				value: '5s',
			);
			
			expect(request.key, 'consensus.timeout_commit');
			expect(request.value, '5s');
		});
		
		test('default constructor', () {
			final request = RequestSetOption();
			
			expect(request.key, '');
			expect(request.value, '');
		});
		
		test('has/clear operations', () {
			final request = RequestSetOption(key: 'test.key', value: 'test.value');
			
			expect(request.hasKey(), true);
			expect(request.hasValue(), true);
			
			request.clearKey();
			request.clearValue();
			
			expect(request.hasKey(), false);
			expect(request.hasValue(), false);
			expect(request.key, '');
			expect(request.value, '');
		});
		
		test('various configuration options', () {
			final configOptions = [
				{'key': 'consensus.timeout_commit', 'value': '5s'},
				{'key': 'mempool.size', 'value': '5000'},
				{'key': 'p2p.max_num_inbound_peers', 'value': '40'},
				{'key': 'rpc.unsafe', 'value': 'false'},
				{'key': 'tx_index.indexer', 'value': 'kv'},
			];
			
			for (final config in configOptions) {
				final request = RequestSetOption(
					key: config['key']!,
					value: config['value']!,
				);
				
				expect(request.key, config['key']);
				expect(request.value, config['value']);
				
				final buffer = request.writeToBuffer();
				final restored = RequestSetOption.fromBuffer(buffer);
				expect(restored.key, config['key']);
				expect(restored.value, config['value']);
			}
		});
		
		test('empty key and value combinations', () {
			final combinations = [
				{'key': '', 'value': ''},
				{'key': 'key', 'value': ''},
				{'key': '', 'value': 'value'},
				{'key': 'key', 'value': 'value'},
			];
			
			for (final combo in combinations) {
				final request = RequestSetOption(
					key: combo['key']!,
					value: combo['value']!,
				);
				
				expect(request.key, combo['key']);
				expect(request.value, combo['value']);
				// For protobuf strings, hasX() returns true even for empty strings if explicitly set
				expect(request.hasKey(), true);
				expect(request.hasValue(), true);
			}
		});
	});
	
	group('tendermint.abci RequestInitChain', () {
		test('constructor with all parameters', () {
			final timestamp = Timestamp.fromDateTime(DateTime.utc(2023, 1, 1));
			final validators = [
				ValidatorUpdate(power: Int64(1000000)),
				ValidatorUpdate(power: Int64(2000000)),
			];
			
			final request = RequestInitChain(
				time: timestamp,
				chainId: 'test-chain-1',
				consensusParams: ConsensusParams(),
				validators: validators,
				appStateBytes: Uint8List.fromList([1, 2, 3, 4, 5]),
				initialHeight: Int64(1),
			);
			
			expect(request.hasTime(), true);
			expect(request.chainId, 'test-chain-1');
			expect(request.hasConsensusParams(), true);
			expect(request.validators.length, 2);
			expect(request.validators[0].power, Int64(1000000));
			expect(request.validators[1].power, Int64(2000000));
			expect(request.appStateBytes, [1, 2, 3, 4, 5]);
			expect(request.initialHeight, Int64(1));
		});
		
		test('default constructor', () {
			final request = RequestInitChain();
			
			expect(request.hasTime(), false);
			expect(request.chainId, '');
			expect(request.hasConsensusParams(), false);
			expect(request.validators, isEmpty);
			expect(request.appStateBytes, isEmpty);
			expect(request.initialHeight, Int64.ZERO);
		});
		
		test('has/clear/ensure operations', () {
			final request = RequestInitChain();
			
			expect(request.hasTime(), false);
			expect(request.hasConsensusParams(), false);
			
			final time = request.ensureTime();
			expect(request.hasTime(), true);
			expect(time, isA<Timestamp>());
			
			final consensusParams = request.ensureConsensusParams();
			expect(request.hasConsensusParams(), true);
			expect(consensusParams, isA<ConsensusParams>());
			
			request.clearTime();
			request.clearConsensusParams();
			
			expect(request.hasTime(), false);
			expect(request.hasConsensusParams(), false);
		});
		
		test('validators list operations', () {
			final request = RequestInitChain();
			
			expect(request.validators, isEmpty);
			
			final validator1 = ValidatorUpdate(power: Int64(1000000));
			final validator2 = ValidatorUpdate(power: Int64(2000000));
			final validator3 = ValidatorUpdate(power: Int64(1500000));
			
			request.validators.addAll([validator1, validator2]);
			expect(request.validators.length, 2);
			expect(request.validators[0].power, Int64(1000000));
			expect(request.validators[1].power, Int64(2000000));
			
			request.validators.add(validator3);
			expect(request.validators.length, 3);
			expect(request.validators[2].power, Int64(1500000));
			
			request.validators.removeAt(1);
			expect(request.validators.length, 2);
			expect(request.validators[0].power, Int64(1000000));
			expect(request.validators[1].power, Int64(1500000));
			
			request.validators.clear();
			expect(request.validators, isEmpty);
		});
		
		test('chain ID variations', () {
			final chainIds = [
				'',
				'mainnet',
				'testnet-1',
				'cosmos-hub-4',
				'osmosis-1',
				'juno-1',
				'very-long-chain-name-with-special-chars_123',
			];
			
			for (final chainId in chainIds) {
				final request = RequestInitChain(chainId: chainId);
				expect(request.chainId, chainId);
				
				final buffer = request.writeToBuffer();
				final restored = RequestInitChain.fromBuffer(buffer);
				expect(restored.chainId, chainId);
			}
		});
		
		test('large app state bytes', () {
			final largeAppState = Uint8List(50000);
			for (int i = 0; i < 50000; i++) {
				largeAppState[i] = i % 256;
			}
			
			final request = RequestInitChain(
				appStateBytes: largeAppState,
				initialHeight: Int64(100),
			);
			
			expect(request.appStateBytes.length, 50000);
			expect(request.appStateBytes[0], 0);
			expect(request.appStateBytes[49999], 79); // 49999 % 256 = 79
			expect(request.initialHeight, Int64(100));
			
			final buffer = request.writeToBuffer();
			final restored = RequestInitChain.fromBuffer(buffer);
			expect(restored.appStateBytes.length, 50000);
			expect(restored.appStateBytes[25000], 168); // 25000 % 256 = 168
			expect(restored.initialHeight, Int64(100));
		});
	});
	
	group('tendermint.abci RequestQuery', () {
		test('constructor with all parameters', () {
			final request = RequestQuery(
				data: Uint8List.fromList([1, 2, 3, 4, 5]),
				path: '/store/bank/key',
				height: Int64(1000),
				prove: true,
			);
			
			expect(request.data, [1, 2, 3, 4, 5]);
			expect(request.path, '/store/bank/key');
			expect(request.height, Int64(1000));
			expect(request.prove, true);
		});
		
		test('default constructor', () {
			final request = RequestQuery();
			
			expect(request.data, isEmpty);
			expect(request.path, '');
			expect(request.height, Int64.ZERO);
			expect(request.prove, false);
		});
		
		test('has/clear operations', () {
			final request = RequestQuery(
				data: Uint8List.fromList([1, 2, 3]),
				path: '/test/path',
				height: Int64(500),
				prove: true,
			);
			
			expect(request.hasData(), true);
			expect(request.hasPath(), true);
			expect(request.hasHeight(), true);
			expect(request.hasProve(), true);
			
			request.clearData();
			request.clearPath();
			request.clearHeight();
			request.clearProve();
			
			expect(request.hasData(), false);
			expect(request.hasPath(), false);
			expect(request.hasHeight(), false);
			expect(request.hasProve(), false);
			expect(request.data, isEmpty);
			expect(request.path, '');
			expect(request.height, Int64.ZERO);
			expect(request.prove, false);
		});
		
		test('various query paths', () {
			final queryPaths = [
				'/store/bank/key',
				'/store/staking/validators',
				'/store/gov/proposals',
				'/store/slashing/signing_info',
				'/store/distribution/delegator_rewards',
				'/p2p/filter/addr',
				'/p2p/filter/id',
				'/abci_query',
				'',
			];
			
			for (final path in queryPaths) {
				final request = RequestQuery(path: path);
				expect(request.path, path);
				
				final buffer = request.writeToBuffer();
				final restored = RequestQuery.fromBuffer(buffer);
				expect(restored.path, path);
			}
		});
		
		test('query data variations', () {
			final dataVariations = [
				Uint8List(0), // Empty
				Uint8List.fromList([0]), // Single zero byte
				Uint8List.fromList([255]), // Single max byte
				Uint8List.fromList([1, 2, 3, 4, 5]), // Small data
				Uint8List.fromList(List.generate(1000, (i) => i % 256)), // Large data
			];
			
			for (final data in dataVariations) {
				final request = RequestQuery(data: data, prove: true);
				expect(request.data, data);
				expect(request.prove, true);
				
				final buffer = request.writeToBuffer();
				final restored = RequestQuery.fromBuffer(buffer);
				expect(restored.data, data);
				expect(restored.prove, true);
			}
		});
		
		test('height variations', () {
			final heights = [
				Int64.ZERO,
				Int64.ONE,
				Int64(100),
				Int64(1000000),
				Int64.MAX_VALUE,
			];
			
			for (final height in heights) {
				final request = RequestQuery(height: height);
				expect(request.height, height);
				
				final buffer = request.writeToBuffer();
				final restored = RequestQuery.fromBuffer(buffer);
				expect(restored.height, height);
			}
		});
	});
	
	group('tendermint.abci RequestBeginBlock', () {
		test('constructor with all parameters', () {
			final header = tm_types.Header();
			final lastCommitInfo = LastCommitInfo(
				round: 1,
				votes: [
					VoteInfo(signedLastBlock: true),
					VoteInfo(signedLastBlock: false),
				],
			);
			final evidence = [
				Evidence(
					type: EvidenceType.DUPLICATE_VOTE,
					height: Int64(100),
				),
			];
			
			final request = RequestBeginBlock(
				hash: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
				header: header,
				lastCommitInfo: lastCommitInfo,
				byzantineValidators: evidence,
			);
			
			expect(request.hash, [1, 2, 3, 4, 5, 6, 7, 8]);
			expect(request.hasHeader(), true);
			expect(request.hasLastCommitInfo(), true);
			expect(request.lastCommitInfo.round, 1);
			expect(request.lastCommitInfo.votes.length, 2);
			expect(request.byzantineValidators.length, 1);
			expect(request.byzantineValidators[0].type, EvidenceType.DUPLICATE_VOTE);
		});
		
		test('default constructor', () {
			final request = RequestBeginBlock();
			
			expect(request.hash, isEmpty);
			expect(request.hasHeader(), false);
			expect(request.hasLastCommitInfo(), false);
			expect(request.byzantineValidators, isEmpty);
		});
		
		test('has/clear/ensure operations', () {
			final request = RequestBeginBlock();
			
			expect(request.hasHeader(), false);
			expect(request.hasLastCommitInfo(), false);
			
			final header = request.ensureHeader();
			expect(request.hasHeader(), true);
			expect(header, isA<tm_types.Header>());
			
			final lastCommitInfo = request.ensureLastCommitInfo();
			expect(request.hasLastCommitInfo(), true);
			expect(lastCommitInfo, isA<LastCommitInfo>());
			
			request.clearHeader();
			request.clearLastCommitInfo();
			
			expect(request.hasHeader(), false);
			expect(request.hasLastCommitInfo(), false);
		});
		
		test('byzantine validators list operations', () {
			final request = RequestBeginBlock();
			
			expect(request.byzantineValidators, isEmpty);
			
			final evidence1 = Evidence(type: EvidenceType.DUPLICATE_VOTE, height: Int64(100));
			final evidence2 = Evidence(type: EvidenceType.LIGHT_CLIENT_ATTACK, height: Int64(200));
			
			request.byzantineValidators.addAll([evidence1, evidence2]);
			expect(request.byzantineValidators.length, 2);
			expect(request.byzantineValidators[0].type, EvidenceType.DUPLICATE_VOTE);
			expect(request.byzantineValidators[1].type, EvidenceType.LIGHT_CLIENT_ATTACK);
			
			request.byzantineValidators.clear();
			expect(request.byzantineValidators, isEmpty);
		});
		
		test('hash variations', () {
			final hashes = [
				Uint8List(0), // Empty
				Uint8List.fromList([0]), // Single zero
				Uint8List.fromList(List.generate(32, (i) => i)), // SHA-256 size
				Uint8List.fromList(List.generate(64, (i) => i)), // SHA-512 size
			];
			
			for (final hash in hashes) {
				final request = RequestBeginBlock(hash: hash);
				expect(request.hash, hash);
				
				final buffer = request.writeToBuffer();
				final restored = RequestBeginBlock.fromBuffer(buffer);
				expect(restored.hash, hash);
			}
		});
	});
	
	group('tendermint.abci RequestCheckTx', () {
		test('constructor with all parameters', () {
			final request = RequestCheckTx(
				tx: Uint8List.fromList([10, 20, 30, 40, 50]),
				type: CheckTxType.NEW,
			);
			
			expect(request.tx, [10, 20, 30, 40, 50]);
			expect(request.type, CheckTxType.NEW);
		});
		
		test('constructor with RECHECK type', () {
			final request = RequestCheckTx(
				tx: Uint8List.fromList([1, 2, 3]),
				type: CheckTxType.RECHECK,
			);
			
			expect(request.tx, [1, 2, 3]);
			expect(request.type, CheckTxType.RECHECK);
		});
		
		test('default constructor', () {
			final request = RequestCheckTx();
			
			expect(request.tx, isEmpty);
			expect(request.type, CheckTxType.NEW); // Default value
		});
		
		test('has/clear operations', () {
			final request = RequestCheckTx(
				tx: Uint8List.fromList([1, 2, 3, 4, 5]),
				type: CheckTxType.RECHECK,
			);
			
			expect(request.hasTx(), true);
			expect(request.hasType(), true);
			
			request.clearTx();
			request.clearType();
			
			expect(request.hasTx(), false);
			expect(request.hasType(), false);
			expect(request.tx, isEmpty);
			expect(request.type, CheckTxType.NEW); // Default value
		});
		
		test('transaction size variations', () {
			final txSizes = [0, 1, 100, 1000, 10000];
			
			for (final size in txSizes) {
				final txData = Uint8List(size);
				for (int i = 0; i < size; i++) {
					txData[i] = i % 256;
				}
				
				final request = RequestCheckTx(tx: txData, type: CheckTxType.NEW);
				expect(request.tx.length, size);
				
				final buffer = request.writeToBuffer();
				final restored = RequestCheckTx.fromBuffer(buffer);
				expect(restored.tx.length, size);
				if (size > 0) {
					expect(restored.tx[0], 0);
					expect(restored.tx[size - 1], (size - 1) % 256);
				}
			}
		});
		
		test('CheckTxType enum values', () {
			// Test NEW type
			final newRequest = RequestCheckTx(type: CheckTxType.NEW);
			expect(newRequest.type, CheckTxType.NEW);
			expect(newRequest.type.value, 0);
			
			// Test RECHECK type
			final recheckRequest = RequestCheckTx(type: CheckTxType.RECHECK);
			expect(recheckRequest.type, CheckTxType.RECHECK);
			expect(recheckRequest.type.value, 1);
			
			// Test serialization
			for (final type in [CheckTxType.NEW, CheckTxType.RECHECK]) {
				final request = RequestCheckTx(
					tx: Uint8List.fromList([1, 2, 3]),
					type: type,
				);
				
				final buffer = request.writeToBuffer();
				final restored = RequestCheckTx.fromBuffer(buffer);
				expect(restored.type, type);
			}
		});
	});
	
	group('tendermint.abci RequestDeliverTx', () {
		test('constructor with transaction data', () {
			final request = RequestDeliverTx(
				tx: Uint8List.fromList([100, 101, 102, 103, 104]),
			);
			
			expect(request.tx, [100, 101, 102, 103, 104]);
		});
		
		test('default constructor', () {
			final request = RequestDeliverTx();
			
			expect(request.tx, isEmpty);
		});
		
		test('has/clear operations', () {
			final request = RequestDeliverTx(tx: Uint8List.fromList([1, 2, 3, 4, 5]));
			
			expect(request.hasTx(), true);
			expect(request.tx, [1, 2, 3, 4, 5]);
			
			request.clearTx();
			expect(request.hasTx(), false);
			expect(request.tx, isEmpty);
		});
		
		test('clone and copyWith operations', () {
			final original = RequestDeliverTx(tx: Uint8List.fromList([10, 20, 30]));
			
			final cloned = original.clone();
			expect(cloned.tx, [10, 20, 30]);
			expect(identical(original, cloned), false);
			
			final copied = original.copyWith((message) {
				message.tx = Uint8List.fromList([40, 50, 60]);
			});
			expect(copied.tx, [40, 50, 60]);
			expect(original.tx, [10, 20, 30]); // Original unchanged
		});
		
		test('large transaction handling', () {
			final largeTx = Uint8List(100000); // 100KB transaction
			for (int i = 0; i < 100000; i++) {
				largeTx[i] = (i * 7) % 256; // Some pattern
			}
			
			final request = RequestDeliverTx(tx: largeTx);
			expect(request.tx.length, 100000);
			expect(request.tx[50000], (50000 * 7) % 256);
			
			final buffer = request.writeToBuffer();
			final restored = RequestDeliverTx.fromBuffer(buffer);
			expect(restored.tx.length, 100000);
			expect(restored.tx[75000], (75000 * 7) % 256);
		});
		
		test('JSON and buffer serialization', () {
			final request = RequestDeliverTx(tx: Uint8List.fromList([255, 254, 253, 252]));
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = RequestDeliverTx.fromJson(json);
			expect(fromJson.tx, [255, 254, 253, 252]);
			
			final buffer = request.writeToBuffer();
			final fromBuffer = RequestDeliverTx.fromBuffer(buffer);
			expect(fromBuffer.tx, [255, 254, 253, 252]);
		});
	});
	
	group('tendermint.abci RequestEndBlock', () {
		test('constructor with height', () {
			final request = RequestEndBlock(height: Int64(12345));
			
			expect(request.height, Int64(12345));
		});
		
		test('default constructor', () {
			final request = RequestEndBlock();
			
			expect(request.height, Int64.ZERO);
		});
		
		test('has/clear operations', () {
			final request = RequestEndBlock(height: Int64(999));
			
			expect(request.hasHeight(), true);
			expect(request.height, Int64(999));
			
			request.clearHeight();
			expect(request.hasHeight(), false);
			expect(request.height, Int64.ZERO);
		});
		
		test('height value variations', () {
			final heights = [
				Int64.ZERO,
				Int64.ONE,
				Int64(1000),
				Int64(1000000),
				Int64(9223372036854775807), // Max Int64
			];
			
			for (final height in heights) {
				final request = RequestEndBlock(height: height);
				expect(request.height, height);
				
				final buffer = request.writeToBuffer();
				final restored = RequestEndBlock.fromBuffer(buffer);
				expect(restored.height, height);
			}
		});
		
		test('clone and copyWith operations', () {
			final original = RequestEndBlock(height: Int64(5000));
			
			final cloned = original.clone();
			expect(cloned.height, Int64(5000));
			expect(identical(original, cloned), false);
			
			final copied = original.copyWith((message) => message.height = Int64(6000));
			expect(copied.height, Int64(6000));
			expect(original.height, Int64(5000)); // Original unchanged
		});
		
		test('JSON and buffer serialization', () {
			final request = RequestEndBlock(height: Int64(777777));
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = RequestEndBlock.fromJson(json);
			expect(fromJson.height, Int64(777777));
			
			final buffer = request.writeToBuffer();
			final fromBuffer = RequestEndBlock.fromBuffer(buffer);
			expect(fromBuffer.height, Int64(777777));
		});
	});
	
	group('tendermint.abci RequestCommit', () {
		test('default constructor', () {
			final request = RequestCommit();
			
			// RequestCommit has no fields, just verify it exists
			expect(request, isA<RequestCommit>());
		});
		
		test('clone and copyWith operations', () {
			final original = RequestCommit();
			
			final cloned = original.clone();
			expect(cloned, isA<RequestCommit>());
			expect(identical(original, cloned), false);
			
			final copied = original.copyWith((message) => {});
			expect(copied, isA<RequestCommit>());
		});
		
		test('JSON and buffer serialization', () {
			final request = RequestCommit();
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = RequestCommit.fromJson(json);
			expect(fromJson, isA<RequestCommit>());
			
			final buffer = request.writeToBuffer();
			final fromBuffer = RequestCommit.fromBuffer(buffer);
			expect(fromBuffer, isA<RequestCommit>());
		});
		
		test('getDefault and createEmptyInstance', () {
			final defaultInstance = RequestCommit.getDefault();
			final emptyInstance = RequestCommit().createEmptyInstance();
			
			expect(defaultInstance, isA<RequestCommit>());
			expect(emptyInstance, isA<RequestCommit>());
			expect(identical(RequestCommit.getDefault(), RequestCommit.getDefault()), true);
		});
		
		test('info_ property', () {
			final request = RequestCommit();
			expect(request.info_, isA<pb.BuilderInfo>());
			expect(request.info_.messageName, 'RequestCommit');
		});
	});
	
	group('tendermint.abci error handling', () {
		test('invalid buffer deserialization for all Request types', () {
			final invalidBuffer = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF];
			
			expect(() => RequestEcho.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => RequestFlush.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => RequestInfo.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => RequestSetOption.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => RequestInitChain.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => RequestQuery.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => RequestBeginBlock.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => RequestCheckTx.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => RequestDeliverTx.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => RequestEndBlock.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => RequestCommit.fromBuffer(invalidBuffer), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization for all Request types', () {
			const invalidJson = 'invalid json string';
			
			expect(() => RequestEcho.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => RequestFlush.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => RequestInfo.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => RequestSetOption.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => RequestInitChain.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => RequestQuery.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => RequestBeginBlock.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => RequestCheckTx.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => RequestDeliverTx.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => RequestEndBlock.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
			expect(() => RequestCommit.fromJson(invalidJson), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('tendermint.abci comprehensive Request coverage', () {
		test('all Request message types have proper info_', () {
			expect(RequestEcho().info_, isA<pb.BuilderInfo>());
			expect(RequestFlush().info_, isA<pb.BuilderInfo>());
			expect(RequestInfo().info_, isA<pb.BuilderInfo>());
			expect(RequestSetOption().info_, isA<pb.BuilderInfo>());
			expect(RequestInitChain().info_, isA<pb.BuilderInfo>());
			expect(RequestQuery().info_, isA<pb.BuilderInfo>());
			expect(RequestBeginBlock().info_, isA<pb.BuilderInfo>());
			expect(RequestCheckTx().info_, isA<pb.BuilderInfo>());
			expect(RequestDeliverTx().info_, isA<pb.BuilderInfo>());
			expect(RequestEndBlock().info_, isA<pb.BuilderInfo>());
			expect(RequestCommit().info_, isA<pb.BuilderInfo>());
		});
		
		test('all Request message types support createEmptyInstance', () {
			expect(RequestEcho().createEmptyInstance(), isA<RequestEcho>());
			expect(RequestFlush().createEmptyInstance(), isA<RequestFlush>());
			expect(RequestInfo().createEmptyInstance(), isA<RequestInfo>());
			expect(RequestSetOption().createEmptyInstance(), isA<RequestSetOption>());
			expect(RequestInitChain().createEmptyInstance(), isA<RequestInitChain>());
			expect(RequestQuery().createEmptyInstance(), isA<RequestQuery>());
			expect(RequestBeginBlock().createEmptyInstance(), isA<RequestBeginBlock>());
			expect(RequestCheckTx().createEmptyInstance(), isA<RequestCheckTx>());
			expect(RequestDeliverTx().createEmptyInstance(), isA<RequestDeliverTx>());
			expect(RequestEndBlock().createEmptyInstance(), isA<RequestEndBlock>());
			expect(RequestCommit().createEmptyInstance(), isA<RequestCommit>());
		});
		
		test('getDefault returns same instance for all Request types', () {
			expect(identical(RequestEcho.getDefault(), RequestEcho.getDefault()), true);
			expect(identical(RequestFlush.getDefault(), RequestFlush.getDefault()), true);
			expect(identical(RequestInfo.getDefault(), RequestInfo.getDefault()), true);
			expect(identical(RequestSetOption.getDefault(), RequestSetOption.getDefault()), true);
			expect(identical(RequestInitChain.getDefault(), RequestInitChain.getDefault()), true);
			expect(identical(RequestQuery.getDefault(), RequestQuery.getDefault()), true);
			expect(identical(RequestBeginBlock.getDefault(), RequestBeginBlock.getDefault()), true);
			expect(identical(RequestCheckTx.getDefault(), RequestCheckTx.getDefault()), true);
			expect(identical(RequestDeliverTx.getDefault(), RequestDeliverTx.getDefault()), true);
			expect(identical(RequestEndBlock.getDefault(), RequestEndBlock.getDefault()), true);
			expect(identical(RequestCommit.getDefault(), RequestCommit.getDefault()), true);
		});
	});
} 