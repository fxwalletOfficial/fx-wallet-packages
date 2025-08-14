import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/v1beta1/tx.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';
import 'package:fixnum/fixnum.dart';

void main() {
	group('proto cosmos.tx.v1beta1', () {
		test('TxRaw signatures and bytes roundtrip', () {
			final raw = TxRaw.create()
				..bodyBytes = [1,2,3]
				..authInfoBytes = [4,5,6];
			raw.signatures.addAll([
				List<int>.filled(64, 7),
			]);
			final bytes = raw.writeToBuffer();
			final decoded = TxRaw.fromBuffer(bytes);
			expect(decoded.bodyBytes, [1,2,3]);
			expect(decoded.authInfoBytes, [4,5,6]);
			expect(decoded.signatures.length, 1);
			expect(decoded.signatures.first.length, 64);
		});

		test('Tx with body/authInfo/fee and messages', () {
			final tx = Tx.create();
			tx.body = TxBody.create();
			tx.body.memo = 'm';
			tx.authInfo = AuthInfo.create();
			tx.authInfo.fee = Fee.create();
			tx.authInfo.fee.gasLimit = Int64(200000);
			tx.authInfo.fee.amount.add(CosmosCoin(denom: 'uatom', amount: '10'));
			final bytes = tx.writeToBuffer();
			final decoded = Tx.fromBuffer(bytes);
			expect(decoded.body.memo, 'm');
			expect(decoded.authInfo.fee.gasLimit.toInt(), 200000);
			expect(decoded.authInfo.fee.amount.first.denom, 'uatom');
		});

		test('SignDoc encodes chainId/accountNumber/body/auth bytes', () {
			final doc = SignDoc.create()
				..chainId = 'cid'
				..accountNumber = Int64(7)
				..bodyBytes = [1]
				..authInfoBytes = [2];
			final bytes = doc.writeToBuffer();
			final decoded = SignDoc.fromBuffer(bytes);
			expect(decoded.chainId, 'cid');
			expect(decoded.accountNumber.toInt(), 7);
			expect(decoded.bodyBytes, [1]);
			expect(decoded.authInfoBytes, [2]);
		});
	});
} 