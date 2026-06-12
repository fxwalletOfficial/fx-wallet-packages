# Design: move network I/O out of `aleo_ffi` into Dart

Status: **phase 2 implemented** — phase 1 shipped the `_static` exports +
helpers (old exports untouched); phase 2 adds the Dart `AleoNode` (all node I/O,
with `dio` + real `CancelToken` cancellation), rewrites the `AleoProgram`
orchestration onto the pure primitives, and lands the Rust exact-match guard
(`checked_static_query`: the supplied state paths must equal exactly
`required_commitments`). Phases 3–4 (delete the old in-Rust network code; drop
the proving-parameter `curl`/OpenSSL download) not started.
Owner: aleo_ffi
Supersedes: the in-Rust HTTP hardening accreted across PR #51 review rounds 5–13.

## Phase 1 status (implemented)

Phase 1 is strictly additive: it ships **ten** pure, RPC-free exports (they
issue no node RPC; proving's parameter download is a separate, still-open matter
— see "Proving parameters") alongside the untouched old ones — four helpers (`required_commitments`,
`required_imports`, `state_root_from_paths`, `consensus_version_for`) plus six
`_static` proving/fee/authorize variants (`get_base_fee_static`,
`execution_fee_authorization_static`, `execute_proof_static`,
`execute_fee_proof_static`, `execute_program_proof_static`,
`program_authorization_static`). Five of those carry `_static` because they would
otherwise collide with an existing old symbol of the same name (`execute_proof`,
`execute_fee_proof`, `execute_program_proof`, `get_base_fee`,
`execution_fee_authorization`); `program_authorization_static` has **no** old
counterpart and takes the suffix only for naming consistency across the new
static API. The four helpers are new names, so they need no suffix.
The pure helpers, the size budgets (`state_paths_json` byte + entry caps;
`program_sources_json` byte + program-count caps; the program-loader wall-clock
deadline), and the private-flow `StaticQuery` construction are unit-tested
offline (real sampled `StatePath`s); the release cdylib's exported ABI is checked
in CI. Not yet tested: the deferred state-path exact-match (below) and anything
Dart-side (phase 2).

Four P1 issues from follow-up reviews were fixed in-phase (not deferred): (1)
the fee API (`get_base_fee_static` / `execution_fee_authorization_static`) now
takes `program_sources_json` and loads the execution's root program, since
snarkVM's `execution_cost` reads each transition's program `Stack` (without it a
non-credits execution returned fee 0 / ""); (2) `required_commitments` now
excludes a composite program's intra-transaction ("local") record by walking the
authorization's transitions in execution order (paired to requests by `tcm`) and
dropping an input only if an *earlier* transition output it — mirroring
`Inclusion::insert_transition` exactly, not an order-insensitive all-outputs
subtraction that could drop a real on-chain input matching a *later* output
(`vm.authorize` already populates the transitions, so this is exact and offline); (3) `add_programs_from_sources` keeps a wall-clock deadline
over its CPU-bound parse / Stack-build steps — moving HTTP to Dart removed the
*network* stall, but a hostile closure of large valid programs is still
uninterruptible CPU work the Dart timeout cannot reach; and (4) added
`program_authorization_static(private_key, program_id, function, arguments,
program_sources_json)` — the pure authorize primitive for *arbitrary* programs
(load the program from sources, then `vm.authorize`). Without it phase 2 had no
offline entry point for non-credits flows and would have to keep calling the
network-bound `contract_execution` / `execute_program`; the credits-only
`execution_authorization` / `join_authorization` / `upgrade_authorization`
don't cover it.

The following are **intentionally deferred** — surfaced by a high-effort
self-review, none blocking, all sequenced to a later phase:

- ~~**No exact-match of state paths to `required_commitments`.**~~ **Done in
  phase 2.** The three proving primitives now build their query through
  `checked_static_query`, which requires the supplied paths' commitment set to
  equal exactly `global_commitment_set(authorization)` — rejecting an *extra*
  padded path (the budget bounds size, not relevance) as well as a missing one.
  Covered offline by `checked_static_query_*` Rust tests (real sampled
  `StatePath`s keyed by a private transfer's actual commitment) and, through the
  FFI, by `aleo_required_commitments_test.dart`.
- **End-to-end SNARK proving is only partly covered.** `execute_proof_static`
  for a *public* transfer is proved end-to-end (the `#[ignore]`d
  `execute_proof_static_public_transfer_end_to_end`, run with proving keys), and
  the private-flow `StaticQuery` mechanism is covered offline with real sampled
  `StatePath`s. Still **not** end-to-end: the *private* execution flow (needs a
  real on-chain state path, impractical offline) and the `execute_fee_proof_static`
  / `execute_program_proof_static` paths — all left to the phase-2 testnet parity
  run.
- **Minor cleanup left for phase 3** (when the old path is deleted and `_static`
  is renamed to canonical): `base_fee_at_height` and the three `execute_*_static`
  share structure with the old exports. Kept duplicated for now to match the
  file's per-export style and keep the diff easy to check against this spec.

## Why

Every network-robustness finding on PR #51 (rounds 5, 7, 9, 10, 11, 12, 13 —
timeouts, retries, batch state paths, import-depth, unbounded import load,
deadline coverage, connect/DNS, broadcast hang, thread accumulation) has one
root: **`aleo_ffi` performs blocking network I/O inside synchronous FFI
calls.** With `ureq` + uninterruptible DNS + a synchronous C ABI, a *hard*
in-process bound is not achievable — each fix shrinks the leak and the next
review finds the next one. The worker-thread + budget machinery is the best
in-process approximation, but it is machinery defending an inherently leaky
shape.

Moving all node RPC to the Dart layer — which has a real async runtime with
proper timeouts and cancellation — makes the Rust functions compute over
pre-fetched inputs (the network I/O still left in Rust, snarkVM's
proving-parameter download, is a separate matter called out in "Proving
parameters"). That deletes the entire **RPC** finding class instead of shrinking
it: no `ureq`, no node-RPC DNS, no worker threads, no node-RPC retries in Rust.
(The proving-parameter download is the exception — it still does DNS and retries
a list of URLs; see "Proving parameters". A size budget and a CPU wall-clock
deadline also stay on the offline program loader — parsing and Stack-building
untrusted sources is still bounded work; see "Resource budgets survive the
move".)

## Current network surface

After phase 1, **26 of the 41 exports** are RPC- and network-free (account,
record, offline authorization and assembly, plus 7 of the 10 new phase-1
exports). **15 can touch the network:** the **12 old network-touching exports**
in the table below (still present — phase 3 deletes them once Dart no longer
calls them), **plus** the 3 new proving primitives `execute_proof_static`,
`execute_fee_proof_static`, `execute_program_proof_static` — they issue no node
RPC, but proving can synchronously download proving keys / the SRS on a cold
cache (see "Proving parameters"). The other 7 new exports (the four helpers,
`get_base_fee_static`, `execution_fee_authorization_static`,
`program_authorization_static`) don't prove, so they touch nothing. (Before phase
1 it was 19 of 31.)

| FFI export | Needs from node |
|---|---|
| `get_base_fee` | block height (→ consensus version) |
| `execution_fee_authorization` | block height (base fee) |
| `execute_proof` | state root + state paths |
| `execute_fee_proof` | state root + state paths |
| `execute_program_proof` | program source(s) + state root + state paths |
| `build_transaction` | height + state root/paths (full pipeline) |
| `try_transfer` | height + state root/paths + **broadcast POST** |
| `try_join` | height + state root/paths + **broadcast POST** |
| `execute_program` | program source(s) + height + state/paths + **broadcast POST** |
| `contract_execution` | program source(s) + state root/paths |
| `contract_fee_execution` | program source(s) + height |
| `broadcast` | **broadcast POST** only |

So the node provides exactly **four** kinds of data:

1. **block height** (`latest/height`) — `u32`.
2. **state root** (`latest/stateRoot`).
3. **state paths** for a set of commitments (`statePaths?commitments=…`) — only
   for record-spending (private / private-fee / join) flows.
4. **program source at edition** (`/program/{id}/latest_edition`,
   `/program/{id}/{edition}`) — only for non-builtin programs.

Plus the one **write**: broadcast `POST transaction/broadcast`.

## Key enabler (verified)

snarkVM's `StaticQuery<N>` already carries exactly what proving needs:

```rust
StaticQuery::new(block_height: u32,
                 state_root: N::StateRoot,
                 state_paths: HashMap<Field<N>, StatePath<N>>)
```

`execute_authorization_raw` / `execute_fee_authorization_raw` call
`current_state_root`, `get_state_paths_for_commitments`, **and
`current_block_height`** on the query (height selects the consensus version and
feeds inclusion `prepare`), all of which `StaticQuery` answers from its
preloaded data. So proving needs no **node RPC** once the caller supplies
`{height, state_root, state_paths}` (it still loads proving keys / the SRS, which
snarkVM downloads on a cold cache — see "Proving parameters", so "offline" is not
yet literal) — note `height` is required, not optional:
`StaticQuery::new` takes it as its first argument and a wrong/absent height
yields an invalid query.

## New FFI shape

### Pure primitives (replace `url`/`network` with pre-fetched data)

Every proving primitive takes `height` — proving reads `current_block_height`
for the consensus version, so it cannot be omitted:

- `execute_proof(authorization, height, state_paths_json, public_state_root)`
  — builds the `StaticQuery` and proves; no node RPC (proving may still download
  proving keys / the SRS on a cold cache — see "Proving parameters").
- `execute_fee_proof(authorization, height, state_paths_json, public_state_root)`.
- `execute_program_proof(authorization, program_sources_json, height, state_paths_json, public_state_root)`.
- `get_base_fee(execution, program_sources_json, height)` — height in, fee out,
  pure. `program_sources_json` loads the execution's root program: snarkVM's
  `execution_cost` reads each transition's program `Stack`, so a non-credits
  execution needs it (empty for a credits.aleo execution).
- `execution_fee_authorization(private_key, execution, fee_credits, fee_record, program_sources_json, height)`
  — base fee derived from `height` over the loaded program(s), pure.

Plus one offline **authorize** primitive (not a proving primitive, so no
`height`), the entry point for arbitrary-program flows that the credits-only
`execution_authorization` / `join_authorization` / `upgrade_authorization` don't
cover:

- `program_authorization(private_key, program_id, function, arguments, program_sources_json)`
  — loads the program (+ imports) from sources, then `vm.authorize`; `arguments`
  is a JSON array of Aleo value strings (record inputs already plaintext). Shipped
  as `program_authorization_static` (no old symbol to collide with; the suffix is
  only for naming consistency).

**Phase-1 symbol names — these cannot reuse the old symbols.** `execute_proof`,
`execute_fee_proof`, `execute_program_proof` already exist as exports with the
*old* parameter lists and Dart looks them up by exactly those names; a cdylib
cannot export two different ABIs under one symbol, and silently replacing them
would feed old callers into native code with the wrong signature. So phase 1
ships the new functions under **distinct symbols** — `execute_proof_static`,
`execute_fee_proof_static`, `execute_program_proof_static`,
`get_base_fee_static`, `execution_fee_authorization_static` — alongside the
untouched old exports. Only in phase 3, once Dart no longer looks up the old
names, are the old exports deleted (and the `_static` names optionally renamed to
the canonical ones in lockstep with the Dart `lookupFunction` calls, since a
rename is itself an ABI change). The names above are the *target* shapes; read
them with the `_static` suffix until phase 3.

**Root handling (no protocol parsing in Dart).** Dart has no `StatePath`
parser, and Rust parses the paths anyway, so Rust — not Dart — derives the root:

- `state_paths_json` non-empty (private flows): Rust parses each path, verifies
  they all carry the same `global_state_root`, and builds
  `StaticQuery::new(height, that_root, map)`. `public_state_root` must be empty
  (or, if supplied, must equal the derived root) — Rust rejects a mismatch.
- `state_paths_json` empty (public flows): Rust builds the query from
  `public_state_root` (the opaque `latest/stateRoot` string Dart fetched).

So Dart only ever passes through opaque strings it got from the node: the path
strings from `statePaths`, or the root string from `latest/stateRoot`. It never
parses snarkVM types.

**`state_paths_json` is untrusted node input too — budget + exact-match it.**
A malicious node can return a huge array or huge path strings to exhaust Dart's
response buffer or Rust's serde. Bounds, both sides:

- *Dart (fetch side):* cap the `statePaths` response bytes and entry count
  before buffering the whole body.
- *Rust (parse side), phase 1 (implemented):* check the raw `state_paths_json`
  byte length **before** deserializing (bounding serde memory), then the parsed
  entry count **after** (≤ `MAX_INPUTS` per transition × `MAX_TRANSITIONS`, the
  most any execution can require). `public_state_root` is length-checked before
  parsing. A missing path fails closed (proving's `get_state_path_for_commitment`
  errors).
- *Rust (parse side), phase 2 (implemented):* `checked_static_query`
  additionally requires the parsed paths' commitment set to **exactly equal
  `global_commitment_set(authorization)`** — no extra, no missing. This is a
  stronger correctness check (prove inclusion for exactly the spent records) and
  a tighter, protocol-grounded bound. The Dart fetch side asks for exactly
  `required_commitments`, so the two agree by construction; the guard is what
  stops an untrusted node from padding the response.

`program_sources_json`: a JSON array of `{id, edition, source}` the caller has
already fetched (closure included, any order). Rust validates ids, loads
imports-before-importers from the supplied set, and applies the existing cycle /
id-mismatch / `MAX_PROGRAM_SIZE` checks **plus a program-count and total-byte
budget** (see "Resource budgets survive the move" below) — now over an in-memory
set rather than the network.

### New pure helpers (so Dart knows what to fetch)

- `required_commitments(authorization_json) -> JSON [field]` — the **global**
  input-record commitments whose state paths the caller must fetch before
  proving: each transition's record inputs, dropping any whose record was output
  by an *earlier* transition in the same transaction (a "local" record — proving
  builds its inclusion path itself and the node has no path for it). The filter
  is applied in execution order (transitions paired to requests by `tcm`), so a
  later output can't drop an earlier on-chain input. Empty for public transfers. **Called once per authorization** — both the execution
  authorization and (separately) the fee authorization, since a private fee
  spends its own record (see the example flow).
- `required_imports(program_source) -> JSON [program_id]` — direct imports of a
  program, so Dart can walk the closure it must fetch. (Dart recurses; Rust
  stays a pure per-program function.)
- `state_root_from_paths(state_paths_json) -> field` — optional convenience if
  Dart needs the snapshot root for logging/caching; not required for proving
  (the proving primitives derive it themselves, above).

### Removed exports (planned, phase 3)

These still exist after phase 1; phase 3 removes them once the Dart orchestration
no longer calls them. The one-call orchestration functions that bundle network
I/O — `build_transaction`, `try_transfer`, `try_join`, `execute_program` — will be
dropped from Rust and **re-implemented in Dart** as compositions of the pure
primitives (authorize → fetch → prove → assemble → broadcast). `contract_execution`
/ `contract_fee_execution` likewise become Dart compositions over the
program-proof primitives. `broadcast` is deleted (Dart does the POST).

## State-root snapshot contract

`statePaths?commitments=…` returns paths only, **not** the latest state root, so
a separately-fetched `latest/stateRoot` can come from a different block than the
paths. To keep one consistent snapshot, the root is sourced differently per flow,
and (per finding above) Rust derives and verifies it — Dart passes opaque
strings only:

- **Private flows (≥1 commitment):** do **not** fetch `latest/stateRoot`. Every
  returned `StatePath` carries a `global_state_root`; Rust parses the paths,
  **rejects** the call unless they all agree, and uses that shared root. The
  root and the paths are thus one verified snapshot with no second fetch to
  straddle a block.
- **Public flows (no commitments → no paths):** there is no path to derive from,
  so Dart fetches `latest/stateRoot` and passes it as `public_state_root`;
  `state_paths_json` is empty. Inclusion proving uses this root directly
  (snarkVM falls back to `current_state_root` when there are no paths).

**Height vs the snapshot — not automatically harmless.** `height` selects the
consensus version, which changes at specific upgrade heights. If `height` and
the root/paths straddle such an upgrade height, proving applies the wrong rules
and fails. So height is not "a block of slack for free": the caller pins one
`height`/`version` for the **whole** transaction and verifies it is unchanged
after the snapshots. A `consensus_version_for(height) -> u16` helper (pure,
wrapping `Net::CONSENSUS_VERSION`) lets Dart check without hardcoding upgrade
heights. Because a transaction takes two snapshots (execution and a private
fee), the response to a mid-flow version change is **not** to re-snapshot one
piece — every authorization and proof already generated was bound to the old
version and must be discarded, and the whole flow restarts (see the orchestration
steps, "Consistency gate").

## Dart responsibilities (new)

A small `AleoNode` Dart class owns all node I/O with **`dio`** (already a
dependency of `aleo_dart`):

- `latestHeight()`, `latestStateRoot()`, `statePaths(commitments)`,
  `programSource(id)` (+ closure walk via `required_imports`), `broadcast(tx)`.
- **Real cancellation, not just `Future.timeout`.** `Future.timeout` only stops
  *awaiting* — the underlying socket keeps running, which would recreate the
  abandoned-worker resource leak we are leaving Rust to escape. So every request
  carries a `dio` `CancelToken`; on timeout we `cancelToken.cancel()` (which
  aborts the HTTP request), and `dio`'s own `connectTimeout` / `receiveTimeout`
  bound the connect and read phases. `Future.timeout` is at most a belt-and-
  suspenders outer guard, never described as the cancellation mechanism.

The existing `AleoProgram` Dart methods keep their signatures where possible by
orchestrating internally. The full flow has two independent inclusion snapshots
— one for the execution, one for the fee — because a **private fee spends its
own record**, so its proof needs its own state paths. One height/consensus
version is pinned for the **whole** transaction; the execution proof and the fee
proof and the fee authorization are all bound to it, so a consensus upgrade
landing mid-flow invalidates *everything* generated so far, not just the next
snapshot. `tryTransfer(...)` becomes (with the whole thing wrapped in a
bounded retry):

1. `height = node.height()`; `version = consensus_version_for(height)` — pinned
   for the whole transaction.
2. `exec = executionAuthorization(...)`.
3. `execPaths = node.statePaths(required_commitments(exec))` — empty for a
   public transfer.
4. `executionProof = executeProof(exec, height, execPaths, publicRoot)` where
   `publicRoot = execPaths.isEmpty ? node.stateRoot() : ""`.
5. `feeAuth = executionFeeAuthorization(..., height)`.
6. `feePaths = node.statePaths(required_commitments(feeAuth))` — **non-empty
   when the fee is private** (spends a fee record), empty for a public fee.
7. `feeProof = executeFeeProof(feeAuth, height, feePaths, feePublicRoot)` with
   `feePublicRoot = feePaths.isEmpty ? node.stateRoot() : ""`.
8. **Consistency gate:** `consensus_version_for(node.height()) == version`?
   If not, an upgrade landed mid-flow — **discard `exec`, `executionProof`,
   `feeAuth`, `feeProof` and restart from step 1.** Re-snapshotting only the fee
   while keeping the old `height`/`executionProof` would prove against a stale
   version. (Each snapshot's paths are also self-consistent via the root
   derivation, but only an all-or-nothing version pin keeps the two snapshots
   *and* the pinned height mutually consistent.)
9. `tx = buildTransactionOffline(executionProof, feeProof)`.
10. `node.broadcast(tx)`.

Steps 3–4 and 6–7 are the same snapshot contract applied twice, to two
different commitment sets. So app-facing call sites change little, but the
orchestration is not a single linear fetch — the fee path is its own snapshot.

## Resource budgets survive the move

Moving HTTP to Dart does **not** remove the malicious-node risk it was added to
contain: a node can still answer an endless *acyclic* chain of distinct valid
programs. Now the Dart closure walk would fetch forever, and the assembled
`program_sources_json` would grow without limit — `MAX_PROGRAM_SIZE` caps one
program, not the set. So the **count + total-byte budget is kept, on both
sides**, even though the HTTP/worker-thread machinery is deleted:

- **Dart (fetch side):** the closure walk via `required_imports` enforces a
  max-program-count and cumulative-byte budget (and a wall-clock budget, now
  natural with `dio`/`CancelToken`); it stops and errors rather than fetch an
  unbounded chain.
- **Rust (parse side):** parsing `program_sources_json` re-checks a program
  count cap and a total-byte cap (not just per-program `MAX_PROGRAM_SIZE`),
  **and keeps a wall-clock deadline** gating each `Program::from_str` and each
  `add_program_with_edition` (Stack build) — both are expensive, uninterruptible
  CPU work, so a hostile-but-valid closure of up to `MAX_IMPORT_PROGRAMS` large
  programs must not be able to block the synchronous FFI call. The Dart-side
  timeout can only bound the *fetch*; it cannot interrupt work already inside the
  FFI, so the CPU bound has to live in Rust. Rust must not trust the caller's set
  blindly either.

Only the *worker-thread / in-flight* machinery is dropped (no **RPC** blocking
I/O left in Rust to bound — the proving-parameter download is separate, see
"Proving parameters"); the *size* and *wall-clock* parts persist.

## Deleted from Rust (planned, phase 3)

When the in-Rust network code is removed: `ureq` dependency; `http_agent`,
`http_get`, `http_get_until`, `http_post`,
`request_once_bounded`, `InflightPermit`/`MAX_INFLIGHT_REQUESTS`; the
*thread/in-flight* part of the load machinery (`get_once_bounded` plumbing) —
**but not** `LoadBudget`'s size and wall-clock budget, which move to the
`program_sources_json` parser (it keeps a deadline over its CPU-bound
parse/Stack-build steps) per above; `NodeQuery`'s HTTP impl (replaced by building `StaticQuery`
from caller JSON); `node_latest_edition`, `add_program_from_node` (network),
`broadcast_to_node`. The worker-thread / in-flight tests go with them. Already
done in phase 1: the program-count/byte-budget tests and a wall-clock-deadline
test point at the new `program_sources_json` parser (the loader keeps its CPU
deadline, so that test stays rather than being deleted with the network code).

Result: the Rust crate makes **zero RPC calls** — state, program sources, and
broadcast all move to Dart. **One network *dependency* is NOT yet removed** (it
can fetch several parameter files, each retrying a list of URLs) (see
"Proving parameters" below): snarkVM's `snarkvm-parameters` still lazily
downloads proving keys / the Varuna SRS via `curl` (synchronous, no timeout) on
a cold parameter cache, so the crate still links `curl` + `openssl-sys`.
Eliminating it — pre-provisioning the parameters with remote fetch disabled — is
its own task and the actual prerequisite for the no-OpenSSL iOS/Android
cross-compile in the GPL-removal plan.

## Proving parameters (open gap — the network I/O still in Rust)

This phase's premise is "Rust does no network I/O." That holds for **node RPC**
(state / program sources / broadcast), but **not** for snarkVM's proving
parameters, an issue this design originally overlooked:

- The proving primitives (`execute_*_static`) call `execute_authorization_raw`,
  which proves; proving needs the credits.aleo proving keys and the Varuna SRS.
- `snarkvm-parameters` loads these (several files — a proving key per credits
  function plus the SRS) from `aleo_std::aleo_dir()` and, on a **cold cache**,
  downloads **each missing one** with `curl::easy` — **synchronous, with no
  timeout** (`transfer.perform()`), each retrying a list of URLs.
- `curl` (and thus `openssl-sys`) is an unconditional `cfg(not(wasm),
  not(sgx))` dependency of `snarkvm-parameters`; **no Cargo feature disables it**
  on native targets. So removing `ureq` does not stop the crate linking
  curl/OpenSSL, and a cold-cache prove can still block on the network.

This is **not introduced by phase 1** — the old network-bound `execute_proof`
downloads parameters the same way — but it does mean the early "zero-network /
no HTTP stack" claims were wrong, and it is the real blocker for the no-OpenSSL
mobile cross-compile.

**Fix (its own task, sequenced as phase 4 / part of the GPL-removal mobile
build):** vendor `snarkvm-parameters` (as we already vendor `snarkvm-synthesizer`)
and make native targets take the `RemoteFetchDisabled` path that wasm/sgx already
use — return an error instead of fetching — then drop the `curl`/`openssl-sys`
dependency. Parameters are pre-provisioned: bundled with the app, or downloaded
once by the Dart layer (with `dio` timeout/cancel) into `aleo_dir()` before the
first prove. Until then, the parameter download remains snarkVM's default
behaviour.

## Migration plan (phased, each independently shippable)

1. **Add pure primitives + helpers under new symbol names, alongside the
   existing functions** (no removals, no symbol reuse — see "Phase-1 symbol
   names"). New exports: `required_commitments`, `required_imports`,
   `state_root_from_paths`, `consensus_version_for(height)`, the
   `*_static` proving/fee variants (`execute_proof_static`,
   `execute_fee_proof_static`, `execute_program_proof_static`,
   `get_base_fee_static`, `execution_fee_authorization_static`) carrying the
   `height, state_paths_json, public_state_root` shape and the program/path
   resource budgets, and `program_authorization_static` (the pure authorize
   primitive for arbitrary programs). The old `execute_proof` etc. stay exactly
   as they are, so CI and current Dart keep working.
2. **Move orchestration to Dart** *(done)*: `AleoNode`
   (`packages/aleo_dart/lib/src/aleo_node.dart`) owns all node I/O with `dio` +
   `CancelToken`; `AleoProgram` (`aleo_programs.dart`) composes the pure
   primitives over it, pinning one consensus version across the whole transfer
   (a mid-flow upgrade restarts the build). Public method signatures unchanged.
   Plus the Rust exact-match guard (above). Offline-tested: `aleo_node_test.dart`
   (the whole node class against a local `HttpServer`), `aleo_required_commitments_test.dart`,
   and the `checked_static_query_*` Rust tests. End-to-end SNARK proving (the
   private flow, fee, program paths) and the full live-node parity remain a
   manual run (`test/transfer/aleo_phase2_e2e.dart`), still blocked on a live
   testnet with includable transactions.
3. **Delete the in-Rust network code** and the now-unused exports once Dart no
   longer calls them; drop `ureq`.
4. **Remove the proving-parameter network dependency + re-point cross-compile**:
   vendor/patch `snarkvm-parameters` to disable native remote fetch
   (pre-provision the keys/SRS), dropping `curl`/`openssl-sys` — see "Proving
   parameters". This is the actual no-OpenSSL prerequisite; folds into the
   GPL-removal / mobile-build work.

## Open questions / risks

- **State-path correctness across blocks**: handled by the state-root snapshot
  contract above (derive the root from the batch `statePaths` response for
  private flows; fetch it separately only for public ones; Rust verifies the
  paths agree). The `required_commitments` helper must return *exactly* the set
  snarkVM will ask for during proving — to be pinned by a parity test against
  the current `NodeQuery` path before deleting it.
- **API churn**: app code calling the one-call functions directly (not via the
  Dart wrapper) would change. Mitigated by keeping `AleoProgram` method
  signatures stable in step 2.
- **Two snapshots per transaction**: the execution and a private fee each need
  their own inclusion snapshot (different commitment sets). The orchestration
  must not share one snapshot across both — pinned by a private-fee parity test.
- **Resource budget parity**: the Rust count/byte budget must reject the same
  oversized closures the (phase-2) Dart walk does, and the `state_paths_json`
  parser must reject path sets that don't exactly match `required_commitments`.
  Phase 1 has the Rust size-budget tests (state-path byte + entry caps;
  program-sources byte + count caps); the exact-match and the Dart-side budget
  are **not yet implemented/tested** — both land in phase 2.
- **Consensus-version pin**: a parity/regression test that a version change
  between the two snapshots restarts the whole flow rather than mixing versions.
- **Effort**: ~12 FFI functions redesigned, an `AleoNode` Dart class, and a
  parity pass. Bounded, but a real piece of work — hence its own phased PR set,
  not a rider on #51.
