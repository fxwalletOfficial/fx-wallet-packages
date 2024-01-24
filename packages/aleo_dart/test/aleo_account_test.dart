import 'dart:typed_data';

import 'package:convert/convert.dart' show hex;

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

void main() {
  final mnemonic =
      "fly lecture gasp juice hover ice business census bless weapon polar upgrade";
  final seedTarget =
      '9722a773f4fe09f2d0510a68942c8a4ae668c91771c15fb1a74e42a7c6fa4d03';
  final targetPrivateKey =
      'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
  final targetAddress =
      'aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn';
  final targetViewKey = 'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp';
  final message = Uint8List.fromList([
    104,
    101,
    108,
    108,
    111,
    32,
    119,
    111,
    114,
    108,
    100,
  ]);

  late final Uint8List seed;
  late final String privateKey;
  late final String address;
  late final String viewKey;
  test('test rust ffi', () {
    final int a = 10;
    final int b = 32;
    expect(testRustFFi(a, b), a + b);
  });

  test('mnemonicToSeed', () {
    seed = mnemonicToSeed(mnemonic);
    expect(hex.encode(seed), seedTarget);
  });

  test('seedToPrivateKey', () {
    privateKey = seedToPrivateKey(seed);
    expect(privateKey, targetPrivateKey);
  });

  test('mnemonicToPrivateKey', () {
    expect(mnemonicToPrivateKey(mnemonic), targetPrivateKey);
  });

  test('privateKeyToAddress', () {
    address = privateKeyToAddress(privateKey);
    expect(address, targetAddress);
  });

  test('mnemonicToAddress', () {
    expect(mnemonicToAddress(mnemonic), targetAddress);
  });

  test('privateKeyToViewKey', () {
    viewKey = privateKeyToViewKey(privateKey);
    expect(viewKey, targetViewKey);
  });

  test('mnemonicToViewKey', () {
    expect(mnemonicToViewKey(mnemonic), targetViewKey);
  });

  test('viewKeyToAddress', () {
    expect(viewKeyToAddress(viewKey), targetAddress);
  });

  test('viewKeyToAddress', () {
    expect(viewKeyToAddress(viewKey), targetAddress);
  });

  test('sign', () {
    // sign178e076gmzswtvq68ma2p350g8mfzg87dyzlmggts8348vescdyp07jg5mz52ecnux0at0943hzx5lnzh53tff5l3d9p7teepv64yjprdtl7lkehl0xyhjrhqz3v6ymkm73gs9vvj4t7sv673nhm50pj8p0xa895ta843wlh9wekyuqgwade9z5r0chfzp8ckud8ymt969j8ssc8qn3d
    final signature = sign(privateKey, message);
    assert(isValidSignature(address, signature, message));
  });
}
