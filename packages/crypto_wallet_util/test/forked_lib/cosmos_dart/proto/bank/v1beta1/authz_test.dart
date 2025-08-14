import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/authz.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';

void main() {
	group('proto cosmos.bank.v1beta1 authz', () {
		test('SendAuthorization list ops/clone/copyWith/json/errors/defaults', () {
			final a = SendAuthorization(spendLimit: [CosmosCoin(denom: 'uatom', amount: '1')]);
			expect(a.spendLimit.first.denom, 'uatom');
			a.spendLimit.add(CosmosCoin(denom: 'uiris', amount: '2'));
			expect(a.spendLimit.length, 2);
			final copied = a.copyWith((aa) => aa.spendLimit.add(CosmosCoin(denom: 'uosmo', amount: '3')));
			expect(copied.spendLimit.length, 3);
			final bz = a.writeToBuffer();
			final a2 = SendAuthorization.fromBuffer(bz);
			expect(a2.spendLimit.first.amount, '1');
			final jsonStr = jsonEncode(a.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			expect(() => SendAuthorization.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => SendAuthorization.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(SendAuthorization.getDefault(), isA<SendAuthorization>());
			expect(SendAuthorization().createEmptyInstance(), isA<SendAuthorization>());
			expect(SendAuthorization.createRepeated(), isA<pb.PbList<SendAuthorization>>());
		});
	});
} 