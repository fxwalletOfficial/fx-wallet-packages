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

dio + `CancelToken` (the existing `AleoNode` lifecycle: overall deadline, bounded
retries, real socket abort). For each `missing` entry:
1. acquire the file's single-flight lock (§4);
2. **re-stat** (another flight may have finished it) — if now present+correct, done;
3. download `urls[0]` (fall back to `urls[1]`) into `<final>.<rand>.tmp`, enforcing
   `size` as a hard cap (abort+delete on overrun);
4. verify SHA-256 == `checksum` (defensive; Rust preflight re-checks too);
5. `flush`/`fsync` → atomic `rename` to the final `relativePath`;
6. release the lock.
Download UX (D2: Wi-Fi-only default, progress, resume) — **minimal in 2b** (a
progress callback hook + the resume-friendly tmp+rename); full Wi-Fi-gating/resume
policy is a thin follow-up, called out so it is not forgotten.

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

## 7. Tests (offline / `ALEO_NEW_LIB`, like `aleo_node_test`)
- Envelope parser: ok/missing/error/`restart_required`→latch; non-JSON→throw.
- Latch: after `restart_required`, the next call fail-fasts without FFI.
- Downloader vs a local `dart:io` `HttpServer`: atomic rename; size-cap abort; url[0]→
  url[1] fallback; **single-flight** (two concurrent downloaders of the same file —
  one downloads, one waits then sees it present).
- Lock: concurrent `provisionAndProve` (shared tier lock lets both prove; an
  exclusive holder blocks).
- **Cold-cache E2E (`#[ignore]`/manual):** isolated temp param dir, download the 16
  real files via the manifest, run a real credits prove → success. The definitive
  "16 files sufficient" check (spec 2a §7); manual (needs ~1.2 GiB + a real node).

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
