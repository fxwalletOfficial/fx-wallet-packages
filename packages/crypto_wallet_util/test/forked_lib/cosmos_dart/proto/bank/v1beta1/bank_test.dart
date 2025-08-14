import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/bank.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/genesis.pb.dart' as bankgenesis;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';

void main() {
	group('proto cosmos.bank.v1beta1 bank', () {
		test('Params and SendEnabled list: has/clear/copyWith/json', () {
			final se = SendEnabled(denom: 'uatom', enabled: true);
			final p = Params(sendEnabled: [se], defaultSendEnabled: false);
			expect(p.sendEnabled.length, 1);
			expect(p.defaultSendEnabled, isFalse);
			p.clearDefaultSendEnabled();
			expect(p.hasDefaultSendEnabled(), isFalse);
			final copied = p.copyWith((m) => m.defaultSendEnabled = true);
			final jsonStr = jsonEncode(copied.writeToJsonMap());
			expect(jsonStr.contains('true'), isTrue);
		});

		test('Input/Output with coins: roundtrip and boundary', () {
			final inMsg = Input(address: '', coins: [CosmosCoin(denom: 'uiris', amount: '0')]);
			final outMsg = Output(address: 'cosmos1to', coins: [CosmosCoin(denom: 'uatom', amount: '1')]);
			final ib = inMsg.writeToBuffer();
			final ob = outMsg.writeToBuffer();
			final in2 = Input.fromBuffer(ib);
			final out2 = Output.fromBuffer(ob);
			expect(in2.address, '');
			expect(in2.coins.first.amount, '0');
			expect(out2.address, 'cosmos1to');
			expect(out2.coins.first.amount, '1');
		});

		test('Metadata, DenomUnit and Supply/Balance presence', () {
			final mu = DenomUnit(denom: 'uatom', exponent: 0, aliases: ['microatom']);
			final md = Metadata(
				base: 'uatom',
				display: 'ATOM',
				name: 'Cosmos Hub Atom',
				symbol: 'ATOM',
				denomUnits: [mu],
			);
			final b = bankgenesis.Balance(address: 'cosmos1addr', coins: [CosmosCoin(denom: 'uatom', amount: '123')]);
			final s = Supply(total: [CosmosCoin(denom: 'uatom', amount: '1000000')]);
			final mdb = md.writeToBuffer();
			final bb = b.writeToBuffer();
			final sb = s.writeToBuffer();
			final md2 = Metadata.fromBuffer(mdb);
			final b2 = bankgenesis.Balance.fromBuffer(bb);
			final s2 = Supply.fromBuffer(sb);
			expect(md2.base, 'uatom');
			expect(md2.denomUnits.first.denom, 'uatom');
			expect(b2.coins.first.amount, '123');
			expect(s2.total.first.amount, '1000000');
		});

		test('should throw on invalid buffer', () {
			expect(() => Params.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => SendEnabled.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => Input.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => Output.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => Metadata.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			final jsonStr = jsonEncode(bankgenesis.Balance().writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
		});

		test('Params getDefault/createEmptyInstance/createRepeated and SendEnabled defaults', () {
			expect(Params.getDefault(), isA<Params>());
			expect(Params().createEmptyInstance(), isA<Params>());
			expect(Params.createRepeated(), isA<pb.PbList<Params>>());
			final se = SendEnabled();
			expect(se.hasDenom(), isFalse);
			expect(se.hasEnabled(), isFalse);
			se.denom = 'x';
			se.enabled = true;
			final bz = se.writeToBuffer();
			expect(SendEnabled.fromBuffer(bz).enabled, isTrue);
		});
	});
} 