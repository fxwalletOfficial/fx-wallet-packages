import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/v1beta1/tx.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/any.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/signing/v1beta1/signing.pbenum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/crypto/multisig/v1beta1/multisig.pb.dart';

void main() {
	group('cosmos.tx.v1beta1 Tx', () {
		test('constructor with all parameters', () {
			final body = TxBody();
			final authInfo = AuthInfo();
			final signatures = [
				Uint8List.fromList([1, 2, 3]),
				Uint8List.fromList([4, 5, 6]),
			];
			
			final tx = Tx(
				body: body,
				authInfo: authInfo,
				signatures: signatures,
			);
			
			expect(tx.hasBody(), true);
			expect(tx.hasAuthInfo(), true);
			expect(tx.signatures.length, 2);
			expect(tx.signatures[0], [1, 2, 3]);
			expect(tx.signatures[1], [4, 5, 6]);
		});
		
		test('constructor with partial parameters', () {
			final body = TxBody();
			
			final tx = Tx(body: body);
			
			expect(tx.hasBody(), true);
			expect(tx.hasAuthInfo(), false);
			expect(tx.signatures, isEmpty);
		});
		
		test('default constructor', () {
			final tx = Tx();
			
			expect(tx.hasBody(), false);
			expect(tx.hasAuthInfo(), false);
			expect(tx.signatures, isEmpty);
		});
		
		test('has/clear/ensure operations', () {
			final tx = Tx();
			
			// Test body
			expect(tx.hasBody(), false);
			final body = tx.ensureBody();
			expect(tx.hasBody(), true);
			expect(body, isA<TxBody>());
			
			tx.clearBody();
			expect(tx.hasBody(), false);
			
			// Test authInfo
			expect(tx.hasAuthInfo(), false);
			final authInfo = tx.ensureAuthInfo();
			expect(tx.hasAuthInfo(), true);
			expect(authInfo, isA<AuthInfo>());
			
			tx.clearAuthInfo();
			expect(tx.hasAuthInfo(), false);
		});
		
		test('signatures list operations', () {
			final tx = Tx();
			
			expect(tx.signatures, isEmpty);
			
			final sig1 = Uint8List.fromList([10, 20, 30]);
			final sig2 = Uint8List.fromList([40, 50, 60]);
			
			tx.signatures.add(sig1);
			tx.signatures.add(sig2);
			
			expect(tx.signatures.length, 2);
			expect(tx.signatures[0], [10, 20, 30]);
			expect(tx.signatures[1], [40, 50, 60]);
			
			tx.signatures.removeAt(0);
			expect(tx.signatures.length, 1);
			expect(tx.signatures[0], [40, 50, 60]);
			
			tx.signatures.clear();
			expect(tx.signatures, isEmpty);
		});
		
		test('clone operation', () {
			final original = Tx();
			original.ensureBody();
			original.ensureAuthInfo();
			original.signatures.add(Uint8List.fromList([1, 2, 3]));
			
			final cloned = original.clone();
			expect(cloned.hasBody(), true);
			expect(cloned.hasAuthInfo(), true);
			expect(cloned.signatures.length, 1);
			expect(cloned.signatures[0], [1, 2, 3]);
			
			// Verify independence
			cloned.signatures.add(Uint8List.fromList([4, 5, 6]));
			expect(cloned.signatures.length, 2);
			expect(original.signatures.length, 1);
		});
		
		test('copyWith operation', () {
			final original = Tx();
			original.ensureBody();
			
			final copied = original.clone().copyWith((tx) {
				tx.ensureAuthInfo();
			});
			
			expect(copied.hasBody(), true);
			expect(copied.hasAuthInfo(), true);
			expect(original.hasAuthInfo(), false); // original unchanged
		});
		
		test('JSON and buffer serialization', () {
			final tx = Tx();
			tx.ensureBody();
			tx.ensureAuthInfo();
			tx.signatures.add(Uint8List.fromList([100, 200]));
			
			final json = jsonEncode(tx.writeToJsonMap());
			final fromJson = Tx.fromJson(json);
			expect(fromJson.hasBody(), true);
			expect(fromJson.hasAuthInfo(), true);
			expect(fromJson.signatures.length, 1);
			expect(fromJson.signatures[0], [100, 200]);
			
			final buffer = tx.writeToBuffer();
			final fromBuffer = Tx.fromBuffer(buffer);
			expect(fromBuffer.hasBody(), true);
			expect(fromBuffer.hasAuthInfo(), true);
			expect(fromBuffer.signatures.length, 1);
			expect(fromBuffer.signatures[0], [100, 200]);
		});
		
		test('getDefault and createRepeated', () {
			expect(identical(Tx.getDefault(), Tx.getDefault()), isTrue);
			
			final list = Tx.createRepeated();
			expect(list, isA<pb.PbList<Tx>>());
		});
	});
	
	group('cosmos.tx.v1beta1 TxRaw', () {
		test('constructor with all parameters', () {
			final bodyBytes = Uint8List.fromList([1, 2, 3, 4]);
			final authInfoBytes = Uint8List.fromList([5, 6, 7, 8]);
			final signatures = [Uint8List.fromList([9, 10, 11])];
			
			final txRaw = TxRaw(
				bodyBytes: bodyBytes,
				authInfoBytes: authInfoBytes,
				signatures: signatures,
			);
			
			expect(txRaw.bodyBytes, [1, 2, 3, 4]);
			expect(txRaw.authInfoBytes, [5, 6, 7, 8]);
			expect(txRaw.signatures.length, 1);
			expect(txRaw.signatures[0], [9, 10, 11]);
		});
		
		test('default constructor', () {
			final txRaw = TxRaw();
			
			expect(txRaw.bodyBytes, isEmpty);
			expect(txRaw.authInfoBytes, isEmpty);
			expect(txRaw.signatures, isEmpty);
		});
		
		test('has/clear operations', () {
			final txRaw = TxRaw(
				bodyBytes: Uint8List.fromList([1, 2]),
				authInfoBytes: Uint8List.fromList([3, 4]),
			);
			
			expect(txRaw.hasBodyBytes(), true);
			expect(txRaw.hasAuthInfoBytes(), true);
			
			txRaw.clearBodyBytes();
			txRaw.clearAuthInfoBytes();
			
			expect(txRaw.hasBodyBytes(), false);
			expect(txRaw.hasAuthInfoBytes(), false);
			expect(txRaw.bodyBytes, isEmpty);
			expect(txRaw.authInfoBytes, isEmpty);
		});
		
		test('clone and JSON/buffer serialization', () {
			final original = TxRaw(
				bodyBytes: Uint8List.fromList([10, 20]),
				authInfoBytes: Uint8List.fromList([30, 40]),
			);
			original.signatures.add(Uint8List.fromList([50, 60]));
			
			final cloned = original.clone();
			expect(cloned.bodyBytes, [10, 20]);
			expect(cloned.authInfoBytes, [30, 40]);
			expect(cloned.signatures.length, 1);
			expect(cloned.signatures[0], [50, 60]);
			
			final json = jsonEncode(original.writeToJsonMap());
			final fromJson = TxRaw.fromJson(json);
			expect(fromJson.bodyBytes, [10, 20]);
			expect(fromJson.authInfoBytes, [30, 40]);
			expect(fromJson.signatures.length, 1);
			expect(fromJson.signatures[0], [50, 60]);
			
			final buffer = original.writeToBuffer();
			final fromBuffer = TxRaw.fromBuffer(buffer);
			expect(fromBuffer.bodyBytes, [10, 20]);
			expect(fromBuffer.authInfoBytes, [30, 40]);
			expect(fromBuffer.signatures.length, 1);
			expect(fromBuffer.signatures[0], [50, 60]);
		});
	});
	
	group('cosmos.tx.v1beta1 SignDoc', () {
		test('constructor with all parameters', () {
			final bodyBytes = Uint8List.fromList([1, 2, 3]);
			final authInfoBytes = Uint8List.fromList([4, 5, 6]);
			
			final signDoc = SignDoc(
				bodyBytes: bodyBytes,
				authInfoBytes: authInfoBytes,
				chainId: 'cosmos-hub-4',
				accountNumber: Int64(12345),
			);
			
			expect(signDoc.bodyBytes, [1, 2, 3]);
			expect(signDoc.authInfoBytes, [4, 5, 6]);
			expect(signDoc.chainId, 'cosmos-hub-4');
			expect(signDoc.accountNumber, Int64(12345));
		});
		
		test('default constructor', () {
			final signDoc = SignDoc();
			
			expect(signDoc.bodyBytes, isEmpty);
			expect(signDoc.authInfoBytes, isEmpty);
			expect(signDoc.chainId, '');
			expect(signDoc.accountNumber, Int64.ZERO);
		});
		
		test('has/clear operations', () {
			final signDoc = SignDoc(
				bodyBytes: Uint8List.fromList([1]),
				authInfoBytes: Uint8List.fromList([2]),
				chainId: 'test-chain',
				accountNumber: Int64(100),
			);
			
			expect(signDoc.hasBodyBytes(), true);
			expect(signDoc.hasAuthInfoBytes(), true);
			expect(signDoc.hasChainId(), true);
			expect(signDoc.hasAccountNumber(), true);
			
			signDoc.clearBodyBytes();
			signDoc.clearAuthInfoBytes();
			signDoc.clearChainId();
			signDoc.clearAccountNumber();
			
			expect(signDoc.hasBodyBytes(), false);
			expect(signDoc.hasAuthInfoBytes(), false);
			expect(signDoc.hasChainId(), false);
			expect(signDoc.hasAccountNumber(), false);
		});
		
		test('large account number', () {
			final signDoc = SignDoc(
				accountNumber: Int64.parseInt('9223372036854775807'),
			);
			
			expect(signDoc.accountNumber.toString(), '9223372036854775807');
			
			final buffer = signDoc.writeToBuffer();
			final fromBuffer = SignDoc.fromBuffer(buffer);
			expect(fromBuffer.accountNumber.toString(), '9223372036854775807');
		});
	});
	
	group('cosmos.tx.v1beta1 TxBody', () {
		test('constructor with all parameters', () {
			final message1 = Any(typeUrl: 'type1', value: Uint8List.fromList([1, 2]));
			final message2 = Any(typeUrl: 'type2', value: Uint8List.fromList([3, 4]));
			
			final txBody = TxBody(
				messages: [message1, message2],
				memo: 'test memo',
				timeoutHeight: Int64(1000),
				extensionOptions: [Any(typeUrl: 'ext1')],
				nonCriticalExtensionOptions: [Any(typeUrl: 'ext2')],
			);
			
			expect(txBody.messages.length, 2);
			expect(txBody.messages[0].typeUrl, 'type1');
			expect(txBody.messages[1].typeUrl, 'type2');
			expect(txBody.memo, 'test memo');
			expect(txBody.timeoutHeight, Int64(1000));
			expect(txBody.extensionOptions.length, 1);
			expect(txBody.nonCriticalExtensionOptions.length, 1);
		});
		
		test('default constructor', () {
			final txBody = TxBody();
			
			expect(txBody.messages, isEmpty);
			expect(txBody.memo, '');
			expect(txBody.timeoutHeight, Int64.ZERO);
			expect(txBody.extensionOptions, isEmpty);
			expect(txBody.nonCriticalExtensionOptions, isEmpty);
		});
		
		test('list operations', () {
			final txBody = TxBody();
			
			// Test messages
			final msg1 = Any(typeUrl: 'msg1');
			final msg2 = Any(typeUrl: 'msg2');
			
			txBody.messages.addAll([msg1, msg2]);
			expect(txBody.messages.length, 2);
			
			txBody.messages.removeAt(0);
			expect(txBody.messages.length, 1);
			expect(txBody.messages[0].typeUrl, 'msg2');
			
			// Test extension options
			final ext1 = Any(typeUrl: 'ext1');
			txBody.extensionOptions.add(ext1);
			expect(txBody.extensionOptions.length, 1);
			
			// Test non-critical extension options
			final nonCritExt = Any(typeUrl: 'noncrit');
			txBody.nonCriticalExtensionOptions.add(nonCritExt);
			expect(txBody.nonCriticalExtensionOptions.length, 1);
		});
		
		test('has/clear operations', () {
			final txBody = TxBody(
				memo: 'test',
				timeoutHeight: Int64(500),
			);
			
			expect(txBody.hasMemo(), true);
			expect(txBody.hasTimeoutHeight(), true);
			
			txBody.clearMemo();
			txBody.clearTimeoutHeight();
			
			expect(txBody.hasMemo(), false);
			expect(txBody.hasTimeoutHeight(), false);
			expect(txBody.memo, '');
			expect(txBody.timeoutHeight, Int64.ZERO);
		});
	});
	
	group('cosmos.tx.v1beta1 AuthInfo', () {
		test('constructor with all parameters', () {
			final signerInfo1 = SignerInfo();
			final signerInfo2 = SignerInfo();
			final fee = Fee();
			
			final authInfo = AuthInfo(
				signerInfos: [signerInfo1, signerInfo2],
				fee: fee,
			);
			
			expect(authInfo.signerInfos.length, 2);
			expect(authInfo.hasFee(), true);
		});
		
		test('default constructor', () {
			final authInfo = AuthInfo();
			
			expect(authInfo.signerInfos, isEmpty);
			expect(authInfo.hasFee(), false);
		});
		
		test('has/clear/ensure operations', () {
			final authInfo = AuthInfo();
			
			expect(authInfo.hasFee(), false);
			
			final fee = authInfo.ensureFee();
			expect(authInfo.hasFee(), true);
			expect(fee, isA<Fee>());
			
			authInfo.clearFee();
			expect(authInfo.hasFee(), false);
		});
		
		test('signerInfos list operations', () {
			final authInfo = AuthInfo();
			
			final signer1 = SignerInfo();
			final signer2 = SignerInfo();
			
			authInfo.signerInfos.addAll([signer1, signer2]);
			expect(authInfo.signerInfos.length, 2);
			
			authInfo.signerInfos.clear();
			expect(authInfo.signerInfos, isEmpty);
		});
	});
	
	group('cosmos.tx.v1beta1 SignerInfo', () {
		test('constructor with all parameters', () {
			final publicKey = Any(typeUrl: 'cosmos.crypto.secp256k1.PubKey');
			final modeInfo = ModeInfo();
			
			final signerInfo = SignerInfo(
				publicKey: publicKey,
				modeInfo: modeInfo,
				sequence: Int64(42),
			);
			
			expect(signerInfo.hasPublicKey(), true);
			expect(signerInfo.publicKey.typeUrl, 'cosmos.crypto.secp256k1.PubKey');
			expect(signerInfo.hasModeInfo(), true);
			expect(signerInfo.sequence, Int64(42));
		});
		
		test('default constructor', () {
			final signerInfo = SignerInfo();
			
			expect(signerInfo.hasPublicKey(), false);
			expect(signerInfo.hasModeInfo(), false);
			expect(signerInfo.sequence, Int64.ZERO);
		});
		
		test('has/clear/ensure operations', () {
			final signerInfo = SignerInfo();
			
			// Test publicKey
			expect(signerInfo.hasPublicKey(), false);
			final publicKey = signerInfo.ensurePublicKey();
			expect(signerInfo.hasPublicKey(), true);
			expect(publicKey, isA<Any>());
			
			signerInfo.clearPublicKey();
			expect(signerInfo.hasPublicKey(), false);
			
			// Test modeInfo
			expect(signerInfo.hasModeInfo(), false);
			final modeInfo = signerInfo.ensureModeInfo();
			expect(signerInfo.hasModeInfo(), true);
			expect(modeInfo, isA<ModeInfo>());
			
			signerInfo.clearModeInfo();
			expect(signerInfo.hasModeInfo(), false);
			
			// Test sequence
			signerInfo.sequence = Int64(999);
			expect(signerInfo.hasSequence(), true);
			
			signerInfo.clearSequence();
			expect(signerInfo.hasSequence(), false);
			expect(signerInfo.sequence, Int64.ZERO);
		});
	});
	
	group('cosmos.tx.v1beta1 ModeInfo_Single', () {
		test('constructor with mode', () {
			final single = ModeInfo_Single(mode: SignMode.SIGN_MODE_DIRECT);
			
			expect(single.mode, SignMode.SIGN_MODE_DIRECT);
		});
		
		test('default constructor', () {
			final single = ModeInfo_Single();
			
			expect(single.mode, SignMode.SIGN_MODE_UNSPECIFIED);
		});
		
		test('has/clear operations', () {
			final single = ModeInfo_Single(mode: SignMode.SIGN_MODE_TEXTUAL);
			
			expect(single.hasMode(), true);
			expect(single.mode, SignMode.SIGN_MODE_TEXTUAL);
			
			single.clearMode();
			expect(single.hasMode(), false);
			expect(single.mode, SignMode.SIGN_MODE_UNSPECIFIED);
		});
		
		test('all SignMode values', () {
			final modes = [
				SignMode.SIGN_MODE_UNSPECIFIED,
				SignMode.SIGN_MODE_DIRECT,
				SignMode.SIGN_MODE_TEXTUAL,
				SignMode.SIGN_MODE_LEGACY_AMINO_JSON,
				SignMode.SIGN_MODE_EIP_191,
			];
			
			for (final mode in modes) {
				final single = ModeInfo_Single(mode: mode);
				expect(single.mode, mode);
				
				final buffer = single.writeToBuffer();
				final fromBuffer = ModeInfo_Single.fromBuffer(buffer);
				expect(fromBuffer.mode, mode);
			}
		});
	});
	
	group('cosmos.tx.v1beta1 ModeInfo_Multi', () {
		test('constructor with all parameters', () {
			final bitarray = CompactBitArray();
			final modeInfo1 = ModeInfo();
			final modeInfo2 = ModeInfo();
			
			final multi = ModeInfo_Multi(
				bitarray: bitarray,
				modeInfos: [modeInfo1, modeInfo2],
			);
			
			expect(multi.hasBitarray(), true);
			expect(multi.modeInfos.length, 2);
		});
		
		test('default constructor', () {
			final multi = ModeInfo_Multi();
			
			expect(multi.hasBitarray(), false);
			expect(multi.modeInfos, isEmpty);
		});
		
		test('has/clear/ensure operations', () {
			final multi = ModeInfo_Multi();
			
			expect(multi.hasBitarray(), false);
			
			final bitarray = multi.ensureBitarray();
			expect(multi.hasBitarray(), true);
			expect(bitarray, isA<CompactBitArray>());
			
			multi.clearBitarray();
			expect(multi.hasBitarray(), false);
		});
		
		test('modeInfos list operations', () {
			final multi = ModeInfo_Multi();
			
			final mode1 = ModeInfo();
			final mode2 = ModeInfo();
			
			multi.modeInfos.addAll([mode1, mode2]);
			expect(multi.modeInfos.length, 2);
			
			multi.modeInfos.removeAt(0);
			expect(multi.modeInfos.length, 1);
			
			multi.modeInfos.clear();
			expect(multi.modeInfos, isEmpty);
		});
	});
	
	group('cosmos.tx.v1beta1 ModeInfo', () {
		test('constructor with single', () {
			final single = ModeInfo_Single(mode: SignMode.SIGN_MODE_DIRECT);
			final modeInfo = ModeInfo(single: single);
			
			expect(modeInfo.hasSingle(), true);
			expect(modeInfo.hasMulti(), false);
			expect(modeInfo.whichSum(), ModeInfo_Sum.single);
			expect(modeInfo.single.mode, SignMode.SIGN_MODE_DIRECT);
		});
		
		test('constructor with multi', () {
			final multi = ModeInfo_Multi();
			final modeInfo = ModeInfo(multi: multi);
			
			expect(modeInfo.hasSingle(), false);
			expect(modeInfo.hasMulti(), true);
			expect(modeInfo.whichSum(), ModeInfo_Sum.multi);
		});
		
		test('default constructor', () {
			final modeInfo = ModeInfo();
			
			expect(modeInfo.hasSingle(), false);
			expect(modeInfo.hasMulti(), false);
			expect(modeInfo.whichSum(), ModeInfo_Sum.notSet);
		});
		
		test('oneof behavior - setting single clears multi', () {
			final modeInfo = ModeInfo();
			
			// Set multi first
			modeInfo.multi = ModeInfo_Multi();
			expect(modeInfo.hasMulti(), true);
			expect(modeInfo.whichSum(), ModeInfo_Sum.multi);
			
			// Set single - should clear multi
			modeInfo.single = ModeInfo_Single();
			expect(modeInfo.hasSingle(), true);
			expect(modeInfo.hasMulti(), false);
			expect(modeInfo.whichSum(), ModeInfo_Sum.single);
		});
		
		test('oneof behavior - setting multi clears single', () {
			final modeInfo = ModeInfo();
			
			// Set single first
			modeInfo.single = ModeInfo_Single();
			expect(modeInfo.hasSingle(), true);
			expect(modeInfo.whichSum(), ModeInfo_Sum.single);
			
			// Set multi - should clear single
			modeInfo.multi = ModeInfo_Multi();
			expect(modeInfo.hasSingle(), false);
			expect(modeInfo.hasMulti(), true);
			expect(modeInfo.whichSum(), ModeInfo_Sum.multi);
		});
		
		test('clearSum operation', () {
			final modeInfo = ModeInfo();
			
			modeInfo.single = ModeInfo_Single();
			expect(modeInfo.whichSum(), ModeInfo_Sum.single);
			
			modeInfo.clearSum();
			expect(modeInfo.whichSum(), ModeInfo_Sum.notSet);
		});
		
		test('ensure operations', () {
			final modeInfo = ModeInfo();
			
			final single = modeInfo.ensureSingle();
			expect(modeInfo.hasSingle(), true);
			expect(single, isA<ModeInfo_Single>());
			
			modeInfo.clearSum();
			
			final multi = modeInfo.ensureMulti();
			expect(modeInfo.hasMulti(), true);
			expect(multi, isA<ModeInfo_Multi>());
		});
	});
	
	group('cosmos.tx.v1beta1 Fee', () {
		test('constructor with all parameters', () {
			final coin1 = CosmosCoin(denom: 'stake', amount: '1000');
			final coin2 = CosmosCoin(denom: 'atom', amount: '500');
			
			final fee = Fee(
				amount: [coin1, coin2],
				gasLimit: Int64(200000),
				payer: 'cosmos1payer...',
				granter: 'cosmos1granter...',
			);
			
			expect(fee.amount.length, 2);
			expect(fee.amount[0].denom, 'stake');
			expect(fee.amount[0].amount, '1000');
			expect(fee.amount[1].denom, 'atom');
			expect(fee.amount[1].amount, '500');
			expect(fee.gasLimit, Int64(200000));
			expect(fee.payer, 'cosmos1payer...');
			expect(fee.granter, 'cosmos1granter...');
		});
		
		test('default constructor', () {
			final fee = Fee();
			
			expect(fee.amount, isEmpty);
			expect(fee.gasLimit, Int64.ZERO);
			expect(fee.payer, '');
			expect(fee.granter, '');
		});
		
		test('has/clear operations', () {
			final fee = Fee(
				gasLimit: Int64(100000),
				payer: 'test-payer',
				granter: 'test-granter',
			);
			
			expect(fee.hasGasLimit(), true);
			expect(fee.hasPayer(), true);
			expect(fee.hasGranter(), true);
			
			fee.clearGasLimit();
			fee.clearPayer();
			fee.clearGranter();
			
			expect(fee.hasGasLimit(), false);
			expect(fee.hasPayer(), false);
			expect(fee.hasGranter(), false);
			expect(fee.gasLimit, Int64.ZERO);
			expect(fee.payer, '');
			expect(fee.granter, '');
		});
		
		test('amount list operations', () {
			final fee = Fee();
			
			final coin1 = CosmosCoin(denom: 'fee1', amount: '100');
			final coin2 = CosmosCoin(denom: 'fee2', amount: '200');
			
			fee.amount.addAll([coin1, coin2]);
			expect(fee.amount.length, 2);
			
			fee.amount.removeAt(0);
			expect(fee.amount.length, 1);
			expect(fee.amount[0].denom, 'fee2');
			
			fee.amount.clear();
			expect(fee.amount, isEmpty);
		});
		
		test('large gas limit', () {
			final fee = Fee(gasLimit: Int64.parseInt('9223372036854775807'));
			
			expect(fee.gasLimit.toString(), '9223372036854775807');
			
			final buffer = fee.writeToBuffer();
			final fromBuffer = Fee.fromBuffer(buffer);
			expect(fromBuffer.gasLimit.toString(), '9223372036854775807');
		});
	});
	
	group('cosmos.tx.v1beta1 error handling', () {
		test('invalid buffer deserialization', () {
			expect(() => Tx.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => TxRaw.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => SignDoc.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => TxBody.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => AuthInfo.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => SignerInfo.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => ModeInfo.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => Fee.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			expect(() => Tx.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => TxRaw.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => SignDoc.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => TxBody.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => AuthInfo.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => SignerInfo.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => ModeInfo.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
			expect(() => Fee.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('cosmos.tx.v1beta1 comprehensive coverage', () {
		test('all message types have proper info_', () {
			expect(Tx().info_, isA<pb.BuilderInfo>());
			expect(TxRaw().info_, isA<pb.BuilderInfo>());
			expect(SignDoc().info_, isA<pb.BuilderInfo>());
			expect(TxBody().info_, isA<pb.BuilderInfo>());
			expect(AuthInfo().info_, isA<pb.BuilderInfo>());
			expect(SignerInfo().info_, isA<pb.BuilderInfo>());
			expect(ModeInfo_Single().info_, isA<pb.BuilderInfo>());
			expect(ModeInfo_Multi().info_, isA<pb.BuilderInfo>());
			expect(ModeInfo().info_, isA<pb.BuilderInfo>());
			expect(Fee().info_, isA<pb.BuilderInfo>());
		});
		
		test('all message types support createEmptyInstance', () {
			expect(Tx().createEmptyInstance(), isA<Tx>());
			expect(TxRaw().createEmptyInstance(), isA<TxRaw>());
			expect(SignDoc().createEmptyInstance(), isA<SignDoc>());
			expect(TxBody().createEmptyInstance(), isA<TxBody>());
			expect(AuthInfo().createEmptyInstance(), isA<AuthInfo>());
			expect(SignerInfo().createEmptyInstance(), isA<SignerInfo>());
			expect(ModeInfo_Single().createEmptyInstance(), isA<ModeInfo_Single>());
			expect(ModeInfo_Multi().createEmptyInstance(), isA<ModeInfo_Multi>());
			expect(ModeInfo().createEmptyInstance(), isA<ModeInfo>());
			expect(Fee().createEmptyInstance(), isA<Fee>());
		});
		
		test('complex nested transaction structure roundtrip', () {
			// Create a complex transaction
			final tx = Tx();
			
			// Set up TxBody
			tx.ensureBody();
			tx.body.messages.add(Any(
				typeUrl: 'cosmos.bank.v1beta1.MsgSend',
				value: Uint8List.fromList([1, 2, 3, 4, 5]),
			));
			tx.body.memo = 'Complex transaction test';
			tx.body.timeoutHeight = Int64(1000000);
			
			// Set up AuthInfo
			tx.ensureAuthInfo();
			
			// Add SignerInfo
			final signerInfo = SignerInfo();
			signerInfo.publicKey = Any(
				typeUrl: 'cosmos.crypto.secp256k1.PubKey',
				value: Uint8List.fromList([10, 20, 30, 40, 50]),
			);
			signerInfo.modeInfo = ModeInfo();
			signerInfo.modeInfo.single = ModeInfo_Single(mode: SignMode.SIGN_MODE_DIRECT);
			signerInfo.sequence = Int64(42);
			
			tx.authInfo.signerInfos.add(signerInfo);
			
			// Set up Fee
			tx.authInfo.fee = Fee();
			tx.authInfo.fee.amount.add(CosmosCoin(denom: 'stake', amount: '5000'));
			tx.authInfo.fee.gasLimit = Int64(200000);
			tx.authInfo.fee.payer = 'cosmos1payer123';
			
			// Add signature
			tx.signatures.add(Uint8List.fromList([100, 101, 102, 103, 104, 105]));
			
			// Test JSON roundtrip
			final json = jsonEncode(tx.writeToJsonMap());
			final fromJson = Tx.fromJson(json);
			
			expect(fromJson.hasBody(), true);
			expect(fromJson.body.messages.length, 1);
			expect(fromJson.body.messages[0].typeUrl, 'cosmos.bank.v1beta1.MsgSend');
			expect(fromJson.body.messages[0].value, [1, 2, 3, 4, 5]);
			expect(fromJson.body.memo, 'Complex transaction test');
			expect(fromJson.body.timeoutHeight, Int64(1000000));
			
			expect(fromJson.hasAuthInfo(), true);
			expect(fromJson.authInfo.signerInfos.length, 1);
			
			final restoredSignerInfo = fromJson.authInfo.signerInfos[0];
			expect(restoredSignerInfo.publicKey.typeUrl, 'cosmos.crypto.secp256k1.PubKey');
			expect(restoredSignerInfo.publicKey.value, [10, 20, 30, 40, 50]);
			expect(restoredSignerInfo.modeInfo.hasSingle(), true);
			expect(restoredSignerInfo.modeInfo.single.mode, SignMode.SIGN_MODE_DIRECT);
			expect(restoredSignerInfo.sequence, Int64(42));
			
			expect(fromJson.authInfo.hasFee(), true);
			expect(fromJson.authInfo.fee.amount.length, 1);
			expect(fromJson.authInfo.fee.amount[0].denom, 'stake');
			expect(fromJson.authInfo.fee.amount[0].amount, '5000');
			expect(fromJson.authInfo.fee.gasLimit, Int64(200000));
			expect(fromJson.authInfo.fee.payer, 'cosmos1payer123');
			
			expect(fromJson.signatures.length, 1);
			expect(fromJson.signatures[0], [100, 101, 102, 103, 104, 105]);
			
			// Test buffer roundtrip
			final buffer = tx.writeToBuffer();
			final fromBuffer = Tx.fromBuffer(buffer);
			
			expect(fromBuffer.hasBody(), true);
			expect(fromBuffer.body.messages.length, 1);
			expect(fromBuffer.body.messages[0].typeUrl, 'cosmos.bank.v1beta1.MsgSend');
			expect(fromBuffer.body.memo, 'Complex transaction test');
			expect(fromBuffer.body.timeoutHeight, Int64(1000000));
			
			expect(fromBuffer.hasAuthInfo(), true);
			expect(fromBuffer.authInfo.signerInfos.length, 1);
			expect(fromBuffer.authInfo.signerInfos[0].sequence, Int64(42));
			expect(fromBuffer.authInfo.fee.gasLimit, Int64(200000));
			
			expect(fromBuffer.signatures.length, 1);
			expect(fromBuffer.signatures[0], [100, 101, 102, 103, 104, 105]);
		});
		
		test('oneof field behavior consistency', () {
			final modeInfo = ModeInfo();
			
			// Test that only one field can be set at a time
			modeInfo.single = ModeInfo_Single();
			expect(modeInfo.whichSum(), ModeInfo_Sum.single);
			expect(modeInfo.hasSingle(), true);
			expect(modeInfo.hasMulti(), false);
			
			modeInfo.multi = ModeInfo_Multi();
			expect(modeInfo.whichSum(), ModeInfo_Sum.multi);
			expect(modeInfo.hasSingle(), false);
			expect(modeInfo.hasMulti(), true);
			
			modeInfo.clearSum();
			expect(modeInfo.whichSum(), ModeInfo_Sum.notSet);
			expect(modeInfo.hasSingle(), false);
			expect(modeInfo.hasMulti(), false);
		});
		
		test('default values consistency', () {
			final tx = Tx();
			final txRaw = TxRaw();
			final signDoc = SignDoc();
			final txBody = TxBody();
			final authInfo = AuthInfo();
			final signerInfo = SignerInfo();
			final fee = Fee();
			
			expect(tx.signatures, isEmpty);
			expect(txRaw.signatures, isEmpty);
			expect(signDoc.chainId, '');
			expect(signDoc.accountNumber, Int64.ZERO);
			expect(txBody.messages, isEmpty);
			expect(txBody.memo, '');
			expect(txBody.timeoutHeight, Int64.ZERO);
			expect(authInfo.signerInfos, isEmpty);
			expect(signerInfo.sequence, Int64.ZERO);
			expect(fee.amount, isEmpty);
			expect(fee.gasLimit, Int64.ZERO);
		});
	});
} 