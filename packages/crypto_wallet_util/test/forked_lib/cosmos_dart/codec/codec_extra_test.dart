import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';

void main() {
	group('cosmos_dart Codec extra', () {
		test('registerAccountImpl throws on duplicate typeUrl', () {
			final impl = AccountImpl('dup.Type', (_) => throw UnimplementedError());
			Codec.registerAccountImpl(impl);
			expect(() => Codec.registerAccountImpl(impl), throwsException);
		});
	});
} 