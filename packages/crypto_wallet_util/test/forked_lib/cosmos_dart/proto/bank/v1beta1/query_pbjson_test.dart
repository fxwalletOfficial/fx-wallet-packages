import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/query.pbjson.dart' as qpbjson;

void main() {
	group('proto cosmos.bank.v1beta1 query.pbjson', () {
		test('Query* descriptors basic checks', () {
			expect(qpbjson.QueryBalanceRequest$json['1'], 'QueryBalanceRequest');
			expect(qpbjson.QueryBalanceResponse$json['1'], 'QueryBalanceResponse');
			expect(qpbjson.QueryAllBalancesRequest$json['1'], 'QueryAllBalancesRequest');
			expect(qpbjson.QueryAllBalancesResponse$json['1'], 'QueryAllBalancesResponse');
			expect(qpbjson.QuerySpendableBalancesRequest$json['1'], 'QuerySpendableBalancesRequest');
			expect(qpbjson.QuerySpendableBalancesResponse$json['1'], 'QuerySpendableBalancesResponse');
			expect(qpbjson.QueryTotalSupplyRequest$json['1'], 'QueryTotalSupplyRequest');
			expect(qpbjson.QueryTotalSupplyResponse$json['1'], 'QueryTotalSupplyResponse');
			expect(qpbjson.QuerySupplyOfRequest$json['1'], 'QuerySupplyOfRequest');
			expect(qpbjson.QuerySupplyOfResponse$json['1'], 'QuerySupplyOfResponse');
			expect(qpbjson.QueryParamsRequest$json['1'], 'QueryParamsRequest');
			expect(qpbjson.QueryParamsResponse$json['1'], 'QueryParamsResponse');
			expect(qpbjson.QueryDenomsMetadataRequest$json['1'], 'QueryDenomsMetadataRequest');
			expect(qpbjson.QueryDenomsMetadataResponse$json['1'], 'QueryDenomsMetadataResponse');
			expect(qpbjson.QueryDenomMetadataRequest$json['1'], 'QueryDenomMetadataRequest');
			expect(qpbjson.QueryDenomMetadataResponse$json['1'], 'QueryDenomMetadataResponse');

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