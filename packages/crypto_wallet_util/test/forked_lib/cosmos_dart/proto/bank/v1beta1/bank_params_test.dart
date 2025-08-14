import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/bank.pb.dart';

void main() {
	group('proto cosmos.bank.v1beta1 bank params', () {
		test('Params has/clear/sendEnabled list/clone/copyWith/json/errors/defaults', () {
			final se = SendEnabled(denom: 'uatom', enabled: true);
			final p = Params(sendEnabled: [se], defaultSendEnabled: false);
			expect(p.hasDefaultSendEnabled(), isTrue);
			p.clearDefaultSendEnabled();
			expect(p.hasDefaultSendEnabled(), isFalse);
			p.sendEnabled.add(SendEnabled(denom: 'uiris', enabled: false));
			expect(p.sendEnabled.length, 2);
			final copied = p.copyWith((pp) {
				pp.defaultSendEnabled = true;
				pp.sendEnabled.add(SendEnabled(denom: 'uosmo', enabled: true));
			});
			expect(copied.defaultSendEnabled, isTrue);
			expect(copied.sendEnabled.length, 3);
			final clone = copied.clone();
			expect(clone.sendEnabled.first.denom, 'uatom');
			final jsonStr = jsonEncode(copied.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			expect(() => Params.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => Params.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(Params.getDefault(), isA<Params>());
			expect(Params().createEmptyInstance(), isA<Params>());
			expect(Params.createRepeated(), isA<pb.PbList<Params>>());
		});
	});
} 