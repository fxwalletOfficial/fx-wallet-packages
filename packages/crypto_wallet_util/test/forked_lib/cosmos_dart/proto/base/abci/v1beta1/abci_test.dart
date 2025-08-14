import 'dart:convert';

import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/abci/v1beta1/abci.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/any.pb.dart' as anypb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/abci/types.pb.dart' as tend;
import 'package:protobuf/protobuf.dart' as pb;

void main() {
	group('cosmos.base.abci.v1beta1 TxResponse', () {
		test('has/clear/ensure/clone/copyWith/json/buffer', () {
			final tx = TxResponse(
				height: Int64(10),
				txhash: 'hash',
				codespace: 'code',
				code: 1,
				data: 'data',
				rawLog: 'raw',
				logs: [ABCIMessageLog(msgIndex: 0, log: 'l')],
				info: 'info',
				gasWanted: Int64(100),
				gasUsed: Int64(90),
				tx: anypb.Any(typeUrl: 'url', value: []),
				timestamp: 'ts',
				events: [tend.Event()]
			);
			expect(tx.hasTxhash(), isTrue);
			tx.clearTxhash();
			expect(tx.hasTxhash(), isFalse);
			final bz = tx.writeToBuffer();
			final tx2 = TxResponse.fromBuffer(bz);
			expect(tx2.height.toInt(), 10);
			final j = jsonEncode(tx.writeToJsonMap());
			expect(jsonDecode(j), isA<Map>());
			final copied = tx.copyWith((t) => t.info = 'i2');
			expect(copied.info, 'i2');
		});
	});

	group('cosmos.base.abci.v1beta1 models', () {
		test('ABCIMessageLog/StringEvent/Attribute list ops', () {
			final ev = StringEvent(type: 't', attributes: [Attribute(key: 'k', value: 'v')]);
			final log = ABCIMessageLog(msgIndex: 1, log: 'l', events: [ev]);
			expect(log.events.first.type, 't');
			final clone = log.clone();
			expect(clone.msgIndex, 1);
			final attr = Attribute(key: 'a', value: 'b');
			attr.clearValue();
			expect(attr.hasValue(), isFalse);
		});

		test('GasInfo/Result has/clear', () {
			final gi = GasInfo(gasWanted: Int64(1), gasUsed: Int64(2));
			expect(gi.hasGasWanted(), isTrue);
			gi.clearGasUsed();
			expect(gi.hasGasUsed(), isFalse);
			final res = Result(data: [1,2], log: 'ok');
			res.events.add(tend.Event());
			expect(res.events.length, 1);
			final res2 = Result.fromBuffer(res.writeToBuffer());
			expect(res2.log, 'ok');
		});

		test('SimulationResponse ensure/clear and MsgData/TxMsgData', () {
			final sr = SimulationResponse();
			expect(sr.ensureGasInfo(), isA<GasInfo>());
			sr.clearResult();
			expect(sr.hasResult(), isFalse);
			final md = MsgData(msgType: 't', data: [1]);
			final tmd = TxMsgData(data: [md]);
			expect(tmd.data.first.msgType, 't');
		});

		test('SearchTxsResult list ops and defaults', () {
			final s = SearchTxsResult(totalCount: Int64(1), count: Int64(1), pageNumber: Int64(1), pageTotal: Int64(1), limit: Int64(50));
			s.txs.add(TxResponse());
			expect(s.txs.length, 1);
			final s2 = SearchTxsResult.fromBuffer(s.writeToBuffer());
			expect(s2.limit.toInt(), 50);
		});
	});

	group('cosmos.base.abci.v1beta1 more coverage', () {
		test('TxResponse ensureTx identity, has/clear for multiple fields, info_/defaults', () {
			final any = anypb.Any(typeUrl: 'url', value: []);
			final tx = TxResponse(tx: any);
			final ensured = tx.ensureTx();
			expect(identical(ensured, any), isTrue);
			// has/clear on string/int fields
			tx
				..codespace = 'cs'
				..code = 3
				..data = 'd'
				..rawLog = 'r'
				..info = 'i'
				..timestamp = 't';
			expect(tx.hasCodespace(), isTrue);
			tx.clearCodespace();
			expect(tx.hasCodespace(), isFalse);
			expect(tx.hasCode(), isTrue);
			tx.clearCode();
			expect(tx.hasCode(), isFalse);
			expect(tx.hasData(), isTrue);
			tx.clearData();
			expect(tx.hasData(), isFalse);
			expect(tx.hasRawLog(), isTrue);
			tx.clearRawLog();
			expect(tx.hasRawLog(), isFalse);
			expect(tx.hasInfo(), isTrue);
			tx.clearInfo();
			expect(tx.hasInfo(), isFalse);
			expect(tx.hasTimestamp(), isTrue);
			tx.clearTimestamp();
			expect(tx.hasTimestamp(), isFalse);
			// list ops
			tx.logs.add(ABCIMessageLog(msgIndex: 2));
			tx.events.add(tend.Event());
			expect(tx.logs.length, 1);
			expect(tx.events.length, 1);
			// clone deep copy lists
			final cloned = tx.clone();
			tx.logs.clear();
			expect(cloned.logs.length, 1);
			// defaults/info_
			expect(TxResponse.getDefault().info_.messageName, contains('TxResponse'));
			expect(TxResponse.createRepeated(), isA<pb.PbList<TxResponse>>());
			// error json
			expect(() => TxResponse.fromJson('bad'), throwsA(isA<FormatException>()));
		});

		test('ABCIMessageLog/StringEvent/Attribute defaults/info_/errors', () {
			expect(ABCIMessageLog.getDefault().info_.messageName, contains('ABCIMessageLog'));
			expect(ABCIMessageLog.createRepeated(), isA<pb.PbList<ABCIMessageLog>>());
			expect(() => ABCIMessageLog.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(StringEvent.getDefault().info_.messageName, contains('StringEvent'));
			expect(StringEvent.createRepeated(), isA<pb.PbList<StringEvent>>());
			expect(() => StringEvent.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(Attribute.getDefault().info_.messageName, contains('Attribute'));
			expect(Attribute.createRepeated(), isA<pb.PbList<Attribute>>());
			expect(() => Attribute.fromJson('bad'), throwsA(isA<FormatException>()));
		});

		test('GasInfo/Result defaults/info_/errors', () {
			expect(GasInfo.getDefault().info_.messageName, contains('GasInfo'));
			expect(GasInfo.createRepeated(), isA<pb.PbList<GasInfo>>());
			expect(() => GasInfo.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(Result.getDefault().info_.messageName, contains('Result'));
			expect(Result.createRepeated(), isA<pb.PbList<Result>>());
			expect(() => Result.fromJson('bad'), throwsA(isA<FormatException>()));
		});

		test('SimulationResponse/MsgData/TxMsgData/SearchTxsResult defaults/info_/errors', () {
			expect(SimulationResponse.getDefault().info_.messageName, contains('SimulationResponse'));
			expect(SimulationResponse.createRepeated(), isA<pb.PbList<SimulationResponse>>());
			expect(() => SimulationResponse.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(MsgData.getDefault().info_.messageName, contains('MsgData'));
			expect(MsgData.createRepeated(), isA<pb.PbList<MsgData>>());
			expect(() => MsgData.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(TxMsgData.getDefault().info_.messageName, contains('TxMsgData'));
			expect(TxMsgData.createRepeated(), isA<pb.PbList<TxMsgData>>());
			expect(() => TxMsgData.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(SearchTxsResult.getDefault().info_.messageName, contains('SearchTxsResult'));
			expect(SearchTxsResult.createRepeated(), isA<pb.PbList<SearchTxsResult>>());
			expect(() => SearchTxsResult.fromJson('bad'), throwsA(isA<FormatException>()));
		});
	});

	group('cosmos.base.abci.v1beta1 deep coverage', () {
		test('TxResponse has/clear for height/gas fields and copyWith on nested lists', () {
			final tx = TxResponse(height: Int64(1), gasWanted: Int64(2), gasUsed: Int64(3));
			expect(tx.hasHeight(), isTrue);
			tx.clearHeight();
			expect(tx.hasHeight(), isFalse);
			expect(tx.hasGasWanted(), isTrue);
			tx.clearGasWanted();
			expect(tx.hasGasWanted(), isFalse);
			expect(tx.hasGasUsed(), isTrue);
			tx.clearGasUsed();
			expect(tx.hasGasUsed(), isFalse);
			final withLogs = tx.copyWith((t) => t.logs.add(ABCIMessageLog(msgIndex: 9)));
			expect(withLogs.logs.first.msgIndex, 9);
			final withEvents = withLogs.copyWith((t) => t.events.add(tend.Event()));
			expect(withEvents.events.length, 1);
		});

		test('ABCIMessageLog events list add/remove and info_', () {
			final log = ABCIMessageLog(msgIndex: 5, log: 'x');
			log.events.add(StringEvent(type: 't'));
			expect(log.events.length, 1);
			log.events.removeAt(0);
			expect(log.events, isEmpty);
			expect(ABCIMessageLog.getDefault().info_.messageName, contains('ABCIMessageLog'));
		});

		test('StringEvent attributes list ops and defaults', () {
			final se = StringEvent(type: 'evt');
			se.attributes.add(Attribute(key: 'k', value: 'v'));
			expect(se.attributes.first.key, 'k');
			se.clearType();
			expect(se.hasType(), isFalse);
			expect(StringEvent.createRepeated(), isA<pb.PbList<StringEvent>>());
		});

		test('Attribute clearKey/value and defaults', () {
			final a = Attribute(key: 'k', value: 'v');
			a.clearKey();
			expect(a.hasKey(), isFalse);
			a.clearValue();
			expect(a.hasValue(), isFalse);
			expect(Attribute.createRepeated(), isA<pb.PbList<Attribute>>());
		});

		test('GasInfo defaults and copyWith', () {
			final gi = GasInfo(gasWanted: Int64(7));
			final gi2 = gi.copyWith((g) => g.gasUsed = Int64(8));
			expect(gi2.gasUsed.toInt(), 8);
			expect(GasInfo.getDefault().info_.messageName, contains('GasInfo'));
		});

		test('Result has/clear data with bytes and json', () {
			final r = Result(data: [0xAA, 0xBB], log: 'ok');
			expect(r.hasData(), isTrue);
			r.clearData();
			expect(r.hasData(), isFalse);
			final j = jsonEncode(r.writeToJsonMap());
			expect(jsonDecode(j), isA<Map>());
		});

		test('SimulationResponse ensureResult identity/clearGasInfo', () {
			final sr = SimulationResponse(result: Result());
			final ensured = sr.ensureResult();
			expect(identical(ensured, sr.result), isTrue);
			sr.clearGasInfo();
			expect(sr.hasGasInfo(), isFalse);
		});

		test('MsgData has/clear msgType and data bytes', () {
			final m = MsgData(msgType: 'm', data: [1,2,3]);
			expect(m.hasMsgType(), isTrue);
			m.clearMsgType();
			expect(m.hasMsgType(), isFalse);
			expect(m.hasData(), isTrue);
			m.clearData();
			expect(m.hasData(), isFalse);
		});

		test('TxMsgData clone deep copy and createRepeated/info_', () {
			final t = TxMsgData(data: [MsgData(msgType: 'm', data: [1])]);
			final cl = t.clone();
			t.data.clear();
			expect(cl.data.length, 1);
			expect(TxMsgData.createRepeated(), isA<pb.PbList<TxMsgData>>());
			expect(TxMsgData.getDefault().info_.messageName, contains('TxMsgData'));
		});

		test('SearchTxsResult has/clear all scalar fields and copyWith', () {
			final s = SearchTxsResult(
				totalCount: Int64(1), count: Int64(2), pageNumber: Int64(3), pageTotal: Int64(4), limit: Int64(5)
			);
			expect(s.hasTotalCount(), isTrue);
			s.clearTotalCount();
			expect(s.hasTotalCount(), isFalse);
			expect(s.hasCount(), isTrue);
			s.clearCount();
			expect(s.hasCount(), isFalse);
			expect(s.hasPageNumber(), isTrue);
			s.clearPageNumber();
			expect(s.hasPageNumber(), isFalse);
			expect(s.hasPageTotal(), isTrue);
			s.clearPageTotal();
			expect(s.hasPageTotal(), isFalse);
			expect(s.hasLimit(), isTrue);
			s.clearLimit();
			expect(s.hasLimit(), isFalse);
			final s2 = s.copyWith((x) => x.limit = Int64(99));
			expect(s2.limit.toInt(), 99);
		});
	});

	group('cosmos.base.abci.v1beta1 extremes & errors', () {
		test('TxResponse ensureTx creates when null and minimal fromJson', () {
			final tx = TxResponse();
			final anyCreated = tx.ensureTx();
			expect(anyCreated, isNotNull);
			final m = TxResponse(height: Int64(12), gasWanted: Int64(0), gasUsed: Int64(0)).writeToJsonMap();
			final txMin = TxResponse.fromJson(jsonEncode(m));
			expect(txMin.height.toInt(), 12);
		});

		test('fromBuffer invalid throws for multiple messages', () {
			expect(() => ABCIMessageLog.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => StringEvent.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => Attribute.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => GasInfo.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => Result.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => SimulationResponse.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => MsgData.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => TxMsgData.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => SearchTxsResult.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
		});

		test('SearchTxsResult Int64 extreme values', () {
			final max = Int64.MAX_VALUE;
			final s = SearchTxsResult(totalCount: max, count: max, pageNumber: max, pageTotal: max, limit: max);
			final s2 = SearchTxsResult.fromBuffer(s.writeToBuffer());
			expect(s2.totalCount, max);
			expect(s2.limit, max);
		});
	});

	group('cosmos.base.abci.v1beta1 TxResponse extremes', () {
		test('Max Int64 values and large lists', () {
			final maxInt = Int64.MAX_VALUE;
			final tx = TxResponse(
				height: maxInt,
				gasWanted: maxInt,
				gasUsed: maxInt,
				logs: List.generate(100, (i) => ABCIMessageLog(msgIndex: i)),
				events: List.generate(50, (i) => tend.Event(type: 'event$i')),
			);

			final bz = tx.writeToBuffer();
			final decoded = TxResponse.fromBuffer(bz);
			expect(decoded.height, maxInt);
			expect(decoded.logs.length, 100);
			expect(decoded.events.first.type, 'event0');
		});

		test('ensureTx creates new Any when null', () {
			final tx = TxResponse();
			expect(tx.hasTx(), isFalse);
			final created = tx.ensureTx();
			expect(created, isA<anypb.Any>());
			expect(tx.hasTx(), isTrue);
		});

		test('Error paths for invalid buffer/json', () {
			expect(() => TxResponse.fromBuffer([0xFF]),
					throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => TxResponse.fromJson('{invalid}'),
					throwsA(isA<FormatException>()));
		});

		test('copyWith modifies lists correctly', () {
			final original = TxResponse(logs: [ABCIMessageLog()]);
			final modified = original.copyWith((x) => x.logs.add(ABCIMessageLog(msgIndex: 1)));
			expect(modified.logs.length, 2);
			expect(modified.logs.last.msgIndex, 1);
		});
	});

	group('cosmos.base.abci.v1beta1 ABCIMessageLog', () {
		test('Nested StringEvent list operations', () {
			final log = ABCIMessageLog(
				events: [StringEvent(type: 't', attributes: [
					Attribute(key: 'k1', value: 'v1'),
					Attribute(key: 'k2', value: 'v2')
				])]
			);

			final copied = log.copyWith((x) =>
				x.events.first.attributes.add(Attribute(key: 'k3')));
			expect(copied.events.first.attributes.length, 3);
		});
	});

	group('cosmos.base.abci.v1beta1 json roundtrips & defaults', () {
		test('ABCIMessageLog json roundtrip with nested StringEvent/Attribute', () {
			final log = ABCIMessageLog(
				msgIndex: 7,
				log: 'l',
				events: [
					StringEvent(type: 'tt', attributes: [
						Attribute(key: 'k', value: 'v')
					])
				]
			);
			final j = jsonEncode(log.writeToJsonMap());
			final decoded = ABCIMessageLog.fromJson(j);
			expect(decoded.msgIndex, 7);
			expect(decoded.events.first.type, 'tt');
			// has/clear additional fields
			expect(decoded.hasLog(), isTrue);
			decoded.clearLog();
			expect(decoded.hasLog(), isFalse);
		});

		test('StringEvent json roundtrip and defaults', () {
			final se = StringEvent(type: 'evt', attributes: [Attribute(key: 'a', value: 'b')]);
			final j = jsonEncode(se.writeToJsonMap());
			final decoded = StringEvent.fromJson(j);
			expect(decoded.type, 'evt');
			expect(decoded.attributes.first.value, 'b');
			expect(identical(StringEvent.getDefault(), StringEvent.getDefault()), isTrue);
			expect(StringEvent().createEmptyInstance(), isA<StringEvent>());
		});

		test('Attribute json roundtrip, has/clear, createEmptyInstance', () {
			final a = Attribute(key: 'k', value: 'v');
			final j = jsonEncode(a.writeToJsonMap());
			final d = Attribute.fromJson(j);
			expect(d.key, 'k');
			expect(d.value, 'v');
			d.clearKey();
			expect(d.hasKey(), isFalse);
			expect(Attribute().createEmptyInstance(), isA<Attribute>());
		});

		test('GasInfo json roundtrip and getDefault identity', () {
			final g = GasInfo(gasWanted: Int64(11), gasUsed: Int64(22));
			final j = jsonEncode(g.writeToJsonMap());
			final d = GasInfo.fromJson(j);
			expect(d.gasWanted.toInt(), 11);
			expect(d.gasUsed.toInt(), 22);
			expect(identical(GasInfo.getDefault(), GasInfo.getDefault()), isTrue);
		});

		test('Result json roundtrip (bytes/log) and has/clear log', () {
			final r = Result(data: [0x01, 0x02, 0x03], log: 'ok');
			final j = jsonEncode(r.writeToJsonMap());
			final d = Result.fromJson(j);
			expect(d.data.length, 3);
			expect(d.log, 'ok');
			expect(d.hasLog(), isTrue);
			d.clearLog();
			expect(d.hasLog(), isFalse);
		});

		test('SimulationResponse json roundtrip and ensureX identity', () {
			final sr = SimulationResponse(
				gasInfo: GasInfo(gasWanted: Int64(1), gasUsed: Int64(2)),
				result: Result(log: 'res'),
			);
			final j = jsonEncode(sr.writeToJsonMap());
			final d = SimulationResponse.fromJson(j);
			expect(d.gasInfo.gasUsed.toInt(), 2);
			expect(d.result.log, 'res');
			// ensure existing keeps identity
			final prev = d.gasInfo;
			final ensured = d.ensureGasInfo();
			expect(identical(prev, ensured), isTrue);
		});

		test('MsgData json roundtrip (bytes and string type) and has/clear', () {
			final m = MsgData(msgType: 'mt', data: [0xAA]);
			final j = jsonEncode(m.writeToJsonMap());
			final d = MsgData.fromJson(j);
			expect(d.msgType, 'mt');
			expect(d.data, isNotEmpty);
			expect(d.hasMsgType(), isTrue);
			d.clearMsgType();
			expect(d.hasMsgType(), isFalse);
		});

		test('TxMsgData json roundtrip with multiple MsgData and list ops', () {
			final t = TxMsgData(data: [
				MsgData(msgType: 'a', data: [1]),
				MsgData(msgType: 'b', data: [2,3]),
			]);
			final j = jsonEncode(t.writeToJsonMap());
			final d = TxMsgData.fromJson(j);
			expect(d.data.length, 2);
			d.data.removeAt(0);
			expect(d.data.first.msgType, 'b');
		});

		test('SearchTxsResult json roundtrip with one TxResponse and list ops', () {
			final s = SearchTxsResult(
				totalCount: Int64(3),
				count: Int64(2),
				pageNumber: Int64(1),
				pageTotal: Int64(1),
				limit: Int64(50),
				txs: [TxResponse(txhash: 'h')]
			);
			final j = jsonEncode(s.writeToJsonMap());
			final d = SearchTxsResult.fromJson(j);
			expect(d.limit.toInt(), 50);
			expect(d.txs.first.txhash, 'h');
			d.txs.add(TxResponse(txhash: 'h2'));
			expect(d.txs.length, 2);
		});

		test('Buffer roundtrip for all messages (smoke)', () {
			final m1 = ABCIMessageLog(msgIndex: 1, log: 'l');
			final m2 = StringEvent(type: 't');
			final m3 = Attribute(key: 'k', value: 'v');
			final m4 = GasInfo(gasWanted: Int64(1), gasUsed: Int64(2));
			final m5 = Result(log: 'ok');
			final m6 = SimulationResponse(gasInfo: m4, result: m5);
			final m7 = MsgData(msgType: 'mt', data: [1]);
			final m8 = TxMsgData(data: [m7]);
			final m9 = SearchTxsResult(totalCount: Int64(1), count: Int64(1), pageNumber: Int64(1), pageTotal: Int64(1), limit: Int64(1));

			expect(ABCIMessageLog.fromBuffer(m1.writeToBuffer()).msgIndex, 1);
			expect(StringEvent.fromBuffer(m2.writeToBuffer()).type, 't');
			expect(Attribute.fromBuffer(m3.writeToBuffer()).key, 'k');
			expect(GasInfo.fromBuffer(m4.writeToBuffer()).gasUsed.toInt(), 2);
			expect(Result.fromBuffer(m5.writeToBuffer()).log, 'ok');
			expect(SimulationResponse.fromBuffer(m6.writeToBuffer()).gasInfo.gasWanted.toInt(), 1);
			expect(MsgData.fromBuffer(m7.writeToBuffer()).msgType, 'mt');
			expect(TxMsgData.fromBuffer(m8.writeToBuffer()).data.first.msgType, 'mt');
			expect(SearchTxsResult.fromBuffer(m9.writeToBuffer()).count.toInt(), 1);
		});

		test('TxResponse writeToJsonMap stringified Int64 fields', () {
			final tx = TxResponse(height: Int64(123), gasWanted: Int64(0), gasUsed: Int64(9));
			final m = tx.writeToJsonMap();
			final tx2 = TxResponse.fromJson(jsonEncode(m));
			expect(tx2.height.toInt(), 123);
			expect(tx2.gasWanted.toInt(), 0);
			expect(tx2.gasUsed.toInt(), 9);
		});

		test('getDefault identity for core messages', () {
			expect(identical(ABCIMessageLog.getDefault(), ABCIMessageLog.getDefault()), isTrue);
			expect(identical(Attribute.getDefault(), Attribute.getDefault()), isTrue);
			expect(identical(Result.getDefault(), Result.getDefault()), isTrue);
			expect(identical(TxMsgData.getDefault(), TxMsgData.getDefault()), isTrue);
			expect(identical(SearchTxsResult.getDefault(), SearchTxsResult.getDefault()), isTrue);
		});
	});
} 