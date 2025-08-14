import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/auth.pb.dart' as authpb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/genesis.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/any.pb.dart';
import 'package:fixnum/fixnum.dart';

void main() {
	group('proto cosmos.auth.v1beta1 params & genesis', () {
		test('Params roundtrip and fields', () {
			final p = authpb.Params(
				maxMemoCharacters: Int64(256),
				txSigLimit: Int64(7),
				txSizeCostPerByte: Int64(5),
				sigVerifyCostEd25519: Int64(999),
				sigVerifyCostSecp256k1: Int64(888),
			);
			final bz = p.writeToBuffer();
			final p2 = authpb.Params.fromBuffer(bz);
			expect(p2.maxMemoCharacters.toInt(), 256);
			expect(p2.txSigLimit.toInt(), 7);
			expect(p2.txSizeCostPerByte.toInt(), 5);
			expect(p2.sigVerifyCostEd25519.toInt(), 999);
			expect(p2.sigVerifyCostSecp256k1.toInt(), 888);
		});

		test('GenesisState roundtrip and ensure methods', () {
			final g = GenesisState(
				params: authpb.Params(maxMemoCharacters: Int64(1)),
				accounts: [Any(typeUrl: 'acc', value: [0x01])],
			);
			final bz = g.writeToBuffer();
			final g2 = GenesisState.fromBuffer(bz);
			expect(g2.hasParams(), isTrue);
			expect(g2.params.maxMemoCharacters.toInt(), 1);
			expect(g2.accounts.first.typeUrl, 'acc');

			// ensureParams should keep existing
			final ensured = g2.ensureParams();
			expect(identical(ensured, g2.params), isTrue);
		});
	});
} 