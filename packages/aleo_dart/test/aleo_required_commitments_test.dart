import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

import 'support/test_dylib.dart';

/// Offline coverage of `required_commitments` through the FFI boundary — the
/// helper that tells the phase-2 orchestration which state paths to fetch.
///
/// This pins the cardinality contract the Rust exact-match (`checked_static_query`)
/// then enforces at proving time: a single-record private transfer needs exactly
/// one commitment, a public transfer none. The full field-value parity against a
/// live node's proving path is the manual testnet run (transfer/aleo_phase2_e2e.dart).
void main() {
  final dyLib = tryLoadAleoLib();
  if (dyLib == null) {
    test('required_commitments', () {}, skip: nativeLibMissingReason);
    return;
  }
  final rust = AleoProgram(dyLib, 'testnet');

  // record[2] from test/_diff_records.dart, owned by ownerKey.
  const ownerKey = 'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
  const ownerAddress =
      'aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn';
  const testRecord =
      'record1qyqspdn8f6lh4eum9a36l93mnxh5vcqssjsep9z4lp4vpya2efgmjdsvqyxx66trwfhkxun9v35hguerqqpqzq9yu3tvsnj4x0a7e2w9w204aya09thraeckdlsn59pve6fnnd3eqv0n7jpp5rsxn48jdjj3z55vhmp42f8hxp7vk5d2430vuvk3fzrsx0w9wqw';

  // url is ignored by the offline credits.aleo authorize path.
  const url = 'https://example.invalid';

  test('a private transfer requires exactly its spent record commitment',
      () async {
    final auth = await rust.executionAuthorization(
        ownerKey, ownerAddress, TransferMethod.private, 1, url, testRecord);
    expect(auth, isNotEmpty, reason: 'offline authorize should succeed');
    final commitments = rust.requiredCommitments(auth);
    expect(commitments, hasLength(1));
    expect(commitments.single, endsWith('field'));
  });

  test('a public transfer requires no commitments', () async {
    final auth = await rust.executionAuthorization(
        ownerKey, ownerAddress, TransferMethod.public, 1, url, '');
    expect(auth, isNotEmpty);
    expect(rust.requiredCommitments(auth), isEmpty);
  });
}
