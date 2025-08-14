import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/abci/v1beta1/abci.pbjson.dart' as abcipbjson;

void main() {
	group('cosmos.base.abci.v1beta1 abci.pbjson', () {
		test('Binary descriptors are non-empty', () {
			expect(abcipbjson.txResponseDescriptor.isNotEmpty, isTrue);
			expect(abcipbjson.aBCIMessageLogDescriptor.isNotEmpty, isTrue);
			expect(abcipbjson.stringEventDescriptor.isNotEmpty, isTrue);
			expect(abcipbjson.attributeDescriptor.isNotEmpty, isTrue);
			expect(abcipbjson.gasInfoDescriptor.isNotEmpty, isTrue);
			expect(abcipbjson.resultDescriptor.isNotEmpty, isTrue);
			expect(abcipbjson.simulationResponseDescriptor.isNotEmpty, isTrue);
			expect(abcipbjson.msgDataDescriptor.isNotEmpty, isTrue);
			expect(abcipbjson.txMsgDataDescriptor.isNotEmpty, isTrue);
			expect(abcipbjson.searchTxsResultDescriptor.isNotEmpty, isTrue);
		});
	});
}