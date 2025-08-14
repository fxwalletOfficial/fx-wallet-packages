import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';

void main() {
	group('cosmos_dart Wallet extras', () {
		test('Wallet.random derives valid wallet', () {
			final info = CosmosNetworkInfo(bech32Hrp: 'cosmos');
			final w = CosmosWallet.random(info);
			expect(w.privateKey.length, 32);
			expect(w.publicKey.isNotEmpty, isTrue);
			expect(w.address.length, 20);
			expect(w.bech32Address.startsWith('cosmos'), isTrue);
		});

		test('Wallet.convert preserves keys but changes network hrp', () {
			final info1 = CosmosNetworkInfo(bech32Hrp: 'cosmos');
			final info2 = CosmosNetworkInfo(bech32Hrp: 'osmo');
			final w1 = CosmosWallet.random(info1);
			final w2 = CosmosWallet.convert(w1, info2);
			expect(w2.privateKey, w1.privateKey);
			expect(w2.publicKey, w1.publicKey);
			expect(w2.address, w1.address);
			expect(w2.bech32Address.startsWith('osmo'), isTrue);
		});

		test('Wallet.fromJson/toJson roundtrip', () {
			final info = CosmosNetworkInfo(bech32Hrp: 'cosmos');
			final w = CosmosWallet.random(info);
			final json = w.toJson();
			final w2 = CosmosWallet.fromJson(json, Uint8List.fromList(w.privateKey));
			expect(w2.privateKey, w.privateKey);
			expect(w2.publicKey, w.publicKey);
			expect(w2.address, w.address);
			expect(w2.bech32Address, w.bech32Address);
		});
	});
}