import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/abci/types.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/timestamp.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/crypto/keys.pb.dart' as crypto_keys;

void main() {
	group('tendermint.abci Request', () {
		test('constructor with echo', () {
			final echo = RequestEcho(message: 'test echo');
			final request = Request(echo: echo);
			
			expect(request.hasEcho(), true);
			expect(request.echo.message, 'test echo');
			expect(request.whichValue(), Request_Value.echo);
		});
		
		test('constructor with info', () {
			final info = RequestInfo(version: '0.34.0', blockVersion: Int64(11));
			final request = Request(info: info);
			
			expect(request.hasInfo(), true);
			expect(request.info.version, '0.34.0');
			expect(request.info.blockVersion, Int64(11));
			expect(request.whichValue(), Request_Value.info);
		});
		
		test('constructor with query', () {
			final query = RequestQuery(
				data: Uint8List.fromList([1, 2, 3, 4]),
				path: '/store/bank/key',
				height: Int64(1000),
				prove: true,
			);
			final request = Request(query: query);
			
			expect(request.hasQuery(), true);
			expect(request.query.data, [1, 2, 3, 4]);
			expect(request.query.path, '/store/bank/key');
			expect(request.query.height, Int64(1000));
			expect(request.query.prove, true);
			expect(request.whichValue(), Request_Value.query);
		});
		
		test('default constructor', () {
			final request = Request();
			
			expect(request.whichValue(), Request_Value.notSet);
			expect(request.hasEcho(), false);
			expect(request.hasInfo(), false);
			expect(request.hasQuery(), false);
		});
		
		test('oneof behavior - setting different values', () {
			final request = Request();
			
			// Set echo first
			request.echo = RequestEcho(message: 'first');
			expect(request.whichValue(), Request_Value.echo);
			expect(request.hasEcho(), true);
			
			// Set info - should clear echo
			request.info = RequestInfo(version: '1.0.0');
			expect(request.whichValue(), Request_Value.info);
			expect(request.hasEcho(), false);
			expect(request.hasInfo(), true);
			
			// Set query - should clear info
			request.query = RequestQuery(path: '/test');
			expect(request.whichValue(), Request_Value.query);
			expect(request.hasInfo(), false);
			expect(request.hasQuery(), true);
		});
		
		test('clearValue operation', () {
			final request = Request(echo: RequestEcho(message: 'test'));
			expect(request.whichValue(), Request_Value.echo);
			
			request.clearValue();
			expect(request.whichValue(), Request_Value.notSet);
			expect(request.hasEcho(), false);
		});
		
		test('JSON and buffer serialization', () {
			final request = Request(
				info: RequestInfo(version: '0.34.0', blockVersion: Int64(11)),
			);
			
			final json = jsonEncode(request.writeToJsonMap());
			final fromJson = Request.fromJson(json);
			expect(fromJson.hasInfo(), true);
			expect(fromJson.info.version, '0.34.0');
			expect(fromJson.info.blockVersion, Int64(11));
			
			final buffer = request.writeToBuffer();
			final fromBuffer = Request.fromBuffer(buffer);
			expect(fromBuffer.hasInfo(), true);
			expect(fromBuffer.info.version, '0.34.0');
			expect(fromBuffer.info.blockVersion, Int64(11));
		});
	});
	
	group('tendermint.abci Response', () {
		test('constructor with echo', () {
			final echo = ResponseEcho(message: 'echo response');
			final response = Response(echo: echo);
			
			expect(response.hasEcho(), true);
			expect(response.echo.message, 'echo response');
			expect(response.whichValue(), Response_Value.echo);
		});
		
		test('constructor with exception', () {
			final exception = ResponseException(error: 'something went wrong');
			final response = Response(exception: exception);
			
			expect(response.hasException(), true);
			expect(response.exception.error, 'something went wrong');
			expect(response.whichValue(), Response_Value.exception);
		});
		
		test('constructor with info', () {
			final info = ResponseInfo(
				data: 'test app',
				version: '1.0.0',
				appVersion: Int64(1),
				lastBlockHeight: Int64(100),
			);
			final response = Response(info: info);
			
			expect(response.hasInfo(), true);
			expect(response.info.data, 'test app');
			expect(response.info.version, '1.0.0');
			expect(response.info.appVersion, Int64(1));
			expect(response.info.lastBlockHeight, Int64(100));
			expect(response.whichValue(), Response_Value.info);
		});
		
		test('oneof behavior consistency', () {
			final response = Response();
			
			// Test that only one field can be set at a time
			response.echo = ResponseEcho(message: 'test');
			expect(response.whichValue(), Response_Value.echo);
			expect(response.hasEcho(), true);
			expect(response.hasException(), false);
			
			response.exception = ResponseException(error: 'error');
			expect(response.whichValue(), Response_Value.exception);
			expect(response.hasEcho(), false);
			expect(response.hasException(), true);
		});
	});
	
	group('tendermint.abci Event', () {
		test('constructor with all parameters', () {
			final attributes = [
				EventAttribute(
					key: Uint8List.fromList([115, 101, 110, 100, 101, 114]), // 'sender' as bytes
					value: Uint8List.fromList([99, 111, 115, 109, 111, 115, 49, 97, 98, 99, 49, 50, 51]), // 'cosmos1abc123' as bytes
					index: true,
				),
				EventAttribute(
					key: Uint8List.fromList([114, 101, 99, 105, 112, 105, 101, 110, 116]), // 'recipient' as bytes
					value: Uint8List.fromList([99, 111, 115, 109, 111, 115, 49, 100, 101, 102, 52, 53, 54]), // 'cosmos1def456' as bytes
					index: true,
				),
				EventAttribute(
					key: Uint8List.fromList([97, 109, 111, 117, 110, 116]), // 'amount' as bytes
					value: Uint8List.fromList([49, 48, 48, 48, 115, 116, 97, 107, 101]), // '1000stake' as bytes
					index: false,
				),
			];
			
			final event = Event(
				type: 'transfer',
				attributes: attributes,
			);
			
			expect(event.type, 'transfer');
			expect(event.attributes.length, 3);
			expect(event.attributes[0].key, [115, 101, 110, 100, 101, 114]); // 'sender'
			expect(event.attributes[0].index, true);
			expect(event.attributes[1].key, [114, 101, 99, 105, 112, 105, 101, 110, 116]); // 'recipient'
			expect(event.attributes[2].key, [97, 109, 111, 117, 110, 116]); // 'amount'
			expect(event.attributes[2].index, false);
		});
		
		test('default constructor', () {
			final event = Event();
			
			expect(event.type, '');
			expect(event.attributes, isEmpty);
		});
		
		test('has/clear operations', () {
			final event = Event(type: 'test_event');
			
			expect(event.hasType(), true);
			expect(event.type, 'test_event');
			
			event.clearType();
			expect(event.hasType(), false);
			expect(event.type, '');
		});
		
		test('attributes list operations', () {
			final event = Event(type: 'test');
			
			expect(event.attributes, isEmpty);
			
			final attr1 = EventAttribute(
				key: Uint8List.fromList([107, 101, 121, 49]), // 'key1' as bytes
				value: Uint8List.fromList([118, 97, 108, 117, 101, 49]), // 'value1' as bytes
			);
			final attr2 = EventAttribute(
				key: Uint8List.fromList([107, 101, 121, 50]), // 'key2' as bytes
				value: Uint8List.fromList([118, 97, 108, 117, 101, 50]), // 'value2' as bytes
			);
			
			event.attributes.addAll([attr1, attr2]);
			expect(event.attributes.length, 2);
			expect(event.attributes[0].key, [107, 101, 121, 49]); // 'key1'
			expect(event.attributes[1].key, [107, 101, 121, 50]); // 'key2'
			
			event.attributes.removeAt(0);
			expect(event.attributes.length, 1);
			expect(event.attributes[0].key, [107, 101, 121, 50]); // 'key2'
			
			event.attributes.clear();
			expect(event.attributes, isEmpty);
		});
		
		test('JSON and buffer serialization', () {
			final event = Event(
				type: 'message',
				attributes: [
					EventAttribute(
						key: Uint8List.fromList([97, 99, 116, 105, 111, 110]), // 'action' as bytes
						value: Uint8List.fromList([115, 101, 110, 100]), // 'send' as bytes
						index: true,
					),
					EventAttribute(
						key: Uint8List.fromList([109, 111, 100, 117, 108, 101]), // 'module' as bytes
						value: Uint8List.fromList([98, 97, 110, 107]), // 'bank' as bytes
						index: false,
					),
				],
			);
			
			final json = jsonEncode(event.writeToJsonMap());
			final fromJson = Event.fromJson(json);
			expect(fromJson.type, 'message');
			expect(fromJson.attributes.length, 2);
			expect(fromJson.attributes[0].key, [97, 99, 116, 105, 111, 110]); // 'action'
			expect(fromJson.attributes[0].value, [115, 101, 110, 100]); // 'send'
			expect(fromJson.attributes[0].index, true);
			expect(fromJson.attributes[1].index, false);
			
			final buffer = event.writeToBuffer();
			final fromBuffer = Event.fromBuffer(buffer);
			expect(fromBuffer.type, 'message');
			expect(fromBuffer.attributes.length, 2);
		});
	});
	
	group('tendermint.abci EventAttribute', () {
		test('constructor with all parameters', () {
			final attr = EventAttribute(
				key: Uint8List.fromList([116, 101, 115, 116, 95, 107, 101, 121]), // 'test_key' as bytes
				value: Uint8List.fromList([116, 101, 115, 116, 95, 118, 97, 108, 117, 101]), // 'test_value' as bytes
				index: true,
			);
			
			expect(attr.key, [116, 101, 115, 116, 95, 107, 101, 121]); // 'test_key'
			expect(attr.value, [116, 101, 115, 116, 95, 118, 97, 108, 117, 101]); // 'test_value'
			expect(attr.index, true);
		});
		
		test('constructor with partial parameters', () {
			final attr = EventAttribute(
				key: Uint8List.fromList([107, 101, 121]), // 'key' as bytes
				value: Uint8List.fromList([118, 97, 108, 117, 101]), // 'value' as bytes
			);
			
			expect(attr.key, [107, 101, 121]); // 'key'
			expect(attr.value, [118, 97, 108, 117, 101]); // 'value'
			expect(attr.index, false); // default value
		});
		
		test('default constructor', () {
			final attr = EventAttribute();
			
			expect(attr.key, isEmpty);
			expect(attr.value, isEmpty);
			expect(attr.index, false);
		});
		
		test('has/clear operations', () {
			final attr = EventAttribute(
				key: Uint8List.fromList([116, 101, 115, 116, 95, 107, 101, 121]), // 'test_key' as bytes
				value: Uint8List.fromList([116, 101, 115, 116, 95, 118, 97, 108, 117, 101]), // 'test_value' as bytes
				index: true,
			);
			
			expect(attr.hasKey(), true);
			expect(attr.hasValue(), true);
			expect(attr.hasIndex(), true);
			
			attr.clearKey();
			attr.clearValue();
			attr.clearIndex();
			
			expect(attr.hasKey(), false);
			expect(attr.hasValue(), false);
			expect(attr.hasIndex(), false);
			expect(attr.key, isEmpty);
			expect(attr.value, isEmpty);
			expect(attr.index, false);
		});
		
		test('byte array values', () {
			final attr = EventAttribute(
				key: Uint8List.fromList([98, 105, 110, 97, 114, 121, 95, 107, 101, 121]), // 'binary_key' as bytes
				value: Uint8List.fromList([98, 105, 110, 97, 114, 121, 95, 118, 97, 108, 117, 101]), // 'binary_value' as bytes
			);
			
			expect(attr.key, [98, 105, 110, 97, 114, 121, 95, 107, 101, 121]); // 'binary_key'
			expect(attr.value, [98, 105, 110, 97, 114, 121, 95, 118, 97, 108, 117, 101]); // 'binary_value'
			
			final buffer = attr.writeToBuffer();
			final restored = EventAttribute.fromBuffer(buffer);
			expect(restored.key, [98, 105, 110, 97, 114, 121, 95, 107, 101, 121]); // 'binary_key'
			expect(restored.value, [98, 105, 110, 97, 114, 121, 95, 118, 97, 108, 117, 101]); // 'binary_value'
		});
	});
	
	group('tendermint.abci TxResult', () {
		test('constructor with all parameters', () {
			final events = [
				Event(type: 'transfer', attributes: [
					EventAttribute(
						key: Uint8List.fromList([115, 101, 110, 100, 101, 114]), // 'sender' as bytes
						value: Uint8List.fromList([99, 111, 115, 109, 111, 115, 49, 97, 98, 99]), // 'cosmos1abc' as bytes
					),
				]),
				Event(type: 'message', attributes: [
					EventAttribute(
						key: Uint8List.fromList([97, 99, 116, 105, 111, 110]), // 'action' as bytes
						value: Uint8List.fromList([115, 101, 110, 100]), // 'send' as bytes
					),
				]),
			];
			
			final txResult = TxResult(
				height: Int64(1000),
				index: 5,
				tx: Uint8List.fromList([1, 2, 3, 4, 5]),
				result: ResponseDeliverTx(
					code: 0,
					data: Uint8List.fromList([6, 7, 8]),
					log: 'success',
					info: 'transaction executed successfully',
					gasWanted: Int64(200000),
					gasUsed: Int64(150000),
					events: events,
					codespace: '',
				),
			);
			
			expect(txResult.height, Int64(1000));
			expect(txResult.index, 5);
			expect(txResult.tx, [1, 2, 3, 4, 5]);
			expect(txResult.hasResult(), true);
			expect(txResult.result.code, 0);
			expect(txResult.result.data, [6, 7, 8]);
			expect(txResult.result.log, 'success');
			expect(txResult.result.gasWanted, Int64(200000));
			expect(txResult.result.gasUsed, Int64(150000));
			expect(txResult.result.events.length, 2);
		});
		
		test('default constructor', () {
			final txResult = TxResult();
			
			expect(txResult.height, Int64.ZERO);
			expect(txResult.index, 0);
			expect(txResult.tx, isEmpty);
			expect(txResult.hasResult(), false);
		});
		
		test('has/clear/ensure operations', () {
			final txResult = TxResult();
			
			expect(txResult.hasResult(), false);
			
			final result = txResult.ensureResult();
			expect(txResult.hasResult(), true);
			expect(result, isA<ResponseDeliverTx>());
			
			txResult.clearResult();
			expect(txResult.hasResult(), false);
		});
		
		test('large transaction data', () {
			final largeTx = Uint8List(5000);
			for (int i = 0; i < 5000; i++) {
				largeTx[i] = i % 256;
			}
			
			final txResult = TxResult(
				height: Int64(5000),
				index: 100,
				tx: largeTx,
			);
			
			expect(txResult.tx.length, 5000);
			expect(txResult.tx[0], 0);
			expect(txResult.tx[4999], 135); // 4999 % 256 = 135
			
			final buffer = txResult.writeToBuffer();
			final restored = TxResult.fromBuffer(buffer);
			expect(restored.tx.length, 5000);
			expect(restored.tx[2500], 196); // 2500 % 256 = 196
		});
	});
	
	group('tendermint.abci Validator', () {
		test('constructor with all parameters', () {
			final validator = Validator(
				address: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]),
				power: Int64(1000000),
			);
			
			expect(validator.address.length, 20);
			expect(validator.address[0], 1);
			expect(validator.address[19], 20);
			expect(validator.power, Int64(1000000));
		});
		
		test('default constructor', () {
			final validator = Validator();
			
			expect(validator.address, isEmpty);
			expect(validator.power, Int64.ZERO);
		});
		
		test('has/clear operations', () {
			final validator = Validator(
				address: Uint8List.fromList([1, 2, 3]),
				power: Int64(500000),
			);
			
			expect(validator.hasAddress(), true);
			expect(validator.hasPower(), true);
			
			validator.clearAddress();
			validator.clearPower();
			
			expect(validator.hasAddress(), false);
			expect(validator.hasPower(), false);
			expect(validator.address, isEmpty);
			expect(validator.power, Int64.ZERO);
		});
		
		test('validator address formats', () {
			// Test different address lengths (Tendermint supports various formats)
			final addresses = [
				Uint8List.fromList([1, 2, 3, 4]), // Short address
				Uint8List.fromList(List.generate(20, (i) => i + 1)), // Standard 20-byte address
				Uint8List.fromList(List.generate(32, (i) => i + 1)), // 32-byte address
			];
			
			for (int i = 0; i < addresses.length; i++) {
				final validator = Validator(
					address: addresses[i],
					power: Int64(i * 1000),
				);
				
				expect(validator.address, addresses[i]);
				expect(validator.power, Int64(i * 1000));
				
				final buffer = validator.writeToBuffer();
				final restored = Validator.fromBuffer(buffer);
				expect(restored.address, addresses[i]);
				expect(restored.power, Int64(i * 1000));
			}
		});
	});
	
	group('tendermint.abci ValidatorUpdate', () {
		test('constructor with all parameters', () {
			final pubKey = crypto_keys.PublicKey();
			// Note: We can't easily construct a valid PublicKey without more complexity
			// so we'll test the basic structure
			
			final validatorUpdate = ValidatorUpdate(
				pubKey: pubKey,
				power: Int64(2000000),
			);
			
			expect(validatorUpdate.hasPubKey(), true);
			expect(validatorUpdate.power, Int64(2000000));
		});
		
		test('default constructor', () {
			final validatorUpdate = ValidatorUpdate();
			
			expect(validatorUpdate.hasPubKey(), false);
			expect(validatorUpdate.power, Int64.ZERO);
		});
		
		test('has/clear/ensure operations', () {
			final validatorUpdate = ValidatorUpdate();
			
			expect(validatorUpdate.hasPubKey(), false);
			
			final pubKey = validatorUpdate.ensurePubKey();
			expect(validatorUpdate.hasPubKey(), true);
			expect(pubKey, isA<crypto_keys.PublicKey>());
			
			validatorUpdate.clearPubKey();
			expect(validatorUpdate.hasPubKey(), false);
		});
	});
	
	group('tendermint.abci VoteInfo', () {
		test('constructor with all parameters', () {
			final validator = Validator(
				address: Uint8List.fromList([1, 2, 3, 4, 5]),
				power: Int64(1000000),
			);
			
			final voteInfo = VoteInfo(
				validator: validator,
				signedLastBlock: true,
			);
			
			expect(voteInfo.hasValidator(), true);
			expect(voteInfo.validator.address, [1, 2, 3, 4, 5]);
			expect(voteInfo.validator.power, Int64(1000000));
			expect(voteInfo.signedLastBlock, true);
		});
		
		test('default constructor', () {
			final voteInfo = VoteInfo();
			
			expect(voteInfo.hasValidator(), false);
			expect(voteInfo.signedLastBlock, false);
		});
		
		test('has/clear/ensure operations', () {
			final voteInfo = VoteInfo();
			
			expect(voteInfo.hasValidator(), false);
			
			final validator = voteInfo.ensureValidator();
			expect(voteInfo.hasValidator(), true);
			expect(validator, isA<Validator>());
			
			voteInfo.clearValidator();
			expect(voteInfo.hasValidator(), false);
		});
	});
	
	group('tendermint.abci Evidence', () {
		test('constructor with all parameters', () {
			final evidence = Evidence(
				type: EvidenceType.DUPLICATE_VOTE,
				validator: Validator(
					address: Uint8List.fromList([1, 2, 3, 4, 5]),
					power: Int64(1000000),
				),
				height: Int64(1000),
				time: Timestamp.fromDateTime(DateTime.utc(2023, 1, 1)),
				totalVotingPower: Int64(10000000),
			);
			
			expect(evidence.type, EvidenceType.DUPLICATE_VOTE);
			expect(evidence.hasValidator(), true);
			expect(evidence.validator.power, Int64(1000000));
			expect(evidence.height, Int64(1000));
			expect(evidence.hasTime(), true);
			expect(evidence.totalVotingPower, Int64(10000000));
		});
		
		test('default constructor', () {
			final evidence = Evidence();
			
			expect(evidence.type, EvidenceType.UNKNOWN);
			expect(evidence.hasValidator(), false);
			expect(evidence.height, Int64.ZERO);
			expect(evidence.hasTime(), false);
			expect(evidence.totalVotingPower, Int64.ZERO);
		});
		
		test('has/clear/ensure operations', () {
			final evidence = Evidence();
			
			expect(evidence.hasValidator(), false);
			expect(evidence.hasTime(), false);
			
			final validator = evidence.ensureValidator();
			expect(evidence.hasValidator(), true);
			expect(validator, isA<Validator>());
			
			final time = evidence.ensureTime();
			expect(evidence.hasTime(), true);
			expect(time, isA<Timestamp>());
			
			evidence.clearValidator();
			evidence.clearTime();
			
			expect(evidence.hasValidator(), false);
			expect(evidence.hasTime(), false);
		});
	});
	
	group('tendermint.abci Snapshot', () {
		test('constructor with all parameters', () {
			final snapshot = Snapshot(
				height: Int64(1000000),
				format: 1,
				chunks: 10,
				hash: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
				metadata: Uint8List.fromList([10, 20, 30, 40]),
			);
			
			expect(snapshot.height, Int64(1000000));
			expect(snapshot.format, 1);
			expect(snapshot.chunks, 10);
			expect(snapshot.hash, [1, 2, 3, 4, 5, 6, 7, 8]);
			expect(snapshot.metadata, [10, 20, 30, 40]);
		});
		
		test('default constructor', () {
			final snapshot = Snapshot();
			
			expect(snapshot.height, Int64.ZERO);
			expect(snapshot.format, 0);
			expect(snapshot.chunks, 0);
			expect(snapshot.hash, isEmpty);
			expect(snapshot.metadata, isEmpty);
		});
		
		test('has/clear operations', () {
			final snapshot = Snapshot(
				height: Int64(500000),
				format: 2,
				chunks: 5,
				hash: Uint8List.fromList([1, 2, 3]),
				metadata: Uint8List.fromList([4, 5, 6]),
			);
			
			expect(snapshot.hasHeight(), true);
			expect(snapshot.hasFormat(), true);
			expect(snapshot.hasChunks(), true);
			expect(snapshot.hasHash(), true);
			expect(snapshot.hasMetadata(), true);
			
			snapshot.clearHeight();
			snapshot.clearFormat();
			snapshot.clearChunks();
			snapshot.clearHash();
			snapshot.clearMetadata();
			
			expect(snapshot.hasHeight(), false);
			expect(snapshot.hasFormat(), false);
			expect(snapshot.hasChunks(), false);
			expect(snapshot.hasHash(), false);
			expect(snapshot.hasMetadata(), false);
		});
		
		test('large snapshot data', () {
			final largeHash = Uint8List(64); // SHA-512 hash
			final largeMetadata = Uint8List(1000);
			
			for (int i = 0; i < 64; i++) {
				largeHash[i] = i;
			}
			for (int i = 0; i < 1000; i++) {
				largeMetadata[i] = i % 256;
			}
			
			final snapshot = Snapshot(
				height: Int64(2000000),
				format: 3,
				chunks: 100,
				hash: largeHash,
				metadata: largeMetadata,
			);
			
			expect(snapshot.hash.length, 64);
			expect(snapshot.metadata.length, 1000);
			expect(snapshot.hash[63], 63);
			expect(snapshot.metadata[999], 231); // 999 % 256 = 231
			
			final buffer = snapshot.writeToBuffer();
			final restored = Snapshot.fromBuffer(buffer);
			expect(restored.hash.length, 64);
			expect(restored.metadata.length, 1000);
			expect(restored.hash[32], 32);
			expect(restored.metadata[500], 244); // 500 % 256 = 244
		});
	});
	
	group('tendermint.abci error handling', () {
		test('invalid buffer deserialization', () {
			expect(() => Request.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => Response.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => Event.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => TxResult.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => Validator.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			expect(() => Request.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => Response.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => Event.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => TxResult.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => Validator.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('tendermint.abci comprehensive coverage', () {
		test('all message types have proper info_', () {
			expect(Request().info_, isA<pb.BuilderInfo>());
			expect(Response().info_, isA<pb.BuilderInfo>());
			expect(Event().info_, isA<pb.BuilderInfo>());
			expect(EventAttribute().info_, isA<pb.BuilderInfo>());
			expect(TxResult().info_, isA<pb.BuilderInfo>());
			expect(Validator().info_, isA<pb.BuilderInfo>());
			expect(ValidatorUpdate().info_, isA<pb.BuilderInfo>());
			expect(VoteInfo().info_, isA<pb.BuilderInfo>());
			expect(Evidence().info_, isA<pb.BuilderInfo>());
			expect(Snapshot().info_, isA<pb.BuilderInfo>());
		});
		
		test('all message types support createEmptyInstance', () {
			expect(Request().createEmptyInstance(), isA<Request>());
			expect(Response().createEmptyInstance(), isA<Response>());
			expect(Event().createEmptyInstance(), isA<Event>());
			expect(EventAttribute().createEmptyInstance(), isA<EventAttribute>());
			expect(TxResult().createEmptyInstance(), isA<TxResult>());
			expect(Validator().createEmptyInstance(), isA<Validator>());
			expect(ValidatorUpdate().createEmptyInstance(), isA<ValidatorUpdate>());
			expect(VoteInfo().createEmptyInstance(), isA<VoteInfo>());
			expect(Evidence().createEmptyInstance(), isA<Evidence>());
			expect(Snapshot().createEmptyInstance(), isA<Snapshot>());
		});
		
		test('getDefault returns same instance for all types', () {
			expect(identical(Request.getDefault(), Request.getDefault()), isTrue);
			expect(identical(Response.getDefault(), Response.getDefault()), isTrue);
			expect(identical(Event.getDefault(), Event.getDefault()), isTrue);
			expect(identical(EventAttribute.getDefault(), EventAttribute.getDefault()), isTrue);
			expect(identical(TxResult.getDefault(), TxResult.getDefault()), isTrue);
			expect(identical(Validator.getDefault(), Validator.getDefault()), isTrue);
			expect(identical(ValidatorUpdate.getDefault(), ValidatorUpdate.getDefault()), isTrue);
			expect(identical(VoteInfo.getDefault(), VoteInfo.getDefault()), isTrue);
			expect(identical(Evidence.getDefault(), Evidence.getDefault()), isTrue);
			expect(identical(Snapshot.getDefault(), Snapshot.getDefault()), isTrue);
		});
		
		test('complete ABCI transaction flow', () {
			// Test a complete ABCI transaction flow from request to response
			
			// 1. Create a transaction check request
			final checkTxRequest = Request(
				checkTx: RequestCheckTx(
					tx: Uint8List.fromList([10, 20, 30, 40, 50]),
					type: CheckTxType.NEW,
				),
			);
			
			expect(checkTxRequest.whichValue(), Request_Value.checkTx);
			expect(checkTxRequest.checkTx.tx, [10, 20, 30, 40, 50]);
			expect(checkTxRequest.checkTx.type, CheckTxType.NEW);
			
			// 2. Create a corresponding response
			final checkTxResponse = Response(
				checkTx: ResponseCheckTx(
					code: 0,
					data: Uint8List.fromList([100, 101, 102]),
					log: 'transaction valid',
					info: 'check passed',
					gasWanted: Int64(100000),
					gasUsed: Int64(75000),
					events: [
						Event(
							type: 'tx',
							attributes: [
								EventAttribute(
									key: Uint8List.fromList([104, 97, 115, 104]), // 'hash' as bytes
									value: Uint8List.fromList([65, 66, 67, 49, 50, 51]), // 'ABC123' as bytes
								),
								EventAttribute(
									key: Uint8List.fromList([104, 101, 105, 103, 104, 116]), // 'height' as bytes
									value: Uint8List.fromList([49, 48, 48, 48]), // '1000' as bytes
								),
							],
						),
					],
					codespace: '',
				),
			);
			
			expect(checkTxResponse.whichValue(), Response_Value.checkTx);
			expect(checkTxResponse.checkTx.code, 0);
			expect(checkTxResponse.checkTx.data, [100, 101, 102]);
			expect(checkTxResponse.checkTx.log, 'transaction valid');
			expect(checkTxResponse.checkTx.gasWanted, Int64(100000));
			expect(checkTxResponse.checkTx.gasUsed, Int64(75000));
			expect(checkTxResponse.checkTx.events.length, 1);
			expect(checkTxResponse.checkTx.events[0].type, 'tx');
			expect(checkTxResponse.checkTx.events[0].attributes.length, 2);
			
			// 3. Test serialization roundtrip
			final requestBuffer = checkTxRequest.writeToBuffer();
			final responseBuffer = checkTxResponse.writeToBuffer();
			
			final restoredRequest = Request.fromBuffer(requestBuffer);
			final restoredResponse = Response.fromBuffer(responseBuffer);
			
			expect(restoredRequest.whichValue(), Request_Value.checkTx);
			expect(restoredRequest.checkTx.tx, [10, 20, 30, 40, 50]);
			
			expect(restoredResponse.whichValue(), Response_Value.checkTx);
			expect(restoredResponse.checkTx.code, 0);
			expect(restoredResponse.checkTx.events.length, 1);
		});
		
		test('validator set operations', () {
			// Test validator set operations
			final validators = [
				Validator(
					address: Uint8List.fromList(List.generate(20, (i) => i + 1)),
					power: Int64(1000000),
				),
				Validator(
					address: Uint8List.fromList(List.generate(20, (i) => i + 21)),
					power: Int64(2000000),
				),
				Validator(
					address: Uint8List.fromList(List.generate(20, (i) => i + 41)),
					power: Int64(1500000),
				),
			];
			
			// Test validator updates
			final validatorUpdates = validators.map((v) => ValidatorUpdate(
				power: v.power,
			)).toList();
			
			expect(validatorUpdates.length, 3);
			expect(validatorUpdates[0].power, Int64(1000000));
			expect(validatorUpdates[1].power, Int64(2000000));
			expect(validatorUpdates[2].power, Int64(1500000));
			
			// Test vote info
			final voteInfos = validators.map((v) => VoteInfo(
				validator: v,
				signedLastBlock: true,
			)).toList();
			
			expect(voteInfos.length, 3);
			expect(voteInfos[0].validator.power, Int64(1000000));
			expect(voteInfos[0].signedLastBlock, true);
			expect(voteInfos[1].validator.power, Int64(2000000));
			expect(voteInfos[2].validator.power, Int64(1500000));
			
			// Test serialization of validator collections
			for (int i = 0; i < validators.length; i++) {
				final buffer = validators[i].writeToBuffer();
				final restored = Validator.fromBuffer(buffer);
				expect(restored.address, validators[i].address);
				expect(restored.power, validators[i].power);
			}
		});
		
		test('event system comprehensive', () {
			// Test comprehensive event system usage
			final events = [
				Event(
					type: 'message',
					attributes: [
						EventAttribute(
							key: Uint8List.fromList([97, 99, 116, 105, 111, 110]), // 'action' as bytes
							value: Uint8List.fromList([115, 101, 110, 100]), // 'send' as bytes
							index: true,
						),
						EventAttribute(
							key: Uint8List.fromList([115, 101, 110, 100, 101, 114]), // 'sender' as bytes
							value: Uint8List.fromList([99, 111, 115, 109, 111, 115, 49, 97, 98, 99, 49, 50, 51]), // 'cosmos1abc123' as bytes
							index: true,
						),
						EventAttribute(
							key: Uint8List.fromList([109, 111, 100, 117, 108, 101]), // 'module' as bytes
							value: Uint8List.fromList([98, 97, 110, 107]), // 'bank' as bytes
							index: false,
						),
					],
				),
				Event(
					type: 'transfer',
					attributes: [
						EventAttribute(
							key: Uint8List.fromList([114, 101, 99, 105, 112, 105, 101, 110, 116]), // 'recipient' as bytes
							value: Uint8List.fromList([99, 111, 115, 109, 111, 115, 49, 100, 101, 102, 52, 53, 54]), // 'cosmos1def456' as bytes
							index: true,
						),
						EventAttribute(
							key: Uint8List.fromList([97, 109, 111, 117, 110, 116]), // 'amount' as bytes
							value: Uint8List.fromList([49, 48, 48, 48, 115, 116, 97, 107, 101]), // '1000stake' as bytes
							index: false,
						),
					],
				),
				Event(
					type: 'coin_spent',
					attributes: [
						EventAttribute(
							key: Uint8List.fromList([115, 112, 101, 110, 100, 101, 114]), // 'spender' as bytes
							value: Uint8List.fromList([99, 111, 115, 109, 111, 115, 49, 97, 98, 99, 49, 50, 51]), // 'cosmos1abc123' as bytes
							index: true,
						),
						EventAttribute(
							key: Uint8List.fromList([97, 109, 111, 117, 110, 116]), // 'amount' as bytes
							value: Uint8List.fromList([49, 48, 48, 48, 115, 116, 97, 107, 101]), // '1000stake' as bytes
							index: false,
						),
					],
				),
				Event(
					type: 'coin_received',
					attributes: [
						EventAttribute(
							key: Uint8List.fromList([114, 101, 99, 101, 105, 118, 101, 114]), // 'receiver' as bytes
							value: Uint8List.fromList([99, 111, 115, 109, 111, 115, 49, 100, 101, 102, 52, 53, 54]), // 'cosmos1def456' as bytes
							index: true,
						),
						EventAttribute(
							key: Uint8List.fromList([97, 109, 111, 117, 110, 116]), // 'amount' as bytes
							value: Uint8List.fromList([49, 48, 48, 48, 115, 116, 97, 107, 101]), // '1000stake' as bytes
							index: false,
						),
					],
				),
			];
			
			// Verify event structure
			expect(events.length, 4);
			expect(events[0].type, 'message');
			expect(events[0].attributes.length, 3);
			expect(events[1].type, 'transfer');
			expect(events[1].attributes.length, 2);
			
			// Test indexed vs non-indexed attributes
			final messageEvent = events[0];
			expect(messageEvent.attributes[0].index, true); // action
			expect(messageEvent.attributes[1].index, true); // sender
			expect(messageEvent.attributes[2].index, false); // module
			
			// Test JSON serialization of complex event structure
			final json = jsonEncode(events.map((e) => e.writeToJsonMap()).toList());
			expect(json, isA<String>());
			
			// Test individual event serialization
			for (final event in events) {
				final buffer = event.writeToBuffer();
				final restored = Event.fromBuffer(buffer);
				expect(restored.type, event.type);
				expect(restored.attributes.length, event.attributes.length);
				
				for (int i = 0; i < event.attributes.length; i++) {
					expect(restored.attributes[i].key, event.attributes[i].key);
					expect(restored.attributes[i].value, event.attributes[i].value);
					expect(restored.attributes[i].index, event.attributes[i].index);
				}
			}
		});
		
		test('enum values coverage', () {
			// Test CheckTxType enum
			expect(CheckTxType.NEW.value, 0);
			expect(CheckTxType.RECHECK.value, 1);
			expect(CheckTxType.values.length, 2);
			expect(CheckTxType.valueOf(0), CheckTxType.NEW);
			expect(CheckTxType.valueOf(1), CheckTxType.RECHECK);
			
			// Test EvidenceType enum
			expect(EvidenceType.UNKNOWN.value, 0);
			expect(EvidenceType.DUPLICATE_VOTE.value, 1);
			expect(EvidenceType.LIGHT_CLIENT_ATTACK.value, 2);
			expect(EvidenceType.values.length, 3);
			expect(EvidenceType.valueOf(0), EvidenceType.UNKNOWN);
			expect(EvidenceType.valueOf(1), EvidenceType.DUPLICATE_VOTE);
			expect(EvidenceType.valueOf(2), EvidenceType.LIGHT_CLIENT_ATTACK);
		});
	});
} 