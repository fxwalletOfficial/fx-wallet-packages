import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/bank.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';

void main() {
	group('proto cosmos.bank.v1beta1 bank models', () {
		test('Input has/clear/clone/copyWith/json/errors/defaults', () {
			final m = Input(address: 'addr', coins: [CosmosCoin(denom: 'uatom', amount: '1')]);
			expect(m.hasAddress(), isTrue);
			expect(m.coins.first.denom, 'uatom');
			m.clearAddress();
			expect(m.hasAddress(), isFalse);
			m.coins.add(CosmosCoin(denom: 'uiris', amount: '2'));
			expect(m.coins.length, 2);
			final clone = m.deepCopy();
			expect(clone.coins.length, 2);
			final copied = m.rebuild((x) => x.address = 'addr2');
			expect(copied.address, 'addr2');
			final jsonStr = jsonEncode(copied.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			expect(() => Input.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => Input.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(Input.getDefault(), isA<Input>());
			expect(Input().createEmptyInstance(), isA<Input>());
			expect(Input.createRepeated(), isA<pb.PbList<Input>>());
		});

		test('Output has/clear/clone/copyWith/json/errors/defaults', () {
			final m = Output(address: 'addr', coins: [CosmosCoin(denom: 'uatom', amount: '1')]);
			expect(m.hasAddress(), isTrue);
			m.clearAddress();
			expect(m.hasAddress(), isFalse);
			m.coins.add(CosmosCoin(denom: 'x', amount: '0'));
			expect(m.coins.length, 2);
			final clone = m.clone();
			expect(clone.coins.length, 2);
			final copied = m.copyWith((x) => x.address = 'addr2');
			expect(copied.address, 'addr2');
			final jsonStr = jsonEncode(copied.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			expect(() => Output.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => Output.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(Output.getDefault(), isA<Output>());
			expect(Output().createEmptyInstance(), isA<Output>());
			expect(Output.createRepeated(), isA<pb.PbList<Output>>());
		});

		test('DenomUnit has/clear/clone/copyWith/json/errors/defaults', () {
			final d = DenomUnit(denom: 'uatom', exponent: 0, aliases: ['micro']);
			expect(d.hasDenom(), isTrue);
			expect(d.hasExponent(), isTrue);
			d.aliases.addAll(['u', 'a']);
			expect(d.aliases.length, 3);
			d.clearDenom();
			expect(d.hasDenom(), isFalse);
			d.clearExponent();
			expect(d.hasExponent(), isFalse);
			final clone = d.clone();
			expect(clone.aliases.length, 3);
			final copied = d.copyWith((x) {
				x.denom = 'uiris';
				x.exponent = 6;
			});
			expect(copied.denom, 'uiris');
			expect(copied.exponent, 6);
			final jsonStr = jsonEncode(copied.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			expect(() => DenomUnit.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => DenomUnit.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(DenomUnit.getDefault(), isA<DenomUnit>());
			expect(DenomUnit().createEmptyInstance(), isA<DenomUnit>());
			expect(DenomUnit.createRepeated(), isA<pb.PbList<DenomUnit>>());
		});

		test('Metadata has/clear/clone/copyWith/json/errors/defaults', () {
			final m = Metadata(description: 'd', base: 'uatom', display: 'ATOM', name: 'Cosmos', symbol: 'ATOM');
			expect(m.hasDescription(), isTrue);
			expect(m.hasBase(), isTrue);
			expect(m.hasDisplay(), isTrue);
			expect(m.hasName(), isTrue);
			expect(m.hasSymbol(), isTrue);
			m.clearDescription();
			m.clearBase();
			m.clearDisplay();
			m.clearName();
			m.clearSymbol();
			expect(m.hasDescription(), isFalse);
			expect(m.hasBase(), isFalse);
			expect(m.hasDisplay(), isFalse);
			expect(m.hasName(), isFalse);
			expect(m.hasSymbol(), isFalse);
			m.denomUnits.add(DenomUnit(denom: 'uatom', exponent: 0));
			expect(m.denomUnits.length, 1);
			final clone = m.clone();
			expect(clone.denomUnits.length, 1);
			final copied = m.copyWith((x) {
				x.base = 'uiris';
				x.display = 'IRIS';
				x.name = 'Iris';
				x.symbol = 'IRIS';
			});
			expect(copied.base, 'uiris');
			expect(copied.display, 'IRIS');
			expect(copied.name, 'Iris');
			expect(copied.symbol, 'IRIS');
			final jsonStr = jsonEncode(copied.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			expect(() => Metadata.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => Metadata.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(Metadata.getDefault(), isA<Metadata>());
			expect(Metadata().createEmptyInstance(), isA<Metadata>());
			expect(Metadata.createRepeated(), isA<pb.PbList<Metadata>>());
		});

		test('Supply list ops/defaults/errors', () {
			final s = Supply(total: [CosmosCoin(denom: 'uatom', amount: '1')]);
			expect(s.total.first.amount, '1');
			s.total.add(CosmosCoin(denom: 'uiris', amount: '2'));
			expect(s.total.length, 2);
			final jsonStr = jsonEncode(s.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			expect(() => Supply.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => Supply.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(Supply.getDefault(), isA<Supply>());
			expect(Supply().createEmptyInstance(), isA<Supply>());
			expect(Supply.createRepeated(), isA<pb.PbList<Supply>>());
		});
	});
}
