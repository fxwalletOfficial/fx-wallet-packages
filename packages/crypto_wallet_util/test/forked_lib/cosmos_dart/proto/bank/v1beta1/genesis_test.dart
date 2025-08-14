import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/genesis.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/bank.pb.dart' as bankpb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';

void main() {
	group('proto cosmos.bank.v1beta1 genesis', () {
		test('GenesisState list ops/ensure/clone/copyWith/json/errors/defaults', () {
			final gs = GenesisState(
				params: bankpb.Params(defaultSendEnabled: true),
				balances: [Balance(address: 'a', coins: [CosmosCoin(denom: 'uatom', amount: '1')])],
				supply: [CosmosCoin(denom: 'uatom', amount: '100')],
				denomMetadata: [bankpb.Metadata(base: 'uatom')],
			);
			expect(gs.hasParams(), isTrue);
			expect(gs.balances.first.address, 'a');
			expect(gs.supply.first.amount, '100');
			gs.balances.add(Balance(address: 'b'));
			expect(gs.balances.length, 2);
			final ensured = gs.ensureParams();
			expect(ensured, isA<bankpb.Params>());
			final clone = gs.clone();
			expect(clone.denomMetadata.first.base, 'uatom');
			final copy = gs.copyWith((g) => g.supply.add(CosmosCoin(denom: 'uiris', amount: '2')));
			expect(copy.supply.length, 2);
			final bz = gs.writeToBuffer();
			final gs2 = GenesisState.fromBuffer(bz);
			expect(gs2.params.defaultSendEnabled, isTrue);
			final jsonStr = jsonEncode(gs.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			expect(() => GenesisState.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => GenesisState.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(GenesisState.getDefault(), isA<GenesisState>());
			expect(GenesisState().createEmptyInstance(), isA<GenesisState>());
			expect(GenesisState.createRepeated(), isA<pb.PbList<GenesisState>>());
		});
	});

	group('proto cosmos.bank.v1beta1 genesis more', () {
		test('GenesisState ensure/clone/copyWith/json/buffer/defaults/info_/errors', () {
			final gs = GenesisState(
				params: bankpb.Params(defaultSendEnabled: true),
				balances: [Balance(address: 'a', coins: [CosmosCoin(denom: 'x', amount: '1')])],
				supply: [CosmosCoin(denom: 'x', amount: '10')],
				denomMetadata: [bankpb.Metadata(base: 'x')],
			);
			expect(gs.hasParams(), isTrue);
			expect(gs.ensureParams(), isA<bankpb.Params>());
			final clone = gs.clone();
			expect(clone.denomMetadata.first.base, 'x');
			final copied = gs.copyWith((g) {
				g.supply.add(CosmosCoin(denom: 'y', amount: '2'));
				g.balances.add(Balance(address: 'b'));
			});
			expect(copied.supply.length, 2);
			expect(copied.balances.length, 2);
			final jsonStr = jsonEncode(gs.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			final bz = gs.writeToBuffer();
			final gs2 = GenesisState.fromBuffer(bz);
			expect(gs2.params.defaultSendEnabled, isTrue);
			expect(GenesisState.getDefault().info_.messageName, contains('GenesisState'));
			expect(() => GenesisState.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => GenesisState.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
		});

		test('Balance has/clear/list ops/json/errors/defaults', () {
			final b = Balance(address: 'addr', coins: [CosmosCoin(denom: 'x', amount: '1')]);
			expect(b.hasAddress(), isTrue);
			b.clearAddress();
			expect(b.hasAddress(), isFalse);
			b.coins.add(CosmosCoin(denom: 'y', amount: '2'));
			expect(b.coins.length, 2);
			final jsonStr = jsonEncode(b.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			expect(() => Balance.fromJson('bad'), throwsA(isA<FormatException>()));
			expect(() => Balance.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(Balance.getDefault(), isA<Balance>());
			expect(Balance().createEmptyInstance(), isA<Balance>());
			expect(Balance.createRepeated(), isA<pb.PbList<Balance>>());
		});
	});
} 