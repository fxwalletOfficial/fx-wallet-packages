import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:aleo_dart/src/aleo_node.dart';
import 'package:aleo_dart/src/rust_lib/programs_rust_ffi.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';
import 'package:aleo_dart/src/aleo_utils.dart';

/// Aleo program orchestration.
///
/// Phase 2 of the I/O-to-Dart migration: the one-call flows (`tryTransfer`,
/// `tryJoin`, `buildTransaction`, `executeProgram`, `contractExecution`,
/// `contractFeeExecution`) and the node-touching leaves (`executeProof`,
/// `executeFeeProof`, `executeProgramProof`, `getBaseFee`,
/// `executionFeeAuthorization`, `broadcast`) no longer call the blocking-HTTP
/// FFI exports. They compose the pure phase-1 `*_static` primitives over data an
/// [AleoNode] fetches in Dart (with real `CancelToken` cancellation), so the
/// network I/O lives in a layer that can actually be cancelled and bounded.
/// Public method signatures are unchanged.
///
/// The split-proof transfer flow mirrors the old in-Rust `full_transaction`
/// exactly — authorize → prove execution → authorize fee → prove fee → assemble
/// — but takes two independent inclusion snapshots (execution, then the fee,
/// because a private fee spends its own record) and pins one consensus version
/// across the whole transaction (a mid-flow upgrade discards everything and
/// restarts).
class AleoProgram {
  late ProgramsRustFFI programsRustFFI;

  /// One HTTP client shared by every node operation, created lazily. Each
  /// operation builds a fresh [AleoNode] but they all reuse this Dio, so we do
  /// not spin up — and leak — a client (and its pooled keep-alive sockets) per
  /// operation. Released by [dispose].
  Dio? _httpClient;

  /// How many times the whole transfer flow restarts if a consensus upgrade
  /// lands mid-build. A generous ceiling: upgrades are rare, so more than one
  /// retry means something is badly wrong rather than a real version churn.
  static const int _maxConsensusRetries = 3;

  AleoProgram(dyLib, [String network_raw = 'testnet']) {
    this.programsRustFFI = ProgramsRustFFI(dyLib, network_raw);
  }

  /// A node bound to [url_raw] and this program's network, reusing the shared
  /// HTTP client and wiring in the pure `required_imports` helper for the
  /// program-closure walk. The node does not own the Dio (this program does),
  /// so node teardown is handled here via [dispose].
  AleoNode _node(String url_raw) => AleoNode(
        url_raw,
        network: programsRustFFI.network,
        dio: _httpClient ??= AleoNode.defaultDio(),
        parseImports: _requiredImports,
      );

  /// Releases the shared HTTP client and its keep-alive connections. Call when
  /// the app is done with this AleoProgram; a later operation lazily recreates
  /// the client.
  void dispose() {
    _httpClient?.close(force: true);
    _httpClient = null;
  }

  // --- one-call flows (compose primitives + node I/O) -----------------------

  /// Builds and broadcasts a credits.aleo transfer, returning the node response.
  Future<String> tryTransfer(
    String private_key_raw,
    String recipient_raw,
    String transfer_type_raw,
    int amount_credits,
    int fee_credits,
    String url_raw,
    String amount_record_raw,
    String fee_record_raw,
  ) async {
    final transaction = await buildTransaction(
      private_key_raw,
      recipient_raw,
      transfer_type_raw,
      amount_credits,
      fee_credits,
      url_raw,
      amount_record_raw,
      fee_record_raw,
    );
    return _node(url_raw).broadcast(transaction);
  }

  /// Builds a complete credits.aleo transfer transaction (without broadcasting).
  Future<String> buildTransaction(
    String private_key_raw,
    String recipient_raw,
    String transfer_type_raw,
    int amount_credits,
    int fee_credits,
    String url_raw,
    String amount_record_raw,
    String fee_record_raw,
  ) async {
    AleoUtils.checkAmount(amount_credits, 'amount');
    AleoUtils.checkAmount(fee_credits, 'fee');
    final node = _node(url_raw);

    for (var attempt = 0;; attempt++) {
      final height = await node.latestHeight();
      final version = programsRustFFI.consensusVersionFor(height);

      // (2) execution authorization — offline (credits.aleo is built in).
      final execution = _require(
          await executionAuthorization(private_key_raw, recipient_raw,
              transfer_type_raw, amount_credits, url_raw, amount_record_raw),
          'execution authorization');

      // (3-4) execution snapshot + proof.
      final executionProof = await _proveExecution(node, execution, height);

      // (5) fee authorization — priority fee = fee_credits; public/private by
      // fee_record. Empty program sources: credits.aleo is built in.
      final feeAuth = _require(
          await executionFeeAuthorizationStatic(private_key_raw, executionProof,
              fee_credits, fee_record_raw, '', height),
          'fee authorization');

      // (6-7) fee snapshot + proof (its own commitments — a private fee spends
      // its own record).
      final feeProof = await _proveFee(node, feeAuth, height);

      // (8) consistency gate: an upgrade landing mid-flow invalidates every
      // proof bound to the old version, so discard all of them and restart.
      if (programsRustFFI.consensusVersionFor(await node.latestHeight()) !=
          version) {
        if (attempt + 1 >= _maxConsensusRetries) {
          throw AleoNodeException(
              'consensus version changed on every one of $_maxConsensusRetries '
              'transfer-build attempts');
        }
        continue;
      }

      // (9) assemble.
      return _require(await buildTransactionOffline(executionProof, feeProof),
          'transaction assembly');
    }
  }

  /// Builds, proves, and broadcasts a credits.aleo `join` of two private
  /// records, returning the node response.
  Future<String> tryJoin(
    String private_key_raw,
    String record_1_raw,
    String record_2_raw,
    int fee_credits,
    String fee_record_raw,
    String url_raw,
  ) async {
    AleoUtils.checkAmount(fee_credits, 'fee');
    final node = _node(url_raw);

    for (var attempt = 0;; attempt++) {
      final height = await node.latestHeight();
      final version = programsRustFFI.consensusVersionFor(height);

      final joinAuth = _require(
          await joinAuthorization(
              private_key_raw, record_1_raw, record_2_raw, url_raw),
          'join authorization');

      // join spends two on-chain records, so this is a private flow.
      final executionProof = await _proveExecution(node, joinAuth, height);

      final feeAuth = _require(
          await executionFeeAuthorizationStatic(private_key_raw, executionProof,
              fee_credits, fee_record_raw, '', height),
          'fee authorization');
      final feeProof = await _proveFee(node, feeAuth, height);

      if (programsRustFFI.consensusVersionFor(await node.latestHeight()) !=
          version) {
        if (attempt + 1 >= _maxConsensusRetries) {
          throw AleoNodeException(
              'consensus version changed on every one of $_maxConsensusRetries '
              'join-build attempts');
        }
        continue;
      }

      final transaction = _require(
          await buildTransactionOffline(executionProof, feeProof),
          'transaction assembly');
      return node.broadcast(transaction);
    }
  }

  /// Executes an arbitrary program function and broadcasts the transaction,
  /// returning the node response. The fee is public (no fee record).
  Future<String> executeProgram(
    String private_key_raw,
    String program_id_raw,
    String function_name_raw,
    String arguments_raw,
    int fee,
    String url_raw,
  ) async {
    AleoUtils.checkAmount(fee, 'fee');
    final node = _node(url_raw);

    for (var attempt = 0;; attempt++) {
      final height = await node.latestHeight();
      final version = programsRustFFI.consensusVersionFor(height);

      // Fetch the program's import closure once; it is needed to authorize, to
      // prove, and to cost the fee (execution_cost reads each transition's
      // program Stack).
      final sources = await node.programClosure(program_id_raw);

      final auth = _require(
          await programAuthorizationStatic(private_key_raw, program_id_raw,
              function_name_raw, arguments_raw, sources),
          'program authorization');

      final executionProof =
          await _proveProgramExecution(node, auth, sources, height);

      final feeAuth = _require(
          await executionFeeAuthorizationStatic(
              private_key_raw, executionProof, fee, '', sources, height),
          'fee authorization');
      final feeProof = await _proveFee(node, feeAuth, height);

      if (programsRustFFI.consensusVersionFor(await node.latestHeight()) !=
          version) {
        if (attempt + 1 >= _maxConsensusRetries) {
          throw AleoNodeException(
              'consensus version changed on every one of $_maxConsensusRetries '
              'program-execution attempts');
        }
        continue;
      }

      final transaction = _require(
          await buildTransactionOffline(executionProof, feeProof),
          'transaction assembly');
      return node.broadcast(transaction);
    }
  }

  /// Produces the execution proof for an arbitrary program function (split
  /// proof; the fee follows via [contractFeeExecution]). Returns the serialized
  /// execution.
  Future<String> contractExecution(
    String private_key_raw,
    String program_id_raw,
    String function_name_raw,
    String arguments_raw,
    String url_raw,
  ) async {
    final node = _node(url_raw);
    final height = await node.latestHeight();
    final sources = await node.programClosure(program_id_raw);
    final auth = _require(
        await programAuthorizationStatic(private_key_raw, program_id_raw,
            function_name_raw, arguments_raw, sources),
        'program authorization');
    return _proveProgramExecution(node, auth, sources, height);
  }

  /// Produces the public fee proof for a contract execution. Returns the
  /// serialized fee.
  Future<String> contractFeeExecution(
    String private_key_raw,
    int fee,
    String execution_raw,
    String program_id_raw,
    String url_raw,
  ) async {
    AleoUtils.checkAmount(fee, 'fee');
    final node = _node(url_raw);
    final height = await node.latestHeight();
    final sources = await node.programClosure(program_id_raw);
    final feeAuth = _require(
        await executionFeeAuthorizationStatic(
            private_key_raw, execution_raw, fee, '', sources, height),
        'fee authorization');
    return _proveFee(node, feeAuth, height);
  }

  // --- node-touching leaves (compose a static primitive over node I/O) ------

  /// Generates the execution proof for a credits.aleo authorization. Fetches the
  /// snapshot (height + state paths/root) and proves offline.
  Future<String> executeProof(String url_raw, String authorization_raw) async {
    final node = _node(url_raw);
    final height = await node.latestHeight();
    return _proveExecution(node, authorization_raw, height);
  }

  /// Generates the execution proof for an authorization that targets a
  /// non-builtin program: its closure is fetched and supplied in-memory.
  Future<String> executeProgramProof(String url_raw, String authorization_raw,
      {String program_id_raw = 'credits.aleo'}) async {
    final node = _node(url_raw);
    final height = await node.latestHeight();
    final sources = await node.programClosure(program_id_raw);
    return _proveProgramExecution(node, authorization_raw, sources, height);
  }

  /// Generates the fee proof for a fee authorization.
  Future<String> executeFeeProof(
    String url_raw,
    String authorization_raw,
  ) async {
    final node = _node(url_raw);
    final height = await node.latestHeight();
    return _proveFee(node, authorization_raw, height);
  }

  /// Base (minimum) fee in microcredits for a serialized credits.aleo
  /// execution. Fetches the height that selects the consensus version.
  Future<int> getBaseFee(
    String url_raw,
    String execution_raw,
  ) async {
    final height = await _node(url_raw).latestHeight();
    return getBaseFeeStatic(execution_raw, '', height);
  }

  /// Builds the fee authorization for an execution. `transfer_type_raw` is kept
  /// for signature stability but unused — public vs private fee is decided by
  /// whether `fee_record_raw` is empty.
  Future<String> executionFeeAuthorization(
      String private_key_raw,
      String transfer_type_raw,
      int fee_credits,
      String url_raw,
      String fee_record_raw,
      String execution_raw) async {
    AleoUtils.checkAmount(fee_credits, 'fee');
    final height = await _node(url_raw).latestHeight();
    return executionFeeAuthorizationStatic(
        private_key_raw, execution_raw, fee_credits, fee_record_raw, '', height);
  }

  /// Broadcasts a serialized transaction. `transfer_type_raw` is unused (kept
  /// for signature stability).
  Future<String> broadcast(
    String transaction_raw,
    String url_raw,
    String transfer_type_raw,
  ) async {
    return _node(url_raw).broadcast(transaction_raw);
  }

  // --- offline authorize / assemble (unchanged; the FFI ignores url) --------

  Future<String> joinAuthorization(
    String private_key_raw,
    String record_1_raw,
    String record_2_raw,
    String url_raw,
  ) async {
    final private_key = dartStrToC(private_key_raw);
    final record_1 = dartStrToC(record_1_raw);
    final record_2 = dartStrToC(record_2_raw);
    final url = dartStrToC(url_raw);
    try {
      final result = await programsRustFFI.joinAuthorization(
          private_key, record_1, record_2, url);
      return takeNativeString(programsRustFFI.dyLib, result);
    } finally {
      freeAll([private_key, record_1, record_2, url]);
    }
  }

  Future<String> upgradeAuthorization(
    String private_key_raw,
    String record_raw,
    String url_raw,
  ) async {
    final private_key = dartStrToC(private_key_raw);
    final record = dartStrToC(record_raw);
    final url = dartStrToC(url_raw);
    try {
      final result =
          await programsRustFFI.upgradeAuthorization(private_key, record, url);
      return takeNativeString(programsRustFFI.dyLib, result);
    } finally {
      freeAll([private_key, record, url]);
    }
  }

  Future<String> executionAuthorization(
    String private_key_raw,
    String recipient_raw,
    String transfer_type_raw,
    int amount_credits,
    String url_raw,
    String amount_record_raw,
  ) async {
    AleoUtils.checkAmount(amount_credits, 'amount');
    final private_key = dartStrToC(private_key_raw);
    final transfer_type = dartStrToC(transfer_type_raw);
    final recipient = dartStrToC(recipient_raw);
    final url = dartStrToC(url_raw);
    final amount_record = dartStrToC(amount_record_raw);
    try {
      final result = await programsRustFFI.executionAuthorization(private_key,
          recipient, transfer_type, amount_credits, url, amount_record);
      return takeNativeString(programsRustFFI.dyLib, result);
    } finally {
      freeAll([private_key, transfer_type, recipient, url, amount_record]);
    }
  }

  Future<String> buildTransactionOffline(
    String execution_raw,
    String fee_raw,
  ) async {
    final execution = dartStrToC(execution_raw);
    final fee = dartStrToC(fee_raw);
    try {
      final result =
          await programsRustFFI.buildTransactionOffline(execution, fee);
      return takeNativeString(programsRustFFI.dyLib, result);
    } finally {
      freeAll([execution, fee]);
    }
  }

  Future<String> buildUpgradeTransactionOffline(
    String execution_raw,
  ) async {
    final execution = dartStrToC(execution_raw);
    try {
      final result =
          await programsRustFFI.buildUpgradeTransactionOffline(execution);
      return takeNativeString(programsRustFFI.dyLib, result);
    } finally {
      freeAll([execution]);
    }
  }

  // --- phase-1 pure primitives (Dart wrappers) ------------------------------

  /// Proves [authorization] (a serialized fee authorization) against its own
  /// pre-fetched snapshot.
  Future<String> executeFeeProofStatic(
    String authorization_raw,
    int height,
    String state_paths_json,
    String public_state_root,
  ) async {
    final authorization = dartStrToC(authorization_raw);
    final statePaths = dartStrToC(state_paths_json);
    final publicRoot = dartStrToC(public_state_root);
    try {
      return takeNativeString(
          programsRustFFI.dyLib,
          programsRustFFI.executeFeeProofStatic(
              authorization, height, statePaths, publicRoot));
    } finally {
      freeAll([authorization, statePaths, publicRoot]);
    }
  }

  /// Proves [authorization] against a StaticQuery built from pre-fetched node
  /// data (no node RPC; proving may still download parameters on a cold cache).
  Future<String> executeProofStatic(
    String authorization_raw,
    int height,
    String state_paths_json,
    String public_state_root,
  ) async {
    final authorization = dartStrToC(authorization_raw);
    final statePaths = dartStrToC(state_paths_json);
    final publicRoot = dartStrToC(public_state_root);
    try {
      return takeNativeString(
          programsRustFFI.dyLib,
          programsRustFFI.executeProofStatic(
              authorization, height, statePaths, publicRoot));
    } finally {
      freeAll([authorization, statePaths, publicRoot]);
    }
  }

  /// Like [executeProofStatic] but the program closure is supplied in-memory.
  Future<String> executeProgramProofStatic(
    String authorization_raw,
    String program_sources_json,
    int height,
    String state_paths_json,
    String public_state_root,
  ) async {
    final authorization = dartStrToC(authorization_raw);
    final sources = dartStrToC(program_sources_json);
    final statePaths = dartStrToC(state_paths_json);
    final publicRoot = dartStrToC(public_state_root);
    try {
      return takeNativeString(
          programsRustFFI.dyLib,
          programsRustFFI.executeProgramProofStatic(
              authorization, sources, height, statePaths, publicRoot));
    } finally {
      freeAll([authorization, sources, statePaths, publicRoot]);
    }
  }

  /// Builds the fee authorization for a proven [execution] at [height].
  Future<String> executionFeeAuthorizationStatic(
    String private_key_raw,
    String execution_raw,
    int fee_credits,
    String fee_record_raw,
    String program_sources_json,
    int height,
  ) async {
    AleoUtils.checkAmount(fee_credits, 'fee');
    final private_key = dartStrToC(private_key_raw);
    final execution = dartStrToC(execution_raw);
    final fee_record = dartStrToC(fee_record_raw);
    final sources = dartStrToC(program_sources_json);
    try {
      return takeNativeString(
          programsRustFFI.dyLib,
          programsRustFFI.executionFeeAuthorizationStatic(
              private_key, execution, fee_credits, fee_record, sources, height));
    } finally {
      freeAll([private_key, execution, fee_record, sources]);
    }
  }

  /// Builds an execution authorization for an arbitrary program function,
  /// offline. [arguments_raw] is a JSON array of Aleo value strings.
  Future<String> programAuthorizationStatic(
    String private_key_raw,
    String program_id_raw,
    String function_name_raw,
    String arguments_raw,
    String program_sources_json,
  ) async {
    final private_key = dartStrToC(private_key_raw);
    final program_id = dartStrToC(program_id_raw);
    final function_name = dartStrToC(function_name_raw);
    final arguments = dartStrToC(arguments_raw);
    final sources = dartStrToC(program_sources_json);
    try {
      return takeNativeString(
          programsRustFFI.dyLib,
          programsRustFFI.programAuthorizationStatic(
              private_key, program_id, function_name, arguments, sources));
    } finally {
      freeAll([private_key, program_id, function_name, arguments, sources]);
    }
  }

  /// Base fee (microcredits) for [execution_raw] at [height]; [sources] supplies
  /// the execution's program(s) (empty for credits.aleo). 0 on failure.
  int getBaseFeeStatic(String execution_raw, String sources, int height) {
    final execution = dartStrToC(execution_raw);
    final programSources = dartStrToC(sources);
    try {
      return programsRustFFI.getBaseFeeStatic(execution, programSources, height);
    } finally {
      freeAll([execution, programSources]);
    }
  }

  /// The global input-record commitments whose state paths must be fetched
  /// before proving [authorization_raw]. Empty for a public flow.
  List<String> requiredCommitments(String authorization_raw) {
    final authorization = dartStrToC(authorization_raw);
    try {
      final raw = takeNativeString(programsRustFFI.dyLib,
          programsRustFFI.requiredCommitments(authorization));
      if (raw.isEmpty) {
        throw AleoNodeException(
            'required_commitments failed (malformed authorization)');
      }
      return (jsonDecode(raw) as List).cast<String>();
    } finally {
      freeAll([authorization]);
    }
  }

  /// The consensus version active at [height] — pin one for a whole transaction
  /// without hardcoding upgrade heights.
  int consensusVersionFor(int height) =>
      programsRustFFI.consensusVersionFor(height);

  /// The shared global state root of a non-empty batch of state paths, or "".
  String stateRootFromPaths(String state_paths_json) {
    final statePaths = dartStrToC(state_paths_json);
    try {
      return takeNativeString(programsRustFFI.dyLib,
          programsRustFFI.stateRootFromPaths(statePaths));
    } finally {
      freeAll([statePaths]);
    }
  }

  /// The direct imports of [program_source], for the closure walk.
  List<String> _requiredImports(String program_source) {
    final source = dartStrToC(program_source);
    try {
      final raw = takeNativeString(
          programsRustFFI.dyLib, programsRustFFI.requiredImports(source));
      if (raw.isEmpty) {
        throw AleoNodeException(
            'required_imports failed (malformed program source)');
      }
      return (jsonDecode(raw) as List).cast<String>();
    } finally {
      freeAll([source]);
    }
  }

  // --- internal snapshot+prove steps ----------------------------------------

  /// Snapshot contract for a credits.aleo authorization: fetch the state paths
  /// for its required commitments (empty for a public flow, in which case the
  /// latest state root is fetched instead), then prove.
  Future<String> _proveExecution(
      AleoNode node, String authorization, int height) async {
    final commitments = requiredCommitments(authorization);
    final paths = await node.statePaths(commitments);
    final publicRoot =
        commitments.isEmpty ? await node.latestStateRoot() : '';
    return _require(
        await executeProofStatic(authorization, height, paths, publicRoot),
        'execution proof');
  }

  /// Snapshot contract for a fee authorization (its own commitments — a private
  /// fee spends its own record), then prove.
  Future<String> _proveFee(
      AleoNode node, String feeAuthorization, int height) async {
    final commitments = requiredCommitments(feeAuthorization);
    final paths = await node.statePaths(commitments);
    final publicRoot =
        commitments.isEmpty ? await node.latestStateRoot() : '';
    return _require(
        await executeFeeProofStatic(feeAuthorization, height, paths, publicRoot),
        'fee proof');
  }

  /// Snapshot contract for an arbitrary-program authorization, proved with the
  /// program closure supplied in-memory.
  Future<String> _proveProgramExecution(
      AleoNode node, String authorization, String sources, int height) async {
    final commitments = requiredCommitments(authorization);
    final paths = await node.statePaths(commitments);
    final publicRoot =
        commitments.isEmpty ? await node.latestStateRoot() : '';
    return _require(
        await executeProgramProofStatic(
            authorization, sources, height, paths, publicRoot),
        'program execution proof');
  }

  /// The phase-1 primitives return "" on failure (the FFI's single error
  /// channel). Turn that into a descriptive throw so a failed proof never feeds
  /// an empty string into the next step.
  String _require(String value, String what) {
    if (value.isEmpty) {
      throw AleoNodeException('$what failed (empty FFI result)');
    }
    return value;
  }

  String modifyAuthorization(
    String authorizationJson,
  ) {
    final authorization = json.decode(authorizationJson);
    final data = {'requests': [], 'transitions': []};
    final transitions = authorization['transitions'];
    for (var request in authorization['requests']) {
      final program = request['program'];
      final function = request['function'];
      for (var transition in transitions) {
        if (transition['program'] == program &&
            transition['function'] == function) {
          data['transitions']!.add(transition);
          data['requests']!.add(request);
        }
      }
    }
    return json.encode(data);
  }
}

