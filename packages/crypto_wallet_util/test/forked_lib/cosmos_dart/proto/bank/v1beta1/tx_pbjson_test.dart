import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/bank/v1beta1/tx.pbjson.dart' as txpbjson;

void main() {
	group('proto cosmos.bank.v1beta1 tx.pbjson', () {
		test('Msg* descriptors basic checks', () {
			expect(txpbjson.MsgSend$json['1'], 'MsgSend');
			expect(txpbjson.MsgSendResponse$json['1'], 'MsgSendResponse');
			expect(txpbjson.MsgMultiSend$json['1'], 'MsgMultiSend');
			expect(txpbjson.MsgMultiSendResponse$json['1'], 'MsgMultiSendResponse');

			expect(txpbjson.msgSendDescriptor.isNotEmpty, isTrue);
			expect(txpbjson.msgSendResponseDescriptor.isNotEmpty, isTrue);
			expect(txpbjson.msgMultiSendDescriptor.isNotEmpty, isTrue);
			expect(txpbjson.msgMultiSendResponseDescriptor.isNotEmpty, isTrue);
		});
	});
} 