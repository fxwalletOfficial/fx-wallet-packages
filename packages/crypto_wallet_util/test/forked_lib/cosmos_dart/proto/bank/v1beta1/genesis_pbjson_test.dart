import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/genesis.pbjson.dart' as gpbjson;

void main() {
	group('proto cosmos.bank.v1beta1 genesis.pbjson', () {
		test('GenesisState/Balance descriptors basic checks', () {
			expect(gpbjson.GenesisState$json['1'], 'GenesisState');
			expect(gpbjson.Balance$json['1'], 'Balance');
			expect(gpbjson.genesisStateDescriptor.isNotEmpty, isTrue);
			expect(gpbjson.balanceDescriptor.isNotEmpty, isTrue);
		});
	});
} 