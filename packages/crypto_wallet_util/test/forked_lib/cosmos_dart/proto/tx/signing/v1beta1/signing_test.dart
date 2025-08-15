import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/tx/signing/v1beta1/signing.pb.dart' as sign;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/any.pb.dart' as anypb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/crypto/multisig/v1beta1/multisig.pb.dart' as ms;

void main() {
	group('cosmos.tx.signing.v1beta1 signing', () {
		test('SignatureDescriptor.Data single has/clear/json/buffer', () {
			final single = sign.SignatureDescriptor_Data_Single(
				mode: sign.SignMode.SIGN_MODE_DIRECT,
				signature: [0x01, 0x02],
			);
			expect(single.hasSignature(), isTrue);
			single.clearSignature();
			expect(single.hasSignature(), isFalse);
			final j = jsonEncode(single.writeToJsonMap());
			expect(jsonDecode(j), isA<Map>());
			final dec = sign.SignatureDescriptor_Data_Single.fromBuffer(single.writeToBuffer());
			expect(dec.mode, sign.SignMode.SIGN_MODE_DIRECT);
		});

		test('SignatureDescriptor.Data multi ensure/list ops', () {
			final multi = sign.SignatureDescriptor_Data_Multi(
				bitarray: ms.CompactBitArray(elems: [0x01]),
				signatures: [
					sign.SignatureDescriptor_Data(single: sign.SignatureDescriptor_Data_Single()),
				],
			);
			expect(multi.hasBitarray(), isTrue);
			final ensured = multi.ensureBitarray();
			expect(ensured, isA<ms.CompactBitArray>());
			multi.signatures.add(sign.SignatureDescriptor_Data(multi: sign.SignatureDescriptor_Data_Multi()));
			expect(multi.signatures.length, 2);
		});

		test('SignatureDescriptor oneof set/clear and ensure', () {
			final data = sign.SignatureDescriptor_Data();
			data.single = sign.SignatureDescriptor_Data_Single();
			expect(data.whichSum(), sign.SignatureDescriptor_Data_Sum.single);
			data.clearSingle();
			expect(data.whichSum(), sign.SignatureDescriptor_Data_Sum.notSet);
			final ensuredMulti = data.ensureMulti();
			expect(data.whichSum(), sign.SignatureDescriptor_Data_Sum.multi);
			expect(ensuredMulti, isA<sign.SignatureDescriptor_Data_Multi>());
		});

		test('SignatureDescriptor has/clear/ensure/json/buffer/defaults', () {
			final pub = anypb.Any(typeUrl: 't', value: []);
			final sd = sign.SignatureDescriptor(publicKey: pub, data: sign.SignatureDescriptor_Data(), sequence: Int64(7));
			expect(sd.hasPublicKey(), isTrue);
			sd.clearPublicKey();
			expect(sd.hasPublicKey(), isFalse);
			final ensured = sd.ensureData();
			expect(identical(ensured, sd.data), isTrue);
			final bz = sd.writeToBuffer();
			final dec = sign.SignatureDescriptor.fromBuffer(bz);
			expect(dec.sequence.toInt(), 7);
			final j = jsonEncode(sd.writeToJsonMap());
			expect(jsonDecode(j), isA<Map>());
			expect(sign.SignatureDescriptor.getDefault().info_.messageName, contains('SignatureDescriptor'));
			expect(sign.SignatureDescriptors.createRepeated(), isA<pb.PbList<sign.SignatureDescriptors>>());
		});

		test('SignatureDescriptors list ops and buffer', () {
			final d = sign.SignatureDescriptors(signatures: [sign.SignatureDescriptor(sequence: Int64(1))]);
			final clone = d.clone();
			expect(clone.signatures.first.sequence.toInt(), 1);
			d.signatures.add(sign.SignatureDescriptor(sequence: Int64(2)));
			expect(d.signatures.length, 2);
			final dec = sign.SignatureDescriptors.fromBuffer(d.writeToBuffer());
			expect(dec.signatures.length, 2);
		});
	});
} 