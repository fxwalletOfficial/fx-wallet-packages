// Differential parity for the private-key Encryptor (encrypt/decrypt_private_key)
// vs the reference libaleo_rust. Run with:
//   ALEO_REF_LIB=/abs/ref/libaleo_rust.dylib \
//   ALEO_NEW_LIB=/abs/new/libaleo_rust.dylib \
//   flutter test test/_diff_encryptor.dart
import 'dart:io';

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

// Known vector from aleo_record_test.dart.
const knownCipher =
    'ciphertext1qvqg7rgvam3xdcu55pwu6sl8rxwefxaj5gwthk0yzln6jv5fastzup0qn0qftqlqq7jcckyx03fzv9kke0z9puwd7cl7jzyhxfy2f2juplz39dkqs6p24urhxymhv364qm3z8mvyklv5gr52n4fxr2z59jgqytyddj8';
const knownSecret = 'mypassword';
const knownPrivateKey = 'APrivateKey1zkpAYS46Dq4rnt9wdohyWMwdmjmTeMJKPZdp5AhvjXZDsVG';
// Another deterministic key for round-trip tests.
const otherPrivateKey = 'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';

void main() {
  final refPath = Platform.environment['ALEO_REF_LIB'];
  final newPath = Platform.environment['ALEO_NEW_LIB'];
  if (refPath == null || newPath == null) {
    test('encryptor parity', () {},
        skip: 'set ALEO_REF_LIB and ALEO_NEW_LIB to two libaleo_rust builds');
    return;
  }

  final ref = AleoRecord(DyLib.getDyLibByPosition(refPath));
  final neu = AleoRecord(DyLib.getDyLibByPosition(newPath));

  test('decrypt the known ciphertext to the canonical private key', () {
    expect(neu.decryptToPrivateKey(knownCipher, knownSecret), knownPrivateKey);
    expect(ref.decryptToPrivateKey(knownCipher, knownSecret), knownPrivateKey);
  });

  test('round-trip + cross-library interop', () {
    for (final pk in [knownPrivateKey, otherPrivateKey]) {
      const secret = 'hunter2';
      // clean encrypts -> clean & ref both decrypt back to pk
      final ctNew = neu.encryptPrivateKey(pk, secret);
      expect(neu.decryptToPrivateKey(ctNew, secret), pk);
      expect(ref.decryptToPrivateKey(ctNew, secret), pk);
      // ref encrypts -> clean decrypts back to pk
      final ctRef = ref.encryptPrivateKey(pk, secret);
      expect(neu.decryptToPrivateKey(ctRef, secret), pk);
      // each encryption is randomized (different ciphertext each call)
      expect(neu.encryptPrivateKey(pk, secret), isNot(ctNew));
      // wrong password must not recover the key
      expect(neu.decryptToPrivateKey(ctNew, 'wrong'), isNot(pk));
    }
  });
}
