import 'dart:typed_data';

import 'package:crypto_wallet_util/src/utils/bip39/src/bip39_base.dart';
import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';
import 'package:fixnum/fixnum.dart' as fixnum;

void main() {
	group('cosmos_dart Utils', () {
		test('Bip39 validateMnemonic/mnemonicToSeed/generateMnemonic', () {
			final mnemonic = [
				'abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','abandon','about'
			];
			expect(BIP39.validateMnemonic(mnemonic.join(' ')), isTrue);

			final seed = BIP39.mnemonicToSeed(mnemonic.join(' '));
			expect(seed.length, 64);

			final gen = BIP39.generateMnemonic(strength: 128);
			expect(gen.split(' ').length, 12);
			expect(BIP39.validateMnemonic(gen), isTrue);
		});

		test('Int.toInt64', () {
			final v = 42;
			final i64 = v.toInt64();
			expect(i64, fixnum.Int64(42));
		});

		test('utils_byte_array.copy copies into destination slice', () {
			final src = Uint8List.fromList([1,2,3]);
			final dst = Uint8List(5);
			copy(src, 1, 4, dst);
			expect(dst, [0,1,2,3,0]);
		});
	});
}