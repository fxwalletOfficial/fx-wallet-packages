import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/transaction/eth/lib/typed_data/typed_data.dart';
import 'package:crypto_wallet_util/src/transaction/eth/lib/typed_data/abi.dart';
import 'package:crypto_wallet_util/src/transaction/eth/lib/typed_data/abi_decoder.dart';

Uint8List u(List<int> a) => Uint8List.fromList(a);

void main() {
	group('typed_data concat helpers', () {
		test('concatSig/concatSigCompact indirectly covers _padWithZeroes', () {
			final r = u([0x01]);
			final sBytes = u([0x02]);
			final v = u([0x1b]);
			final sig = concatSig(r, sBytes, v);
			expect(sig.length, greaterThan(0));
			final sigc = concatSigCompact(r, sBytes);
			expect(sigc.length, greaterThan(0));
		});

		test('signToCompact throws with invalid private key format', () {
			final msg = u([1,2,3]);
			final pk = Uint8List(32); // 无效私钥，期望抛错
			expect(() => signToCompact(message: msg, privateKey: pk), throwsA(isA<FormatException>()));
		});
	});

	group('AbiUtil encodeSingle branches', () {
		test('address/string/bool/bytes/bytesN/uint/int/fixed/ufixed', () {
			// address
			AbiUtil.encodeSingle('address', '0x0000000000000000000000000000000000000001');
			// string
			AbiUtil.encodeSingle('string', 'hello');
			// bool with different inputs
			AbiUtil.encodeSingle('bool', 0);
			AbiUtil.encodeSingle('bool', 1);
			AbiUtil.encodeSingle('bool', true);
			AbiUtil.encodeSingle('bool', false);
			AbiUtil.encodeSingle('bool', '');
			// bytes dynamic
			AbiUtil.encodeSingle('bytes', u([1,2,3]));
			// bytesN
			AbiUtil.encodeSingle('bytes32', u([1]));
			// uint/int
			AbiUtil.encodeSingle('uint256', 1);
			AbiUtil.encodeSingle('int256', -1);
			// fixed/ufixed
			AbiUtil.encodeSingle('fixed128x128', 1);
			AbiUtil.encodeSingle('ufixed128x128', 1);
		});

		test('arrays dynamic/fixed and errors', () {
			// dynamic array
			AbiUtil.encodeSingle('uint256[]', [1,2,3]);
			// fixed array
			AbiUtil.encodeSingle('uint256[2]', [1,2]);
			expect(() => AbiUtil.encodeSingle('uint256[1]', [1,2]), throwsArgumentError);
			expect(() => AbiUtil.encodeSingle('bytes33', u([1])), throwsArgumentError);
			expect(() => AbiUtil.encodeSingle('uint257', 1), throwsArgumentError);
			expect(() => AbiUtil.encodeSingle('int257', 1), throwsArgumentError);
			expect(() => AbiUtil.encodeSingle('uint256', -1), throwsArgumentError);
			// unsupported type
			expect(() => AbiUtil.encodeSingle('foo', 1), throwsArgumentError);
		});

		test('rawEncode/head-tail and solidity helpers', () {
			final out = AbiUtil.rawEncode(['uint256','string','bytes'], [1,'hi', u([1,2])]);
			expect(out.length, greaterThan(0));
			final sh = AbiUtil.soliditySHA3(['uint256'], [1]);
			expect(sh.length, 32);
			final pack = AbiUtil.solidityPack(['uint256','string'], [1,'x']);
			expect(pack.length, greaterThan(0));
			final hexv = AbiUtil.solidityHexValue('string', 'x', null);
			expect(hexv.length, greaterThan(0));
		});

		test('elementaryName/parse helpers and isArray/isDynamic', () {
			expect(AbiUtil.elementaryName('int'), 'int256');
			expect(AbiUtil.elementaryName('uint'), 'uint256');
			expect(AbiUtil.parseTypeN('bytes32'), 32);
			final nxm = AbiUtil.parseTypeNxM('fixed128x128');
			expect(nxm[0], 128);
			expect(AbiUtil.parseTypeArray('uint256[]'), 'dynamic');
			expect(AbiUtil.isArray('uint256[]'), isTrue);
			expect(AbiUtil.isDynamic('string'), isTrue);
		});
	});

	group('AbiDecoder basic', () {
		test('build from ABI, function lookup and selector', () {
			final abi = [
				{
					'type': 'function',
					'name': 'transfer',
					'inputs': [
						{'name':'to','type':'address'},
						{'name':'amount','type':'uint256'}
					]
				}
			];
			final dec = AbiDecoder.fromABI(abi);
			final sig4 = AbiDecoder.compute4BytesSignature('transfer(address,uint256)');
			expect(dec.getFunctionName('${sig4}00000000'), 'transfer');
			expect(dec.getFunctionSignature('${sig4}00000000'), 'transfer(address,uint256)');
			final decoded = dec.decodeParameters('${sig4}'+('0'*64)+'0'.padLeft(64,'0'));
			expect(decoded?['function'], 'transfer');
		});
	});
} 