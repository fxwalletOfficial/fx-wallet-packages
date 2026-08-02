import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Regression test for the secondary hardening item: secp256k1 private key
/// input previously had no length/range validation anywhere —
/// `EcdaSignature.privateKeyToPublicKey`/`getUnCompressedPublicKey` would
/// silently scalar-multiply whatever bytes they were given, producing a
/// "valid-looking" but wrong key for any length other than 32 bytes. A
/// survey of every wallet's `privateKeyToPublicKey` path found none in this
/// package actually need a non-32-byte raw key (NEAR's 64-byte export
/// format is sliced down to a 32-byte seed before it ever reaches here),
/// so a strict 32-byte + in-range check is safe.
void main() {
  final valid32 = fromHex(
      '64a0d0de1e0ad3b371476db54c85ef374695137aee3af3f2766dfa81e55877cb');

  test('accepts a normal 32-byte private key', () {
    expect(() => EcdaSignature.privateKeyToPublicKey(valid32),
        returnsNormally);
  });

  test('rejects a 16-byte private key instead of silently deriving a '
      'wrong key', () {
    final short = valid32.sublist(0, 16);
    expect(() => EcdaSignature.privateKeyToPublicKey(short),
        throwsArgumentError);
  });

  test('rejects a 64-byte private key instead of silently deriving a '
      'wrong key', () {
    final long = Uint8List.fromList([...valid32, ...valid32]);
    expect(() => EcdaSignature.privateKeyToPublicKey(long),
        throwsArgumentError);
  });

  test('rejects an all-zero private key', () {
    expect(() => EcdaSignature.privateKeyToPublicKey(Uint8List(32)),
        throwsArgumentError);
  });

  test('getUnCompressedPublicKey applies the same validation', () {
    expect(() => EcdaSignature.getUnCompressedPublicKey(valid32.sublist(0, 20)),
        throwsArgumentError);
  });
}
