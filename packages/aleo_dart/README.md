# aleo_rust

cd aleo_rust/rust
cargo build

# aleo_dart

first step: dart run aleo_dart:setup  /// download rust ffi dynamic library or download in github.
second step: 
```
import 'package:aleo_dart/aleo.dart';

/// choose the position of dynamic library

final dyLib = DyLib.getDyLib();  /// get dynamic library in default position: './aleo_rust/target/debug/libaleo_rust.so' 

/// or choose position. 
final String libPosition = './aleo_rust/libaleo_rust.so';
final dyLib = DyLib.getDyLibByPosition(libPosition);

```
than, run test.

dart test/aleo_account_test.dart

```
import 'package:aleo_dart/aleo.dart';

final dyLib = DyLib.getDyLib();
final rust = AleoAccount(dyLib);

final mnemonic =
      "fly lecture gasp juice hover ice business census bless weapon polar upgrade";
final aleoHdSeed = rust.mnemonicToSeed(mnemonic);                // 9722a773f4fe09f2d0510a68942c8a4ae668c91771c15fb1a74e42a7c6fa4d03
final String address = rust.mnemonicToAddress(mnemonic);         // aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn
final String privateKey = rust.mnemonicToPrivateKey(mnemonic);   // APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v
final String viewKey = rust.privateKeyToViewKey(privateKey);     // AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp
```

dart test/aleo_record_test.dart

```
import 'package:aleo_dart/aleo.dart';

final dyLib = DyLib.getDyLib();
final rust = AleoRecord(dyLib);

final ciphertext =
        'ciphertext1qvqg7rgvam3xdcu55pwu6sl8rxwefxaj5gwthk0yzln6jv5fastzup0qn0qftqlqq7jcckyx03fzv9kke0z9puwd7cl7jzyhxfy2f2juplz39dkqs6p24urhxymhv364qm3z8mvyklv5gr52n4fxr2z59jgqytyddj8';
final password = 'mypassword';
fianl privateKey = rust.decryptToPrivateKey(ciphertext, password); // APrivateKey1zkpAYS46Dq4rnt9wdohyWMwdmjmTeMJKPZdp5AhvjXZDsVG
final recordCipher =
        'record1qyqsqpe2szk2wwwq56akkwx586hkndl3r8vzdwve32lm7elvphh37rsyqyxx66trwfhkxun9v35hguerqqpqzqrtjzeu6vah9x2me2exkgege824sd8x2379scspmrmtvczs0d93qttl7y92ga0k0rsexu409hu3vlehe3yxjhmey3frh2z5pxm5cmxsv4un97q';
final viewKey = 'AViewKey1ccEt8A2Ryva5rxnKcAbn7wgTaTsb79tzkKHFpeKsm9NX';
final record = rust.decryptCipherText(recordCipher, viewKey);
'{\n'
'  owner: aleo1j7qxyunfldj2lp8hsvy7mw5k8zaqgjfyr72x2gh3x4ewgae8v5gscf5jh3.private,\n'
'  microcredits: 1500000000000000u64.private,\n'
'  _nonce: 3077450429259593211617823051143573281856129402760267155982965992208217472983group.public\n'
'}';
```

dart test/aleo_program_test.dart

```
import 'package:aleo_dart/aleo.dart';

final dyLib = DyLib.getDyLib();
final rust = AleoProgram(dyLib);

final url = 'http://23.20.9.85:3033'; // test rpc
final private_key = 'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';      
final recipient = "aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px";
final amount_credits = 1000000;
final fee_credits = 1000000;

final transfer_type = 'transfer_public';
final amount_record = 'None';  // any string when transfer_public
final fee_record = 'None';
final tx = rust.tryTransfer(private_key, recipient, transfer_type, amount_credits, fee_credits, url, amount_record, amount_record);
```



