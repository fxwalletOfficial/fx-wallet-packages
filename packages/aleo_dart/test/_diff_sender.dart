// Parity for decrypt_sender_ciphertext vs the reference libaleo_rust. Run with:
//   ALEO_REF_LIB=/abs/ref/libaleo_rust.dylib \
//   ALEO_NEW_LIB=/abs/new/libaleo_rust.dylib \
//   flutter test test/_diff_sender.dart
import 'dart:io';

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

// Verified vector (record owned by viewKey; sender_ciphertext decrypts to sender).
const record =
    'record1qyqsqpfr4rj0ga9c3j7q40hdv4zasd0dx9creup4f582my6zvncfczqvqyxx66trwfhkxun9v35hguerqqpqzq8rs7l2c2h3ccfqw3gaxt388dwwpcts2847dc7a0pj9jujt2suuqgm3j6tvj4qlp6fh3rk6nzn6k7w0tyx7mk4zjffl22c4gte92t8q6awh66c';
const viewKey = 'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp';
const senderCiphertext =
    '4175156355918265960054361476553013064789872276298327169806164695262201272565field';
const expectedSender =
    'aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px';

void main() {
  final refPath = Platform.environment['ALEO_REF_LIB'];
  final newPath = Platform.environment['ALEO_NEW_LIB'];
  if (refPath == null || newPath == null) {
    test('sender parity', () {},
        skip: 'set ALEO_REF_LIB and ALEO_NEW_LIB to two libaleo_rust builds');
    return;
  }

  final ref = AleoRecord(DyLib.getDyLibByPosition(refPath));
  final neu = AleoRecord(DyLib.getDyLibByPosition(newPath));

  test('decrypt_sender_ciphertext matches the canonical sender + the reference', () {
    expect(neu.decryptSenderCiphertext(record, viewKey, senderCiphertext),
        expectedSender);
    expect(ref.decryptSenderCiphertext(record, viewKey, senderCiphertext),
        expectedSender);
  });
}
