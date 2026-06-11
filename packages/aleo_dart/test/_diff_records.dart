// Differential parity for Group 2 record reads (is_owner, decrypt_cipher_text)
// vs the reference libaleo_rust. Run with:
//   ALEO_REF_LIB=/abs/ref/libaleo_rust.dylib \
//   ALEO_NEW_LIB=/abs/new/libaleo_rust.dylib \
//   flutter test test/_diff_records.dart
import 'dart:io';

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

// Known encrypted records + view keys (from aleo_record_test.dart).
const records = <String>[
  'record1qyqsqpe2szk2wwwq56akkwx586hkndl3r8vzdwve32lm7elvphh37rsyqyxx66trwfhkxun9v35hguerqqpqzqrtjzeu6vah9x2me2exkgege824sd8x2379scspmrmtvczs0d93qttl7y92ga0k0rsexu409hu3vlehe3yxjhmey3frh2z5pxm5cmxsv4un97q',
  'record1qyqsqpfr4rj0ga9c3j7q40hdv4zasd0dx9creup4f582my6zvncfczqvqyxx66trwfhkxun9v35hguerqqpqzq8rs7l2c2h3ccfqw3gaxt388dwwpcts2847dc7a0pj9jujt2suuqgm3j6tvj4qlp6fh3rk6nzn6k7w0tyx7mk4zjffl22c4gte92t8q6awh66c',
  'record1qyqspdn8f6lh4eum9a36l93mnxh5vcqssjsep9z4lp4vpya2efgmjdsvqyxx66trwfhkxun9v35hguerqqpqzq9yu3tvsnj4x0a7e2w9w204aya09thraeckdlsn59pve6fnnd3eqv0n7jpp5rsxn48jdjj3z55vhmp42f8hxp7vk5d2430vuvk3fzrsx0w9wqw',
];
const viewKeys = <String>[
  'AViewKey1ccEt8A2Ryva5rxnKcAbn7wgTaTsb79tzkKHFpeKsm9NX',
  'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp',
];

void main() {
  final refPath = Platform.environment['ALEO_REF_LIB'];
  final newPath = Platform.environment['ALEO_NEW_LIB'];
  if (refPath == null || newPath == null) {
    test('record parity', () {},
        skip: 'set ALEO_REF_LIB and ALEO_NEW_LIB to two libaleo_rust builds');
    return;
  }

  final ref = AleoRecord(DyLib.getDyLibByPosition(refPath));
  final neu = AleoRecord(DyLib.getDyLibByPosition(newPath));

  test('is_owner + decrypt_cipher_text parity over all record x view-key pairs', () {
    var ownedChecked = 0;
    var notOwnedChecked = 0;
    for (final record in records) {
      for (final vk in viewKeys) {
        final ownedRef = ref.isOwner(record, vk);
        final ownedNew = neu.isOwner(record, vk);
        expect(ownedNew, ownedRef, reason: 'is_owner mismatch record=$record vk=$vk');

        if (ownedRef) {
          expect(neu.decryptCipherTextRaw(record, vk),
              ref.decryptCipherTextRaw(record, vk),
              reason: 'decrypt mismatch record=$record vk=$vk');
          ownedChecked++;
        } else {
          notOwnedChecked++;
        }
      }
    }
    // Sanity: the sample exercised both owned and not-owned paths.
    expect(ownedChecked, greaterThan(0));
    expect(notOwnedChecked, greaterThan(0));
  });

  test('serial_number_string parity over owned records', () {
    // The Dart layer only ever computes serial numbers for owned records
    // (it filters by is_owner first), so restrict parity to that domain.
    const privateKey =
        'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
    const viewKey = 'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp';
    var checked = 0;
    for (final record in records) {
      if (!ref.isOwner(record, viewKey)) continue;
      expect(neu.serialNumberString(record, privateKey),
          ref.serialNumberString(record, privateKey),
          reason: 'serial_number mismatch record=$record');
      checked++;
    }
    expect(checked, greaterThan(0));
    // Absolute check against the canonical value (record[2] is owned by this key).
    expect(
        neu.serialNumberString(records[2], privateKey),
        '832456939067524461249417512029753636275825913577828456140675004985222334481field');
  });
}
