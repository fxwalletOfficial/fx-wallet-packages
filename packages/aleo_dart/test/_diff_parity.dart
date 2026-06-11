// Differential parity oracle: the clean-room aleo_ffi build vs a reference
// build (e.g. the original libaleo_rust). Used to confirm each rewritten group
// is byte-for-byte identical to the reference across a large random sample.
//
// Run with two libaleo_rust builds:
//   ALEO_REF_LIB=/abs/ref/libaleo_rust.dylib \
//   ALEO_NEW_LIB=/abs/new/libaleo_rust.dylib \
//   flutter test test/_diff_parity.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:convert/convert.dart' show hex;
import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

void main() {
  final refPath = Platform.environment['ALEO_REF_LIB'];
  final newPath = Platform.environment['ALEO_NEW_LIB'];
  if (refPath == null || newPath == null) {
    test('differential parity', () {},
        skip: 'set ALEO_REF_LIB and ALEO_NEW_LIB to two libaleo_rust builds');
    return;
  }

  final gpl = AleoAccount(DyLib.getDyLibByPosition(refPath));
  final clean = AleoAccount(DyLib.getDyLibByPosition(newPath));

  test('numbers_add parity', () {
    for (var i = 0; i < 50; i++) {
      expect(clean.testRustFFi(i, i * 7), gpl.testRustFFi(i, i * 7));
    }
  });

  test('account derivation parity over 300 random mnemonics', () {
    const n = 300;
    var checked = 0;
    for (var i = 0; i < n; i++) {
      final mnemonic = bip39.generateMnemonic();
      final seed = gpl.mnemonicToSeed(mnemonic); // pure Dart, identical for both

      final pkG = gpl.seedToPrivateKey(seed);
      final pkC = clean.seedToPrivateKey(seed);
      expect(pkC, pkG, reason: 'seed_to_private_key seed=${hex.encode(seed)}');

      expect(clean.privateKeyToAddress(pkC), gpl.privateKeyToAddress(pkG),
          reason: 'private_key_to_address pk=$pkG');
      final vkG = gpl.privateKeyToViewKey(pkG);
      final vkC = clean.privateKeyToViewKey(pkC);
      expect(vkC, vkG, reason: 'private_key_to_view_key pk=$pkG');
      expect(clean.viewKeyToAddress(vkC), gpl.viewKeyToAddress(vkG),
          reason: 'view_key_to_address vk=$vkG');
      checked++;
    }
    expect(checked, n);
  });

  test('sign/verify interop (cross-library)', () {
    for (var i = 0; i < 20; i++) {
      final mnemonic = bip39.generateMnemonic();
      final pk = clean.seedToPrivateKey(clean.mnemonicToSeed(mnemonic));
      final addr = clean.privateKeyToAddress(pk);
      final msg = Uint8List.fromList(utf8.encode('parity check #$i'));

      final sigFromGpl = gpl.sign(pk, msg);
      final sigFromClean = clean.sign(pk, msg);

      // Each library must accept the other's signature.
      expect(clean.isValidSignature(addr, sigFromGpl, msg), isTrue);
      expect(gpl.isValidSignature(addr, sigFromClean, msg), isTrue);

      // Tampered message must fail under both.
      final tampered = Uint8List.fromList(utf8.encode('parity check #$i!'));
      expect(clean.isValidSignature(addr, sigFromGpl, tampered), isFalse);
      expect(gpl.isValidSignature(addr, sigFromClean, tampered), isFalse);
    }
  });

  test('get_token_owner_hash parity', () {
    const tokenIds = <String>[
      '1751493913335802797273486270793650302076377624243810059080883537084141842600field',
      '0field',
      '1field',
      '42field',
    ];
    for (var i = 0; i < 30; i++) {
      final addr = clean.mnemonicToAddress(bip39.generateMnemonic());
      for (final tokenId in tokenIds) {
        expect(clean.getTokenOwnerHash(addr, tokenId),
            gpl.getTokenOwnerHash(addr, tokenId),
            reason: 'token_owner_hash addr=$addr tokenId=$tokenId');
      }
    }
  });
}
