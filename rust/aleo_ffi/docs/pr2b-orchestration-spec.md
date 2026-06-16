# PR2 part 2b — Dart provisioning + checked-proving orchestration (spec)

> **Status:** spec for review — no code yet. **Base:** `epic/aleo-dart-monorepo` @
> `3cfe498` (PR2 part 2a). Companion: [`pr2a-preflight-spec.md`](./pr2a-preflight-spec.md),
> [`phase4-plan.md`](./phase4-plan.md) (§8 Contracts 1–4).
>
> Spec-first (the churn countermeasure): this pins the Contract 4 lock state machine,
> the envelope/latch contract, and the downloader BEFORE coding.

## 0. Scope

Dart-only (+ delete dead Rust-era download code). All **additive / tested via
`ALEO_NEW_LIB`**; the **public `AleoProgram` proving flow is NOT switched** to the
checked symbols here — that lands with redistribution in **PR4** (so there is no
"new Dart + old distributed lib" window). curl untouched (PR3).

In: (1) Dart FFI bindings for the 6 new symbols + a fail-closed envelope parser;
(2) the `restart_required` latch (§8 Contract 3, Dart side); (3) an atomic
single-flight downloader; (4) Contract 4 file-locking; (5) a new orchestration
entry `provisionAndProve…` exercised by tests; (6) delete the dead
`downloadProvingKey` + its dead S3 URL.

Out (→ PR4): switching `AleoProgram`'s public methods onto the checked symbols;
`ffi_abi_version` + validated loader; cross-compile/redistribution. Quota/eviction
(D2) is **not** implemented in 2b beyond the lock hooks — flagged as a follow-up.

## 1. FFI bindings + envelope parsing

New `programs_rust_ffi.dart` bindings (network-aware, envelope-returning, freed by
`free_string`):
`parameter_preflight(net, u16)`, `execute_proof_checked(net, auth, u32, paths, root)`,
`execute_fee_proof_checked(…)`, `execute_program_proof_checked(net, auth, sources, u32,
paths, root)`, `ffi_set_parameter_dir(path)`, `ffi_aleo_dir()`.

A single `Envelope.parse(String json)` helper — **fail-closed**: parse; if not an
object or `ok != true` → throw. `ok == false` with `code == "restart_required"` →
trip the latch (§2) then throw; other codes → `AleoNodeException`(code+message).
`ok == true` returns the payload (`data` or `missing`). Replaces `_require`'s
empty-check for the new exports (the old `_static` path keeps `_require` until PR4).

## 2. `restart_required` latch (Contract 3, Dart side)

A `static bool _provingDisabled`. On any envelope `restart_required`: set it, throw
`ProvingDisabledException`. Every checked-proving/preflight entry checks it first.

**Scope (corrected):** a Dart `static` is **isolate-local**, so this is a fast-path,
not the cross-isolate guarantee. The authoritative guard is the **Rust** side: every
checked export is `catch_unwind`-wrapped, so a fresh isolate that calls the
already-poisoned FFI gets `restart_required` back cheaply — a poisoned `lazy_static`
re-deref is an immediate caught panic, not a re-download — and self-latches.
Proving therefore never crashes and never silently succeeds after a poison, in any
isolate; the Dart latch only spares a long-lived isolate the (safe, cheap) repeat
FFI call. (A pid-keyed sentinel file was considered for a true cross-isolate latch
but rejected: pid reuse could falsely latch a healthy process, worse than the cheap
repeat call it saves.) Recovery still requires an **OS-process restart** (isolate
restart does not clear the poisoned static); mobile surfaces "restart app".

## 3. Atomic single-flight downloader

dio + `CancelToken`. Per url: a **connect timeout** (30s — a hung DNS/TCP on the
primary fails over to the mirror), a **receive** between-chunks inactivity timeout
(30min), and an **overall per-url wall-clock deadline** (`_perUrlDeadline`, default
30min, constructor-overridable — a `Timer` that cancels the token, catching a
steady-but-slow stream that never goes idle). For each `missing`
entry, under its single-flight lock (§4): re-check size+SHA-256 (another flight may
have finished it); else, for each url in turn, download into `<final>.<rand>.tmp`
(`size` as a hard cap via `onReceiveProgress`), **verify size + SHA-256 — on failure
fall back to the next url** (so a corrupt HTTP-200 from the primary tries the
mirror); then atomic `rename` to `relativePath`. *(Durability note: just `rename`,
no explicit `fsync`; a crash mid-write is caught by the next run's preflight
checksum, which re-downloads.)*

Download UX (D2: Wi-Fi-only default, public progress callback, resume) — **out of
scope in 2b**; only the internal size-cap `onReceiveProgress` exists. A public
progress callback + Wi-Fi gating + resume is a follow-up, called out so it is not
forgotten.

## 4. Contract 4 file-locking (the hard part)

Primitive: `dart:io` `RandomAccessFile.lock(FileLock.shared|exclusive)` (advisory;
POSIX flock/fcntl, Windows LockFileEx; auto-released on close/exit). No FFI, no extra
package.

- **Per-file single-flight (download):** TWO layers, because `RandomAccessFile.lock`
  is POSIX `fcntl` — it coordinates **across processes** but a process never
  conflicts with its **own** locks (and isolates don't share statics anyway):
  - an **in-process** async mutex keyed by `relativePath` (a static `Map<String,
    Future>`), serializing same-isolate concurrent provisions; and
  - inside it, an **exclusive** flock on the stable file
    `<param-dir>/.locks/files/<sha256(relativePath)>.lock` (never renamed, so the
    lock is not tied to the `.tmp` inode), for cross-process/isolate single-flight.
  The holder re-checks size+SHA-256 first (a prior flight may have finished it), then
  downloads to `<file>.<rand>.tmp` → verify → atomic `rename`. *(Found by the
  single-flight test: the flock alone let two same-isolate downloads both run.)*
  **Documented gap:** two isolates of the SAME process are coordinated by neither
  layer (the map is isolate-local; fcntl doesn't conflict intra-process), so both
  could download one file — only wasted bandwidth, since each verifies + atomically
  renames. Dart has no intra-process cross-isolate file lock; closing it needs
  explicit isolate coordination (out of scope).
- **Download verification is inside the url loop:** a url whose body fails
  size/SHA-256 falls back to the next url (like a connection error), so a corrupt
  HTTP-200 from the primary CDN tries the mirror instead of failing the provision.
- **Per-network tier (prove):** after all `missing` are downloaded, take a **shared**
  lock on `<param-dir>/.locks/<network>.lock`, **re-run `parameter_preflight` under
  the lock** (closes the TOCTOU: nothing was evicted between download and prove),
  then call `execute_*_checked` and hold the shared lock across the **entire** FFI
  prove call; release after. Multiple proves run concurrently (shared).
- **Eviction (future):** would take the **exclusive** tier lock; not implemented in
  2b, but the lock layout reserves it so eviction can't run while a prove holds shared.
- Lock files live under the (set-once) param dir, created with the dir.

## 5. Orchestration (new, test-only until PR4)

`Future<String> provisionAndProve({network, consensusVersion, authorization, height,
statePaths, publicStateRoot, programSources?})`:
1. latch check (§2);
2. `ffi_set_parameter_dir(dir)` once (mobile sandbox; desktop default);
3. `parameter_preflight` → if `missing` non-empty, download each (locked, §3/§4);
4. take shared tier lock → re-preflight (must now be empty, else
   `AleoNodeException`) → `execute_*_checked` → release;
5. return the proof (`data`), or throw per the envelope.
All three are implemented: `provisionAndProveExecution`, `provisionAndProveFee`,
`provisionAndProveProgram` (the program one takes `programSources`; v1 rejects a
non-empty/custom closure with `unsupported_feature`). These are NEW methods;
`AleoProgram`'s existing public methods are untouched (PR4 switches them). The Dio is
caller-owned when injected (`close()` only closes an internally-created client).

## 6. Delete dead code
Remove `downloadProvingKey` + the hardcoded `s3-us-west-1…/inclusion.prover.cd85cc5`
URL + the now-unused `downloadFile` (grep-confirm no other caller) from
`aleo_programs.dart`. (The `setup_dylib.dart` `pzhun` / `dyLib.dart` GPL pointers are
PR4 / workstream D — not here.)

## 7. Tests (offline / `ALEO_NEW_LIB`, like `aleo_node_test`) — as implemented
- Envelope parser: ok / error / `restart_required`→latch; non-JSON→throw.
- Downloader vs a local `dart:io` `HttpServer`: download+verify+atomic rename; url[0]→
  url[1] fallback (incl. a corrupt HTTP-200 primary → verified mirror); wrong-checksum
  rejection; **single-flight** (two concurrent same-isolate downloaders → one download).
- Preflight (FFI): empty dir → 16 missing/absent; unknown network; unsupported
  consensus; `execute_program_proof_checked` binding (custom sources →
  `unsupported_feature`); `provisionAndProveProgram` rejects custom sources before any
  provisioning (no dir touched).
- **Not unit-tested (documented):** the per-network **tier-lock** behavior across
  concurrent *proves* — that path needs a real prove (real params), so it is covered
  by the cold-cache E2E below, not an offline test. The lock primitive is `dart:io`
  `RandomAccessFile.lock`; the exclusive flock is exercised by the single-flight test.
- **Cold-cache E2E (manual; needs ~1.2 GiB + a real node):** isolated temp param dir,
  download the 16 real files via the manifest, run a real credits prove → success.
  The definitive "16 files sufficient" check (spec 2a §7) and the only real exercise
  of the prove path + tier lock.

## 8. Open decisions (review before I code)
1. **Split 2b?** It is large (bindings+latch / downloader / locking / orchestration).
   Option: 2b-1 = bindings + envelope + latch + downloader (additive, no locking);
   2b-2 = Contract 4 locking + orchestration + E2E. Lean: **one PR** (the pieces are
   tightly coupled and only meaningful together), but I can split if you prefer.
2. **Download UX in 2b:** minimal (progress hook + resume-friendly tmp/rename) vs full
   D2 (Wi-Fi-only gating, resume, cellular opt-in). Lean: **minimal now**, full UX a
   follow-up — the wallet app owns the network-policy UI anyway.
3. **Eviction/quota (D2):** lock layout reserved; implementation deferred. OK?
4. **Lock primitive:** `RandomAccessFile.lock` (confirmed in `dart:io`). Agreed?
