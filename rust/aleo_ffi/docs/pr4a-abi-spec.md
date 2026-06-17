# Phase 4 — PR4a spec: ABI finalization (rename + network activation + ABI guard + validated loader)

> Status: spec, not yet implemented. Branch `feature/aleo-io-dart-phase4-pr4a` off
> epic `1387238`. This is the ABI half of workstream C from `phase4-plan.md` §3.C.
> PR4b (cross-compile + distribution) is split out per the Phase-4 PR-split decision.

## 0. Applicable baseline (read before reviewing)

This spec is written **against epic `1387238`** (the PR4a branch base, commit
`203023f`). Review against that ref, not `main` or an older branch. The crate under
change is **`rust/aleo_ffi/`**.

⚠️ **Do not review `rust/aleo_rust/`.** That is the legacy **GPL** crate, slated for
deletion in PR5. It is unrelated to the Phase-1..4 work. Both crates set
`[lib] name = "aleo_rust"`, so **both build a `libaleo_rust` artifact** — this name
collision is the easy trap: the Dart layer loads `rust/aleo_ffi`'s output, but a
reviewer who greps `rust/aleo_rust/src/lib.rs` will see the *old* symbols (canonical
`execute_proof`/`get_base_fee`, a 2-arg `build_transaction_offline`, no `_network`)
and conclude the spec is wrong. Those legacy symbols are not this spec's subject.

Ground-truth checks on epic `1387238` (what this spec assumes):

| Claim | Verify | Expected |
|---|---|---|
| CI gate is `rust.yml` (exact symbol set) | `git show 1387238:.github/workflows/rust.yml` | present (in addition to `ci.yml`) |
| `_static` + `_checked` + preflight exports exist | `grep -E '_static\|_checked\|parameter_preflight' rust/aleo_ffi/src/lib.rs` | all present |
| `ParameterProvisioner` exists (PR2) | `packages/aleo_dart/lib/src/aleo_provisioning.dart` | present |
| `build_transaction_offline` arity | `rust/aleo_ffi/src/lib.rs` | 3 args incl. `_network` (matches Dart) |
| `build_upgrade_transaction_offline` arity | `rust/aleo_ffi/src/lib.rs` | 2 args incl. `_network` (matches Dart) |
| `get_base_fee_static` failure mode | `rust/aleo_ffi/src/lib.rs` | `inner().unwrap_or(0)` (no panic) |

## 1. Why PR4a is split from PR4b

Workstream C (the C-ABI change) and workstream D (cross-compile + redistribution)
were planned to land in one lockstep PR so a renamed symbol never reaches a stale
prebuilt library. PR4a makes that lockstep *safe to stage* by shipping the
**`ffi_abi_version` guard + validated Dart loader first**: a library that predates
the guard lacks the `ffi_abi_version` symbol, so the Dart loader fails with a clear
"incompatible native library" error at load time instead of binding a renamed
symbol to a different ABI and crashing silently. PR4a is therefore:

- **Purely local**: every test builds the library from this commit and points at it
  via `ALEO_NEW_LIB` (the established pattern). Nothing in PR4a publishes or
  repoints a distributed library — `dyLib.dart`/`setup_dylib.dart` still point at
  the old artifacts; PR4b repoints them.
- **Guarded**: because the guard lands here, the interim "new Dart + old distributed
  library" window fails loud, not silently. Mobile and CI build their own library,
  so nothing actually consumes the stale distributed artifact today (epic → main is
  not even open yet).

## 2. Scope decisions locked for this PR

| Decision | Choice |
|---|---|
| PR split | PR4a (this) = ABI + loader + flow switch; PR4b = cross-compile + distribute |
| Library hosting (v1) | No runtime download in v1. Mobile build-time bundles; desktop/CI build from source. (PR4b) |
| iOS scope | This repo ships staticlib crate-type + xcframework script + docs; app repo does device. (PR4b) |
| `ffi_abi_version` | Monotonic `u32`, value `1` for this ABI; Dart requires **exact match**. |

## 3. Rust ABI changes (the lockstep surface)

Current exported set = **35 functions + `free_string`** (36 symbols), all verified
in `rust.yml`'s exact-set gate.

### 3.1 Delete (superseded by PR2's enveloped `_checked` proving exports)

- `execute_proof_static`
- `execute_fee_proof_static`
- `execute_program_proof_static`

The Dart public flow switches to `execute_proof_checked` / `execute_fee_proof_checked`
/ `execute_program_proof_checked` (§5), so these have no caller. The canonical names
`execute_proof` / `execute_fee_proof` / `execute_program_proof` are intentionally
**left free** (not reused) — the `_checked` symbols keep their suffix, which carries
meaning (enveloped + network-aware + credits-only enforced) and avoids another
freed-name-reuse hazard.

### 3.2 Rename `_static` → canonical + add `network` dispatch

| Old symbol | New symbol | New first arg |
|---|---|---|
| `get_base_fee_static` | `get_base_fee` | `network: *const c_char` |
| `execution_fee_authorization_static` | `execution_fee_authorization` | `network: *const c_char` |
| `program_authorization_static` | `program_authorization` | `network: *const c_char` |

Each becomes generic over `N: Network` (same refactor shape as PR2 chunk 3) and
dispatches `match parse_network(net) { Mainnet => f::<MainnetV0>(..), Testnet =>
f::<TestnetV0>(..), _ => <fail-closed> }`. **Return shape is unchanged** for this PR
(`get_base_fee` → `u64`, `0` on failure incl. unknown network; the two `*mut c_char`
exports → `""` on failure) — Dart's existing `_require`/zero-fee checks already treat
those as errors. Converting these three to the envelope is a deferred consolidation,
not in PR4a (keeps the diff focused; one ABI-version bump still covers it later).

### 3.3 Activate the already-present (ignored) `_network` on authorize/build

These already carry an ignored `_network: *const c_char` (verified at
`lib.rs:468,499,533,564,585`). Wire it to the same `parse_network` + dispatch; no
signature change, no symbol-set change:

- `execution_authorization`
- `join_authorization`
- `upgrade_authorization`
- `build_upgrade_transaction_offline`
- `build_transaction_offline`

After this, the network ID embedded at authorize time matches the network the proof
is produced for — the precondition for testnet working end-to-end (today everything
is forced to `MainnetV0`, which silently mis-IDs a testnet tx).

### 3.4 Add `ffi_abi_version`

```rust
#[no_mangle]
pub extern "C" fn ffi_abi_version() -> u32 { 1 }
```

Bump on every future ABI change. Retroactively guards the PR-#51 `u64`-widening
drift (an older library lacks the symbol → the loader rejects it).

Dart typedef must mirror `u32` exactly — do **not** reuse the generic `ffi.Int`:

```dart
typedef _FfiAbiVersionNative = ffi.Uint32 Function();
typedef _FfiAbiVersionDart = int Function();
```

### 3.5 `parse_network` contract

A single helper: `"mainnet" → MainnetV0`, `"testnet" → TestnetV0`, anything else →
the export's fail-closed value (`""` / `0`) for the legacy-shaped exports, or
`unsupported_network` for the already-enveloped `_checked`/preflight exports (PR2,
unchanged). No clamping, no default-to-mainnet.

### 3.6 Symbol-set delta

`35 fns − 3 (deleted) + 1 (ffi_abi_version) = 33 fns + free_string = 34 symbols`.
Update `.github/workflows/rust.yml`: drop the 3 deleted, rename the 3 `_static`, add
`ffi_abi_version`, and the "(N functions + free_string)" echo.

## 4. Dart: validated loader / handle (round-1 F3)

Today `AleoAccount(dyLib, [network])`, `AleoRecord(dyLib, …)`, `AleoProgram(dyLib,
[network])` take a **bare untyped `DynamicLibrary`** — any caller passes any library
(arbitrary path / test override) straight to the FFI wrappers with no ABI check.

PR4a introduces one chokepoint that opens the library, calls `ffi_abi_version()`
once, and rejects a mismatch:

```dart
class AleoLib {
  final ffi.DynamicLibrary dyLib;
  AleoLib._(this.dyLib);

  static const int expectedAbiVersion = 1;

  /// Opens [path], validates the ABI version, returns a handle. Throws
  /// [IncompatibleNativeLibraryException] if the symbol is missing (pre-guard /
  /// stale library → ArgumentError on lookup) or the version differs.
  factory AleoLib.open(String path) { … }

  /// For an already-open library (e.g. DynamicLibrary.process() on iOS, or a
  /// test override via ALEO_NEW_LIB).
  factory AleoLib.fromDynamicLibrary(ffi.DynamicLibrary dyLib) { … }
}
```

- The three public classes' constructors take an `AleoLib` (breaking Dart API
  change — documented in the changelog). Internally they read `lib.dyLib`.
- A missing `ffi_abi_version` symbol surfaces as a clear thrown error, not a crash.

### 4.1 `DyLib` → `AleoLib` boundary (close the bypass)

The chokepoint is only real if **every** path that produces a library for the public
classes is validated. Today `DyLib.{getDyLibByPosition,getLocalDyLib,getDyLibFromCargo,
getDyLibFromGit}` each return a **bare `DynamicLibrary`** that callers hand straight to
the constructors. PR4a:

- Adds validated factories on `DyLib` (or a new `AleoLib`) that wrap each loader and
  return an `AleoLib` (open → `ffi_abi_version()` check → handle). These become the
  public way to get a library.
- Keeps the raw `DynamicLibrary`-returning loaders only as **internal/deprecated**
  (`@Deprecated`) helpers used by the validated factories — not as a public unguarded
  path. The public constructors no longer accept a bare `DynamicLibrary` at all (so
  there is no unvalidated bypass left to forget).
- Migrates `example/`, `test/support/test_dylib.dart`, and any in-repo callers to the
  `AleoLib` form. The CHANGELOG calls out the constructor signature break.

### 4.2 Test harness must not let the fallback mask the guard

`tryLoadAleoLib()` currently: `ALEO_NEW_LIB` (loud) → else `getDyLibFromCargo` →
`getDyLibFromGit` (a possibly-stale prebuilt) → `null` (suite skips). For ordinary
suites that fallback is fine, but the **ABI-guard tests must not depend on it** — a
stale-but-new-enough prebuilt, or a graceful skip, would hide a regression. PR4a:

- For the normal suite: build `AleoLib` from `ALEO_NEW_LIB` (CI sets it; loud on a
  bad path) so the guard runs against the freshly built library on every run.
- For the guard's negative cases, construct **explicit fixtures**, never the fallback:
  - *symbol absent* → open a library known to lack `ffi_abi_version` (a system
    library such as libc/libSystem, or a tiny purpose-built stub `.so`); the lookup
    throws `ArgumentError` → assert it maps to `IncompatibleNativeLibraryException`.
  - *version mismatch* → a test seam: the loader's version comparison takes the
    expected version as an injectable parameter (default `AleoLib.expectedAbiVersion`),
    so a test can assert a `2 != 1` mismatch throws before any business lookup without
    needing a second native build.

## 5. Dart: switch the public proving flow to the checked + provisioned path

The public `AleoProgram` flow currently calls the plain `_static` proving exports
directly (no envelope, no parameter provisioning → a cold cache **panics across the
C ABI**, the pre-existing latent bug). PR4a routes proving through
`ParameterProvisioner` (PR2) so the flow is: `parameter_preflight` → download →
`execute_*_checked` under the Contract-4 lock, with the `restart_required` latch
honored.

- `executeProof` / `executeFeeProof` / `executeProgramProof` → the
  `provisionAndProve*` entry points, threading `network` (already a constructor
  field, `programsRustFFI.network`).
- `getBaseFee` / `executionFeeAuthorization` / program authorization → the renamed
  `network`-aware symbols (§3.2), passing the program's network.
- The deleted `_static` proving bindings + their now-unused typedefs are removed
  from `programs_rust_ffi.dart`; the stale "rename deferred to phase 4" comment
  block (lines 39–48) is updated to reflect that PR4a did the rename.
- Public `AleoProgram` method signatures stay source-compatible where possible; any
  that must change (e.g. a result now coming from an envelope) are documented.

## 6. Test table (write first, per the churn lesson)

| Surface | Case | Expectation |
|---|---|---|
| `ffi_abi_version` | freshly built lib (`ALEO_NEW_LIB`), ==1 | loader returns handle |
| loader | symbol absent — fixture: system lib / stub `.so` (not the fallback) | `IncompatibleNativeLibraryException` |
| loader | version mismatch — test seam injects expected `2` | throws before any business lookup |
| `parse_network` | `"mainnet"` / `"testnet"` | correct monomorphization (compile + dispatch) |
| `parse_network` | unknown | `get_base_fee`→0; `execution_fee_authorization`→""; checked→`unsupported_network` |
| authorize/build | `network="testnet"` | tx carries the TestnetV0 network id (not mainnet) |
| symbol set | release cdylib `nm` | exactly the 34-symbol set |
| public flow | `executeProof` cold-cache (subprocess/temp dir) | preflight→download→checked, no abort |
| public flow | proving after latch tripped | fail-fast, no FFI call |

Rust unit tests: rename references; add `ffi_abi_version` test; both-network dispatch
for the renamed exports (TestnetV0 instantiation verified at compile/dispatch level —
live testnet proving still blocked on a tx-bearing testnet, as before).

## 7. Out of scope (later PRs)

- **PR4b**: `build_android.sh` (cd aleo_ffi, drop OPENSSL, 16K check fail-nonzero,
  jniLibs), iOS staticlib + xcframework script + dead-strip/nm docs, `dyLib.dart`
  Android/iOS branches + cargo path repoint, `setup_dylib.dart` (deprecate the dead
  pzhun/S3 path; no runtime download in v1), manifest-drift CI.
- **PR5**: delete GPL `rust/aleo_rust` + prebuilt binaries; `cargo-license` zero GPL;
  pub.dev dry-run.
- Enveloping `get_base_fee`/`execution_fee_authorization`/`program_authorization`
  (deferred consolidation).
- Live private/fee/program testnet end-to-end (blocked on a tx-bearing testnet).
