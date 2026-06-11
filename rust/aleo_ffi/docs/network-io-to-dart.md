# Design: move network I/O out of `aleo_ffi` into Dart

Status: **phase 1 implemented** (the `_static` exports + helpers; old exports
untouched). Phases 2–4 not started.
Owner: aleo_ffi
Supersedes: the in-Rust HTTP hardening accreted across PR #51 review rounds 5–13.

## Phase 1 status (implemented)

Phase 1 is strictly additive: it ships the pure, network-free primitives and
helpers under new `_static` symbols alongside the untouched old exports
(`required_commitments`, `required_imports`, `state_root_from_paths`,
`consensus_version_for`, `get_base_fee_static`, `execution_fee_authorization_static`,
`execute_proof_static`, `execute_fee_proof_static`, `execute_program_proof_static`).
The pure helpers, the budgets, and the private-flow `StaticQuery` construction
are unit-tested offline (real sampled `StatePath`s); the release cdylib's exported
ABI is checked in CI.

Two P1 issues from a follow-up review were fixed in-phase (not deferred): the
fee API (`get_base_fee_static` / `execution_fee_authorization_static`) now takes
`program_sources_json` and loads the execution's root program, since snarkVM's
`execution_cost` reads each transition's program `Stack` (without it a
non-credits execution returned fee 0 / ""); and `required_commitments` now
subtracts the transaction's own transition outputs from the input commitments,
excluding a composite program's intra-transaction ("local") record
(`vm.authorize` already populates the authorization's transitions, so this is
exact and offline).

The following are **intentionally deferred** — surfaced by a high-effort
self-review, none blocking, all sequenced to a later phase:

- **No exact-match of state paths to `required_commitments`.** The proving
  primitives rely on a byte+entry budget plus `StaticQuery`'s missing-path
  fail-closed, not this spec's "the parsed paths' commitment set exactly equals
  `required_commitments`". Pinned by the phase-2 parity test before the old node
  path is deleted.
- **End-to-end SNARK proving of `execute_*_static` is not unit-tested** (needs a
  live node + proving keys); the private-flow `StaticQuery` mechanism *is*
  covered offline with real sampled `StatePath`s.
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

Moving all HTTP to the Dart layer — which has a real async runtime with proper
timeouts and cancellation — makes the Rust functions **pure compute** over
pre-fetched inputs. That deletes the entire finding class instead of shrinking
it: no `ureq`, no DNS, no worker threads, no deadlines, no retry/budget code in
Rust at all.

## Current network surface

19 of the 31 exports are already pure (account, record, offline authorization
and assembly). **12 touch the network:**

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
preloaded data. So proving is fully offline once the caller supplies
`{height, state_root, state_paths}` — note `height` is required, not optional:
`StaticQuery::new` takes it as its first argument and a wrong/absent height
yields an invalid query.

## New FFI shape

### Pure primitives (replace `url`/`network` with pre-fetched data)

Every proving primitive takes `height` — proving reads `current_block_height`
for the consensus version, so it cannot be omitted:

- `execute_proof(authorization, height, state_paths_json, public_state_root)`
  — builds the `StaticQuery` and proves; no HTTP.
- `execute_fee_proof(authorization, height, state_paths_json, public_state_root)`.
- `execute_program_proof(authorization, program_sources_json, height, state_paths_json, public_state_root)`.
- `get_base_fee(execution, program_sources_json, height)` — height in, fee out,
  pure. `program_sources_json` loads the execution's root program: snarkVM's
  `execution_cost` reads each transition's program `Stack`, so a non-credits
  execution needs it (empty for a credits.aleo execution).
- `execution_fee_authorization(private_key, execution, fee_credits, fee_record, program_sources_json, height)`
  — base fee derived from `height` over the loaded program(s), pure.

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
- *Rust (parse side):* check the raw `state_paths_json` byte length and entry
  count **before** deserializing, then require the parsed paths' commitment set
  to **exactly equal `required_commitments(authorization)`** — no extra, no
  missing. This is both a correctness check (you prove inclusion for exactly the
  records being spent) and a tight, protocol-grounded count bound: the required
  commitments are bounded by the execution's inputs (`MAX_INPUTS` per transition
  × `MAX_TRANSITIONS`), so a node cannot inflate the path count beyond what the
  transaction actually needs. `public_state_root` is similarly length-checked
  before parsing.

`program_sources_json`: a JSON array of `{id, edition, source}` the caller has
already fetched (closure included, any order). Rust validates ids, loads
imports-before-importers from the supplied set, and applies the existing cycle /
id-mismatch / `MAX_PROGRAM_SIZE` checks **plus a program-count and total-byte
budget** (see "Resource budgets survive the move" below) — now over an in-memory
set rather than the network.

### New pure helpers (so Dart knows what to fetch)

- `required_commitments(authorization_json) -> JSON [field]` — the **global**
  input-record commitments whose state paths the caller must fetch before
  proving: the request record inputs minus the transaction's own transition
  outputs (a record minted earlier in the same transaction is "local" — proving
  builds its inclusion path itself and the node has no path for it). Empty for
  public transfers. **Called once per authorization** — both the execution
  authorization and (separately) the fee authorization, since a private fee
  spends its own record (see the example flow).
- `required_imports(program_source) -> JSON [program_id]` — direct imports of a
  program, so Dart can walk the closure it must fetch. (Dart recurses; Rust
  stays a pure per-program function.)
- `state_root_from_paths(state_paths_json) -> field` — optional convenience if
  Dart needs the snapshot root for logging/caching; not required for proving
  (the proving primitives derive it themselves, above).

### Removed exports

The one-call orchestration functions that bundled network I/O —
`build_transaction`, `try_transfer`, `try_join`, `execute_program` — are dropped
from Rust and **re-implemented in Dart** as compositions of the pure primitives
(authorize → fetch → prove → assemble → broadcast). `contract_execution` /
`contract_fee_execution` likewise become Dart compositions over the program-proof
primitives. `broadcast` is deleted (Dart does the POST).

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
sides**, even though the HTTP/threading/deadline machinery is deleted:

- **Dart (fetch side):** the closure walk via `required_imports` enforces a
  max-program-count and cumulative-byte budget (and a wall-clock budget, now
  natural with `dio`/`CancelToken`); it stops and errors rather than fetch an
  unbounded chain.
- **Rust (parse side):** parsing `program_sources_json` re-checks a program
  count cap and a total-byte cap (not just per-program `MAX_PROGRAM_SIZE`),
  since Rust must not trust the caller's set blindly either.

Only the *time/deadline* and *worker-thread* parts of the budget are dropped
(no blocking I/O left in Rust to bound); the *size* parts persist.

## Deleted from Rust

`ureq` dependency; `http_agent`, `http_get`, `http_get_until`, `http_post`,
`request_once_bounded`, `InflightPermit`/`MAX_INFLIGHT_REQUESTS`; the
*time/thread* part of `LoadBudget` (the wall-clock deadline, `get_once_bounded`
plumbing) — **but not** its size budget, which moves to the `program_sources_json`
parser per above; `NodeQuery`'s HTTP impl (replaced by building `StaticQuery`
from caller JSON); `node_latest_edition`, `add_program_from_node` (network),
`broadcast_to_node`. The worker-thread/deadline tests go with them; the
program-count/byte-budget tests are kept and re-pointed at the parser.

Result: the Rust crate makes **zero network calls** and links no HTTP stack —
which also simplifies the pending iOS/Android cross-compile (no curl/OpenSSL or
rustls needed; see the GPL-removal plan).

## Migration plan (phased, each independently shippable)

1. **Add pure primitives + helpers under new symbol names, alongside the
   existing functions** (no removals, no symbol reuse — see "Phase-1 symbol
   names"). New exports: `required_commitments`, `required_imports`,
   `state_root_from_paths`, `consensus_version_for(height)`, and the
   `*_static` proving/fee variants (`execute_proof_static`,
   `execute_fee_proof_static`, `execute_program_proof_static`,
   `get_base_fee_static`, `execution_fee_authorization_static`) carrying the
   `height, state_paths_json, public_state_root` shape and the program/path
   resource budgets. The old `execute_proof` etc. stay exactly as they are, so
   CI and current Dart keep working.
2. **Move orchestration to Dart**: implement `AleoNode` + rewrite `AleoProgram`
   orchestration onto the pure primitives; keep method signatures stable.
   Parity-test new Dart pipeline vs the old FFI one against testnet.
3. **Delete the in-Rust network code** and the now-unused exports once Dart no
   longer calls them; drop `ureq`.
4. **Re-point cross-compile** (no HTTP stack) — folds into the GPL-removal /
   mobile-build work.

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
- **Resource budget parity**: the count/byte budget must reject the same
  oversized closures Dart's walk does, and the `state_paths_json` parser must
  reject path sets that don't exactly match `required_commitments`; tested on
  both sides against synthetic oversized/mismatched inputs.
- **Consensus-version pin**: a parity/regression test that a version change
  between the two snapshots restarts the whole flow rather than mixing versions.
- **Effort**: ~12 FFI functions resigned, an `AleoNode` Dart class, and a
  parity pass. Bounded, but a real piece of work — hence its own phased PR set,
  not a rider on #51.
