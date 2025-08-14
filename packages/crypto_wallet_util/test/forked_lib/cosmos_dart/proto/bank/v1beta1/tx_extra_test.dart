import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/tx.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/bank.pb.dart' as bankpb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';

void main() {
	group('proto cosmos.bank.v1beta1 tx extras', () {
		test('MsgMultiSend roundtrip and list ops', () {
			final input = bankpb.Input(address: 'from', coins: [CosmosCoin(denom: 'uatom', amount: '1')]);
			final output = bankpb.Output(address: 'to', coins: [CosmosCoin(denom: 'uatom', amount: '1')]);
			final msg = MsgMultiSend(inputs: [input], outputs: [output]);
			final bz = msg.writeToBuffer();
			final decoded = MsgMultiSend.fromBuffer(bz);
			expect(decoded.inputs.first.address, 'from');
			expect(decoded.outputs.first.address, 'to');
			msg.inputs.add(bankpb.Input(address: 'from2'));
			expect(msg.inputs.length, 2);
			final copied = msg.copyWith((m) => m.outputs.add(bankpb.Output(address: 'to2')));
			expect(copied.outputs.length, 2);
			final jsonStr = jsonEncode(copied.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			expect(() => MsgMultiSend.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
		});

		test('MsgSendResponse and MsgMultiSendResponse constructors', () {
			final r1 = MsgSendResponse();
			expect(r1, isA<MsgSendResponse>());
			final r2 = MsgMultiSendResponse();
			expect(r2, isA<MsgMultiSendResponse>());
		});
	});
} 