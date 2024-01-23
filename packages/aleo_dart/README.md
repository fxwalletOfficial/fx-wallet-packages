# Aleo Wasm

cd aleo_rust/wasm
cargo build

# aleo_dart

dart test/aleo_test.dart

```
import 'package:aleo_dart/aleo.dart';

final mnemonic =
      "fly lecture gasp juice hover ice business census bless weapon polar upgrade";
final aleoHdSeed = mnemonicToSeed(mnemonic);                // 9722a773f4fe09f2d0510a68942c8a4ae668c91771c15fb1a74e42a7c6fa4d03
final String address = mnemonicToAddress(mnemonic);         // aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn
final String privateKey = mnemonicToPrivateKey(mnemonic);   // APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v
final String viewKey = privateKeyToViewKey(privateKey);     // AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp
```
