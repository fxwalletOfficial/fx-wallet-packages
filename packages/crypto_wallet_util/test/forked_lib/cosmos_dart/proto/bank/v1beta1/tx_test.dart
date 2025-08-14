import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/tx.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/bank.pb.dart' as bankpb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';

void main() {
	group('proto cosmos.bank.v1beta1 tx', () {
		test('MsgSend writeToBuffer/fromBuffer with amount', () {
			final msg = MsgSend(
				fromAddress: 'cosmos1from',
				toAddress: 'cosmos1to',
				amount: [CosmosCoin(denom: 'uatom', amount: '1')],
			);
			final bytes = msg.writeToBuffer();
			final decoded = MsgSend.fromBuffer(bytes);
			expect(decoded.fromAddress, 'cosmos1from');
			expect(decoded.toAddress, 'cosmos1to');
			expect(decoded.amount.first.denom, 'uatom');
			expect(decoded.amount.first.amount, '1');
		});

		test('MsgSend has/clear/clone/copyWith/json/errors/defaults', () {
			final msg = MsgSend(fromAddress: 'a', toAddress: 'b');
			expect(msg.hasFromAddress(), isTrue);
			expect(msg.hasToAddress(), isTrue);
			msg.amount.addAll([CosmosCoin(denom: 'x', amount: '0'), CosmosCoin(denom: 'y', amount: '2')]);
			expect(msg.amount.length, 2);
			final clone = msg.deepCopy();
			expect(clone.fromAddress, 'a');

      msg.freeze();
			final copied = msg.rebuild((m) {
				m.fromAddress = 'c';
				m.toAddress = 'd';
			});
			expect(copied.fromAddress, 'c');
			expect(copied.toAddress, 'd');
			final jsonStr = jsonEncode(copied.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			expect(() => MsgSend.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => MsgSend.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(MsgSend.getDefault(), isA<MsgSend>());
			expect(MsgSend().createEmptyInstance(), isA<MsgSend>());
			expect(MsgSend.createRepeated(), isA<pb.PbList<MsgSend>>());
		});
	});

	group('proto cosmos.bank.v1beta1 tx more', () {
		test('MsgSend has/clear/clone/copyWith/json/buffer/defaults/info_/errors', () {
			final m = MsgSend(fromAddress: 'from', toAddress: 'to', amount: [CosmosCoin(denom: 'uatom', amount: '1')]);
			expect(m.hasFromAddress(), isTrue);
			expect(m.hasToAddress(), isTrue);
			expect(m.amount.first.amount, '1');
			m.clearFromAddress();
			m.clearToAddress();
			expect(m.hasFromAddress(), isFalse);
			expect(m.hasToAddress(), isFalse);
			m.amount.add(CosmosCoin(denom: 'uiris', amount: '2'));
			expect(m.amount.length, 2);
			final clone = m.deepCopy();
			expect(clone.amount.length, 2);

      m.freeze();
			final copied = m.rebuild((x) {
				x.fromAddress = 'from2';
				x.toAddress = 'to2';
			});
			expect(copied.fromAddress, 'from2');
			expect(copied.toAddress, 'to2');
			final jsonStr = jsonEncode(copied.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			final bz = copied.writeToBuffer();
			final m2 = MsgSend.fromBuffer(bz);
			expect(m2.fromAddress, 'from2');
			expect(MsgSend.getDefault().info_.messageName, contains('MsgSend'));
			expect(() => MsgSend.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => MsgSend.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
		});

		test('MsgSendResponse defaults/createEmptyInstance/createRepeated/clone', () {
			expect(MsgSendResponse.getDefault(), isA<MsgSendResponse>());
			expect(MsgSendResponse.getDefault().createEmptyInstance(), isA<MsgSendResponse>());
			expect(MsgSendResponse.createRepeated(), isA<pb.PbList<MsgSendResponse>>());
			final clone = MsgSendResponse().deepCopy();
			expect(clone, isA<MsgSendResponse>());
		});

		test('MsgMultiSend lists/clone/copyWith/json/buffer/errors', () {
			final input1 = bankpb.Input(address: 'a', coins: [CosmosCoin(denom: 'x', amount: '1')]);
			final output1 = bankpb.Output(address: 'b', coins: [CosmosCoin(denom: 'y', amount: '2')]);
			final m = MsgMultiSend(inputs: [input1], outputs: [output1]);
			expect(m.inputs.first.address, 'a');
			expect(m.outputs.first.address, 'b');
			m.inputs.add(bankpb.Input(address: 'c'));
			m.outputs.add(bankpb.Output(address: 'd'));
			expect(m.inputs.length, 2);
			expect(m.outputs.length, 2);
			final clone = m.deepCopy();
			expect(clone.inputs.length, 2);

			final jsonStr = jsonEncode(m.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			final bz = m.writeToBuffer();
			final m2 = MsgMultiSend.fromBuffer(bz);
			expect(m2.inputs.first.address, 'a');
			expect(MsgMultiSend.getDefault().info_.messageName, contains('MsgMultiSend'));
			expect(() => MsgMultiSend.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => MsgMultiSend.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));

      m.freeze();
			final copied = m.rebuild((x) {
				x.inputs.clear();
				x.outputs.clear();
			});
			expect(copied.inputs, isEmpty);
			expect(copied.outputs, isEmpty);
		});

		test('MsgMultiSendResponse defaults/createEmptyInstance/createRepeated/clone', () {
			expect(MsgMultiSendResponse.getDefault(), isA<MsgMultiSendResponse>());
			expect(MsgMultiSendResponse.getDefault().createEmptyInstance(), isA<MsgMultiSendResponse>());
			expect(MsgMultiSendResponse.createRepeated(), isA<pb.PbList<MsgMultiSendResponse>>());
			final clone = MsgMultiSendResponse().deepCopy();
			expect(clone, isA<MsgMultiSendResponse>());
		});
	});

	group('proto cosmos.bank.v1beta1 tx extras more', () {
		test('MsgSendResponse json/buffer roundtrip', () {
			final r = MsgSendResponse();
			final bz = r.writeToBuffer();
			expect(MsgSendResponse.fromBuffer(bz), isA<MsgSendResponse>());
			final jsonStr = jsonEncode(r.writeToJsonMap());
			expect(MsgSendResponse.fromJson(jsonStr), isA<MsgSendResponse>());
		});

		test('MsgMultiSend json/fromJson and createRepeated/info_', () {
			final m = MsgMultiSend();
			m.inputs.add(bankpb.Input(address: 'a'));
			m.outputs.add(bankpb.Output(address: 'b'));
			final jsonStr = jsonEncode(m.writeToJsonMap());
			final m2 = MsgMultiSend.fromJson(jsonStr);
			expect(m2.inputs.first.address, 'a');
			expect(m2.outputs.first.address, 'b');
			expect(MsgMultiSend.createRepeated(), isA<pb.PbList<MsgMultiSend>>());
			expect(MsgMultiSend.getDefault().info_.messageName, contains('MsgMultiSend'));
		});

		test('MsgMultiSendResponse json/buffer roundtrip', () {
			final r = MsgMultiSendResponse();
			final bz = r.writeToBuffer();
			expect(MsgMultiSendResponse.fromBuffer(bz), isA<MsgMultiSendResponse>());
			final jsonStr = jsonEncode(r.writeToJsonMap());
			expect(MsgMultiSendResponse.fromJson(jsonStr), isA<MsgMultiSendResponse>());
		});
	});
}