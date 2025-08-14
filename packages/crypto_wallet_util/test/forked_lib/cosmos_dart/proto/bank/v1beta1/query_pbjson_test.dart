import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/query.pbjson.dart' as qpbjson;

void main() {
	group('proto cosmos.bank.v1beta1 query.pbjson', () {
		test('Query* descriptors basic checks', () {
			expect(qpbjson.queryBalanceRequestDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.queryBalanceResponseDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.queryAllBalancesRequestDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.queryAllBalancesResponseDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.querySpendableBalancesRequestDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.querySpendableBalancesResponseDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.queryTotalSupplyRequestDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.queryTotalSupplyResponseDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.querySupplyOfRequestDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.querySupplyOfResponseDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.queryParamsRequestDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.queryParamsResponseDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.queryDenomsMetadataRequestDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.queryDenomsMetadataResponseDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.queryDenomMetadataRequestDescriptor.isNotEmpty, isTrue);
			expect(qpbjson.queryDenomMetadataResponseDescriptor.isNotEmpty, isTrue);
		});
	});
}