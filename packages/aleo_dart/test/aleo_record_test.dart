import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

// final String libPosition = './aleo_rust/libaleo_rust.so';
// final dyLib = DyLib.getDyLibByPosition(libPosition);
final dyLib = DyLib.getDyLibFromGit();
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
    assert(record.contains(result.owner));
    assert(rust.isOwner(recordCipher, viewKey));
    final errorKey = 'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp';
    assert(!rust.isOwner(recordCipher, errorKey));
  });

  test('record owner', () {
    final recordCipher =
        'record1qyqsqpfr4rj0ga9c3j7q40hdv4zasd0dx9creup4f582my6zvncfczqvqyxx66trwfhkxun9v35hguerqqpqzq8rs7l2c2h3ccfqw3gaxt388dwwpcts2847dc7a0pj9jujt2suuqgm3j6tvj4qlp6fh3rk6nzn6k7w0tyx7mk4zjffl22c4gte92t8q6awh66c';
    final viewKey = 'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp';
    final result = rust.decryptCipherText(recordCipher, viewKey);
    expect(result.getOwner(),
        "aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn");
  });

  test('serialNumberString', () {
    final recordCipher =
        'record1qyqspdn8f6lh4eum9a36l93mnxh5vcqssjsep9z4lp4vpya2efgmjdsvqyxx66trwfhkxun9v35hguerqqpqzq9yu3tvsnj4x0a7e2w9w204aya09thraeckdlsn59pve6fnnd3eqv0n7jpp5rsxn48jdjj3z55vhmp42f8hxp7vk5d2430vuvk3fzrsx0w9wqw';
    final privateKey =
        'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
    final programId = "credits.aleo";
    final recordName = "credits";
    final expectedSn =
        "832456939067524461249417512029753636275825913577828456140675004985222334481field";
    final result = rust.serialNumberString(
        recordCipher, privateKey, programId, recordName);
    expect(expectedSn, result);
  });

  test('getPrivateBalance', () async {
    final privateKey =
        'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
    final viewKey = 'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp';
    final recordCipherTexts = [
      'record1qyqspdn8f6lh4eum9a36l93mnxh5vcqssjsep9z4lp4vpya2efgmjdsvqyxx66trwfhkxun9v35hguerqqpqzq9yu3tvsnj4x0a7e2w9w204aya09thraeckdlsn59pve6fnnd3eqv0n7jpp5rsxn48jdjj3z55vhmp42f8hxp7vk5d2430vuvk3fzrsx0w9wqw',
      'record1qyqsqlqqe6juvqslkdhucee33dmsntt5amqptxcddys2e5td3j0mtgq3qyxx66trwfhkxun9v35hguerqqpqzqy9csc67ez5gzezsx2ja59u0727ydfsa4fkgh3d55fgmd5t9yccphss9v6ffmr68yt9jkcex7yg9zzwh57zpznce80zh6rranmcgyus208vey6',
      'record1qyqspj8md5yhtk774sum5r5lp0q7ysrz3uljtw98aqj9n9626ga9kqqxqyxx66trwfhkxun9v35hguerqqpqzqrwzmj36tyjlqnnsfk9j29739zusxxccj5ls0cztztp40aguqu9qvuh09t8r9fsjlvmhhcku6wkz7dejcc43yh4rlwf4gk24hwrpgnswcdfanf',
    ];
    // at1rg96xyzu0m7wk4kxqn6pwjcxen0xvdgpnru2qmdq6d4jj0wxccqqdtl4et
    final result =
        await rust.getPrivateBalance(recordCipherTexts, privateKey, viewKey);
    print(result);
  });
}
