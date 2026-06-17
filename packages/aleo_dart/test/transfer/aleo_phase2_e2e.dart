import 'dart:io';

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

import '../support/test_dylib.dart';

/// Manual phase-2 end-to-end harness: the rewritten `AleoProgram` orchestration
/// over a Dart [AleoNode], run against a live node. Excluded from CI by its
/// filename (`*_e2e.dart`, not `*_test.dart`) — it needs the native library,
/// proving keys/SRS, a funded testnet account, and network access.
///
/// Run manually:
///   ALEO_NEW_LIB=/path/to/libaleo_rust.dylib \
///     dart test test/transfer/aleo_phase2_e2e.dart --run-skipped
///
/// What it pins (the kickoff's MUST-add items):
///   1. The full `tryTransfer` flow now routes node I/O through `AleoNode`.
///   2. `required_commitments` parity vs the live proving path: for a *private*
///      transfer, a successful end-to-end proof confirms the helper returned
///      exactly the commitments snarkVM's proving asked for — the Rust
///      `checked_static_query` guard rejects any extra path and proving fails on
///      a missing one, so "the proof verifies" == "the set was exact".
///   3. The private fee's own inclusion snapshot (a private fee spends its own
///      record), distinct from the execution snapshot.
void main() async {
  final dyLib = tryLoadAleoLib();
  if (dyLib == null) {
    test('phase-2 e2e', () {}, skip: nativeLibMissingReason);
    return;
  }
  final rust = AleoProgram(dyLib, 'testnet');

  // Public testnet (network-0 protocol under a /testnet REST path).
  const url = 'https://api.explorer.provable.com/v1';
  // Funded test account (see the aleo-gpl-removal-plan memory).
  const privateKey =
      'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
  const recipient =
      'aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn';

  test('AleoNode reads the node directly', () async {
    final node = AleoNode(url, network: 'testnet');
    final height = await node.latestHeight();
    final root = await node.latestStateRoot();
    print('height=$height root=$root version=${rust.consensusVersionFor(height)}');
    expect(height, greaterThan(0));
    expect(root, startsWith('sr1'));
  }, skip: 'manual: requires network');

  test('public transfer: build via AleoNode-backed orchestration', () async {
    // No record spent -> required_commitments is empty -> public snapshot path.
    final tx = await rust.buildTransaction(privateKey, recipient,
        TransferMethod.public, 1000000, 10000, url, '', '');
    expect(tx, isNotEmpty);
    print('assembled public transfer tx (${tx.length} bytes)');
    // Broadcast is left commented so the harness never submits unattended.
    // print(await rust.broadcast(tx, url, TransferMethod.public));
  }, skip: 'manual: requires network + proving keys');

  test('private transfer: end-to-end proof pins required_commitments parity',
      () async {
    // A spendable on-chain record owned by privateKey, fetched out-of-band.
    const amountRecord = '<paste a spendable record1... ciphertext>';
    const feeRecord = ''; // public fee; set to a record for a private fee.

    final node = AleoNode(url, network: 'testnet');
    final height = await node.latestHeight();

    final auth = await rust.executionAuthorization(privateKey, recipient,
        TransferMethod.private, 1, url, amountRecord);
    expect(auth, isNotEmpty);

    final commitments = rust.requiredCommitments(auth);
    expect(commitments, hasLength(1),
        reason: 'a single-record private transfer spends one record');

    final paths = await node.statePaths(commitments);
    // PR4a: proving goes through the ParameterProvisioner checked path (preflight
    // → download keys → execute_*_checked). checked_static_query enforces paths'
    // set == required_commitments, so a proof only succeeds when the helper was
    // exact.
    final prov = ParameterProvisioner(dyLib, 'testnet', Directory.systemTemp);
    final version = rust.consensusVersionFor(height);
    final proof = await prov.provisionAndProveExecution(
        authorization: auth,
        height: height,
        consensusVersion: version,
        statePaths: paths);
    expect(proof, isNotEmpty, reason: 'private execution proof must verify');

    final feeAuth = await rust.executionFeeAuthorizationStatic(
        privateKey, proof, 10000, feeRecord, '', height);
    expect(feeAuth, isNotEmpty);
    // The fee has its own snapshot (empty here for a public fee).
    final feeCommitments = rust.requiredCommitments(feeAuth);
    final feePaths = await node.statePaths(feeCommitments);
    final feeRoot = feeCommitments.isEmpty ? await node.latestStateRoot() : '';
    final feeProof = await prov.provisionAndProveFee(
        authorization: feeAuth,
        height: height,
        consensusVersion: version,
        statePaths: feePaths,
        publicStateRoot: feeRoot);
    expect(feeProof, isNotEmpty, reason: 'private-flow fee proof must verify');

    final tx = await rust.buildTransactionOffline(proof, feeProof);
    expect(tx, isNotEmpty);
    print('assembled private transfer tx (${tx.length} bytes)');
    prov.close();
  }, skip: 'manual: requires a funded testnet record + proving keys');
}
