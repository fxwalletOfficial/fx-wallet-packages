import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/v1beta1/tx.pb.dart' as tx;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/any.pb.dart' as anypb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart' as coin;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/crypto/multisig/v1beta1/multisig.pb.dart' as multisig;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/signing/v1beta1/signing.pbenum.dart' as signenum;

void main() {
	group('cosmos.tx.v1beta1 Tx', () {
		test('has/clear/ensure/clone/copyWith/json/buffer', () {
			final txBody = tx.TxBody(messages: [anypb.Any(typeUrl: 'test', value: [1, 2])]);
			final authInfo = tx.AuthInfo(signerInfos: [tx.SignerInfo()], fee: tx.Fee());
			final txMsg = tx.Tx(
				body: txBody,
				authInfo: authInfo,
				signatures: [[3, 4], [5, 6]]
			);
			
			expect(txMsg.hasBody(), isTrue);
			expect(txMsg.hasAuthInfo(), isTrue);
			expect(txMsg.signatures.length, 2);
			
			txMsg.clearBody();
			expect(txMsg.hasBody(), isFalse);
			
			final ensuredBody = txMsg.ensureBody();
			expect(ensuredBody, isNotNull);
			expect(identical(txMsg.ensureBody(), ensuredBody), isTrue);
			
			final cloned = txMsg.clone();
			expect(cloned.signatures.length, 2);
			expect(identical(cloned.authInfo, txMsg.authInfo), isFalse);
			
			final copied = txMsg.copyWith((x) => x.signatures.add([7, 8]));
			expect(copied.signatures.length, 3);
			
			final json = jsonEncode(copied.writeToJsonMap());
			final fromJson = tx.Tx.fromJson(json);
			expect(fromJson.signatures.length, 3);
			
			final buffer = copied.writeToBuffer();
			final fromBuffer = tx.Tx.fromBuffer(buffer);
			expect(fromBuffer.signatures.length, 3);
		});
		
		test('getDefault/createEmptyInstance/createRepeated/info_', () {
			expect(identical(tx.Tx.getDefault(), tx.Tx.getDefault()), isTrue);
			final empty = tx.Tx().createEmptyInstance();
			expect(empty.signatures, isEmpty);
			final list = tx.Tx.createRepeated();
			expect(list, isA<pb.PbList<tx.Tx>>());
			expect(tx.Tx().info_.qualifiedMessageName, contains('Tx'));
		});
		
		test('signatures list operations', () {
			final txMsg = tx.Tx();
			txMsg.signatures.add([1, 2]);
			txMsg.signatures.add([3, 4]);
			expect(txMsg.signatures.length, 2);
			txMsg.signatures.removeAt(0);
			expect(txMsg.signatures.first, [3, 4]);
			txMsg.signatures.clear();
			expect(txMsg.signatures, isEmpty);
		});
	});
	
	group('cosmos.tx.v1beta1 TxRaw', () {
		test('has/clear/json/buffer with byte fields', () {
			final raw = tx.TxRaw(
				bodyBytes: [1, 2, 3],
				authInfoBytes: [4, 5, 6],
				signatures: [[7, 8], [9, 10]]
			);
			
			expect(raw.hasBodyBytes(), isTrue);
			expect(raw.hasAuthInfoBytes(), isTrue);
			expect(raw.bodyBytes, [1, 2, 3]);
			expect(raw.authInfoBytes, [4, 5, 6]);
			expect(raw.signatures.length, 2);
			
			raw.clearBodyBytes();
			expect(raw.hasBodyBytes(), isFalse);
			raw.clearAuthInfoBytes();
			expect(raw.hasAuthInfoBytes(), isFalse);
			
			final json = jsonEncode(raw.writeToJsonMap());
			final fromJson = tx.TxRaw.fromJson(json);
			expect(fromJson.signatures.length, 2);
			
			final buffer = raw.writeToBuffer();
			final fromBuffer = tx.TxRaw.fromBuffer(buffer);
			expect(fromBuffer.signatures.length, 2);
		});
		
		test('empty bytes and signatures operations', () {
			final raw = tx.TxRaw()
				..bodyBytes = []
				..authInfoBytes = [];
			expect(raw.bodyBytes, isEmpty);
			expect(raw.authInfoBytes, isEmpty);
			raw.signatures.addAll([[1], [2, 3]]);
			expect(raw.signatures.length, 2);
		});
	});
	
	group('cosmos.tx.v1beta1 SignDoc', () {
		test('has/clear/json/buffer with chainId and accountNumber', () {
			final signDoc = tx.SignDoc(
				bodyBytes: [1, 2],
				authInfoBytes: [3, 4],
				chainId: 'test-chain',
				accountNumber: Int64(12345)
			);
			
			expect(signDoc.hasBodyBytes(), isTrue);
			expect(signDoc.hasAuthInfoBytes(), isTrue);
			expect(signDoc.hasChainId(), isTrue);
			expect(signDoc.hasAccountNumber(), isTrue);
			expect(signDoc.chainId, 'test-chain');
			expect(signDoc.accountNumber.toInt(), 12345);
			
			signDoc.clearChainId();
			expect(signDoc.hasChainId(), isFalse);
			signDoc.clearAccountNumber();
			expect(signDoc.hasAccountNumber(), isFalse);
			
			final json = jsonEncode(signDoc.writeToJsonMap());
			final fromJson = tx.SignDoc.fromJson(json);
			expect(fromJson.bodyBytes, [1, 2]);
			
			final buffer = signDoc.writeToBuffer();
			final fromBuffer = tx.SignDoc.fromBuffer(buffer);
			expect(fromBuffer.authInfoBytes, [3, 4]);
		});
		
		test('zero accountNumber and empty chainId', () {
			final signDoc = tx.SignDoc()
				..chainId = ''
				..accountNumber = Int64.ZERO;
			expect(signDoc.hasChainId(), isTrue);
			expect(signDoc.hasAccountNumber(), isTrue);
			expect(signDoc.accountNumber.toInt(), 0);
		});
	});
	
	group('cosmos.tx.v1beta1 TxBody', () {
		test('messages list operations and fields', () {
			final msg1 = anypb.Any(typeUrl: 'type1', value: [1]);
			final msg2 = anypb.Any(typeUrl: 'type2', value: [2]);
			final body = tx.TxBody(
				messages: [msg1, msg2],
				memo: 'test memo',
				timeoutHeight: Int64(100),
				extensionOptions: [anypb.Any(typeUrl: 'ext1')],
				nonCriticalExtensionOptions: [anypb.Any(typeUrl: 'ext2')]
			);
			
			expect(body.messages.length, 2);
			expect(body.hasMemo(), isTrue);
			expect(body.hasTimeoutHeight(), isTrue);
			expect(body.memo, 'test memo');
			expect(body.timeoutHeight.toInt(), 100);
			expect(body.extensionOptions.length, 1);
			expect(body.nonCriticalExtensionOptions.length, 1);
			
			body.clearMemo();
			expect(body.hasMemo(), isFalse);
			body.clearTimeoutHeight();
			expect(body.hasTimeoutHeight(), isFalse);
			
			body.messages.add(anypb.Any(typeUrl: 'type3'));
			expect(body.messages.length, 3);
			body.messages.removeAt(0);
			expect(body.messages.first.typeUrl, 'type2');
			
			final cloned = body.clone();
			expect(cloned.messages.length, 2);
			expect(identical(cloned.messages.first, body.messages.first), isFalse);
		});
	});
	
	group('cosmos.tx.v1beta1 AuthInfo', () {
		test('signerInfos and fee operations', () {
			final signerInfo = tx.SignerInfo(
				publicKey: anypb.Any(typeUrl: 'pubkey'),
				modeInfo: tx.ModeInfo(),
				sequence: Int64(5)
			);
			final fee = tx.Fee(
				amount: [coin.CosmosCoin(denom: 'stake', amount: '1000')],
				gasLimit: Int64(200000),
				payer: 'payer_addr',
				granter: 'granter_addr'
			);
			final authInfo = tx.AuthInfo(
				signerInfos: [signerInfo],
				fee: fee
			);
			
			expect(authInfo.signerInfos.length, 1);
			expect(authInfo.hasFee(), isTrue);
			expect(authInfo.fee.gasLimit.toInt(), 200000);
			
			authInfo.clearFee();
			expect(authInfo.hasFee(), isFalse);
			
			final ensuredFee = authInfo.ensureFee();
			expect(ensuredFee, isNotNull);
			expect(identical(authInfo.ensureFee(), ensuredFee), isTrue);
			
			authInfo.signerInfos.add(tx.SignerInfo(sequence: Int64(10)));
			expect(authInfo.signerInfos.length, 2);
		});
	});
	
	group('cosmos.tx.v1beta1 SignerInfo', () {
		test('publicKey/modeInfo/sequence operations', () {
			final pubKey = anypb.Any(typeUrl: 'secp256k1', value: [1, 2, 3]);
			final modeInfo = tx.ModeInfo(single: tx.ModeInfo_Single(mode: signenum.SignMode.SIGN_MODE_DIRECT));
			final signerInfo = tx.SignerInfo(
				publicKey: pubKey,
				modeInfo: modeInfo,
				sequence: Int64(123)
			);
			
			expect(signerInfo.hasPublicKey(), isTrue);
			expect(signerInfo.hasModeInfo(), isTrue);
			expect(signerInfo.hasSequence(), isTrue);
			expect(signerInfo.publicKey.typeUrl, 'secp256k1');
			expect(signerInfo.sequence.toInt(), 123);
			
			signerInfo.clearPublicKey();
			expect(signerInfo.hasPublicKey(), isFalse);
			signerInfo.clearSequence();
			expect(signerInfo.hasSequence(), isFalse);
			
			final ensuredPubKey = signerInfo.ensurePublicKey();
			expect(ensuredPubKey, isNotNull);
			final ensuredModeInfo = signerInfo.ensureModeInfo();
			expect(ensuredModeInfo, isNotNull);
		});
	});
	
	group('cosmos.tx.v1beta1 ModeInfo', () {
		test('single/multi oneof operations', () {
			final single = tx.ModeInfo_Single(mode: signenum.SignMode.SIGN_MODE_DIRECT);
			final modeInfo = tx.ModeInfo(single: single);
			
			expect(modeInfo.hasSingle(), isTrue);
			expect(modeInfo.hasMulti(), isFalse);
			expect(modeInfo.single.mode, signenum.SignMode.SIGN_MODE_DIRECT);
			
			modeInfo.clearSingle();
			expect(modeInfo.hasSingle(), isFalse);
			
			final multi = tx.ModeInfo_Multi(
				bitarray: multisig.CompactBitArray(elems: [1, 2]),
				modeInfos: [tx.ModeInfo(single: tx.ModeInfo_Single())]
			);
			modeInfo.multi = multi;
			expect(modeInfo.hasMulti(), isTrue);
			expect(modeInfo.multi.modeInfos.length, 1);
			
			modeInfo.clearMulti();
			expect(modeInfo.hasMulti(), isFalse);
			
			final ensuredSingle = modeInfo.ensureSingle();
			expect(ensuredSingle, isNotNull);
		});
	});
	
	group('cosmos.tx.v1beta1 Fee', () {
		test('amount/gasLimit/payer/granter operations', () {
			final fee = tx.Fee(
				amount: [
					coin.CosmosCoin(denom: 'stake', amount: '1000'),
					coin.CosmosCoin(denom: 'atom', amount: '500')
				],
				gasLimit: Int64(300000),
				payer: 'payer_address',
				granter: 'granter_address'
			);
			
			expect(fee.amount.length, 2);
			expect(fee.hasGasLimit(), isTrue);
			expect(fee.hasPayer(), isTrue);
			expect(fee.hasGranter(), isTrue);
			expect(fee.gasLimit.toInt(), 300000);
			expect(fee.payer, 'payer_address');
			expect(fee.granter, 'granter_address');
			
			fee.clearGasLimit();
			expect(fee.hasGasLimit(), isFalse);
			fee.clearPayer();
			expect(fee.hasPayer(), isFalse);
			fee.clearGranter();
			expect(fee.hasGranter(), isFalse);
			
			fee.amount.add(coin.CosmosCoin(denom: 'osmo', amount: '200'));
			expect(fee.amount.length, 3);
			fee.amount.removeWhere((c) => c.denom == 'atom');
			expect(fee.amount.length, 2);
		});
	});
	

	
	group('cosmos.tx.v1beta1 edge cases & errors', () {
		test('invalid buffer/json error handling', () {
			expect(() => tx.Tx.fromBuffer([0xFF, 0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => tx.TxRaw.fromJson('invalid json'), throwsA(isA<FormatException>()));
			expect(() => tx.SignDoc.fromBuffer([0xFF, 0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('large Int64 values and empty lists', () {
			final signDoc = tx.SignDoc(accountNumber: Int64.MAX_VALUE);
			expect(signDoc.accountNumber, Int64.MAX_VALUE);
			
			final body = tx.TxBody(messages: []);
			expect(body.messages, isEmpty);
			body.messages.addAll(List.generate(10, (i) => anypb.Any(typeUrl: 'type$i')));
			expect(body.messages.length, 10);
		});
		
		test('nested copyWith operations', () {
			final tx1 = tx.Tx(
				body: tx.TxBody(memo: 'original'),
				authInfo: tx.AuthInfo(fee: tx.Fee(gasLimit: Int64(100000)))
			);
			
			final tx2 = tx1.clone();
			tx2.body.memo = 'modified';
			tx2.authInfo.fee.gasLimit = Int64(200000);
			
			expect(tx2.body.memo, 'modified');
			expect(tx2.authInfo.fee.gasLimit.toInt(), 200000);
			expect(tx1.body.memo, 'original'); // original unchanged
		});
	});
} 