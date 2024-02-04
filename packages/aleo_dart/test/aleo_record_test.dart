import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

// final String libPosition = './aleo_rust/libaleo_rust.so';
// final dyLib = DyLib.getDyLibByPosition(libPosition);
final dyLib = DyLib.getDyLibFromCargo();
final rust = AleoRecord(dyLib);
void main() {
  final privateKey =
      'APrivateKey1zkpAYS46Dq4rnt9wdohyWMwdmjmTeMJKPZdp5AhvjXZDsVG';
  test('encrypt and decrypt key ', () {
    final ciphertext =
        'ciphertext1qvqg7rgvam3xdcu55pwu6sl8rxwefxaj5gwthk0yzln6jv5fastzup0qn0qftqlqq7jcckyx03fzv9kke0z9puwd7cl7jzyhxfy2f2juplz39dkqs6p24urhxymhv364qm3z8mvyklv5gr52n4fxr2z59jgqytyddj8';
    final password = 'mypassword';
    final result = rust.encryptPrivateKey(privateKey, password);
    assert(result != ciphertext);
    expect(rust.decryptToPrivateKey(ciphertext, password), privateKey);
    expect(rust.decryptToPrivateKey(result, password), privateKey);
  });

  final record = '{\n'
      '  owner: aleo1j7qxyunfldj2lp8hsvy7mw5k8zaqgjfyr72x2gh3x4ewgae8v5gscf5jh3.private,\n'
      '  microcredits: 1500000000000000u64.private,\n'
      '  _nonce: 3077450429259593211617823051143573281856129402760267155982965992208217472983group.public\n'
      '}';

  test('decryptCipherText', () {
    final recordCipher =
        'record1qyqsqpe2szk2wwwq56akkwx586hkndl3r8vzdwve32lm7elvphh37rsyqyxx66trwfhkxun9v35hguerqqpqzqrtjzeu6vah9x2me2exkgege824sd8x2379scspmrmtvczs0d93qttl7y92ga0k0rsexu409hu3vlehe3yxjhmey3frh2z5pxm5cmxsv4un97q';
    final viewKey = 'AViewKey1ccEt8A2Ryva5rxnKcAbn7wgTaTsb79tzkKHFpeKsm9NX';
    final result = rust.decryptCipherText(recordCipher, viewKey);
    expect(result, record);
    assert(rust.isOwner(recordCipher, viewKey));
    final errorKey = 'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp';
    assert(!rust.isOwner(recordCipher, errorKey));
  });

  test('record owner', () {
    final recordCipher =
        'record1qyqsqpfr4rj0ga9c3j7q40hdv4zasd0dx9creup4f582my6zvncfczqvqyxx66trwfhkxun9v35hguerqqpqzq8rs7l2c2h3ccfqw3gaxt388dwwpcts2847dc7a0pj9jujt2suuqgm3j6tvj4qlp6fh3rk6nzn6k7w0tyx7mk4zjffl22c4gte92t8q6awh66c';
    final viewKey = 'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp';
    final result = rust.decryptCipherText(recordCipher, viewKey);
    assert(result.contains(
        "aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn"));
  });
}
