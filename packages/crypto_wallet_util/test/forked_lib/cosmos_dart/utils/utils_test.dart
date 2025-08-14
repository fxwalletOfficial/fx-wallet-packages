import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';
import 'package:fixnum/fixnum.dart' as fixnum;

void main() {
	group('cosmos_dart Utils', () {
		test('Bip39 validateMnemonic/mnemonicToSeed/generateMnemonic', () {
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			expect(Bip39.validateMnemonic(mnemonic), isTrue);

			final seed = Bip39.mnemonicToSeed(mnemonic);
			expect(seed.length, 64);

			final gen = Bip39.generateMnemonic(strength: 128);
			expect(gen.length, 12);
			expect(Bip39.validateMnemonic(gen), isTrue);
		});

		test('BigInt/Uint8List big-endian conversions', () {
			final bytes = Uint8List.fromList([0x12, 0x34]);
			final bi = bytes.toBigInt();
			expect(bi, BigInt.from(0x1234));

			final back = bi.toUin8List();
			expect(back, bytes);

			final decoded = BigIntBigEndian.decode([0x01, 0x00]);
			expect(decoded, BigInt.from(256));
		});

		test('Int.toInt64', () {
			final v = 42;
			final i64 = v.toInt64();
			expect(i64, fixnum.Int64(42));
		});

		test('utils_bytearray.copy copies into destination slice', () {
			final src = Uint8List.fromList([1,2,3]);
			final dst = Uint8List(5);
			copy(src, 1, 4, dst);
			expect(dst, [0,1,2,3,0]);
		});
	});
} 