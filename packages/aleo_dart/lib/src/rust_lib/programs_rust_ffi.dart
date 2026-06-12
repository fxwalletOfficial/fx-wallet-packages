import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

typedef TypeTestInRust = ffi.Int Function(ffi.Int, ffi.Int);
typedef TypeTestInDart = int Function(int, int);

// Amounts and fees cross the ABI as unsigned 64-bit microcredits (snarkVM's
// fee/amount type); 32-bit types cannot express the legal range.
typedef TypeAuthorizationInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Uint64,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeAuthorizationInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeUpgradeTransactionOffline = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeProof = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeUpgradeAuthorization = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeJoinAuthorization = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

// --- Pure primitives (node I/O lives in AleoNode) ----------------------------
// These take no `network` argument: they compute over pre-fetched data and
// issue no node RPC. The `_static` proving variants still synchronously download
// snarkVM proving parameters on a cold cache (a separate, phase-4 concern).
// Phase 3 deleted the old blocking-HTTP exports; these keep their `_static` Rust
// symbol names. Renaming them to the now-free canonical names is deferred to the
// phase-4 lib redistribution: reusing a freed name whose ABI differs in an
// already-distributed prebuilt library would turn a clean missing-symbol error
// into a silent ABI mismatch, so the rename must land atomically with a
// rebuilt/redistributed library (+ an ABI-version guard).

/// One `Pointer<Utf8>` in, one out — the shape of `required_commitments`,
/// `required_imports`, and `state_root_from_paths`.
typedef TypeOneArgString = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>);

typedef TypeConsensusVersionForRust = ffi.Uint16 Function(ffi.Uint32);
typedef TypeConsensusVersionForDart = int Function(int);

// get_base_fee_static(execution, program_sources_json, height) -> u64
typedef TypeGetBaseFeeStaticInRust = ffi.Uint64 Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Uint32);
typedef TypeGetBaseFeeStaticInDart = int Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, int);

// execution_fee_authorization_static(
//   private_key, execution, fee_credits, fee_record, program_sources_json, height)
typedef TypeExecutionFeeAuthStaticInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Uint64,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Uint32);
typedef TypeExecutionFeeAuthStaticInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    int);

// execute_proof_static / execute_fee_proof_static(
//   authorization, height, state_paths_json, public_state_root)
typedef TypeExecuteProofStaticInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Uint32, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
typedef TypeExecuteProofStaticInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, int, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

// execute_program_proof_static(
//   authorization, program_sources_json, height, state_paths_json, public_state_root)
typedef TypeExecuteProgramProofStaticInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Uint32,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);
typedef TypeExecuteProgramProofStaticInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, int, ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

// program_authorization_static(
//   private_key, program_id, function_name, arguments, program_sources_json)
typedef TypeProgramAuthStatic = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

class ProgramsRustFFI {
  final ffi.DynamicLibrary dyLib;
  final String network;

  ProgramsRustFFI(this.dyLib, this.network);

  /// Allocates a native copy of [network] for the duration of [action] and
  /// frees it afterwards. The native functions copy the string during the
  /// call, so no allocation needs to outlive it.
  T _withNetwork<T>(T Function(ffi.Pointer<Utf8> network) action) {
    final networkPtr = network.toNativeUtf8();
    try {
      return action(networkPtr);
    } finally {
      malloc.free(networkPtr);
    }
  }

  Future<ffi.Pointer<Utf8>> joinAuthorization(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> record_1,
    ffi.Pointer<Utf8> record_2,
    ffi.Pointer<Utf8> url,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeJoinAuthorization, TypeJoinAuthorization>(
            'join_authorization');

    return _withNetwork((network) =>
        rustFunction(private_key, record_1, record_2, url, network));
  }

  Future<ffi.Pointer<Utf8>> upgradeAuthorization(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> record,
    ffi.Pointer<Utf8> url,
  ) async {
    final rustFunction = dyLib.lookupFunction<TypeUpgradeAuthorization,
        TypeUpgradeAuthorization>('upgrade_authorization');

    return _withNetwork(
        (network) => rustFunction(private_key, record, url, network));
  }

  Future<ffi.Pointer<Utf8>> executionAuthorization(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> recipient,
    ffi.Pointer<Utf8> transfer_type,
    int amount_credits,
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> amount_record,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeAuthorizationInRust, TypeAuthorizationInDart>(
            'execution_authorization');

    return _withNetwork((network) => rustFunction(private_key, recipient,
        transfer_type, amount_credits, url, amount_record, network));
  }

  Future<ffi.Pointer<Utf8>> buildTransactionOffline(
    ffi.Pointer<Utf8> execution,
    ffi.Pointer<Utf8> fee,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeProof, TypeProof>('build_transaction_offline');
    return _withNetwork((network) => rustFunction(execution, fee, network));
  }

  Future<ffi.Pointer<Utf8>> buildUpgradeTransactionOffline(
    ffi.Pointer<Utf8> execution,
  ) async {
    final rustFunction = dyLib.lookupFunction<TypeUpgradeTransactionOffline,
        TypeUpgradeTransactionOffline>('build_upgrade_transaction_offline');
    return _withNetwork((network) => rustFunction(execution, network));
  }

  // --- Pure primitives -------------------------------------------------------
  // Synchronous: they compute over caller-supplied data and pass no `network`.
  // The string-returning ones hand back a Rust-allocated pointer the caller
  // releases through `takeNativeString`, exactly like the older exports.

  /// The global input-record commitments whose state paths the caller must
  /// fetch before proving, as a JSON `[field]`. Empty for a public flow.
  ffi.Pointer<Utf8> requiredCommitments(ffi.Pointer<Utf8> authorization) {
    final fn = dyLib.lookupFunction<TypeOneArgString, TypeOneArgString>(
        'required_commitments');
    return fn(authorization);
  }

  /// The direct imports of a program source, as a JSON `[program_id]`, so the
  /// closure walk knows what else to fetch.
  ffi.Pointer<Utf8> requiredImports(ffi.Pointer<Utf8> programSource) {
    final fn = dyLib.lookupFunction<TypeOneArgString, TypeOneArgString>(
        'required_imports');
    return fn(programSource);
  }

  /// The shared global state root of a non-empty batch of state paths (for
  /// logging/caching; proving derives it itself). "" if empty or disagreeing.
  ffi.Pointer<Utf8> stateRootFromPaths(ffi.Pointer<Utf8> statePathsJson) {
    final fn = dyLib.lookupFunction<TypeOneArgString, TypeOneArgString>(
        'state_root_from_paths');
    return fn(statePathsJson);
  }

  /// The consensus version active at [height] — Dart pins one for a whole
  /// transaction without hardcoding upgrade heights.
  int consensusVersionFor(int height) {
    final fn = dyLib.lookupFunction<TypeConsensusVersionForRust,
        TypeConsensusVersionForDart>('consensus_version_for');
    return fn(height);
  }

  /// Base fee (microcredits) for an [execution] at [height]. [programSources]
  /// supplies the execution's root program (empty for credits.aleo).
  int getBaseFeeStatic(
    ffi.Pointer<Utf8> execution,
    ffi.Pointer<Utf8> programSources,
    int height,
  ) {
    final fn = dyLib.lookupFunction<TypeGetBaseFeeStaticInRust,
        TypeGetBaseFeeStaticInDart>('get_base_fee_static');
    return fn(execution, programSources, height);
  }

  /// Authorizes the fee for a proven [execution] at [height]. An empty
  /// [feeRecord] is a public fee, otherwise a private fee spending that record.
  ffi.Pointer<Utf8> executionFeeAuthorizationStatic(
    ffi.Pointer<Utf8> privateKey,
    ffi.Pointer<Utf8> execution,
    int feeCredits,
    ffi.Pointer<Utf8> feeRecord,
    ffi.Pointer<Utf8> programSources,
    int height,
  ) {
    final fn = dyLib.lookupFunction<TypeExecutionFeeAuthStaticInRust,
        TypeExecutionFeeAuthStaticInDart>('execution_fee_authorization_static');
    return fn(privateKey, execution, feeCredits, feeRecord, programSources,
        height);
  }

  /// Proves an [authorization] against a StaticQuery built from pre-fetched
  /// [height] / [statePathsJson] / [publicStateRoot].
  ffi.Pointer<Utf8> executeProofStatic(
    ffi.Pointer<Utf8> authorization,
    int height,
    ffi.Pointer<Utf8> statePathsJson,
    ffi.Pointer<Utf8> publicStateRoot,
  ) {
    final fn = dyLib.lookupFunction<TypeExecuteProofStaticInRust,
        TypeExecuteProofStaticInDart>('execute_proof_static');
    return fn(authorization, height, statePathsJson, publicStateRoot);
  }

  /// Proves a fee [authorization] against its own pre-fetched snapshot (a
  /// private fee spends its own record, so its paths differ from the execution's).
  ffi.Pointer<Utf8> executeFeeProofStatic(
    ffi.Pointer<Utf8> authorization,
    int height,
    ffi.Pointer<Utf8> statePathsJson,
    ffi.Pointer<Utf8> publicStateRoot,
  ) {
    final fn = dyLib.lookupFunction<TypeExecuteProofStaticInRust,
        TypeExecuteProofStaticInDart>('execute_fee_proof_static');
    return fn(authorization, height, statePathsJson, publicStateRoot);
  }

  /// Like [executeProofStatic] but the referenced program (+ closure) is
  /// supplied in-memory via [programSources] rather than fetched from a node.
  ffi.Pointer<Utf8> executeProgramProofStatic(
    ffi.Pointer<Utf8> authorization,
    ffi.Pointer<Utf8> programSources,
    int height,
    ffi.Pointer<Utf8> statePathsJson,
    ffi.Pointer<Utf8> publicStateRoot,
  ) {
    final fn = dyLib.lookupFunction<TypeExecuteProgramProofStaticInRust,
        TypeExecuteProgramProofStaticInDart>('execute_program_proof_static');
    return fn(
        authorization, programSources, height, statePathsJson, publicStateRoot);
  }

  /// Builds an execution authorization for an arbitrary program function offline.
  /// [arguments] is a JSON array of Aleo value strings (record inputs already
  /// plaintext); [programSources] supplies the program (empty for credits.aleo).
  ffi.Pointer<Utf8> programAuthorizationStatic(
    ffi.Pointer<Utf8> privateKey,
    ffi.Pointer<Utf8> programId,
    ffi.Pointer<Utf8> functionName,
    ffi.Pointer<Utf8> arguments,
    ffi.Pointer<Utf8> programSources,
  ) {
    final fn =
        dyLib.lookupFunction<TypeProgramAuthStatic, TypeProgramAuthStatic>(
            'program_authorization_static');
    return fn(privateKey, programId, functionName, arguments, programSources);
  }
}
