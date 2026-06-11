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

`execute_authorization_raw` / `execute_fee_authorization_raw` only call
`current_state_root` and `get_state_paths_for_commitments` on the query, both of
which `StaticQuery` answers from its preloaded data. So proving is fully offline
once the caller supplies `{height, state_root, state_paths}`.

## New FFI shape

### Pure primitives (replace `url`/`network` with pre-fetched data)

- `execute_proof(authorization, state_root, state_paths_json)` — build a
  `StaticQuery` from the inputs; no HTTP.
- `execute_fee_proof(authorization, state_root, state_paths_json)`.
- `execute_program_proof(authorization, program_sources_json, state_root, state_paths_json)`.
- `get_base_fee(execution, height)` — height in, fee out, pure.
- `execution_fee_authorization(private_key, execution, fee_credits, fee_record, height)`
  — base fee derived from `height`, pure.

`state_paths_json`: a JSON array of snarkVM state-path strings; Rust parses each,
keys it by its commitment, and assembles the `HashMap`. Empty for public flows.

`program_sources_json`: a JSON array of `{id, edition, source}` the caller has
already fetched (closure included, topologically any order — Rust still
validates ids and loads imports-before-importers from the supplied set, with the
existing cycle / id-mismatch / `MAX_PROGRAM_SIZE` checks, now over an in-memory
set rather than the network).

### New pure helpers (so Dart knows what to fetch)

- `required_commitments(authorization_json) -> JSON [field]` — the input-record
  commitments whose state paths the caller must fetch before proving. Empty for
  public transfers.
- `required_imports(program_source) -> JSON [program_id]` — direct imports of a
  program, so Dart can walk the closure it must fetch. (Dart recurses; Rust
  stays a pure per-program function.)

### Removed exports

The one-call orchestration functions that bundled network I/O —
`build_transaction`, `try_transfer`, `try_join`, `execute_program` — are dropped
from Rust and **re-implemented in Dart** as compositions of the pure primitives
(authorize → fetch → prove → assemble → broadcast). `contract_execution` /
`contract_fee_execution` likewise become Dart compositions over the program-proof
primitives. `broadcast` is deleted (Dart does the POST).

## Dart responsibilities (new)

A small `AleoNode` Dart class owns all node I/O with `dio`/`http`:

- `latestHeight()`, `latestStateRoot()`, `statePaths(commitments)`,
  `programSource(id)` (+ closure walk via `required_imports`), `broadcast(tx)`.
- Real timeouts / retries / cancellation via `Future.timeout`, `CancelToken` —
  where they are natural and correct.

The existing `AleoProgram` Dart methods keep their signatures where possible by
orchestrating internally: e.g. `tryTransfer(...)` becomes
`authorize → node.statePaths(required_commitments) → executeProof →
node.height → feeAuthorize → executeFeeProof → buildTransactionOffline →
node.broadcast`, so app-facing call sites change little.

## Deleted from Rust

`ureq` dependency; `http_agent`, `http_get`, `http_get_until`, `http_post`,
`request_once_bounded`, `InflightPermit`/`MAX_INFLIGHT_REQUESTS`; `LoadBudget`
and the whole import-load budget; `NodeQuery`'s HTTP impl (replaced by building
`StaticQuery` from caller JSON); `node_latest_edition`, `add_program_from_node`
(network), `broadcast_to_node`. The worker-thread/deadline tests go with them.

Result: the Rust crate makes **zero network calls** and links no HTTP stack —
which also simplifies the pending iOS/Android cross-compile (no curl/OpenSSL or
rustls needed; see the GPL-removal plan).

## Migration plan (phased, each independently shippable)

1. **Add pure primitives + helpers alongside the existing functions** (no
   removals). New exports: `required_commitments`, `required_imports`,
   `*_static` proving variants, `get_base_fee_at(height)`. CI keeps the old
   path green.
2. **Move orchestration to Dart**: implement `AleoNode` + rewrite `AleoProgram`
   orchestration onto the pure primitives; keep method signatures stable.
   Parity-test new Dart pipeline vs the old FFI one against testnet.
3. **Delete the in-Rust network code** and the now-unused exports once Dart no
   longer calls them; drop `ureq`.
4. **Re-point cross-compile** (no HTTP stack) — folds into the GPL-removal /
   mobile-build work.

## Open questions / risks

- **State-path correctness across blocks**: Dart must fetch state root + all
  state paths atomically (one batch `statePaths?commitments=`, as the in-Rust
  fix already does) so every path shares one global root. The
  `required_commitments` helper must return *exactly* the set snarkVM will ask
  for during proving — to be pinned by a parity test against the current
  `NodeQuery` path before deleting it.
- **API churn**: app code calling the one-call functions directly (not via the
  Dart wrapper) would change. Mitigated by keeping `AleoProgram` method
  signatures stable in step 2.
- **Effort**: ~12 FFI functions resigned, an `AleoNode` Dart class, and a
  parity pass. Bounded, but a real piece of work — hence its own phased PR set,
  not a rider on #51.
