import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import 'rust_lib/dyLib.dart';
import 'rust_lib/utils.dart';

/// Thrown when the native side reports `restart_required`: a proving parameter is
/// missing/corrupt and snarkVM's process-global `lazy_static` is poisoned. Only an
/// OS-process restart clears it — recreating a Dart isolate does NOT, because
/// isolates share the loaded library and its statics. Once this is thrown the
/// [ParameterProvisioner] latch fail-fasts every later proving call without
/// touching the FFI, and the app should prompt the user to restart.
class ProvingDisabledException implements Exception {
  final String message;
  ProvingDisabledException(this.message);
  @override
  String toString() => 'ProvingDisabledException: $message';
}

/// A non-`restart_required` failure envelope (or any provisioning failure).
class ProvisioningException implements Exception {
  final String code;
  final String message;
  ProvisioningException(this.code, this.message);
  @override
  String toString() => 'ProvisioningException($code): $message';
}

/// One missing/corrupt proving-key file reported by `parameter_preflight`.
class MissingParam {
  final String function;
  final String relativePath;
  final List<String> urls;
  final int size;
  final String checksum;
  final String reason; // absent | wrong_size | wrong_checksum | unreadable

  MissingParam({
    required this.function,
    required this.relativePath,
    required this.urls,
    required this.size,
    required this.checksum,
    required this.reason,
  });

  factory MissingParam.fromJson(Map<String, dynamic> j) => MissingParam(
        function: j['function'] as String,
        relativePath: j['relativePath'] as String,
        urls: (j['urls'] as List).cast<String>(),
        size: j['size'] as int,
        checksum: j['checksum'] as String,
        reason: j['reason'] as String,
      );
}

/// Provisions the credits proving keys for one network into the parameter
/// directory (preflight → download missing → prove), coordinating concurrent
/// callers and other processes through advisory file locks (`dart:io`
/// `RandomAccessFile.lock`).
///
/// Additive: this is a new path exercised by tests via `ALEO_NEW_LIB`; it does NOT
/// replace `AleoProgram`'s existing proving methods (that switch lands with the
/// redistributed library in PR4).
class ParameterProvisioner {
  final ffi.DynamicLibrary _lib;

  /// `"mainnet"` or `"testnet"`.
  final String network;

  /// The directory proving keys live under (mobile app sandbox; desktop `~/.aleo`).
  final Directory paramDir;

  final Dio _dio;
  final bool _ownsDio;

  /// Wall-clock ceiling on a single url attempt, so a hung/slow source is abandoned
  /// for the mirror instead of stalling (`connectTimeout`/`receiveTimeout` alone miss
  /// a steady-but-slow stream that never goes idle).
  final Duration _perUrlDeadline;
  bool _dirSet = false;

  /// Poison latch (§8 Contract 3). Tripped when a checked-proving call returns
  /// `restart_required` (a corrupt/missing parameter poisoned snarkVM's
  /// process-global static, which only an OS-process restart clears).
  ///
  /// This `static` is **isolate-local**, so it is only a fast-path: a long-lived
  /// isolate stops touching the FFI after the first poison. It is NOT the
  /// cross-isolate guarantee — the authoritative guard is the Rust side. Every
  /// checked export is `catch_unwind`-wrapped, so a fresh isolate that calls the
  /// already-poisoned FFI gets `restart_required` back cheaply (a poisoned
  /// `lazy_static` re-deref is an immediate caught panic, not a re-download) and
  /// self-latches. Proving therefore never crashes and never silently succeeds
  /// after a poison, in any isolate; it just isn't byte-for-byte FFI-free across
  /// isolates.
  static bool _provingDisabled = false;
  static bool get provingDisabled => _provingDisabled;

  ParameterProvisioner(
    Object lib,
    this.network,
    this.paramDir, {
    Dio? dio,
    Duration? perUrlDownloadDeadline,
  })  : _lib = AleoLib.coerce(lib).dyLib,
        _ownsDio = dio == null,
        _perUrlDeadline = perUrlDownloadDeadline ?? const Duration(minutes: 30),
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 30),
            ));

  // ── FFI ────────────────────────────────────────────────────────────────────

  String _callPreflight(int consensusVersion) {
    final fn = _lib.lookupFunction<
        ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Uint16),
        ffi.Pointer<Utf8> Function(
            ffi.Pointer<Utf8>, int)>('parameter_preflight');
    final net = network.toNativeUtf8();
    try {
      return takeNativeString(_lib, fn(net, consensusVersion));
    } finally {
      malloc.free(net);
    }
  }

  String _callSetParameterDir(String path) {
    final fn = _lib.lookupFunction<
        ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>),
        ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>)>('ffi_set_parameter_dir');
    final ptr = path.toNativeUtf8();
    try {
      return takeNativeString(_lib, fn(ptr));
    } finally {
      malloc.free(ptr);
    }
  }

  String _callAleoDir() {
    final fn = _lib.lookupFunction<ffi.Pointer<Utf8> Function(),
        ffi.Pointer<Utf8> Function()>('ffi_aleo_dir');
    return takeNativeString(_lib, fn());
  }

  String _callExecuteProofChecked(String authorization, int height,
      String statePaths, String publicStateRoot) {
    final fn = _lib.lookupFunction<
        ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>,
            ffi.Uint32, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>),
        ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, int,
            ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>('execute_proof_checked');
    return _callProving(
        (net, auth, paths, root) => fn(net, auth, height, paths, root),
        authorization,
        statePaths,
        publicStateRoot);
  }

  String _callExecuteFeeProofChecked(String authorization, int height,
      String statePaths, String publicStateRoot) {
    final fn = _lib.lookupFunction<
        ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>,
            ffi.Uint32, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>),
        ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, int,
            ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>('execute_fee_proof_checked');
    return _callProving(
        (net, auth, paths, root) => fn(net, auth, height, paths, root),
        authorization,
        statePaths,
        publicStateRoot);
  }

  String _callExecuteProgramProofChecked(
      String authorization,
      String programSources,
      int height,
      String statePaths,
      String publicStateRoot) {
    final fn = _lib.lookupFunction<
        ffi.Pointer<Utf8> Function(
            ffi.Pointer<Utf8>,
            ffi.Pointer<Utf8>,
            ffi.Pointer<Utf8>,
            ffi.Uint32,
            ffi.Pointer<Utf8>,
            ffi.Pointer<Utf8>),
        ffi.Pointer<Utf8> Function(
            ffi.Pointer<Utf8>,
            ffi.Pointer<Utf8>,
            ffi.Pointer<Utf8>,
            int,
            ffi.Pointer<Utf8>,
            ffi.Pointer<Utf8>)>('execute_program_proof_checked');
    final net = network.toNativeUtf8();
    final auth = authorization.toNativeUtf8();
    final sources = programSources.toNativeUtf8();
    final paths = statePaths.toNativeUtf8();
    final root = publicStateRoot.toNativeUtf8();
    try {
      return takeNativeString(
          _lib, fn(net, auth, sources, height, paths, root));
    } finally {
      freeAll([net, auth, sources, paths, root]);
    }
  }

  /// Shared input marshalling for the 4-pointer checked proving exports.
  String _callProving(
    ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>,
            ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)
        call,
    String authorization,
    String statePaths,
    String publicStateRoot,
  ) {
    final net = network.toNativeUtf8();
    final auth = authorization.toNativeUtf8();
    final paths = statePaths.toNativeUtf8();
    final root = publicStateRoot.toNativeUtf8();
    try {
      return takeNativeString(_lib, call(net, auth, paths, root));
    } finally {
      freeAll([net, auth, paths, root]);
    }
  }

  // ── Envelope parsing (fail-closed) ──────────────────────────────────────────

  /// Parses a native envelope. Anything that is not `{"ok": true}` throws; a
  /// `restart_required` code trips the latch first.
  Map<String, dynamic> _ok(String json) {
    dynamic decoded;
    try {
      decoded = jsonDecode(json);
    } catch (_) {
      throw ProvisioningException(
          'invalid_envelope', 'native returned non-JSON: $json');
    }
    if (decoded is! Map || decoded['ok'] != true) {
      final code =
          (decoded is Map ? decoded['code'] : null) ?? 'invalid_envelope';
      final message = (decoded is Map ? decoded['message'] : null) ?? json;
      if (code == 'restart_required') {
        _provingDisabled = true;
        throw ProvingDisabledException(message.toString());
      }
      throw ProvisioningException(code.toString(), message.toString());
    }
    return decoded.cast<String, dynamic>();
  }

  void _ensureNotDisabled() {
    if (_provingDisabled) {
      throw ProvingDisabledException(
          'proving is disabled until the app restarts (a parameter was corrupt)');
    }
  }

  /// Points the native param loader at [paramDir] (idempotent / set-once). Uses the
  /// shared fail-closed [_ok] parser so a non-JSON envelope throws, `restart_required`
  /// trips the latch, and `invalid_path` propagates as itself — only `param_dir_locked`
  /// is reinterpreted (it is fine if the effective dir is already ours).
  void _ensureParameterDir() {
    if (_dirSet) return;
    try {
      _ok(_callSetParameterDir(paramDir.path));
      _dirSet = true;
    } on ProvisioningException catch (e) {
      if (e.code != 'param_dir_locked') rethrow;
      // Already fixed: accept only if the effective dir is already ours.
      final dir = _ok(_callAleoDir())['data'] as String;
      final ours = paramDir.existsSync()
          ? paramDir.resolveSymbolicLinksSync()
          : paramDir.path;
      if (dir != ours) rethrow;
      _dirSet = true;
    }
  }

  // ── Preflight ───────────────────────────────────────────────────────────────

  /// Returns the missing/corrupt parameter files for [consensusVersion] (empty ⇒
  /// the credits-v1 set is provisioned). Throws on an error envelope / latch.
  Future<List<MissingParam>> preflight(int consensusVersion) async {
    _ensureNotDisabled();
    _ensureParameterDir();
    final env = _ok(_callPreflight(consensusVersion));
    final missing = (env['missing'] as List).cast<Map<String, dynamic>>();
    return missing.map(MissingParam.fromJson).toList();
  }

  // ── Download (atomic, single-flight, locked) ────────────────────────────────

  /// Per-file mutex within ONE isolate. `RandomAccessFile.lock` is POSIX `fcntl`,
  /// which coordinates ACROSS processes but not within one (a process never
  /// conflicts with its own locks), so this serializes same-isolate concurrent
  /// provisions; the flock serializes other processes.
  ///
  /// Gap (documented, not closed): two isolates of the SAME process are coordinated
  /// by neither layer — this map is isolate-local, and fcntl doesn't conflict
  /// intra-process — so both could download the same file. That only wastes
  /// bandwidth: each verifies size+SHA-256 and atomically renames, so the result is
  /// still correct. Dart offers no intra-process cross-isolate file lock; closing
  /// it would need explicit isolate coordination (out of scope).
  static final Map<String, Future<void>> _inProcessLocks = {};

  Future<T> _withInProcessLock<T>(String key, Future<T> Function() body) async {
    while (_inProcessLocks.containsKey(key)) {
      await _inProcessLocks[key];
    }
    final completer = Completer<void>();
    _inProcessLocks[key] = completer.future;
    try {
      return await body();
    } finally {
      _inProcessLocks.remove(key);
      completer.complete();
    }
  }

  File _lockFileFor(String relativePath) {
    final hash = sha256.convert(utf8.encode(relativePath)).toString();
    return File(p.join(paramDir.path, '.locks', 'files', '$hash.lock'));
  }

  Future<bool> _fileMatches(File file, MissingParam param) async {
    if (!await file.exists()) return false;
    if (await file.length() != param.size) return false;
    final digest = await sha256.bind(file.openRead()).single;
    return digest.toString() == param.checksum;
  }

  /// Downloads one missing file under an exclusive single-flight lock: a concurrent
  /// caller (or process) blocks, then sees the file already present. The lock binds
  /// a stable `.lock` file, never the renamed `.tmp` (whose inode detaches on
  /// rename). Verifies size + SHA-256, then atomically renames into place.
  Future<void> _provisionFile(MissingParam param) {
    // In-process single-flight (this isolate), then cross-process via the flock.
    return _withInProcessLock(
        param.relativePath, () => _provisionFileLocked(param));
  }

  Future<void> _provisionFileLocked(MissingParam param) async {
    final lockFile = _lockFileFor(param.relativePath);
    await lockFile.parent.create(recursive: true);
    final raf = await lockFile.open(mode: FileMode.write);
    try {
      await raf.lock(FileLock.blockingExclusive);
      final target = File(p.join(paramDir.path, param.relativePath));
      if (await _fileMatches(target, param))
        return; // another flight finished it
      await target.parent.create(recursive: true);

      final tmp = File('${target.path}.${Random().nextInt(1 << 31)}.tmp');
      try {
        await _downloadTo(
            param, tmp); // returns only a size+checksum-verified body
        await tmp.rename(target.path); // atomic on the same filesystem
      } finally {
        if (await tmp.exists()) {
          await tmp.delete().catchError((_) => tmp);
        }
      }
    } finally {
      await raf.unlock();
      await raf.close();
    }
  }

  /// Downloads [param] into [tmp] from the first url whose body verifies (size +
  /// SHA-256). Falls back to the next url on a connection error OR a content
  /// mismatch — so a corrupt/stale primary CDN response (HTTP 200, wrong bytes)
  /// tries the mirror instead of failing the whole provision. Returns only when a
  /// url's body is verified.
  Future<void> _downloadTo(MissingParam param, File tmp) async {
    Object? lastError;
    for (final url in param.urls) {
      final cancel = CancelToken();
      // Overall wall-clock deadline for this attempt: a hung connect or a
      // steady-but-slow stream (which never trips receiveTimeout) is cancelled so
      // the loop falls back to the mirror.
      final deadline = Timer(_perUrlDeadline, () {
        if (!cancel.isCancelled) {
          cancel.cancel('download of ${param.function} from $url exceeded '
              '${_perUrlDeadline.inSeconds}s');
        }
      });
      try {
        await _dio.download(
          url,
          tmp.path,
          cancelToken: cancel,
          onReceiveProgress: (received, _) {
            // Hard cap: never write more than the manifest size.
            if (received > param.size && !cancel.isCancelled) {
              cancel.cancel(
                  'parameter ${param.function} exceeded its declared size');
            }
          },
        );
        if (await _fileMatches(tmp, param)) return; // verified
        lastError = ProvisioningException('checksum_mismatch',
            '$url returned a body failing size/checksum verification');
      } catch (e) {
        lastError = e;
      } finally {
        deadline.cancel();
      }
      if (await tmp.exists()) {
        await tmp.delete().catchError((_) => tmp);
      }
    }
    throw ProvisioningException('download_failed',
        'all sources failed for ${param.function}: $lastError');
  }

  // ── Tier lock + proving ─────────────────────────────────────────────────────

  /// Runs [body] holding a SHARED lock on `<dir>/.locks/<network>.lock`, so a prove
  /// proceeds concurrently with other proves but cannot run while eviction (a future
  /// exclusive holder) is deleting a file in the set.
  Future<T> _withSharedTierLock<T>(Future<T> Function() body) async {
    final lockFile = File(p.join(paramDir.path, '.locks', '$network.lock'));
    await lockFile.parent.create(recursive: true);
    final raf = await lockFile.open(mode: FileMode.write);
    try {
      await raf.lock(FileLock.blockingShared);
      return await body();
    } finally {
      await raf.unlock();
      await raf.close();
    }
  }

  Future<List<MissingParam>> _downloadAll(int consensusVersion) async {
    var missing = await preflight(consensusVersion);
    for (final param in missing) {
      await _provisionFile(param);
    }
    return missing;
  }

  /// Provisions then proves, holding the shared tier lock across a re-preflight (to
  /// close the download→prove TOCTOU) and the whole proving call. Returns the
  /// native envelope's serialized proof (`data`). [prove] performs the FFI call.
  Future<String> _provisionAndProve(
      int consensusVersion, String Function() prove) async {
    _ensureNotDisabled();
    await _downloadAll(consensusVersion);
    return _withSharedTierLock(() async {
      final still = await preflight(consensusVersion);
      if (still.isNotEmpty) {
        throw ProvisioningException('provisioning_incomplete',
            'still missing after download: ${still.map((m) => m.function).join(", ")}');
      }
      return _ok(prove())['data'] as String;
    });
  }

  /// preflight → download → prove an execution authorization. Returns the serialized
  /// execution.
  Future<String> provisionAndProveExecution({
    required String authorization,
    required int height,
    required int consensusVersion,
    String statePaths = '',
    String publicStateRoot = '',
  }) =>
      _provisionAndProve(
          consensusVersion,
          () => _callExecuteProofChecked(
              authorization, height, statePaths, publicStateRoot));

  /// preflight → download → prove a fee authorization. Returns the serialized fee.
  Future<String> provisionAndProveFee({
    required String authorization,
    required int height,
    required int consensusVersion,
    String statePaths = '',
    String publicStateRoot = '',
  }) =>
      _provisionAndProve(
          consensusVersion,
          () => _callExecuteFeeProofChecked(
              authorization, height, statePaths, publicStateRoot));

  /// An empty program closure: `""` or `"[]"` (an empty JSON array). Mirrors the
  /// native rule so a custom program is rejected at the Dart entry; a non-array or
  /// malformed value is NOT empty (and the native side would reject it too). Public
  /// so the orchestration layer can fail-fast a custom program before any node I/O.
  static bool isEmptyClosure(String programSources) {
    final trimmed = programSources.trim();
    if (trimmed.isEmpty) return true;
    try {
      final decoded = jsonDecode(trimmed);
      return decoded is List && decoded.isEmpty;
    } catch (_) {
      return false;
    }
  }

  /// preflight → download → prove an execution through the program path. v1 is
  /// credits-only: a non-empty [programSources] (a custom program) is rejected HERE
  /// with `unsupported_feature`, BEFORE provisioning ~1.15 GiB — the native side
  /// would also reject it, but only after the download. Returns the serialized
  /// execution.
  Future<String> provisionAndProveProgram({
    required String authorization,
    required int height,
    required int consensusVersion,
    String programSources = '',
    String statePaths = '',
    String publicStateRoot = '',
  }) async {
    // Latch first (Contract 3): a poisoned process fail-fasts as
    // ProvingDisabledException, even for a custom-program call.
    _ensureNotDisabled();
    if (!isEmptyClosure(programSources)) {
      throw ProvisioningException('unsupported_feature',
          'custom-program proving is not supported in this version');
    }
    return _provisionAndProve(
        consensusVersion,
        () => _callExecuteProgramProofChecked(authorization, programSources,
            height, statePaths, publicStateRoot));
  }

  /// Closes the internally-created Dio. A caller-injected Dio is left open — the
  /// caller owns its lifecycle (mirrors `AleoNode`).
  void close() {
    if (_ownsDio) _dio.close(force: true);
  }

  // ── Test hooks (the download / envelope / latch logic is otherwise private) ──

  /// Exposes [_provisionFile] so the downloader + single-flight lock can be tested
  /// with a fabricated [MissingParam] against a local server (no real params).
  Future<void> provisionFileForTest(MissingParam param) =>
      _provisionFile(param);

  /// Exposes the fail-closed envelope parser.
  Map<String, dynamic> parseEnvelopeForTest(String json) => _ok(json);

  /// Exposes the program checked-proof binding (bypassing provisioning) so its
  /// typedef can be exercised; a non-empty closure returns `unsupported_feature`
  /// before any parameter load.
  String callProgramProofForTest(String authorization, String programSources,
          int height, String statePaths, String publicStateRoot) =>
      _callExecuteProgramProofChecked(
          authorization, programSources, height, statePaths, publicStateRoot);

  /// Clears the (isolate-local) poison latch between tests.
  static void resetLatchForTest() => _provingDisabled = false;
}
