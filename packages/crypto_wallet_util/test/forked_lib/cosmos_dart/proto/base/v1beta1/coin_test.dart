import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';

void main() {
	group('proto cosmos.base.v1beta1 Coin', () {
		test('CosmosCoin writeToBuffer/fromBuffer roundtrip', () {
			final c1 = CosmosCoin(denom: 'uatom', amount: '123');
			final bytes = c1.writeToBuffer();
			final c2 = CosmosCoin.fromBuffer(bytes);
			expect(c2.denom, 'uatom');
			expect(c2.amount, '123');
		});
	});
} 