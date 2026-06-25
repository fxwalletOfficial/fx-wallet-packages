# PR2 part 2a — `parameter_preflight` + manifest (implementation spec)

> **Status:** approved, implementing. **Base:** `epic/aleo-dart-monorepo` @ `41af617`.
> Companion: [`phase4-plan.md`](./phase4-plan.md). Revised after one external review
> round (FFI ownership, manifest source, JSON schema, testnet semantics, the SRS
> completeness risk, cache key).

## 0. Scope

**In:** the `parameter_preflight` FFI export + the manifest it reads + a verified-file
cache + tests + `rust.yml` 35→36. Purely additive (one new symbol), no Dart, no
behavior change, **curl stays on**.

**Out (→ 2b):** Dart bindings + orchestration (preflight → download → prove), the
atomic downloader, Contract 4 file-locking, the `restart_required` latch, and the
cold-cache E2E. 2b also **removes/replaces the existing hardcoded inclusion download**
in `aleo_programs.dart` (`downloadProvingKey`, the dead S3 URL) — the manifest drives
provisioning instead.

## 1. The v1 parameter set — 16 files per network

Credits-only. Grounded in `insert_credit_keys!` (vendored `mainnet/mod.rs:173`) +
`InclusionProver` (`:235`): **15 credits provers + 1 inclusion prover**, all
`impl_remote!`:

```
bond_public bond_validator unbond_public claim_unbond_public set_validator_state
transfer_public transfer_private transfer_public_as_signer
transfer_private_to_public transfer_public_to_private
join split fee_public fee_private upgrade   + inclusion
```

**Excluded (verified):** `credits_v0` + `InclusionV0Prover` (no caller in the proving
path, fact #8); base SRS `impl_local!`/baked-in (fact #6); higher-degree SRS (the prove
path uses the key's baked `committer_key` + the baked degree-15 base, and
`download_powers_for` is key-generation-only — **§7, confirmed**); all `*Verifier`
(`impl_local!`).

`testnet` is a first-class network: `aleo_ffi`'s checked proving exports (PR2 part 1)
already dispatch `MainnetV0`/`TestnetV0` (both monomorphized in one lib), and the
vendored `testnet/.../resources/credits/*.metadata` are in-repo. `type Net = MainnetV0`
(lib.rs:38) serves only the deprecated `_static` + account ops (network-independent).
So preflight returning `testnet` `ok` matches `execute_proof_checked("testnet", …)`
actually proving testnet — not misleading.

## 2. Exact path / URL / filename (grounded in `macros.rs`)

For checksum `C`, `<fname>.prover` (`macros.rs:181-183`, `:223`):

```
versioned filename:  <fname>.prover.<C[0..7]>
local path:          <param_dir>/resources/<fname>.prover.<C[0..7]>    (NO credits/ at runtime)
url (per base):      <base>/<fname>.prover.<C[0..7]>                    (NO resources/ in url)
```

## 3. The manifest

Built **at runtime, once, cached**, from the vendored crate's `pub const METADATA`
constants — NOT a build.rs and NOT `include_str!` of file paths. Each `impl_remote!`
struct exposes `pub const METADATA: &str` (the `.metadata` JSON); the manifest reads
`snarkvm_parameters::{mainnet,testnet}::{…Prover}::METADATA`, parses `prover_checksum`
/ `prover_size`, and builds the entries. Drift-free: the constants ARE the vendored
source the lib compiles against — no second artifact, nothing to diff.

```rust
struct ParamEntry { function: &'static str, relative_path: String, urls: [String; 2], size: u64, checksum: String }
fn manifest(net: NetworkKind) -> Vec<ParamEntry>   // 16 entries
```

- The only hardcoded data: the **16 `(function, METADATA-const)` pairs** (from
  `insert_credit_keys!` + `InclusionProver`) and the per-network **`REMOTE_URLS`**
  (the crate's `REMOTE_URLS` is private, so hardcode the two D2 hosts:
  `parameters.provable.com/<net>` and `s3.us-west-1.amazonaws.com/<net>.parameters`).
- A unit test asserts: exactly 16 entries/network, the function set equals the
  expected 16, each METADATA parses (so a silent snarkVM bump fails CI).

## 4. `parameter_preflight(network, consensus_version)`

```c
char* parameter_preflight(const char* network, uint16_t consensus_version);
```

**Memory ownership:** the returned `char*` is owned by the caller and freed with the
existing `free_string(char*)` — the same contract as every other export (it is
produced through `ffi_envelope` → `to_cstring` → `CString::into_raw`). No new free
function. Per-prove usage is `preflight → read missing → free_string`, no leak.

Runs under `ffi_envelope` (catch_unwind → `restart_required`). Steps:
1. `parse_network` → else `unsupported_network`.
2. `consensus_version ∈ 8..=13` → else `unsupported_consensus`.
3. for each of the 16 entries, check `<effective_parameter_dir()>/<relative_path>`:
   existence + size + SHA-256. **Read-only — never deserializes a key, so it cannot
   trigger the panicking `lazy_static`** (the reason preflight exists).
4. return the fixed schema below.

**Guarantee (scoped):** empty `missing` ⇒ the **audited credits-v1 parameter set
(these 16)** is present and correct, so a credits prove will not panic for want of
one of them. (Not an absolute "won't panic" — §7.)

**Verified-file cache** (don't SHA-256 ~1.15 GiB before every prove): process-global
`Mutex<Vec<FileKey>>`. On Unix `FileKey = (canonical path, dev, ino, size, mtime_ns)`;
elsewhere `(canonical path, size, mtime_ns)`. `stat` each file; full-hash only on
first-seen or any key field changed; insert on match. The param dir is **set-once**
(frozen after first load), so the directory cannot change under the cache. *Residual
(documented): a size+mtime+inode-preserving swap escapes the cache — the load macro's
own checksum is the backstop.*

### Fixed JSON schema

```jsonc
// ok
{ "ok": true,
  "missing": [ { "function": "transfer_public",                 // which credits key
                 "relativePath": "resources/transfer_public.prover.79da599",
                 "urls": ["https://parameters.provable.com/mainnet/transfer_public.prover.79da599",
                          "https://s3.us-west-1.amazonaws.com/mainnet.parameters/transfer_public.prover.79da599"],
                 "size": 77239780, "checksum": "79da599…",   // full hex
                 "reason": "absent" } ] }                     // absent | wrong_size | wrong_checksum | unreadable
// error
{ "ok": false, "code": "unsupported_network|unsupported_consensus|preflight_error", "message": "…" }
```

Dart: anything not `ok:true` is fatal; `ok:true` + non-empty `missing` drives the (2b)
downloader (each entry `urls[0]`, fall back to `urls[1]`).

## 5. Failure-code table (the table-driven test)

| input | result |
|---|---|
| network ∉ {mainnet,testnet} (incl. null → "") | `code: unsupported_network` |
| consensus_version < 8 or > 13 | `code: unsupported_consensus` |
| 16 present + correct | `ok, missing: []` |
| a file absent / wrong size / wrong checksum / unreadable | `ok`, that entry in `missing` with the matching `reason` |
| unreadable param dir etc. | `code: preflight_error` |

**Tests:** `verify_param(dir, entry, cache)` is unit-tested directly with a *fabricated*
tiny entry over a temp dir — covering the four reasons + the present case — so it needs
no real GB files. Network/consensus rejection is tested through the FFI in-process (no
files). "empty dir → all 16 absent" is tested through the FFI in a subprocess
(`ffi_set_parameter_dir(empty tmp)`, param dir is process-global). Plus an **`#[ignore]`
cold-cache completeness test** (copy only the 16 real files into a temp param dir and
run a real credits prove; asserts the audited set is sufficient — §7).

## 6. Symbol set + verification
`rust.yml` exact set **35 → 36** (`+parameter_preflight`); `cargo test --lib` green;
release cdylib 36; `dart test` unchanged (no Dart); `cargo tree -i openssl-sys` still
resolves (curl on).

## 7. "No higher-degree SRS for credits" — investigated and confirmed

Initially flagged as a risk; resolved during implementation against snarkVM 4.5.0
source. The **prove** path (`ProvingKey::prove_batch`,
`synthesizer-snark/proving_key/mod.rs:84`) uses two SRS sources, neither downloaded:
1. `N::varuna_universal_prover()` (`mainnet_v0.rs:354`) = `UniversalParams::load()` —
   the **baked-in degree-15 base** (`impl_local!`), and
2. `proving_key.committer_key` (`varuna.rs:270`) — trimmed to the circuit's degree at
   **key-generation** time and **baked into the downloaded `.prover` file**.

`download_powers_for(0..max_degree)` is called **only in `circuit_setup`**
(`varuna.rs:86`) — the key-**generation** path, never the prove path. So a credits
**prove** needs only: the credits proving key (`.prover`, with its committer_key) +
the inclusion key + the baked base SRS. **No higher-degree SRS download.** The
16-file manifest is correct.

> ⚠️ Misleading-evidence note (kept so a future reader doesn't re-panic): a dev
> machine's `~/.aleo/resources/` may contain `powers-of-beta-16/17`,
> `shifted-powers-of-beta-17`, etc. Those are **key-generation artifacts**
> (`circuit_setup` downloads powers); a credits *prove* never fetches them. The
> `#[ignore]` completeness test + 2b's curl-off cold E2E confirm sufficiency
> definitively, but the source above is conclusive for the prove path.
