# Aleo FFI — Phase 4 Execution Plan

> **Status:** plan only — **no code has been implemented yet.** This document is the
> design of record after 8 external review rounds. PR1 (workstream B) is ready to start;
> PR2 depends on the four contracts in §8.
>
> **Repo:** `fx-wallet-packages` · **Base:** `origin/epic/aleo-dart-monorepo` @ `e1c771c`
> (Phase 3 squash tip) · **Branch:** `feature/aleo-io-dart-phase4`
>
> Companion: [`network-io-to-dart.md`](./network-io-to-dart.md) (Phases 1–3, the I/O→Dart migration).

## 1. Background & objective

`aleo_ffi` is an Apache-2.0, clean-room FFI layer over **snarkVM 4.5.0**, replacing a GPL-3.0
Aleo SDK fork (`rust/aleo_rust`). Phases 1–3 moved **all node HTTP I/O out of Rust into a Dart
`AleoNode`** and deleted the in-Rust RPC code. The Rust side is now "no node RPC" — but **not
"no HTTP stack"**, and the mobile build still carries OpenSSL.

**Phase 4 goal:** turn "no node RPC" into **"no HTTP stack"** + a **no-OpenSSL**
iOS/Android/desktop cross-compile + **delete the GPL crate**. Clear three deferred items:

- **(A)** `snarkvm-parameters` downloads proving keys via `curl` → drags in `openssl-sys`.
- **(B)** A transitive `ureq` (rustls) arrives via `snarkvm-ledger-query`'s `query` feature.
- **(C)** The `_static`-suffixed exports were never renamed to canonical names, and there is no
  load-time ABI guard.

Then **(D)** cross-compile, fix stale download pointers, delete GPL, publish.

Vendoring precedent: `rust/vendor/snarkvm-synthesizer-4.5.0` is a verbatim crates.io copy + a
2-line `expose-raw.patch`, consumed via `[patch.crates-io]`. Workstreams A and B reuse this.

**v1 scope:** credits proving only, **network-aware** (mainnet + testnet). Custom/non-credits
programs return `unsupported_feature` (a documented breaking change to the already-public
`executeProgram` / `contractExecution` / `execute_program_proof_static` surface).

## 2. Verified ground truth (re-checked on `e1c771c` + snarkVM 4.5.0)

| # | Fact | Source |
|---|------|--------|
| 1 | `openssl-sys ← curl ← snarkvm-parameters` single chain (also `curl-sys`); curl is an unconditional native dep. | `cargo tree -i openssl-sys` |
| 2 | Download macro: native curl vs `RemoteFetchDisabled` under `cfg(filesystem, not wasm)`; `filesystem` enabled here. | `snarkvm-parameters/src/macros.rs` |
| 3 | Param load **panics** on missing/corrupt (`.expect`); the 3 proving FFI have no `catch_unwind`. | `snarkvm-synthesizer-process/src/trace/mod.rs:353` |
| 4 | Param statics **poison** on failed load: `INCLUSION_PROVING_KEY` and the credits map are `lazy_static!` (built on `Once::call_once`, which poisons). In-process retry can't recover. | `snarkvm-parameters/src/mainnet/mod.rs:241`, `mainnet_v0.rs:84`, `lazy_static/inline_lazy.rs:30` |
| 5 | A loaded native lib + its process-global Rust statics are shared by all Dart isolates → only an **OS-process** restart resets them. | Dart FFI semantics |
| 6 | **Base SRS is `impl_local!`/`include_bytes!` — compiled into the lib**, not downloaded (`mainnet/mod.rs:29,53,54,72,74,76`); can't be missing → **NOT a provisioning item**. | source read |
| 7 | **No higher-degree SRS for credits**: pre-generated credits proving keys bundle the `committer_key` (`varuna.rs:128,270` — `prove` uses `proving_key.committer_key`, not `download_powers_for`). | source read |
| 8 | Proving calls only `get_credits_proving_key` (`stack/mod.rs:386`); `get_credits_v0_proving_key` has no caller → `credits_v0` proving keys (~0.92 GB) are never used. | source read |
| 9 | Credits keys load as a whole set (`CREDITS_PROVING_KEYS` `lazy_static! IndexMap` via `insert_credit_keys!`) → a network's full `credits` set is an **atomic unit**. | `mainnet_v0.rs:73-93` |
| 10 | **Base SRS is shared across networks**: `testnet_v0.rs:350` `varuna_universal_prover()` delegates to `MainnetV0::...` → no SRS duplication when both networks are compiled in. | source read |
| 11 | Official param URLs: `https://parameters.provable.com/{mainnet,testnet}` + `https://s3.us-west-1.amazonaws.com/{network}.parameters` mirror; files at `resources/<name>`. | `mainnet/mod.rs:25`, `testnet/mod.rs:22` |
| 12 | `aleo_dir()` = `home_dir() + "/.aleo"`, **no `ALEO_HOME`/env override**; reads happen inside `snarkvm-parameters`. | `aleo-std-storage 1.0.3 src/lib.rs:92` |
| 13 | `ureq ← snarkvm-ledger-query` single chain; only `query/rest.rs` uses it; `aleo_ffi` only calls `StaticQuery::new`. Removal blast radius is clean (nothing else references `RestQuery`/`Query::REST`). | `cargo tree -i ureq`; grep |
| 14 | **`type Net = MainnetV0` is hard-coded** (`aleo_ffi/src/lib.rs:38`); proving exports have **no** network param, but **authorize/build/fee exports already carry an (ignored) `_network: *const c_char`** (`lib.rs:468,499,533,564,585`). | source read |
| 15 | Wrappers take a bare untyped `dyLib`; crate-type `cdylib`+`rlib`; **no Android loading path** (`DyLib`/`setup_dylib.dart` branch only Linux/macOS/Windows); `_require` rejects only empty (`aleo_programs.dart:667-672`); CI asserts an exact 29-fn+`free_string` set. | source read |
| 16 | Stale/GPL pointers: `dyLib.dart:4`, `setup_dylib.dart:9` (no integrity check), `aleo_programs.dart:674` (dead S3), `build_android.sh:10,42`. | source read |

## 3. Workstreams

### A — Kill the snarkvm-parameters curl/OpenSSL download
Vendor `snarkvm-parameters 4.5.0` verbatim + `.patch` + README. Patch: (i) native branch
(`macros.rs:197`) → `RemoteFetchDisabled`; delete the `curl::easy` `remote_fetch` impl + the
`curl` target-dep; (ii) **own the param-dir state here** (Contract 2). Add `[patch.crates-io]`.
**Verify:** `cargo tree -i openssl-sys`/`-i curl-sys` empty; `cargo build --release`; `cargo test --lib`.

### B — Drop the transitive ureq
Vendor `snarkvm-ledger-query 4.5.0` + split-feature patch: `rest = ["query", "dep:ureq"]`
(must imply `query`); `#[cfg(feature="rest")]`-gate `mod rest` / `pub use rest::*` /
`use ureq::http` / `Query::REST` / `From<http::Uri>` / the REST `FromStr` branch / REST match
arms. `default = ["query"]` (no `rest`, no `async`). `aleo_ffi` depends with
`default-features = false, features = ["query"]`.
**Verify:** `cargo tree -i ureq`/`-i rustls` empty; default build pulls **neither `ureq` nor
`reqwest`**; query-only (no-ureq) + `rest`-on compile tests. Zero behavior change.

> A + B = "no HTTP stack"; confirm via `cargo-license` / `cargo tree`.

### C — `_static`→canonical rename + `ffi_abi_version` + validated loader (ABI-critical; PR4)
Rename the 6 `_static` exports to canonical; **delete the old plain proving exports** (superseded
by PR2's enveloped ones); **activate `_network` honoring on the authorize/build/fee chain**; add
`ffi_abi_version() -> u32` (bump on every ABI change; retroactively guards the PR-#51 `u64`
drift). Dart: a single **validated loader/handle** that calls `ffi_abi_version()` once — the
wrappers no longer accept a bare `DynamicLibrary`; switch the public flow to the network-aware
checked symbols. **Land only in lockstep with a redistributed lib.** Tests: Phase-3 lib →
"incompatible library"; correct lib → ok; wrong version → fail before the first business lookup.

### D — Cross-compile + distribution + integrity + delete GPL
- `build_android.sh`: `cd aleo_rust`→`aleo_ffi`; drop `OPENSSL_BASE_PATH`; keep cargo-ndk targets
  + 16K `RUSTFLAGS`; **make the `readelf` 16K-alignment check exit non-zero on failure**.
- **iOS:** add `staticlib` to crate-type; build an **xcframework** (device + simulator); load via
  `DynamicLibrary.process()`; **dead-strip guard** (`-force_load` / `-exported_symbols_list`) +
  an **`nm` check on the final app binary** (not just the `.a`/xcframework). Script in this repo;
  the app repo applies `-force_load` + integration + device smoke.
- **Android:** **build-time bundle** the per-ABI `.so` into `jniLibs` (loaded via
  `DynamicLibrary.open('libaleo_rust.so')`). No runtime `.so` download.
- **Desktop host:** runtime download via `setup_dylib.dart` (CI + local `dart test`).
- **Lib integrity:** an **in-package** pinned SHA-256 constant (or embedded-public-key signature)
  verifies the downloaded archive; temp file + atomic replace. (A same-origin manifest is not an
  anchor.)
- **Repoint** `dyLib.dart` `CARGO_*` + `setup_dylib.dart` `BASE_URL`/`VERSION` → `aleo_ffi`
  artifacts (`[lib] name` stays `aleo_rust`).
- **Delete GPL** (gated on the app building+running on the new lib): remove `rust/aleo_rust` +
  prebuilt GPL binaries; keep `rust/vendor`; `cargo-license` zero GPL; pub.dev dry-run.

**Network-aware (single lib, runtime dispatch).** Every network-typed export takes a `network`
string (`"mainnet"|"testnet"`); internally `match net { Mainnet => f::<MainnetV0>(..),
Testnet => f::<TestnetV0>(..) }`; unknown → `unsupported_network`. Both monomorphizations compile
in (base SRS shared, #10). The `_network` slot already exists on authorize/build/fee (#14) —
honoring it activates in PR4; the new checked proving + preflight symbols are network-aware from
PR2. Chosen over two per-network libs because on iOS two staticlibs export the same symbol names
→ linker collision.

| Platform | Native lib | Proving params |
|---|---|---|
| iOS | staticlib in xcframework, build-time link (`process()`) | runtime Dart download into the param dir |
| Android | per-ABI `.so` in `jniLibs`, build-time bundle | runtime Dart download into the param dir |
| Desktop host | runtime download (`setup_dylib.dart`, integrity-anchored) | runtime Dart download into the param dir |

## 4. Parameter provisioning (v1: credits-only, two-network, static set)

Params **panic → poison** on missing/corrupt (#3, #4); recovery needs an **OS-process** restart
(#5). For each `{network, consensusVersion ∈ that network's V8..=V13}` the required set is
**static**: the current `credits` proving-key set (incl. inclusion at that consensus version).
**No** base SRS (#6, baked into the lib), **no** higher-degree SRS (#7), **no** `credits_v0` (#8).

1. **`parameter_preflight(network, consensus_version)`** verifies the fixed set's
   **existence + checksum** (reads embedded `.metadata` only; no key deserialization → cannot
   panic). Returns `missing[]` of `{relativePath, url, size, checksum}`.
2. **Run preflight before every proof.** The verified-file cache (4.3) makes the warm path a
   cheap `stat`; completion is cached per `{network, consensusVersion}`.
3. **Verified-file cache:** key = `path + size + mtime`; full SHA-256 only on first provisioning /
   size-or-mtime change. *Residual:* a size+mtime-preserving offline swap escapes the cache
   (conscious trade-off).
4. **Custom/non-credits → `unsupported_feature`** at the FFI boundary, enforced in **all three**
   checked proving exports (§8 Contract 3). `download_powers_for` is therefore never called → no
   degree ceiling, no `unsupported_degree`/`missing_srs` distinction.
5. **Manifest** is build-time generated from the vendored `.metadata` + `REMOTE_URLS`, **per
   network**; a CI drift check regenerates and diffs it (asserts network/consensus coverage).
6. **Param-dir control** is owned by the vendored crate (§8 Contract 2); the cold-cache E2E uses
   a temp dir, never the real `~/.aleo`.
7. **Panic → `restart_required`** (§8 Contract 3); **concurrency/locking** (§8 Contract 4).

## 5. FFI result envelope

See §8 Contract 1 for the exact tagged, fail-closed JSON schemas and the uniform `catch_unwind`
wrapper. `_require`'s empty-string check is replaced by envelope parsing (anything not explicitly
`ok:true` throws).

## 6. ABI / trust-boundary / failure matrix

| Boundary | Risk | Guard | Verify |
|---|---|---|---|
| Param absent/corrupt | load **panics** + **poisons** process-global statics (isolate-shared) | preflight every proof; `catch_unwind` → `restart_required`; Dart latch + user "restart app" + fail-fast | subprocess: missing/corrupt → `restart_required`, no abort; retry-after-panic still fails; latch blocks proving |
| Error mistaken for success | non-empty error string read as a proof | fail-closed envelope; Dart throws on not-`ok:true` | envelope-branch unit tests |
| Preflight→load TOCTOU | concurrent eviction deletes a file in use | download → acquire shared tier lock → **re-preflight under lock** → prove; eviction needs the exclusive lock | evict-during-prove cannot remove a pinned file |
| Wrong network | testnet tx proven as Mainnet (wrong network ID) | `network` arg + dispatch; unknown → `unsupported_network` | prove on each network → correct network ID |
| Custom program (credits-only) | silent break of a public API | `unsupported_feature` in all 3 checked exports; documented breaking change | custom-program authorization → `unsupported_feature` |
| PR2 pre-guard semantics | old Dart + PR2 lib misreads | new enveloped symbols; public switch deferred to PR4; capability detection throws | symbol-set diff per PR; old lib → clear error |
| C freed-name reuse | stale lib + new Dart mis-bind | `ffi_abi_version` + validated loader + lockstep redistribution | Phase-3 lib + new Dart → clean "incompatible" |
| Lib substitution | tampered native lib | in-package pinned digest/signature + atomic replace | corrupt artifact → rejected before load |
| iOS staticlib | linker dead-strips FFI exports | `-force_load`/`-exported_symbols_list` + `nm` on the final app binary | symbol present in the app binary |
| Android | no runtime `.so` path | `jniLibs` build-time bundle | device loads `libaleo_rust.so` |
| Vendored / manifest drift | version skew | pin `=4.5.0` verbatim; CI regen + diff | single-version resolve / CI |
| GPL delete | app still needs the crate | gate on app verified; keep `rust/vendor` | `cargo-license` zero GPL |

## 7. Locked D2 (v1, two-network)

- **Scope:** credits proving, **mainnet + testnet** (network-aware). Custom/non-credits →
  `unsupported_feature` (breaking change, documented).
- **Hosting — params:** primary `https://parameters.provable.com/{network}`, fallback
  `https://s3.us-west-1.amazonaws.com/{network}.parameters`; files at `resources/<name>`. **No
  self-hosting of params.**
- **Hosting — native lib:** GitHub Releases of `fxwalletOfficial/fx-wallet-packages`; integrity
  via an **in-package pinned SHA-256 constant** over the release archive.
- **Per-network static manifest:** the current `credits` proving-key set (incl. inclusion at the
  network's consensus version). **Excluded:** base SRS (baked in), higher-degree SRS, `credits_v0`,
  verifying keys (embedded).
- **Sizes:** mainnet ≈ **1.154 GiB**, testnet ≈ **1.372 GiB**. **Quota: 2 GiB per network**
  (≤ ~4 GiB if both are used).
- **Consensus:** detect the version from the node height, **strictly** validate against the
  network's `V8..=V13` (no clamp); outside the range → `unsupported_consensus`. Never download
  `credits_v0`.
- **Param dir:** mobile = app sandbox subdir set via `ffi_set_parameter_dir` (snarkVM
  `resources/...` underneath); desktop = `aleo_dir()` default.
- **Concurrency:** tier = the per-network set; lock file `<param-dir>/.locks/<network>.lock`;
  details in §8 Contract 4.
- **Download UX:** first-use confirmation (~1.2 GiB); progress; resumable; **default Wi-Fi-only**
  with a temporary cellular opt-in.

## 8. Pre-PR2 contracts (precise; finalized after review round 8)

**Network arg convention:** a NUL-terminated string `"mainnet" | "testnet"` (matches the existing
`_network: *const c_char`, #14). Dispatch: `match parse_network(network)? { Mainnet =>
f::<MainnetV0>(..), Testnet => f::<TestnetV0>(..) }`; unparseable → envelope `unsupported_network`.

### Contract 1 — Result envelope + uniform no-unwind wrapper
Every PR2-new export returns a NUL-terminated **JSON envelope** (`*mut c_char`, freed by
`free_string`), produced through one wrapper:

```rust
fn ffi_envelope(f: impl FnOnce() -> Envelope + UnwindSafe) -> *mut c_char {
    let env = std::panic::catch_unwind(f)
        .unwrap_or_else(|_| Envelope::err("restart_required", "panic during FFI call"));
    to_cstring(env.to_json())  // to_json is infallible; const fallback string on any serialize error
}
```

`[profile.release] panic = "unwind"` (so `catch_unwind` works). Schemas:

```jsonc
parameter_preflight  : {"ok":true,"missing":[{"relativePath","url","size","checksum"}]}
                     | {"ok":false,"code":"preflight_error|unsupported_network|restart_required","message"}
execute_*_checked    : {"ok":true,"data":"<serialized execution|fee>"}
                     | {"ok":false,"code":"unsupported_feature|unsupported_consensus|unsupported_network|invalid_input|restart_required","message"}
ffi_set_parameter_dir: {"ok":true} | {"ok":false,"code":"param_dir_locked|invalid_path|restart_required","message"}
ffi_aleo_dir         : {"ok":true,"data":"<path>"} | {"ok":false,"code":"restart_required","message"}
```

**Dart:** parse the envelope; anything not explicitly `ok:true` (empty / unparseable / unknown
code) → **throw** (replaces `_require`'s empty-check).

New PR2 symbols (network-aware where typed):

```c
char* parameter_preflight(const char* network, uint16_t consensus_version);
char* execute_proof_checked(const char* network, const char* authorization, uint32_t height,
                            const char* state_paths_json, const char* public_state_root);
char* execute_fee_proof_checked(const char* network, const char* authorization, uint32_t height,
                                const char* state_paths_json, const char* public_state_root);
char* execute_program_proof_checked(const char* network, const char* authorization,
                                    const char* program_sources_json, uint32_t height,
                                    const char* state_paths_json, const char* public_state_root);
char* ffi_set_parameter_dir(const char* path);   // network-independent
char* ffi_aleo_dir(void);                          // network-independent
```

### Contract 2 — param-dir state owned by the vendored snarkvm-parameters
The param reads happen inside `snarkvm-parameters`, so the **vendored crate** owns the state
(not the `aleo_ffi` FFI layer):

```rust
static PARAM_DIR: OnceLock<PathBuf> = OnceLock::new();
static LOAD_STARTED: AtomicBool = AtomicBool::new(false);

pub fn set_parameter_dir(path: &Path) -> Result<(), ParamDirError> {
    if path.as_os_str().is_empty() { return Err(ParamDirError::InvalidPath); }
    fs::create_dir_all(path).map_err(|_| ParamDirError::InvalidPath)?;
    let canon = path.canonicalize().map_err(|_| ParamDirError::InvalidPath)?; // resolves symlinks
    match PARAM_DIR.get() {
        Some(d) if *d == canon => Ok(()),                                  // idempotent
        Some(_) => Err(ParamDirError::Locked),
        None if LOAD_STARTED.load(Acquire) => Err(ParamDirError::Locked),  // already loading from default
        None => match PARAM_DIR.set(canon.clone()) {                       // round-8 F2: handle the race
            Ok(()) => Ok(()),
            Err(_) => if PARAM_DIR.get() == Some(&canon) { Ok(()) } else { Err(ParamDirError::Locked) },
        },
    }
}

pub fn effective_parameter_dir() -> PathBuf {
    PARAM_DIR.get().cloned().unwrap_or_else(aleo_std::aleo_dir)
}
```

The download macro uses `effective_parameter_dir()` (not `aleo_dir()`) and sets
`LOAD_STARTED = true` on the first read. `aleo_ffi`: `ffi_set_parameter_dir` → `set_parameter_dir`
(map `Locked → param_dir_locked`, `InvalidPath → invalid_path`); `ffi_aleo_dir` →
`effective_parameter_dir`. **Multi-dir tests use separate subprocesses.**

*Permissions (round-8 F5):* params are **public proving keys (not secrets)**, so `0700` is
optional hardening, not security-critical — the contract uses default perms (no `0700` claim). If
`0700` is later wanted, set it explicitly with `fs::set_permissions(.., from_mode(0o700))` on the
dirs we create (unix only).

### Contract 3 — panic / recovery + credits-only enforcement
- **Anticipated errors are typed envelope codes, never panics:** `invalid_input` (bad args/JSON),
  `unsupported_feature` (custom program), `unsupported_network`, `unsupported_consensus` (outside
  the network's `V8..=V13`), preflight `missing[]`.
- **Any unwindable panic → `restart_required`** (incl. a re-panic from a poisoned `lazy_static`).
  No `panic` code. OOM / `abort` / double-panic are uncatchable.
- **Dart:** on `restart_required`, set a process-global **`provingDisabled` latch**, surface
  "please restart the app", and **fail-fast all subsequent proving without calling the FFI**
  (OS-process restart required; isolate restart insufficient, #5).
- **Credits-only enforcement (round-8 F3):** **all three** `execute_*_checked` exports parse the
  authorization and verify that **every** execution request's `program_id` equals the network's
  `credits.aleo` (reuse the existing `required_commitments` authorization walk); any non-credits
  request (or a non-empty / non-credits `program_sources` for `execute_program_proof_checked`) →
  `unsupported_feature` **before** entering proving.

### Contract 4 — concurrency / locking
- **Tier** = a network's full credits+inclusion set (atomic, #9). **Lock file:**
  `<param-dir>/.locks/<network>.lock` (advisory flock).
- **Download single-flight (round-8 F4):** lock a **stable** lock file
  `<param-dir>/.locks/files/<path-hash>.lock` (never renamed) — **not** the `.tmp`, whose inode
  detaches on rename; write a unique `<file>.<rand>.tmp` → fsync → atomic `rename` into place.
- **Proving (round-8 F1):** download missing → acquire a **shared** flock on `<network>.lock` →
  **re-run preflight under the lock** → prove (hold the shared lock across the entire
  `execute_*_checked` call) → release. The in-lock re-preflight closes the TOCTOU window.
- **Cleanup/eviction:** **exclusive** flock on `<network>.lock`; evict only idle/unpinned tiers;
  it cannot run while a shared holder is proving.

## 9. PR sequence

```
PR1  B — split rest feature; default no ureq/reqwest; compile tests        (symbols unchanged)
         depends on none of the contracts; zero behavior change → ready first.

PR2  Param provisioning (ADDITIVE; curl STILL ON; NEW network-aware symbols only):
       PRE: §8 Contracts 1–4
       + vendor snarkvm-parameters (own the param-dir state; curl NOT yet removed)
       + new symbols (Contract 1) under one catch_unwind wrapper; both Mainnet/Testnet
         monomorphizations + dispatch; credits-only enforced in all 3 checked exports
       + static per-network manifest generator + atomic downloader (stable-lockfile single-flight)
         + verified-file cache
       + Dart bindings + orchestration tested via ALEO_NEW_LIB (both networks); public flow NOT switched
       + tests: subprocess no-abort, retry-after-panic-still-fails, latch-blocks-proving,
                envelope fail-closed branches, evict-cannot-remove-pinned,
                unsupported_feature / unsupported_network / unsupported_consensus
       (old _static + authorize `_network` behavior UNCHANGED; symbols 29 → ~35; update rust.yml)

PR3  A (atomic) — native branch → RemoteFetchDisabled + drop curl dep → openssl/curl gone
       + wire the Dart preflight→download→prove flow; isolated cold-cache E2E (temp dir; both networks)
                                                                        → cargo tree -i openssl-sys empty

PR4  C + build/distribute (LOCKSTEP) — rename _static→canonical; DELETE old plain proving exports;
       activate `_network` honoring on authorize/build/fee; ffi_abi_version; validated loader;
       switch the public Dart flow to the network-aware checked symbols;
       cross-compile android(16K nonzero, jniLibs) / ios(staticlib+xcframework+process()+dead-strip+nm)
         / desktop host; in-package pinned SHA-256 + atomic replace; manifest drift CI;
       repoint dyLib/setup_dylib/build_android; update rust.yml exact set.

PR5  Delete GPL (after app device verification) — remove rust/aleo_rust + prebuilt binaries;
       cargo-license zero GPL; pub.dev dry-run.
```

The `rust.yml` exact-symbol set is updated in every symbol-changing PR (PR2, PR4). PR2/PR3 are
purely additive (new symbols only) and tested via `ALEO_NEW_LIB`, so there is no "new Dart + old
distributed lib" broken window — the public flow switches with redistribution in PR4.

## 10. Review history (all findings verified against source)

- **R1:** param protocol; curl-before-provisioning; bare-`DynamicLibrary`; iOS form; lib
  integrity; 16K check; `rest` feature.
- **R2:** downcast unworkable (load panics) → preflight; multi-GB manifest → D2; `ALEO_HOME` not
  honored → `ffi_set_parameter_dir`; Android no path → `jniLibs`; co-hosted manifest → in-package
  anchor; D1 not pure scope; staticlib dead-strip.
- **R3:** fail-open returns → envelope; over-degree at preflight → option (b); set-once;
  verified-file cache; [round-3 "no poison" claim — overturned in R4]; `catch_unwind` wording;
  manifest CI drift check.
- **R4:** param statics **do** poison → `restart_required`; preflight every proof; new enveloped
  symbols; dir error contract; `unsupported_degree` not directly mappable.
- **R5:** isolate restart insufficient → OS-process restart + latch; all panics → `restart_required`;
  dir state owned by the vendored crate; TOCTOU → pin + locks; uniform wrapper;
  create-then-canonicalize.
- **R6:** varuna stringifies → drop `unsupported_degree` (collapse to `missing_srs`); `credits_v0`
  unused → drop (~0.92 GB); lock lifetime spans proving; PR2 stale-lib → defer the public switch;
  D2 must be concrete.
- **R7:** **base SRS is `impl_local` → removed from the manifest** (corrected a round-6 claim);
  `type Net = MainnetV0` hard-coded → network decision; strict consensus (no clamp); PR2 public
  switch → PR4; sizes 1.154 / 1.372 GiB.
- **R8:** shared lock too late (TOCTOU) → lock then re-preflight; `set_parameter_dir` race →
  re-read on `set` failure; credits-only enforced in **all 3** checked proving exports; don't lock
  the `.tmp` → stable lock file; `create_dir_all` ≠ `0700` → params are public, drop the claim.

**Decisions:** D1 = credits-only (custom → `unsupported_feature`, breaking). D2 = locked (§7).
Network = mainnet+testnet → network-aware single-lib runtime dispatch. D3 = iOS `staticlib` +
xcframework + `DynamicLibrary.process()`.

## 11. Build environment (reproduction)

`PATH="$HOME/.cargo/bin:$PATH"` · Rust toolchain pinned `1.96.0` (`rust/rust-toolchain.toml`) ·
Flutter/Dart at `/Users/workerpei/development/flutter/bin` · `ALEO_NEW_LIB=<built cdylib>` for
`dart test`. The test account holds ~14.45 public testnet credits; live private/fee/program e2e
remains blocked on a testnet that includes user txs (offline-authorize + public-transfer paths
are proven end-to-end).
