import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/wallet/network_info.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/wallet/wallet.dart';

void main() {
	group('cosmos_dart Wallet', () {
		test('derive from mnemonic and bech32 address', () {
			final info = CosmosNetworkInfo(bech32Hrp: 'cosmos');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];

			final wallet = CosmosWallet.derive(mnemonic, info);
			expect(wallet.bech32Address.startsWith('cosmos'), isTrue);
			expect(wallet.privateKey.length, 32);
			expect(wallet.publicKey.isNotEmpty, isTrue);
			expect(wallet.address.length, 20);
		});

		test('import from private key equals derive with same seed child', () {
			final info = CosmosNetworkInfo(bech32Hrp: 'cosmos');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			final wallet1 = CosmosWallet.derive(mnemonic, info);
			final wallet2 = CosmosWallet.import(info, wallet1.privateKey);
			expect(wallet1.publicKey, equals(wallet2.publicKey));
			expect(wallet1.address, equals(wallet2.address));
			expect(wallet1.bech32Address, equals(wallet2.bech32Address));
		});

		test('sign returns 64-byte normalized signature', () {
			final info = CosmosNetworkInfo(bech32Hrp: 'cosmos');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			final wallet = CosmosWallet.derive(mnemonic, info);
			final msg = Uint8List.fromList('hello cosmos'.codeUnits);
			final sig = wallet.sign(msg);
			expect(sig.length, 64);
		});
	});
}