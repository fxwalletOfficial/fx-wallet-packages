import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';

void main() {
	group('cosmos_dart Config', () {
		test('DefaultTxConfig returns expected defaults', () {
			final cfg = DefaultTxConfig.create();
			expect(cfg.defaultSignMode(), SignMode.SIGN_MODE_DIRECT);
			expect(cfg.newTxBuilder(), isA<TxBuilder>());
			expect(cfg.txEncoder(), isNotNull);
			expect(cfg.signModeHandler(), isA<SignModeHandler>());
		});
	});
} 