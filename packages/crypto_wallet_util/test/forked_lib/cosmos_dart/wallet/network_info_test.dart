import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/wallet/network_info.dart';

void main() {
	group('cosmos_dart NetworkInfo', () {
		test('toJson/fromJson and equality', () {
			final n1 = CosmosNetworkInfo(bech32Hrp: 'cosmos');
			final json = n1.toJson();
			expect(json['bech32_hrp'], 'cosmos');
			final n2 = CosmosNetworkInfo.fromJson(json);
			expect(n2.bech32Hrp, 'cosmos');
			expect(n1, equals(n2));
		});
	});
}