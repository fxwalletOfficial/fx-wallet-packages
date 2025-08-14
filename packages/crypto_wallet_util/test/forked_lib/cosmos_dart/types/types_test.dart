import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';

void main() {
	group('cosmos_dart Types extensions', () {
		test('CoinExt validate/isPositive', () {
			final ok = CosmosCoin(denom: 'uatom', amount: '100');
			expect(ok.isPositive, isTrue);
			expect(ok.isValid, isTrue);

			final badDenom = CosmosCoin(denom: 'UATOM', amount: '1');
			expect(badDenom.isValid, isFalse);

			final badAmount = CosmosCoin(denom: 'uatom', amount: '0');
			expect(badAmount.isPositive, isFalse);
			expect(badAmount.isValid, isFalse);
		});

		test('CoinsExt isValid/isPositive on list', () {
			final list = [
				CosmosCoin(denom: 'uatom', amount: '1'),
				CosmosCoin(denom: 'uiris', amount: '2'),
			];
			expect(list.isPositive, isTrue);
			expect(list.isValid, isTrue);

			final list2 = [
				CosmosCoin(denom: 'uatom', amount: '0'),
			];
			expect(list2.isPositive, isFalse);
			expect(list2.isValid, isFalse);
		});

		test('TxResponseExt isSuccessful', () {
			final ok = TxResponse(code: 0);
			expect(ok.isSuccessful, isTrue);
			final fail = TxResponse(code: 5);
			expect(fail.isSuccessful, isFalse);
		});
	});
} 