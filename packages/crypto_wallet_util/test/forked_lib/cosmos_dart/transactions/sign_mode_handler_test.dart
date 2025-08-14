import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';
import 'package:fixnum/fixnum.dart' as fixnum;

void main() {
	group('cosmos_dart SignModeHandler', () {
		test('DirectSignModeHandler supports only SIGN_MODE_DIRECT and returns sign bytes', () {
			final cfg = DefaultTxConfig.create();
			final handler = cfg.signModeHandler();
			expect(handler.modes, [SignMode.SIGN_MODE_DIRECT]);

			final builder = cfg.newTxBuilder();
			builder.setMsgs([MsgSend(fromAddress: 'a', toAddress: 'b', amount: [])]);
			builder.setMemo('memo');
			builder.setSignatures([
				SignatureV2(
					pubKey: Any(),
					sequence: fixnum.Int64(0),
					data: SingleSignatureData(signMode: cfg.defaultSignMode()),
				)
			]);
			final tx = builder.getTx();

			final bytes = handler.getSignBytes(
				SignMode.SIGN_MODE_DIRECT,
				SignerData(chainId: 'cid', accountNumber: fixnum.Int64(1), sequence: fixnum.Int64(0)),
				tx,
			);
			expect(bytes, isNotEmpty);

			expect(
				() => handler.getSignBytes(SignMode.SIGN_MODE_UNSPECIFIED, SignerData(chainId: 'cid', accountNumber: fixnum.Int64(1), sequence: fixnum.Int64(0)), tx),
				throwsException,
			);
		});
	});
} 