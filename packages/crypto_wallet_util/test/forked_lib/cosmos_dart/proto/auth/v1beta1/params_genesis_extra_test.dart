import 'dart:convert';

import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/auth.pb.dart' as authpb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/genesis.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/any.pb.dart';
import 'package:fixnum/fixnum.dart';

void main() {
	group('proto cosmos.auth.v1beta1 params/genesis extra', () {
		test('Params has/clear/json/copyWith', () {
			final p = authpb.Params(maxMemoCharacters: Int64(1));
			expect(p.hasMaxMemoCharacters(), isTrue);
			p.clearMaxMemoCharacters();
			expect(p.hasMaxMemoCharacters(), isFalse);

			// Freeze the message before using rebuild
			final frozenP = p.freeze();
			final copied = frozenP.rebuild((m) {
				(m as authpb.Params).maxMemoCharacters = Int64(2);
				(m).txSigLimit = Int64(3);
			});
			final jsonStr = jsonEncode(copied.writeToJsonMap());
			expect(jsonStr.contains('2'), isTrue);
		});

		test('GenesisState has/clear/ensure/json', () {
			final g = GenesisState();
			expect(g.hasParams(), isFalse);
			g.ensureParams();
			expect(g.hasParams(), isTrue);
			g.params = authpb.Params(sigVerifyCostSecp256k1: Int64(10));
			final jsonStr = jsonEncode(g.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);

			g.accounts.add(Any(typeUrl: 'a'));
			expect(g.accounts.length, 1);
		});
	});
}