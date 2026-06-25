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

// --- Phase-4 ABI (network-aware) ---------------------------------------------
// Phase 4 PR4a finalized the ABI: the proving exports moved to the enveloped,
// cold-cache-safe `*_checked` symbols (bound by `ParameterProvisioner`), the
// fee/authorize primitives were renamed to their canonical names, and every
// network-typed export now takes a `network` string ("mainnet"|"testnet") that
// dispatches the matching snarkVM monomorphization. The load-time
// `ffi_abi_version` guard (see `AleoLib`) makes a stale/mismatched library fail
// loudly rather than binding a renamed symbol or an argument into the wrong slot.

/// `(network, arg) -> string` — `required_commitments` / `state_root_from_paths`.
/// Both gained a `network` first arg in PR4a (they deserialize network-typed
/// snarkVM data, so they must know the network).
typedef TypeNetArgString = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

/// `required_imports` is network-agnostic (a program source is plain text), so it
/// keeps its single-argument shape.
typedef TypeOneArgString = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>);

// consensus_version_for(network, height) -> u16
typedef TypeConsensusVersionForRust = ffi.Uint16 Function(
    ffi.Pointer<Utf8>, ffi.Uint32);
typedef TypeConsensusVersionForDart = int Function(ffi.Pointer<Utf8>, int);

// get_base_fee(network, execution, program_sources_json, height) -> u64
typedef TypeGetBaseFeeInRust = ffi.Uint64 Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Uint32);
typedef TypeGetBaseFeeInDart = int Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, int);

// execution_fee_authorization(
//   network, private_key, execution, fee_credits, fee_record,
//   program_sources_json, height)
typedef TypeExecutionFeeAuthInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Uint64,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Uint32);
typedef TypeExecutionFeeAuthInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    int);

// program_authorization(
//   network, private_key, program_id, function_name, arguments, program_sources_json)
typedef TypeProgramAuth = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
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

  // --- Pure primitives (node I/O lives in AleoNode) --------------------------
  // Synchronous: they compute over caller-supplied data and issue no node RPC.
  // The network-typed ones take a `network` (threaded here via `_withNetwork`);
  // the string-returning ones hand back a Rust-allocated pointer the caller
  // releases through `takeNativeString`.

  /// The global input-record commitments whose state paths the caller must
  /// fetch before proving, as a JSON `[field]`. Empty for a public flow.
  ffi.Pointer<Utf8> requiredCommitments(ffi.Pointer<Utf8> authorization) {
    final fn = dyLib.lookupFunction<TypeNetArgString, TypeNetArgString>(
        'required_commitments');
    return _withNetwork((network) => fn(network, authorization));
  }

  /// The direct imports of a program source, as a JSON `[program_id]`, so the
  /// closure walk knows what else to fetch. Network-agnostic (plain text).
  ffi.Pointer<Utf8> requiredImports(ffi.Pointer<Utf8> programSource) {
    final fn = dyLib
        .lookupFunction<TypeOneArgString, TypeOneArgString>('required_imports');
    return fn(programSource);
  }

  /// The shared global state root of a non-empty batch of state paths (for
  /// logging/caching; proving derives it itself). "" if empty or disagreeing.
  ffi.Pointer<Utf8> stateRootFromPaths(ffi.Pointer<Utf8> statePathsJson) {
    final fn = dyLib.lookupFunction<TypeNetArgString, TypeNetArgString>(
        'state_root_from_paths');
    return _withNetwork((network) => fn(network, statePathsJson));
  }

  /// The consensus version active at [height] for this network — Dart pins one
  /// for a whole transaction without hardcoding upgrade heights (which differ
  /// per network).
  int consensusVersionFor(int height) {
    final fn = dyLib.lookupFunction<TypeConsensusVersionForRust,
        TypeConsensusVersionForDart>('consensus_version_for');
    return _withNetwork((network) => fn(network, height));
  }

  /// Base fee (microcredits) for an [execution] at [height]. [programSources]
  /// supplies the execution's root program (empty for credits.aleo).
  int getBaseFee(
    ffi.Pointer<Utf8> execution,
    ffi.Pointer<Utf8> programSources,
    int height,
  ) {
    final fn = dyLib.lookupFunction<TypeGetBaseFeeInRust, TypeGetBaseFeeInDart>(
        'get_base_fee');
    return _withNetwork(
        (network) => fn(network, execution, programSources, height));
  }

  /// Authorizes the fee for a proven [execution] at [height]. An empty
  /// [feeRecord] is a public fee, otherwise a private fee spending that record.
  ffi.Pointer<Utf8> executionFeeAuthorization(
    ffi.Pointer<Utf8> privateKey,
    ffi.Pointer<Utf8> execution,
    int feeCredits,
    ffi.Pointer<Utf8> feeRecord,
    ffi.Pointer<Utf8> programSources,
    int height,
  ) {
    final fn = dyLib.lookupFunction<TypeExecutionFeeAuthInRust,
        TypeExecutionFeeAuthInDart>('execution_fee_authorization');
    return _withNetwork((network) => fn(network, privateKey, execution,
        feeCredits, feeRecord, programSources, height));
  }

  /// Builds an execution authorization for an arbitrary program function offline.
  /// [arguments] is a JSON array of Aleo value strings (record inputs already
  /// plaintext); [programSources] supplies the program (empty for credits.aleo).
  ffi.Pointer<Utf8> programAuthorization(
    ffi.Pointer<Utf8> privateKey,
    ffi.Pointer<Utf8> programId,
    ffi.Pointer<Utf8> functionName,
    ffi.Pointer<Utf8> arguments,
    ffi.Pointer<Utf8> programSources,
  ) {
    final fn = dyLib.lookupFunction<TypeProgramAuth, TypeProgramAuth>(
        'program_authorization');
    return _withNetwork((network) => fn(network, privateKey, programId,
        functionName, arguments, programSources));
  }
}
