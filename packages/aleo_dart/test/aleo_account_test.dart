import 'dart:typed_data';

import 'package:convert/convert.dart' show hex;

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

import 'support/test_dylib.dart';

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

// final String libPosition = './aleo_rust/libaleo_rust.so';
// final dyLib = DyLib.getDyLibByPosition(libPosition);
  final dyLib = tryLoadAleoLib();
  if (dyLib == null) {
    test('aleo_dart account FFI tests', () {}, skip: nativeLibMissingReason);
    return;
  }
  final rust = AleoAccount(dyLib);

  test('test rust ffi', () {
    final int a = 10;
    final int b = 32;
    expect(rust.testRustFFi(a, b), a + b + 1);
  });

  test('mnemonicToSeed', () {
    seed = rust.mnemonicToSeed(mnemonic);
    expect(hex.encode(seed), seedTarget);
  });

  test('seedToPrivateKey', () {
    privateKey = rust.seedToPrivateKey(seed);
    expect(privateKey, targetPrivateKey);
  });

  test('mnemonicToPrivateKey', () {
    expect(rust.mnemonicToPrivateKey(mnemonic), targetPrivateKey);
  });

  test('mnemonicToViewKey', () {
    expect(rust.mnemonicToViewKey(mnemonic), targetViewKey);
  });

  test('mnemonicToAddress', () {
    expect(rust.mnemonicToAddress(mnemonic), targetAddress);
  });

  test('privateKeyToAddress', () {
    address = rust.privateKeyToAddress(targetPrivateKey);
    expect(address, targetAddress);
  });

  test('privateKeyToViewKey', () {
    viewKey = rust.privateKeyToViewKey(targetPrivateKey);
    expect(viewKey, targetViewKey);
  });

  test('viewKeyToAddress', () {
    expect(rust.viewKeyToAddress(viewKey), targetAddress);
  });

  test('sign', () {
    // sign178e076gmzswtvq68ma2p350g8mfzg87dyzlmggts8348vescdyp07jg5mz52ecnux0at0943hzx5lnzh53tff5l3d9p7teepv64yjprdtl7lkehl0xyhjrhqz3v6ymkm73gs9vvj4t7sv673nhm50pj8p0xa895ta843wlh9wekyuqgwade9z5r0chfzp8ckud8ymt969j8ssc8qn3d
    final signature = rust.sign(targetPrivateKey, message);
    assert(rust.isValidSignature(address, signature, message));
  });

  test('getTokenOwnerHash', () {
    final tokenOwnerHash = rust.getTokenOwnerHash(
        "aleo1j5s754demr84a9mnkwtwxts4z8e6nvsx0f5m9yaw7803cxqgauyqg5vz5u",
        '1751493913335802797273486270793650302076377624243810059080883537084141842600field');
    expect(tokenOwnerHash,
        '768369662790838340899814872592863133882218911906065436640936478881722458364field');
  });

  group('test error', () {
    test('test invalid private key', () {
      final invalidPrivateKey =
          'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8';
      expect(
          () => rust.privateKeyToAddress(invalidPrivateKey), throwsException);
    });

    test('test invalid view key', () {
      final invalidViewKey =
          'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBd';
      expect(() => rust.viewKeyToAddress(invalidViewKey), throwsException);
    });
  });
}
