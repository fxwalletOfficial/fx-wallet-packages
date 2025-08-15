import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/wallet/network_info.dart';

void main() {
	group('cosmos_dart NetworkInfo', () {
		test('toJson/fromJson and equality', () {
			final n1 = NetworkInfo(bech32Hrp: 'cosmos');
			final json = n1.toJson();
			expect(json['bech32_hrp'], 'cosmos');
			final n2 = NetworkInfo.fromJson(json);
			expect(n2.bech32Hrp, 'cosmos');
			expect(n1, equals(n2));
		});

		test('should cover fromSingleHost factory constructor', () {
			// Test the fromSingleHost factory method that was uncovered
			final networkInfo = NetworkInfo.fromSingleHost(
				bech32Hrp: 'osmo',
				host: 'https://osmosis-1.example.com',
			);
			
			expect(networkInfo.bech32Hrp, equals('osmo'));
			expect(networkInfo, isA<NetworkInfo>());
		});

		test('should cover toString method', () {
			// Test the toString method that was uncovered
			final networkInfo = NetworkInfo(bech32Hrp: 'terra');
			
			final stringRepresentation = networkInfo.toString();
			
			expect(stringRepresentation, equals('{ bech32: terra}'));
			expect(stringRepresentation, contains('bech32: terra'));
		});

		test('should verify props method for equality', () {
			// Additional test to ensure props method works correctly
			final n1 = NetworkInfo(bech32Hrp: 'juno');
			final n2 = NetworkInfo(bech32Hrp: 'juno');
			final n3 = NetworkInfo(bech32Hrp: 'akash');
			
			// Test equality based on props
			expect(n1, equals(n2));
			expect(n1, isNot(equals(n3)));
			
			// Test props list content
			expect(n1.props, equals(['juno']));
			expect(n2.props, equals(['juno']));
			expect(n3.props, equals(['akash']));
		});

		test('should handle various bech32Hrp values', () {
			// Test with different network types
			final cosmos = NetworkInfo(bech32Hrp: 'cosmos');
			final osmosis = NetworkInfo(bech32Hrp: 'osmo');
			final juno = NetworkInfo(bech32Hrp: 'juno');
			final secret = NetworkInfo(bech32Hrp: 'secret');
			
			expect(cosmos.bech32Hrp, equals('cosmos'));
			expect(osmosis.bech32Hrp, equals('osmo'));
			expect(juno.bech32Hrp, equals('juno'));
			expect(secret.bech32Hrp, equals('secret'));
			
			// Verify they're all different
			expect(cosmos, isNot(equals(osmosis)));
			expect(osmosis, isNot(equals(juno)));
			expect(juno, isNot(equals(secret)));
		});

		test('should cover fromSingleHost with different parameters', () {
			// Test fromSingleHost with various host values
			final testCases = [
				{'hrp': 'cosmos', 'host': 'https://cosmos-rpc.polkachu.com'},
				{'hrp': 'osmo', 'host': 'https://osmosis-rpc.quickapi.com'},
				{'hrp': 'juno', 'host': 'http://localhost:26657'},
			];
			
			for (final testCase in testCases) {
				final networkInfo = NetworkInfo.fromSingleHost(
					bech32Hrp: testCase['hrp']!,
					host: testCase['host']!,
				);
				
				expect(networkInfo.bech32Hrp, equals(testCase['hrp']));
				expect(networkInfo, isA<NetworkInfo>());
			}
		});

		test('should verify JSON serialization roundtrip', () {
			// Additional comprehensive JSON test
			final original = NetworkInfo(bech32Hrp: 'stargaze');
			
			// Serialize to JSON
			final json = original.toJson();
			expect(json, isA<Map<String, dynamic>>());
			expect(json['bech32_hrp'], equals('stargaze'));
			
			// Deserialize from JSON
			final restored = NetworkInfo.fromJson(json);
			expect(restored.bech32Hrp, equals('stargaze'));
			expect(restored, equals(original));
			
			// Verify toString works on both
			expect(original.toString(), equals(restored.toString()));
		});
	});
} 