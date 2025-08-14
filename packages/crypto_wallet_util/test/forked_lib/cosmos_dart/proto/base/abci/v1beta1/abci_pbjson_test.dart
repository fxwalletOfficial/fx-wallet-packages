import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/abci/v1beta1/abci.pbjson.dart' as abcipbjson;

void main() {
	group('cosmos.base.abci.v1beta1 abci.pbjson', () {
		test('JSON maps contain message names', () {
			expect(abcipbjson.TxResponse$json['1'], 'TxResponse');
			expect(abcipbjson.ABCIMessageLog$json['1'], 'ABCIMessageLog');
			expect(abcipbjson.StringEvent$json['1'], 'StringEvent');
			expect(abcipbjson.Attribute$json['1'], 'Attribute');
			expect(abcipbjson.GasInfo$json['1'], 'GasInfo');
			expect(abcipbjson.Result$json['1'], 'Result');
			expect(abcipbjson.SimulationResponse$json['1'], 'SimulationResponse');
			expect(abcipbjson.MsgData$json['1'], 'MsgData');
			expect(abcipbjson.TxMsgData$json['1'], 'TxMsgData');
			expect(abcipbjson.SearchTxsResult$json['1'], 'SearchTxsResult');
		});

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