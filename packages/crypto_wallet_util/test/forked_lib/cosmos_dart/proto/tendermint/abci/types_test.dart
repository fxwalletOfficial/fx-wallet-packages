import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/abci/types.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/timestamp.pb.dart';

void main() {
	group('tendermint.abci types basic', () {
		test('Request oneof set/clear and ensure methods', () {
			final req = Request()..echo = RequestEcho(message: 'hi');
			expect(req.hasEcho(), isTrue);
			req.clearEcho();
			expect(req.hasEcho(), isFalse);
			req.ensureFlush();
			expect(req.hasFlush(), isTrue);
			final clone = req.clone();
			expect(clone.hasFlush(), isTrue);
		});

		test('Response oneof set/clear and defaults', () {
			final resp = Response()..echo = ResponseEcho(message: 'ok');
			expect(resp.hasEcho(), isTrue);
			resp.clearEcho();
			expect(resp.hasEcho(), isFalse);
			expect(Response.createRepeated(), isA<pb.PbList<Response>>());
		});

				test('Event and EventAttribute list ops', () {
			final e = Event(type: 't', attributes: [EventAttribute(key: [0x6b], value: [0x76], index: true)]);
			expect(e.attributes.first.index, isTrue);
			final bz = e.writeToBuffer();
			expect(Event.fromBuffer(bz).type, 't');
			final copied = e.copyWith((x) => x.attributes.add(EventAttribute(key: [0x6b, 0x32])));
			expect(copied.attributes.length, 2);
		});

				test('ResponseInfo/RequestInfo minimal fields', () {
			final ri = ResponseInfo(data: 'd', version: 'v', appVersion: Int64(1));
			final bz = ri.writeToBuffer();
			expect(ResponseInfo.fromBuffer(bz).appVersion.toInt(), 1);
			final rqi = RequestInfo(version: 'v', blockVersion: Int64(1), p2pVersion: Int64(1));
			final j = jsonEncode(rqi.writeToJsonMap());
			expect(jsonDecode(j), isA<Map>());
		});
	});

	group('ABCI Core Enums', () {
		test('Request_Value enum should have all expected values', () {
			expect(Request_Value.echo, isNotNull);
			expect(Request_Value.flush, isNotNull);
			expect(Request_Value.info, isNotNull);
			expect(Request_Value.setOption, isNotNull);
			expect(Request_Value.initChain, isNotNull);
			expect(Request_Value.query, isNotNull);
			expect(Request_Value.beginBlock, isNotNull);
			expect(Request_Value.checkTx, isNotNull);
			expect(Request_Value.deliverTx, isNotNull);
			expect(Request_Value.endBlock, isNotNull);
			expect(Request_Value.commit, isNotNull);
			expect(Request_Value.listSnapshots, isNotNull);
			expect(Request_Value.offerSnapshot, isNotNull);
			expect(Request_Value.loadSnapshotChunk, isNotNull);
			expect(Request_Value.applySnapshotChunk, isNotNull);
			expect(Request_Value.notSet, isNotNull);
		});

		test('Response_Value enum should have all expected values', () {
			expect(Response_Value.exception, isNotNull);
			expect(Response_Value.echo, isNotNull);
			expect(Response_Value.flush, isNotNull);
			expect(Response_Value.info, isNotNull);
			expect(Response_Value.setOption, isNotNull);
			expect(Response_Value.initChain, isNotNull);
			expect(Response_Value.query, isNotNull);
			expect(Response_Value.beginBlock, isNotNull);
			expect(Response_Value.checkTx, isNotNull);
			expect(Response_Value.deliverTx, isNotNull);
			expect(Response_Value.endBlock, isNotNull);
			expect(Response_Value.commit, isNotNull);
			expect(Response_Value.listSnapshots, isNotNull);
			expect(Response_Value.offerSnapshot, isNotNull);
			expect(Response_Value.loadSnapshotChunk, isNotNull);
			expect(Response_Value.applySnapshotChunk, isNotNull);
			expect(Response_Value.notSet, isNotNull);
		});

		test('CheckTxType enum should have expected values', () {
			expect(CheckTxType.NEW, isNotNull);
			expect(CheckTxType.RECHECK, isNotNull);
		});

		test('ResponseOfferSnapshot_Result enum should have expected values', () {
			expect(ResponseOfferSnapshot_Result.UNKNOWN, isNotNull);
			expect(ResponseOfferSnapshot_Result.ACCEPT, isNotNull);
			expect(ResponseOfferSnapshot_Result.ABORT, isNotNull);
			expect(ResponseOfferSnapshot_Result.REJECT, isNotNull);
			expect(ResponseOfferSnapshot_Result.REJECT_FORMAT, isNotNull);
			expect(ResponseOfferSnapshot_Result.REJECT_SENDER, isNotNull);
		});

		test('ResponseApplySnapshotChunk_Result enum should have expected values', () {
			expect(ResponseApplySnapshotChunk_Result.UNKNOWN, isNotNull);
			expect(ResponseApplySnapshotChunk_Result.ACCEPT, isNotNull);
			expect(ResponseApplySnapshotChunk_Result.ABORT, isNotNull);
			expect(ResponseApplySnapshotChunk_Result.RETRY, isNotNull);
			expect(ResponseApplySnapshotChunk_Result.RETRY_SNAPSHOT, isNotNull);
			expect(ResponseApplySnapshotChunk_Result.REJECT_SNAPSHOT, isNotNull);
		});

		test('EvidenceType enum should have expected values', () {
			expect(EvidenceType.UNKNOWN, isNotNull);
			expect(EvidenceType.DUPLICATE_VOTE, isNotNull);
			expect(EvidenceType.LIGHT_CLIENT_ATTACK, isNotNull);
		});
	});

	group('ABCI Core Messages', () {
		test('Request should support oneof value switching', () {
			final request = Request();
			
			// Initially not set
			expect(request.whichValue(), equals(Request_Value.notSet));
			
			// Set echo
			request.echo = RequestEcho(message: 'test echo');
			expect(request.whichValue(), equals(Request_Value.echo));
			expect(request.hasEcho(), isTrue);
			
			// Switch to info
			request.info = RequestInfo(version: '1.0');
			expect(request.whichValue(), equals(Request_Value.info));
			expect(request.hasInfo(), isTrue);
			expect(request.hasEcho(), isFalse); // Should clear previous value
			
			// Clear current
			request.clearValue();
			expect(request.whichValue(), equals(Request_Value.notSet));
			expect(request.hasInfo(), isFalse);
		});

		test('Response should support oneof value switching', () {
			final response = Response();
			
			// Initially not set
			expect(response.whichValue(), equals(Response_Value.notSet));
			
			// Set echo
			response.echo = ResponseEcho(message: 'test response');
			expect(response.whichValue(), equals(Response_Value.echo));
			expect(response.hasEcho(), isTrue);
			
			// Switch to info
			response.info = ResponseInfo(data: 'app', version: '1.0', appVersion: Int64(1));
			expect(response.whichValue(), equals(Response_Value.info));
			expect(response.hasInfo(), isTrue);
			expect(response.hasEcho(), isFalse); // Should clear previous value
			
			// Clear current
			response.clearValue();
			expect(response.whichValue(), equals(Response_Value.notSet));
			expect(response.hasInfo(), isFalse);
		});

		test('Event should handle attributes correctly', () {
			final event = Event();
			expect(event.type, isEmpty);
			expect(event.attributes, isEmpty);
			
			// Add attributes
			event.type = 'transfer';
			event.attributes.add(EventAttribute(
				key: Uint8List.fromList('sender'.codeUnits),
				value: Uint8List.fromList('cosmos1abc123'.codeUnits),
				index: true,
			));
			event.attributes.add(EventAttribute(
				key: Uint8List.fromList('recipient'.codeUnits),
				value: Uint8List.fromList('cosmos1def456'.codeUnits),
				index: true,
			));
			
			expect(event.type, equals('transfer'));
			expect(event.attributes.length, equals(2));
			expect(event.attributes[0].index, isTrue);
			expect(event.attributes[1].index, isTrue);
		});

		test('EventAttribute should handle key-value pairs', () {
			final attr = EventAttribute(
				key: Uint8List.fromList('amount'.codeUnits),
				value: Uint8List.fromList('1000uatom'.codeUnits),
				index: false,
			);
			
			expect(String.fromCharCodes(attr.key), equals('amount'));
			expect(String.fromCharCodes(attr.value), equals('1000uatom'));
			expect(attr.index, isFalse);
			expect(attr.hasIndex(), isTrue);
			
			// Test clearing
			attr.clearKey();
			expect(attr.key, isEmpty);
			expect(attr.hasKey(), isFalse);
		});

		test('Validator should handle power and public key', () {
			final validator = Validator(
				address: Uint8List.fromList(List.filled(20, 0x42)),
				power: Int64(1000),
			);
			
			expect(validator.address.length, equals(20));
			expect(validator.power, equals(Int64(1000)));
			expect(validator.hasPower(), isTrue);
			
			// Test clearing and ensuring fields
			validator.clearPower();
			expect(validator.hasPower(), isFalse);
			expect(validator.power, equals(Int64.ZERO));
		});

		test('ValidatorUpdate should handle power changes', () {
			final update = ValidatorUpdate(power: Int64(2000));
			
			expect(update.power, equals(Int64(2000)));
			expect(update.hasPower(), isTrue);
			
			// Zero power means remove validator
			final removeUpdate = ValidatorUpdate(power: Int64.ZERO);
			expect(removeUpdate.power, equals(Int64.ZERO));
		});

		test('VoteInfo should handle validator and vote data', () {
			final voteInfo = VoteInfo(
				validator: Validator(
					address: Uint8List.fromList(List.filled(20, 0x01)),
					power: Int64(500),
				),
				signedLastBlock: true,
			);
			
			expect(voteInfo.hasValidator(), isTrue);
			expect(voteInfo.validator.power, equals(Int64(500)));
			expect(voteInfo.signedLastBlock, isTrue);
			expect(voteInfo.hasSignedLastBlock(), isTrue);
		});

		test('Evidence should handle malicious behavior data', () {
			final evidence = Evidence(
				type: EvidenceType.DUPLICATE_VOTE,
				validator: Validator(
					address: Uint8List.fromList(List.filled(20, 0xff)),
					power: Int64(100),
				),
				height: Int64(12345),
				time: Timestamp(seconds: Int64(1234567890), nanos: 0),
				totalVotingPower: Int64(10000),
			);
			
			expect(evidence.type, equals(EvidenceType.DUPLICATE_VOTE));
			expect(evidence.hasValidator(), isTrue);
			expect(evidence.validator.power, equals(Int64(100)));
			expect(evidence.height, equals(Int64(12345)));
			expect(evidence.hasTime(), isTrue);
			expect(evidence.totalVotingPower, equals(Int64(10000)));
		});

		test('TxResult should handle transaction execution results', () {
			final txResult = TxResult(
				height: Int64(100),
				index: 5,
				tx: Uint8List.fromList([0x01, 0x02, 0x03]),
				result: ResponseDeliverTx(
					code: 0,
					data: Uint8List.fromList([0x04, 0x05]),
					log: 'transaction executed successfully',
					gasWanted: Int64(50000),
					gasUsed: Int64(45000),
				),
			);
			
			expect(txResult.height, equals(Int64(100)));
			expect(txResult.index, equals(5));
			expect(txResult.tx, equals([0x01, 0x02, 0x03]));
			expect(txResult.hasResult(), isTrue);
			expect(txResult.result.code, equals(0));
			expect(txResult.result.log, equals('transaction executed successfully'));
			expect(txResult.result.gasWanted, equals(Int64(50000)));
			expect(txResult.result.gasUsed, equals(Int64(45000)));
		});

		test('LastCommitInfo should handle commit data', () {
			final commitInfo = LastCommitInfo(
				round: 1,
				votes: [
					VoteInfo(
						validator: Validator(
							address: Uint8List.fromList(List.filled(20, 0x11)),
							power: Int64(1000),
						),
						signedLastBlock: true,
					),
					VoteInfo(
						validator: Validator(
							address: Uint8List.fromList(List.filled(20, 0x22)),
							power: Int64(2000),
						),
						signedLastBlock: false,
					),
				],
			);
			
			expect(commitInfo.round, equals(1));
			expect(commitInfo.votes.length, equals(2));
			expect(commitInfo.votes[0].signedLastBlock, isTrue);
			expect(commitInfo.votes[1].signedLastBlock, isFalse);
		});

		test('Snapshot should handle state sync data', () {
			final snapshot = Snapshot(
				height: Int64(50000),
				format: 1,
				chunks: 10,
				hash: Uint8List.fromList(List.filled(32, 0xaa)),
				metadata: Uint8List.fromList([0x01, 0x02, 0x03, 0x04]),
			);
			
			expect(snapshot.height, equals(Int64(50000)));
			expect(snapshot.format, equals(1));
			expect(snapshot.chunks, equals(10));
			expect(snapshot.hash.length, equals(32));
			expect(snapshot.metadata, equals([0x01, 0x02, 0x03, 0x04]));
		});
	});

	group('ABCI Serialization', () {
		test('Request should serialize and deserialize correctly', () {
			final originalRequest = Request(
				echo: RequestEcho(message: 'test serialization'),
			);
			
			// Test buffer serialization
			final buffer = originalRequest.writeToBuffer();
			final deserializedRequest = Request.fromBuffer(buffer);
			
			expect(deserializedRequest.whichValue(), equals(Request_Value.echo));
			expect(deserializedRequest.echo.message, equals('test serialization'));
		});

		test('Response should serialize and deserialize correctly', () {
			final originalResponse = Response(
				info: ResponseInfo(
					data: 'test app',
					version: '1.0.0',
					appVersion: Int64(42),
				),
			);
			
			// Test buffer serialization
			final buffer = originalResponse.writeToBuffer();
			final deserializedResponse = Response.fromBuffer(buffer);
			
			expect(deserializedResponse.whichValue(), equals(Response_Value.info));
			expect(deserializedResponse.info.data, equals('test app'));
			expect(deserializedResponse.info.version, equals('1.0.0'));
			expect(deserializedResponse.info.appVersion, equals(Int64(42)));
		});

		test('Event should serialize and deserialize correctly', () {
			final originalEvent = Event(
				type: 'test_event',
				attributes: [
					EventAttribute(
						key: Uint8List.fromList('key1'.codeUnits),
						value: Uint8List.fromList('value1'.codeUnits),
						index: true,
					),
					EventAttribute(
						key: Uint8List.fromList('key2'.codeUnits),
						value: Uint8List.fromList('value2'.codeUnits),
						index: false,
					),
				],
			);
			
			// Test buffer serialization
			final buffer = originalEvent.writeToBuffer();
			final deserializedEvent = Event.fromBuffer(buffer);
			
			expect(deserializedEvent.type, equals('test_event'));
			expect(deserializedEvent.attributes.length, equals(2));
			expect(String.fromCharCodes(deserializedEvent.attributes[0].key), equals('key1'));
			expect(String.fromCharCodes(deserializedEvent.attributes[0].value), equals('value1'));
			expect(deserializedEvent.attributes[0].index, isTrue);
			expect(String.fromCharCodes(deserializedEvent.attributes[1].key), equals('key2'));
			expect(String.fromCharCodes(deserializedEvent.attributes[1].value), equals('value2'));
			expect(deserializedEvent.attributes[1].index, isFalse);
		});

		test('Complex nested structures should serialize correctly', () {
			final txResult = TxResult(
				height: Int64(12345),
				index: 7,
				tx: Uint8List.fromList('test transaction'.codeUnits),
				result: ResponseDeliverTx(
					code: 0,
					data: Uint8List.fromList('result data'.codeUnits),
					log: 'execution successful',
					gasWanted: Int64(100000),
					gasUsed: Int64(95000),
					events: [
						Event(
							type: 'transfer',
							attributes: [
								EventAttribute(
									key: Uint8List.fromList('amount'.codeUnits),
									value: Uint8List.fromList('1000uatom'.codeUnits),
									index: true,
								),
							],
						),
					],
				),
			);
			
			// Test serialization roundtrip
			final buffer = txResult.writeToBuffer();
			final deserialized = TxResult.fromBuffer(buffer);
			
			expect(deserialized.height, equals(Int64(12345)));
			expect(deserialized.index, equals(7));
			expect(String.fromCharCodes(deserialized.tx), equals('test transaction'));
			expect(deserialized.result.code, equals(0));
			expect(deserialized.result.log, equals('execution successful'));
			expect(deserialized.result.events.length, equals(1));
			expect(deserialized.result.events[0].type, equals('transfer'));
			expect(deserialized.result.events[0].attributes.length, equals(1));
			expect(String.fromCharCodes(deserialized.result.events[0].attributes[0].key), equals('amount'));
			expect(String.fromCharCodes(deserialized.result.events[0].attributes[0].value), equals('1000uatom'));
		});
	});

	group('ABCI Default Values and Factories', () {
		test('Message factories should create proper defaults', () {
			// Test default instances
			expect(Request.getDefault(), isA<Request>());
			expect(Response.getDefault(), isA<Response>());
			expect(Event.getDefault(), isA<Event>());
			expect(EventAttribute.getDefault(), isA<EventAttribute>());
			expect(Validator.getDefault(), isA<Validator>());
			expect(TxResult.getDefault(), isA<TxResult>());
			
			// Test repeated factories
			expect(Request.createRepeated(), isA<pb.PbList<Request>>());
			expect(Response.createRepeated(), isA<pb.PbList<Response>>());
			expect(Event.createRepeated(), isA<pb.PbList<Event>>());
			expect(EventAttribute.createRepeated(), isA<pb.PbList<EventAttribute>>());
		});

		test('Empty instances should have expected default values', () {
			final request = Request();
			expect(request.whichValue(), equals(Request_Value.notSet));
			
			final response = Response();
			expect(response.whichValue(), equals(Response_Value.notSet));
			
			final event = Event();
			expect(event.type, isEmpty);
			expect(event.attributes, isEmpty);
			
			final validator = Validator();
			expect(validator.address, isEmpty);
			expect(validator.power, equals(Int64.ZERO));
			
			final evidence = Evidence();
			expect(evidence.type, equals(EvidenceType.UNKNOWN));
			expect(evidence.height, equals(Int64.ZERO));
		});

		test('Clone and copyWith should work correctly', () {
			final originalEvent = Event(
				type: 'test',
				attributes: [
					EventAttribute(
						key: Uint8List.fromList('key'.codeUnits),
						value: Uint8List.fromList('value'.codeUnits),
						index: true,
					),
				],
			);
			
			// Test clone
			final cloned = originalEvent.clone();
			expect(cloned.type, equals('test'));
			expect(cloned.attributes.length, equals(1));
			expect(String.fromCharCodes(cloned.attributes[0].key), equals('key'));
			
			// Test copyWith
			final modified = originalEvent.copyWith((event) {
				event.type = 'modified';
				event.attributes.add(EventAttribute(
					key: Uint8List.fromList('new_key'.codeUnits),
					value: Uint8List.fromList('new_value'.codeUnits),
					index: false,
				));
			});
			
			expect(modified.type, equals('modified'));
			expect(modified.attributes.length, equals(2));
			expect(String.fromCharCodes(modified.attributes[1].key), equals('new_key'));
			
			// Original should be unchanged
			expect(originalEvent.type, equals('test'));
			expect(originalEvent.attributes.length, equals(1));
		});
	});
} 