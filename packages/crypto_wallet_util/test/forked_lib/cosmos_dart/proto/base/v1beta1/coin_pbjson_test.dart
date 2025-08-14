import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pbjson.dart' as cjson;

void main() {
	group('cosmos.base.v1beta1 coin.pbjson', () {
		test('JSON maps and descriptors', () {
			expect(cjson.Coin$json['1'], 'Coin');
			expect(cjson.coinDescriptor.isNotEmpty, isTrue);
		});
	});
} 