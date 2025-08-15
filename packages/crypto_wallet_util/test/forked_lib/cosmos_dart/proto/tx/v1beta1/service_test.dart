import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/v1beta1/service.pb.dart' as svc;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/query/v1beta1/pagination.pb.dart' as page;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/v1beta1/tx.pb.dart' as txpb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/abci/v1beta1/abci.pb.dart' as abci;

void main() {
	group('cosmos.tx.v1beta1 service basic', () {
		test('GetTxsEventRequest has/clear/ensure/json/buffer/defaults', () {
			final req = svc.GetTxsEventRequest(
				events: ['tm.event = \'Tx\''],
				pagination: page.PageRequest(limit: Int64(10)),
				orderBy: svc.OrderBy.ORDER_BY_ASC,
			);
			expect(req.events.first, contains('Tx'));
			expect(req.hasOrderBy(), isTrue);
			req.clearOrderBy();
			expect(req.hasOrderBy(), isFalse);
			expect(req.ensurePagination(), isA<page.PageRequest>());
			final bz = req.writeToBuffer();
			expect(svc.GetTxsEventRequest.fromBuffer(bz).events.length, 1);
			final j = jsonEncode(req.writeToJsonMap());
			expect(jsonDecode(j), isA<Map>());
			expect(svc.GetTxsEventRequest.getDefault().info_.messageName, contains('GetTxsEventRequest'));
			expect(svc.GetTxsEventRequest.createRepeated(), isA<pb.PbList<svc.GetTxsEventRequest>>());
		});

		test('GetTxsEventResponse list ops and ensure/json/buffer', () {
			final resp = svc.GetTxsEventResponse(
				txs: [txpb.Tx()],
				txResponses: [abci.TxResponse(height: Int64(1))],
				pagination: page.PageResponse(total: Int64(1)),
			);
			expect(resp.txs.length, 1);
			final bz = resp.writeToBuffer();
			final dec = svc.GetTxsEventResponse.fromBuffer(bz);
			expect(dec.txResponses.first.height.toInt(), 1);
			final j = jsonEncode(resp.writeToJsonMap());
			expect(jsonDecode(j), isA<Map>());
		});

		test('BroadcastTxRequest bytes/enum and has/clear/buffer', () {
			final br = svc.BroadcastTxRequest(txBytes: [0x01, 0x02], mode: svc.BroadcastMode.BROADCAST_MODE_SYNC);
			expect(br.hasTxBytes(), isTrue);
			br.clearTxBytes();
			expect(br.hasTxBytes(), isFalse);
			final bz = br.writeToBuffer();
			expect(svc.BroadcastTxRequest.fromBuffer(bz).mode, svc.BroadcastMode.BROADCAST_MODE_SYNC);
		});

		test('BroadcastTxResponse ensureTxResponse identity/buffer', () {
			final txr = abci.TxResponse(height: Int64(3));
			final resp = svc.BroadcastTxResponse(txResponse: txr);
			final ensured = resp.txResponse; // no ensure method generated, but field access is fine
			expect(identical(ensured, txr), isTrue);
			final dec = svc.BroadcastTxResponse.fromBuffer(resp.writeToBuffer());
			expect(dec.txResponse.height.toInt(), 3);
		});

		test('SimulateRequest set txBytes and json/buffer', () {
			final sim = svc.SimulateRequest(txBytes: [0xAA]);
			expect(sim.hasTxBytes(), isTrue);
			final dec = svc.SimulateRequest.fromBuffer(sim.writeToBuffer());
			expect(dec.txBytes.first, 0xAA);
			final j = jsonEncode(sim.writeToJsonMap());
			expect(jsonDecode(j), isA<Map>());
		});

		test('SimulateResponse gasInfo/result ensure/buffer', () {
			final sr = svc.SimulateResponse(
				gasInfo: abci.GasInfo(gasWanted: Int64(1), gasUsed: Int64(2)),
				result: abci.Result(log: 'ok'),
			);
			final dec = svc.SimulateResponse.fromBuffer(sr.writeToBuffer());
			expect(dec.gasInfo.gasUsed.toInt(), 2);
			expect(dec.result.log, 'ok');
		});

		test('GetTxRequest hash set/json/buffer/defaults', () {
			final gr = svc.GetTxRequest(hash: 'ABC');
			expect(gr.hash, 'ABC');
			final dec = svc.GetTxRequest.fromBuffer(gr.writeToBuffer());
			expect(dec.hash, 'ABC');
			final j = jsonEncode(gr.writeToJsonMap());
			expect(jsonDecode(j), isA<Map>());
			expect(svc.GetTxRequest.getDefault().info_.messageName, contains('GetTxRequest'));
		});
	});
} 