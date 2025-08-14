import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/crypto/secp256k1/keys.pb.dart';
import 'package:fixnum/fixnum.dart' as fixnum;

void main() {
	group('cosmos_dart TxBuilder & Config', () {
		test('build tx with msgs, memo, fee, gas, timeout and signatures, then encode', () {
			// message
			final msg = MsgSend(
				fromAddress: 'cosmos1from',
				toAddress: 'cosmos1to',
				amount: [CosmosCoin(denom: 'uatom', amount: '123')],
			);

			final cfg = DefaultTxConfig.create();
			final builder = cfg.newTxBuilder();
			builder.setMsgs([msg]);
			builder.setMemo('hello');
			builder.setFeeAmount([CosmosCoin(denom: 'uatom', amount: '10')]);
			builder.setFeePayer('cosmos1payer');
			builder.setFeeGranter('cosmos1granter');
			builder.setGasLimit(fixnum.Int64(200000));
			builder.setTimeoutHeight(123);

			// mock a signature
			final pubKeyAny = Any.pack(PubKey(key: []), typeUrlPrefix: 'cosmos.crypto.secp256k1');
			final sig = SignatureV2(
				pubKey: pubKeyAny,
				sequence: fixnum.Int64(1),
				data: SingleSignatureData(
					signMode: cfg.defaultSignMode(),
					signature: List<int>.filled(64, 1),
				),
			);
			builder.setSignatures([sig]);

			final tx = builder.getTx();
			expect(tx.hasBody(), isTrue);
			expect(tx.body.messages, isNotEmpty);
			expect(tx.body.memo, 'hello');
			expect(tx.hasAuthInfo(), isTrue);
			expect(tx.authInfo.hasFee(), isTrue);
			expect(tx.authInfo.fee.amount, isNotEmpty);
			expect(tx.authInfo.signerInfos.length, 1);
			expect(tx.signatures.length, 1);

			// sign bytes
			final signBytes = cfg.signModeHandler().getSignBytes(
				cfg.defaultSignMode(),
				SignerData(chainId: 'cosmoshub-4', accountNumber: fixnum.Int64(7), sequence: fixnum.Int64(1)),
				tx,
			);
			expect(signBytes, isNotEmpty);

			// encode
			final encoded = cfg.txEncoder()(tx);
			expect(encoded, isNotEmpty);
		});
	});
} 