import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/bank.pbjson.dart' as bankpbjson;

void main() {
	group('proto cosmos.bank.v1beta1 bank.pbjson', () {
		test('Params/SendEnabled/Input/Output/Supply/DenomUnit/Metadata descriptors', () {
			// JSON maps should have message names
			expect(bankpbjson.Params$json['1'], 'Params');
			expect(bankpbjson.SendEnabled$json['1'], 'SendEnabled');
			expect(bankpbjson.Input$json['1'], 'Input');
			expect(bankpbjson.Output$json['1'], 'Output');
			expect(bankpbjson.Supply$json['1'], 'Supply');
			expect(bankpbjson.DenomUnit$json['1'], 'DenomUnit');
			expect(bankpbjson.Metadata$json['1'], 'Metadata');

			// Binary descriptors should be non-empty
			expect(bankpbjson.paramsDescriptor.isNotEmpty, isTrue);
			expect(bankpbjson.sendEnabledDescriptor.isNotEmpty, isTrue);
			expect(bankpbjson.inputDescriptor.isNotEmpty, isTrue);
			expect(bankpbjson.outputDescriptor.isNotEmpty, isTrue);
			expect(bankpbjson.supplyDescriptor.isNotEmpty, isTrue);
			expect(bankpbjson.denomUnitDescriptor.isNotEmpty, isTrue);
			expect(bankpbjson.metadataDescriptor.isNotEmpty, isTrue);
		});
	});
} 