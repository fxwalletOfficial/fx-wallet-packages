import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/wallet/network_info.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/wallet/wallet.dart';

void main() {
	group('cosmos_dart Wallet', () {
		test('derive from mnemonic and bech32 address', () {
			final info = NetworkInfo(bech32Hrp: 'cosmos');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];

			final wallet = Wallet.derive(mnemonic, info);
			expect(wallet.bech32Address.startsWith('cosmos'), isTrue);
			expect(wallet.privateKey.length, 32);
			expect(wallet.publicKey.isNotEmpty, isTrue);
			expect(wallet.address.length, 20);
		});

		test('import from private key equals derive with same seed child', () {
			final info = NetworkInfo(bech32Hrp: 'cosmos');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			final wallet1 = Wallet.derive(mnemonic, info);
			final wallet2 = Wallet.import(info, wallet1.privateKey);
			expect(wallet1.publicKey, equals(wallet2.publicKey));
			expect(wallet1.address, equals(wallet2.address));
			expect(wallet1.bech32Address, equals(wallet2.bech32Address));
		});

		test('sign returns 64-byte normalized signature', () {
			final info = NetworkInfo(bech32Hrp: 'cosmos');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			final wallet = Wallet.derive(mnemonic, info);
			final msg = Uint8List.fromList('hello cosmos'.codeUnits);
			final sig = wallet.sign(msg);
			expect(sig.length, 64);
		});

		test('should throw exception for invalid mnemonic', () {
			// Test the uncovered exception path (line 39)
			final info = NetworkInfo(bech32Hrp: 'cosmos');
			final invalidMnemonic = ['invalid', 'mnemonic', 'words', 'list'];
			
			expect(() => Wallet.derive(invalidMnemonic, info), 
				throwsA(isA<Exception>().having(
					(e) => e.toString(), 
					'message', 
					contains('Invalid mnemonic')
				))
			);
		});

		test('should cover ecPublicKey getter', () {
			// Test the uncovered ecPublicKey getter (lines 153-158)
			final info = NetworkInfo(bech32Hrp: 'juno');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			final wallet = Wallet.derive(mnemonic, info);
			
			// Access the ecPublicKey property
			final ecPublicKey = wallet.ecPublicKey;
			expect(ecPublicKey, isNotNull);
			expect(ecPublicKey.Q, isNotNull);
		});

		test('should cover props getter for Equatable', () {
			// Test the uncovered props getter (lines 205-213)
			final info1 = NetworkInfo(bech32Hrp: 'cosmos');
			final info2 = NetworkInfo(bech32Hrp: 'cosmos');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			
			final wallet1 = Wallet.derive(mnemonic, info1);
			final wallet2 = Wallet.derive(mnemonic, info2);
			
			// Access props for equality comparison
			final props1 = wallet1.props;
			final props2 = wallet2.props;
			
			expect(props1, equals(props2));
			expect(props1.length, equals(4)); // networkInfo, address, privateKey, publicKey
			expect(props1, contains(wallet1.networkInfo));
			expect(props1, contains(wallet1.address));
			expect(props1, contains(wallet1.privateKey));
			expect(props1, contains(wallet1.publicKey));
		});

		test('should cover toString method', () {
			// Test the uncovered toString method (lines 215-222)
			final info = NetworkInfo(bech32Hrp: 'osmosis');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			final wallet = Wallet.derive(mnemonic, info);
			
			final stringRep = wallet.toString();
			expect(stringRep, contains('networkInfo:'));
			expect(stringRep, contains('address:'));
			expect(stringRep, contains('publicKey:'));
			expect(stringRep, isA<String>());
		});

		test('should test wallet random generation', () {
			final info = NetworkInfo(bech32Hrp: 'stargaze');
			
			// Generate two random wallets
			final wallet1 = Wallet.random(info);
			final wallet2 = Wallet.random(info);
			
			// They should be different
			expect(wallet1.privateKey, isNot(equals(wallet2.privateKey)));
			expect(wallet1.publicKey, isNot(equals(wallet2.publicKey)));
			expect(wallet1.address, isNot(equals(wallet2.address)));
			expect(wallet1.bech32Address, isNot(equals(wallet2.bech32Address)));
			
			// But both should be valid
			expect(wallet1.privateKey.length, equals(32));
			expect(wallet2.privateKey.length, equals(32));
			expect(wallet1.bech32Address.startsWith('stargaze'), isTrue);
			expect(wallet2.bech32Address.startsWith('stargaze'), isTrue);
		});

		test('should test wallet convert function', () {
			final info1 = NetworkInfo(bech32Hrp: 'cosmos');
			final info2 = NetworkInfo(bech32Hrp: 'osmo');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			
			final originalWallet = Wallet.derive(mnemonic, info1);
			final convertedWallet = Wallet.convert(originalWallet, info2);
			
			// Same keys and address, different network info
			expect(convertedWallet.privateKey, equals(originalWallet.privateKey));
			expect(convertedWallet.publicKey, equals(originalWallet.publicKey));
			expect(convertedWallet.address, equals(originalWallet.address));
			expect(convertedWallet.networkInfo.bech32Hrp, equals('osmo'));
			expect(convertedWallet.bech32Address.startsWith('osmo'), isTrue);
		});

		test('should test JSON serialization and deserialization', () {
			final info = NetworkInfo(bech32Hrp: 'secret');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			
			final originalWallet = Wallet.derive(mnemonic, info);
			
			// Serialize to JSON
			final json = originalWallet.toJson();
			expect(json['hex_address'], isA<String>());
			expect(json['bech32_address'], startsWith('secret'));
			expect(json['public_key'], isA<String>());
			expect(json['network_info'], isA<Map<String, dynamic>>());
			
			// Deserialize from JSON
			final deserializedWallet = Wallet.fromJson(json, originalWallet.privateKey);
			expect(deserializedWallet.address, equals(originalWallet.address));
			expect(deserializedWallet.publicKey, equals(originalWallet.publicKey));
			expect(deserializedWallet.privateKey, equals(originalWallet.privateKey));
			expect(deserializedWallet.networkInfo.bech32Hrp, equals(originalWallet.networkInfo.bech32Hrp));
		});

		test('should test different derivation paths', () {
			final info = NetworkInfo(bech32Hrp: 'cosmos');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			
			// Test with different derivation paths
			final wallet1 = Wallet.derive(mnemonic, info, derivationPath: "m/44'/118'/0'/0/0");
			final wallet2 = Wallet.derive(mnemonic, info, derivationPath: "m/44'/118'/0'/0/1");
			
			expect(wallet1.privateKey, isNot(equals(wallet2.privateKey)));
			expect(wallet1.publicKey, isNot(equals(wallet2.publicKey)));
			expect(wallet1.address, isNot(equals(wallet2.address)));
		});

		test('should verify signature normalization edge case', () {
			// This test is designed to potentially hit the normalization edge case (line 170)
			final info = NetworkInfo(bech32Hrp: 'cosmos');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			final wallet = Wallet.derive(mnemonic, info);
			
			// Sign multiple different messages to increase chance of hitting normalization
			for (int i = 0; i < 20; i++) {
				final testData = Uint8List.fromList('test message $i with varying content to trigger different signature conditions'.codeUnits);
				final signature = wallet.sign(testData);
				expect(signature.length, equals(64));
			}
		});

		test('should test wallet equality through props', () {
			final info = NetworkInfo(bech32Hrp: 'cosmos');
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			
			final wallet1 = Wallet.derive(mnemonic, info);
			final wallet2 = Wallet.derive(mnemonic, info);
			
			// Should be equal due to same derivation
			expect(wallet1, equals(wallet2));
			expect(wallet1.props, equals(wallet2.props));
		});

		test('should test random wallet with custom derivation path', () {
			final info = NetworkInfo(bech32Hrp: 'juno');
			const customPath = "m/44'/118'/1'/0/0";
			
			final wallet = Wallet.random(info, derivationPath: customPath);
			
			expect(wallet, isA<Wallet>());
			expect(wallet.networkInfo.bech32Hrp, equals('juno'));
			expect(wallet.bech32Address.startsWith('juno'), isTrue);
		});
	});
} 