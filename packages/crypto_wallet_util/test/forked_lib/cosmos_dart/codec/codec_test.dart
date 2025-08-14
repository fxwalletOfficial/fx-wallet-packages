import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/auth.pb.dart' as authpb;
import 'package:fixnum/fixnum.dart';

class _DummyAccount implements AccountI {
	@override
	String get address => 'dummy';

	@override
	Any get pubKey => Any();

	@override
	Int64 get accountNumber => Int64(0);

	@override
	Int64 get sequence => Int64(0);
}

void main() {
	group('cosmos_dart Codec', () {
		test('serialize wraps message into Any', () {
			final coin = CosmosCoin(denom: 'uatom', amount: '1');
			final any = Codec.serialize(coin);
			expect(any.typeUrl.contains('cosmos.base.v1beta1.Coin') || any.typeUrl.contains('CosmosCoin'), isTrue);
			expect(any.value.isNotEmpty, isTrue);
		});

		test('deserializeAccount works for known BaseAccount', () {
			final base = authpb.BaseAccount()
				..address = 'cosmos1xyz'
				..accountNumber = Int64(1)
				..sequence = Int64(0);
			final any = Any.pack(base, typeUrlPrefix: 'cosmos.auth.v1beta1');
			final acc = Codec.deserializeAccount(any);
			expect(acc.address, 'cosmos1xyz');
			expect(acc.accountNumber.toInt(), 1);
		});

		test('deserializeAccount throws for unknown type and can be registered', () {
			final coin = CosmosCoin(denom: 'uatom', amount: '1');
			final any = Any.pack(coin, typeUrlPrefix: 'cosmos.base.v1beta1');
			expect(() => Codec.deserializeAccount(any), throwsException);

			Codec.registerAccountImpl(AccountImpl('cosmos.base.v1beta1.Coin', (_) => _DummyAccount()));
			final acc = Codec.deserializeAccount(any);
			expect(acc.address, 'dummy');
		});
	});
} 