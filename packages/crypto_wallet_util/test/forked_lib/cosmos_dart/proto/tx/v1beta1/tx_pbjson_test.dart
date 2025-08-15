import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/v1beta1/tx.pbjson.dart';

void main() {
	group('cosmos.tx.v1beta1 pbjson', () {
		test('JSON maps have message names', () {
			expect(txDescriptor, isNotEmpty);
			expect(txRawDescriptor, isNotEmpty);
			expect(signDocDescriptor, isNotEmpty);
			expect(txBodyDescriptor, isNotEmpty);
			expect(authInfoDescriptor, isNotEmpty);
			expect(signerInfoDescriptor, isNotEmpty);
			expect(modeInfoDescriptor, isNotEmpty);
			expect(feeDescriptor, isNotEmpty);
		});
	});
} 