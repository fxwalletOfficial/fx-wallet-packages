import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/abci/types.pb.dart';

void main() {
	group('tendermint.abci types basic', () {
		test('Request oneof set/clear and ensure methods', () {
			final req = Request()..echo = RequestEcho(message: 'hi');
			expect(req.hasEcho(), isTrue);
			req.clearEcho();
			expect(req.hasEcho(), isFalse);
			req.ensureFlush();
			expect(req.hasFlush(), isTrue);
			final clone = req.deepCopy();
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
      e.freeze();
			final copied = e.rebuild((x) => x.attributes.add(EventAttribute(key: [0x6b, 0x32])));
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
}