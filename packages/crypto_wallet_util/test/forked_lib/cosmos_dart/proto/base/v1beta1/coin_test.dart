import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';

void main() {
	group('cosmos.base.v1beta1 Coin', () {
		test('CosmosCoin json/buffer/defaults/clone/copyWith', () {
			final c = CosmosCoin(denom: 'uatom', amount: '1');
			final bz = c.writeToBuffer();
			expect(CosmosCoin.fromBuffer(bz).denom, 'uatom');
			final jsonStr = jsonEncode(c.writeToJsonMap());
			expect(CosmosCoin.fromJson(jsonStr).amount, '1');
			final clone = c.deepCopy();
			expect(clone.denom, 'uatom');

      c.freeze();
			final copied = c.rebuild((x) => x.amount = '2');
			expect(copied.amount, '2');
			expect(CosmosCoin.getDefault(), isA<CosmosCoin>());
			expect(CosmosCoin().createEmptyInstance(), isA<CosmosCoin>());
			expect(CosmosCoin.createRepeated(), isA<pb.PbList<CosmosCoin>>());
		});
	});
}