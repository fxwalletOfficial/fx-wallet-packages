# Design: move network I/O out of `aleo_ffi` into Dart

Status: **proposed** (spec only; no code yet)
Owner: aleo_ffi
Supersedes: the in-Rust HTTP hardening accreted across PR #51 review rounds 5–13.

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
- `get_base_fee(execution, height)` — height in, fee out, pure.
- `execution_fee_authorization(private_key, execution, fee_credits, fee_record, height)`
  — base fee derived from `height`, pure.

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

`program_sources_json`: a JSON array of `{id, edition, source}` the caller has
already fetched (closure included, any order). Rust validates ids, loads
imports-before-importers from the supplied set, and applies the existing cycle /
id-mismatch / `MAX_PROGRAM_SIZE` checks **plus a program-count and total-byte
budget** (see "Resource budgets survive the move" below) — now over an in-memory
set rather than the network.

### New pure helpers (so Dart knows what to fetch)

- `required_commitments(authorization_json) -> JSON [field]` — the input-record
  commitments whose state paths the caller must fetch before proving. Empty for
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
and fails. So height is not "a block of slack for free": the caller must ensure
`height` maps to the **same consensus version** as the snapshot. Practical rule
for `AleoNode`: read height, take the snapshot, re-read height; if
`CONSENSUS_VERSION(h_before) != CONSENSUS_VERSION(h_after)` an upgrade landed
mid-snapshot — retry. A `consensus_version_for(height) -> u16` helper (pure,
wrapping `Net::CONSENSUS_VERSION`) lets Dart make this check without hardcoding
upgrade heights.

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
own record**, so its proof needs its own state paths. `tryTransfer(...)` becomes:

1. `height = node.height()` (up front — every proof needs it; re-checked for
   consensus-version stability per the snapshot contract).
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
8. `tx = buildTransactionOffline(executionProof, feeProof)`.
9. `node.broadcast(tx)`.

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

1. **Add pure primitives + helpers alongside the existing functions** (no
   removals). New exports: `required_commitments`, `required_imports`,
   `state_root_from_paths`, `consensus_version_for(height)`, the height-taking
   proving variants (`execute_proof`/`execute_fee_proof`/`execute_program_proof`
   with the `height, state_paths_json, public_state_root` shape), and a
   `program_sources_json` parser carrying the count/byte budget. CI keeps the
   old path green.
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
  oversized closures Dart's walk does; tested on both sides against a synthetic
  oversized set.
- **API churn**: app code calling the one-call functions directly (not via the
  Dart wrapper) would change. Mitigated by keeping `AleoProgram` method
  signatures stable in step 2.
- **Effort**: ~12 FFI functions resigned, an `AleoNode` Dart class, and a
  parity pass. Bounded, but a real piece of work — hence its own phased PR set,
  not a rider on #51.
