// Copyright (c) 2026 fx wallet
// Licensed under the Apache License, Version 2.0.
//
// Clean-room reimplementation of the Aleo account/key FFI surface, written
// directly against snarkVM's public API (Apache-2.0). No code is derived from
// the GPL-3.0 Aleo SDK; this is implemented from the project's FFI contract
// (the Dart `*_rust_ffi.dart` typedefs), its existing test vectors, and
// snarkvm-console's public documentation.
//
// Group 1 of the rewrite: account / key operations. These need only
// snarkvm-console (no VM, no snarkVM visibility patch).

use std::ffi::{c_char, c_int, CStr, CString};
use std::slice;

use rand::rngs::OsRng;
use snarkvm_console::account::{Address, PrivateKey, Signature, ViewKey};
use snarkvm_console::network::MainnetV0;
use snarkvm_console::prelude::*;
use snarkvm_console::program::{Ciphertext, Identifier, Literal, Plaintext, ProgramID, Record};
use snarkvm_console::types::Field;
use snarkvm_console::program::StatePath;
use snarkvm_ledger_block::{Execution, Fee, Transaction};
use snarkvm_ledger_query::QueryTrait;
use snarkvm_ledger_store::helpers::memory::ConsensusMemory;
use snarkvm_ledger_store::ConsensusStore;
use snarkvm_synthesizer::process::Authorization;
use snarkvm_synthesizer::program::Program;
use snarkvm_synthesizer::VM;
use aleo_std_storage::StorageMode;

/// Aleo keys/addresses are encoded identically across networks (same curve,
/// network-independent bech32 HRPs), so the concrete network is irrelevant to
/// these account operations.
type Net = MainnetV0;

/// Borrows a C string as `&str`. Invalid UTF-8 yields "" rather than panicking,
/// so malformed input is handled by the caller's normal "" error path instead
/// of unwinding across the FFI boundary (which aborts the process).
///
/// SAFETY: `p` must be a valid NUL-terminated C string for the duration of the call.
unsafe fn read_str<'a>(p: *const c_char) -> &'a str {
    CStr::from_ptr(p).to_str().unwrap_or("")
}

/// Transfers ownership of a heap C string to the caller (matches the existing
/// FFI contract; the caller is responsible for the buffer). A NUL in the output
/// (never expected for our textual outputs) is truncated rather than panicking.
fn to_cstring(s: String) -> *mut c_char {
    let bytes: Vec<u8> = s.into_bytes().into_iter().take_while(|&b| b != 0).collect();
    // SAFETY: `take_while` stops at the first NUL, so `bytes` has no interior NUL.
    unsafe { CString::from_vec_unchecked(bytes) }.into_raw()
}

/// Frees a string previously returned by this library. Returned pointers are
/// allocated with Rust's allocator via `CString::into_raw`, so they must be
/// handed back to Rust to be freed — calling the C `free` on them is undefined
/// behaviour. Null is a no-op; each pointer must be freed at most once.
///
/// SAFETY: `ptr` is null or a pointer previously returned by this library and
/// not yet freed.
#[no_mangle]
pub unsafe extern "C" fn free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        drop(CString::from_raw(ptr));
    }
}

/// FFI sanity check used by the test suite.
#[no_mangle]
pub extern "C" fn numbers_add(a: c_int, b: c_int) -> c_int {
    a + b + 1
}

/// SAFETY: `seed` must point to at least 32 readable bytes.
#[no_mangle]
pub unsafe extern "C" fn seed_to_private_key(seed: *const u8) -> *mut c_char {
    if seed.is_null() {
        return to_cstring(String::new());
    }
    let bytes = slice::from_raw_parts(seed, 32);
    // Reduce the 32-byte seed modulo the field order. A raw 32-byte value
    // exceeds the BLS12-377 scalar field ~93% of the time, so the canonical
    // `from_bytes_le` would reject most seeds; Aleo derives the account seed by
    // reducing mod order instead.
    let field = Field::<Net>::new(<Net as Environment>::Field::from_bytes_le_mod_order(bytes));
    match PrivateKey::<Net>::try_from(field) {
        Ok(private_key) => to_cstring(private_key.to_string()),
        Err(_) => to_cstring(String::new()),
    }
}

/// Returns "" on a malformed key (rather than panicking, which would unwind
/// across the FFI boundary and abort the process).
///
/// SAFETY: `pk` must be a valid NUL-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn private_key_to_address(pk: *const c_char) -> *mut c_char {
    let result = (|| -> Option<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(pk)).ok()?;
        Some(Address::<Net>::try_from(&private_key).ok()?.to_string())
    })();
    to_cstring(result.unwrap_or_default())
}

/// Returns "" on a malformed key. SAFETY: `pk` is a NUL-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn private_key_to_view_key(pk: *const c_char) -> *mut c_char {
    let result = (|| -> Option<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(pk)).ok()?;
        Some(ViewKey::<Net>::try_from(&private_key).ok()?.to_string())
    })();
    to_cstring(result.unwrap_or_default())
}

/// Returns "" on a malformed key. SAFETY: `vk` is a NUL-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn view_key_to_address(vk: *const c_char) -> *mut c_char {
    let result = (|| -> Option<String> {
        let view_key = ViewKey::<Net>::from_str(read_str(vk)).ok()?;
        Some(view_key.to_address().to_string())
    })();
    to_cstring(result.unwrap_or_default())
}

/// Returns "" on a malformed key, a null/negative-length message, or signing
/// failure (no panic across the FFI boundary). SAFETY: `pk` is a
/// NUL-terminated C string; `msg` points to `len` readable bytes.
#[no_mangle]
pub unsafe extern "C" fn sign_message(pk: *const c_char, msg: *const u8, len: c_int) -> *mut c_char {
    // A negative length would wrap to a huge usize and read out of bounds.
    if msg.is_null() || len < 0 {
        return to_cstring(String::new());
    }
    let message = slice::from_raw_parts(msg, len as usize);
    let result = (|| -> Option<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(pk)).ok()?;
        Some(private_key.sign_bytes(message, &mut OsRng).ok()?.to_string())
    })();
    to_cstring(result.unwrap_or_default())
}

/// Returns 1 if the signature is valid, 0 otherwise (including for a
/// null/negative-length message).
///
/// SAFETY: `addr`/`sig` are NUL-terminated C strings; `msg` points to `len` readable bytes.
#[no_mangle]
pub unsafe extern "C" fn verify(
    addr: *const c_char,
    sig: *const c_char,
    msg: *const u8,
    len: c_int,
) -> c_int {
    // A negative length would wrap to a huge usize and read out of bounds.
    if msg.is_null() || len < 0 {
        return 0;
    }
    let address = match Address::<Net>::from_str(read_str(addr)) {
        Ok(address) => address,
        Err(_) => return 0,
    };
    let signature = match Signature::<Net>::from_str(read_str(sig)) {
        Ok(signature) => signature,
        Err(_) => return 0,
    };
    let message = slice::from_raw_parts(msg, len as usize);
    signature.verify_bytes(&address, message) as c_int
}

/// Computes the token_registry owner hash: BHP256 of the struct
/// `{ account, token_id }`. Returns "" on failure.
///
/// SAFETY: `address`/`token_id` are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn get_token_owner_hash(
    address: *const c_char,
    token_id: *const c_char,
) -> *mut c_char {
    let result = (|| -> Option<String> {
        let plaintext = Plaintext::<Net>::from_str(&format!(
            "{{ account: {}, token_id: {} }}",
            read_str(address),
            read_str(token_id),
        ))
        .ok()?;
        let hash = Net::hash_bhp256(&plaintext.to_bits_le()).ok()?;
        Some(hash.to_string())
    })();
    to_cstring(result.unwrap_or_default())
}

// ----------------------------------------------------------------------------
// Group 2: records (read operations). snarkvm-console only.
// ----------------------------------------------------------------------------

/// Returns 1 if the encrypted record is owned by the view key, 0 otherwise.
///
/// SAFETY: `record`/`view_key` are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn is_owner(record: *const c_char, view_key: *const c_char) -> c_int {
    let view_key = match ViewKey::<Net>::from_str(read_str(view_key)) {
        Ok(view_key) => view_key,
        Err(_) => return 0,
    };
    let record = match Record::<Net, Ciphertext<Net>>::from_str(read_str(record)) {
        Ok(record) => record,
        Err(_) => return 0,
    };
    record.is_owner(&view_key) as c_int
}

/// Decrypts an encrypted record to its plaintext string. Returns "" on failure
/// (e.g. the view key does not own the record).
///
/// SAFETY: `record`/`view_key` are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn decrypt_cipher_text(
    record: *const c_char,
    view_key: *const c_char,
) -> *mut c_char {
    let view_key = match ViewKey::<Net>::from_str(read_str(view_key)) {
        Ok(view_key) => view_key,
        Err(_) => return to_cstring(String::new()),
    };
    let record = match Record::<Net, Ciphertext<Net>>::from_str(read_str(record)) {
        Ok(record) => record,
        Err(_) => return to_cstring(String::new()),
    };
    match record.decrypt(&view_key) {
        Ok(plaintext) => to_cstring(plaintext.to_string()),
        Err(_) => to_cstring(String::new()),
    }
}


/// Decrypts a `transfer_private` `sender_ciphertext` field to the sender's
/// Address, using the recipient's view key and the record's (public) nonce.
/// Returns "" on failure.
///
///   record_view_key = x(record.nonce * view_key)
///   randomizer      = hash_psd4([domain_separator("AleoSymmetricEncryption0"),
///                                record_view_key, 1field])
///   sender_x        = sender_ciphertext - randomizer
///   sender          = Address::from_field(sender_x)
///
/// SAFETY: all three pointers are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn decrypt_sender_ciphertext(
    record: *const c_char,
    view_key: *const c_char,
    sender_ciphertext: *const c_char,
) -> *mut c_char {
    let result = (|| -> Option<String> {
        let view_key = ViewKey::<Net>::from_str(read_str(view_key)).ok()?;
        let record = Record::<Net, Ciphertext<Net>>::from_str(read_str(record)).ok()?;
        let record_view_key = (record.into_nonce() * *view_key).to_x_coordinate();
        let domain = Field::<Net>::new_domain_separator("AleoSymmetricEncryption0");
        let randomizer = Net::hash_psd4(&[domain, record_view_key, Field::<Net>::one()]).ok()?;
        let sender_ciphertext = Field::<Net>::from_str(read_str(sender_ciphertext)).ok()?;
        let sender_x = sender_ciphertext - randomizer;
        Some(Address::<Net>::from_field(&sender_x).ok()?.to_string())
    })();
    to_cstring(result.unwrap_or_default())
}

// ----------------------------------------------------------------------------
// Private-key Encryptor (password-based). The seed is multiplicatively blinded:
//   secret_field = domain_separator(secret)
//   blinding     = hash_psd2([domain_separator("private_key"), nonce, secret_field])
//   key          = blinding * seed         (encrypt)
//   seed         = key / blinding          (decrypt)
// and { key, nonce } is then symmetric-encrypted under secret_field.
// ----------------------------------------------------------------------------

/// Extracts the `key` and `nonce` field members from the decrypted struct.
fn key_nonce(plaintext: &Plaintext<Net>) -> Option<(Field<Net>, Field<Net>)> {
    let members = match plaintext {
        Plaintext::Struct(members, _) => members,
        _ => return None,
    };
    let (mut key, mut nonce) = (None, None);
    for (id, member) in members {
        if let Plaintext::Literal(Literal::Field(field), _) = member {
            match id.to_string().as_str() {
                "key" => key = Some(*field),
                "nonce" => nonce = Some(*field),
                _ => {}
            }
        }
    }
    Some((key?, nonce?))
}

/// Encrypts an "APrivateKey1..." under `secret`, producing a "ciphertext1...".
/// Returns "" on failure. Non-deterministic (random nonce).
///
/// SAFETY: `private_key`/`secret` are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn encrypt_private_key(
    private_key: *const c_char,
    secret: *const c_char,
) -> *mut c_char {
    let result = (|| -> Option<String> {
        let secret_field = Field::<Net>::new_domain_separator(read_str(secret));
        let seed = PrivateKey::<Net>::from_str(read_str(private_key)).ok()?.seed();
        let nonce = Field::<Net>::new(Uniform::rand(&mut OsRng));
        let domain = Field::<Net>::new_domain_separator("private_key");
        let blinding = Net::hash_psd2(&[domain, nonce, secret_field]).ok()?;
        let key = blinding * seed;
        let plaintext =
            Plaintext::<Net>::from_str(&format!("{{ key: {}, nonce: {} }}", key, nonce)).ok()?;
        let ciphertext = plaintext.encrypt_symmetric(secret_field).ok()?;
        Some(ciphertext.to_string())
    })();
    to_cstring(result.unwrap_or_default())
}

/// Decrypts a "ciphertext1..." back to "APrivateKey1..." using `secret`.
/// Returns "" on failure (e.g. wrong password).
///
/// SAFETY: `ciphertext`/`secret` are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn decrypt_to_private_key(
    ciphertext: *const c_char,
    secret: *const c_char,
) -> *mut c_char {
    let result = (|| -> Option<String> {
        let secret_field = Field::<Net>::new_domain_separator(read_str(secret));
        let ciphertext = Ciphertext::<Net>::from_str(read_str(ciphertext)).ok()?;
        let plaintext = ciphertext.decrypt_symmetric(secret_field).ok()?;
        let (key, nonce) = key_nonce(&plaintext)?;
        let domain = Field::<Net>::new_domain_separator("private_key");
        let blinding = Net::hash_psd2(&[domain, nonce, secret_field]).ok()?;
        let seed = key / blinding;
        Some(PrivateKey::<Net>::try_from(seed).ok()?.to_string())
    })();
    to_cstring(result.unwrap_or_default())
}

// ----------------------------------------------------------------------------
// Group 3: programs / proofs / transactions.
// ----------------------------------------------------------------------------

/// A fresh in-memory VM (credits.aleo and the other built-in programs are
/// bundled in snarkVM, so no network fetch is needed to authorize/execute them).
fn new_vm() -> anyhow::Result<VM<Net, ConsensusMemory<Net>>> {
    VM::from(ConsensusStore::<Net, ConsensusMemory<Net>>::open(StorageMode::Production)?)
}

/// Shared HTTP agent with bounded timeouts. `.timeout()` is a deadline for the
/// whole exchange — connect, request, and reading the response body — so a
/// node that stalls *or trickles bytes indefinitely* surfaces as an error
/// instead of hanging the (synchronous) FFI call. Per-read timeouts alone
/// would not do that: each trickled byte resets them. Response memory is
/// bounded as well: every body is read via `into_string()`, which fails past
/// 10 MiB rather than growing without limit.
fn http_agent() -> &'static ureq::Agent {
    static AGENT: std::sync::OnceLock<ureq::Agent> = std::sync::OnceLock::new();
    AGENT.get_or_init(|| {
        ureq::AgentBuilder::new()
            .timeout_connect(std::time::Duration::from_secs(10))
            .timeout(std::time::Duration::from_secs(60))
            .build()
    })
}

/// HTTP GET with a few retries (the public node occasionally returns transient
/// 5xx / connection errors).
fn http_get(url: &str) -> anyhow::Result<String> {
    let mut last_error = None;
    for attempt in 0..4 {
        match http_agent().get(url).call() {
            Ok(response) => return Ok(response.into_string()?),
            Err(error) => {
                last_error = Some(error);
                std::thread::sleep(std::time::Duration::from_millis(500 * (attempt + 1)));
            }
        }
    }
    Err(anyhow::anyhow!("GET {url} failed after retries: {last_error:?}"))
}

/// REST query against `{url}/{network}`. snarkVM's own RestQuery derives the
/// URL path from the network type (MainnetV0 -> `/mainnet`), but Aleo's testnet
/// runs the network-0 protocol under a `/testnet` path, so we issue the
/// requests ourselves with the caller-provided network path.
struct NodeQuery {
    base: String,
}

impl NodeQuery {
    fn new(url: &str, network: &str) -> Self {
        Self { base: format!("{}/{}", url.trim_end_matches('/'), network) }
    }

    fn get_json<T: serde::de::DeserializeOwned>(&self, route: &str) -> anyhow::Result<T> {
        Ok(serde_json::from_str(http_get(&format!("{}/{route}", self.base))?.trim())?)
    }
}

impl QueryTrait<Net> for NodeQuery {
    fn current_state_root(&self) -> anyhow::Result<<Net as Network>::StateRoot> {
        self.get_json("latest/stateRoot")
    }

    fn get_state_path_for_commitment(
        &self,
        commitment: &Field<Net>,
    ) -> anyhow::Result<StatePath<Net>> {
        self.get_json(&format!("statePath/{commitment}"))
    }

    fn get_state_paths_for_commitments(
        &self,
        commitments: &[Field<Net>],
    ) -> anyhow::Result<Vec<StatePath<Net>>> {
        // One batch request (the same `statePaths` route snarkVM's RestQuery
        // uses) so every returned path is anchored to a single block: fetching
        // per commitment can straddle a block boundary, and the inclusion
        // prover rejects state paths that disagree on the global state root.
        if commitments.is_empty() {
            return Ok(Vec::new());
        }
        let commitments =
            commitments.iter().map(|commitment| commitment.to_string()).collect::<Vec<_>>();
        self.get_json(&format!("statePaths?commitments={}", commitments.join(",")))
    }

    fn current_block_height(&self) -> anyhow::Result<u32> {
        self.get_json("latest/height")
    }
}

/// Current block height from the node (used to select the consensus version).
/// Goes through `NodeQuery` so it shares the retrying `http_get` (the public
/// node returns transient 5xx/522), like every other node read.
fn fetch_height(url: &str, network: &str) -> anyhow::Result<u32> {
    NodeQuery::new(url, network).current_block_height()
}

/// Rejects a fee the network can never accept, *before* the expensive fee
/// proving: snarkVM verification requires `fee.amount() <= N::MAX_FEE`, so a
/// base + priority total past the cap could only produce a proof of a
/// transaction every node rejects.
fn check_total_fee(base_fee: u64, priority_fee: u64) -> anyhow::Result<()> {
    let total = base_fee
        .checked_add(priority_fee)
        .ok_or_else(|| anyhow::anyhow!("total fee overflows u64"))?;
    anyhow::ensure!(
        total <= Net::MAX_FEE,
        "total fee {total} exceeds the network maximum {}",
        Net::MAX_FEE
    );
    Ok(())
}

/// Minimum (base) fee in microcredits for an execution at the node's height.
fn base_fee_for(execution: &Execution<Net>, url: &str, network: &str) -> anyhow::Result<u64> {
    let consensus_version = Net::CONSENSUS_VERSION(fetch_height(url, network)?)?;
    let vm = new_vm()?;
    let process = vm.process();
    let process = process.read();
    let (base_fee, _details) =
        snarkvm_synthesizer::process::execution_cost(&process, execution, consensus_version)?;
    Ok(base_fee)
}

/// Returns a plaintext record string suitable as a function input. Records are
/// supplied encrypted (`record1...`); they are decrypted with the key's view
/// key. An already-plaintext record (`{ ... }`) is returned unchanged.
fn plaintext_record(record: &str, private_key: &PrivateKey<Net>) -> anyhow::Result<String> {
    let record = record.trim();
    if record.starts_with("record1") {
        let view_key = ViewKey::<Net>::try_from(private_key)?;
        let ciphertext = Record::<Net, Ciphertext<Net>>::from_str(record)?;
        Ok(ciphertext.decrypt(&view_key)?.to_string())
    } else {
        Ok(record.to_string())
    }
}

/// Decrypts (if needed) and parses a record as a typed plaintext record.
fn plaintext_record_typed(
    record: &str,
    private_key: &PrivateKey<Net>,
) -> anyhow::Result<Record<Net, Plaintext<Net>>> {
    Ok(Record::<Net, Plaintext<Net>>::from_str(&plaintext_record(record, private_key)?)?)
}

/// Maps a credits.aleo transfer function to its input list, decrypting the
/// spent record for private transfers.
fn transfer_inputs(
    function: &str,
    recipient: &str,
    amount: u64,
    amount_record: &str,
    private_key: &PrivateKey<Net>,
) -> anyhow::Result<Vec<String>> {
    let amount = format!("{amount}u64");
    Ok(match function {
        "transfer_public" | "transfer_public_to_private" => vec![recipient.to_string(), amount],
        "transfer_private" | "transfer_private_to_public" => {
            vec![plaintext_record(amount_record, private_key)?, recipient.to_string(), amount]
        }
        _ => anyhow::bail!("unsupported transfer type: {function}"),
    })
}

/// Runs the whole split-proof flow for a credits.aleo function and returns the
/// assembled transaction: authorize -> execute -> fee authorize -> fee execute
/// -> assemble. `fee_credits` is the priority fee; empty `fee_record` = public fee.
#[allow(clippy::too_many_arguments)]
fn full_transaction(
    private_key: &PrivateKey<Net>,
    program_id: &str,
    function: &str,
    inputs: Vec<String>,
    fee_credits: u64,
    fee_record: &str,
    url: &str,
    network: &str,
) -> anyhow::Result<String> {
    let vm = new_vm()?;
    add_program_from_node(&vm, program_id, url, network)?;
    let query = NodeQuery::new(url, network);
    let rng = &mut rand::thread_rng();

    let authorization = vm.authorize(private_key, program_id, function, inputs, rng)?;
    let (execution, _response) = vm.execute_authorization_raw(authorization, &query, rng)?;

    let execution_id = execution.to_execution_id()?;
    let base_fee = {
        let consensus_version = Net::CONSENSUS_VERSION(query.current_block_height()?)?;
        let process = vm.process();
        let process = process.read();
        snarkvm_synthesizer::process::execution_cost(&process, &execution, consensus_version)?.0
    };
    check_total_fee(base_fee, fee_credits)?;
    let fee_authorization = if fee_record.trim().is_empty() {
        vm.authorize_fee_public(private_key, base_fee, fee_credits, execution_id, rng)?
    } else {
        let record = plaintext_record_typed(fee_record, private_key)?;
        vm.authorize_fee_private(private_key, record, base_fee, fee_credits, execution_id, rng)?
    };
    let fee = vm.execute_fee_authorization_raw(fee_authorization, &query, rng)?;

    Ok(Transaction::from_execution(execution, Some(fee))?.to_string())
}

/// Reads a program's current on-chain edition from snarkOS's
/// `/program/{id}/latest_edition` route (via the retrying `http_get`).
fn node_latest_edition(base: &str, program_id: &str) -> anyhow::Result<u16> {
    let body = http_get(&format!("{base}/program/{program_id}/latest_edition"))?;
    Ok(body.trim().trim_matches('"').parse()?)
}

/// A fetched program whose imports have not all been confirmed present yet.
struct PendingProgram {
    program: Program<Net>,
    edition: u16,
    /// Imports still to satisfy before this program can be added.
    pending: Vec<ProgramID<Net>>,
}

/// Wall-clock ceiling on resolving one import graph from a node. A real
/// closure loads in a second or two; this is a DoS guard, not a protocol
/// limit, so it sits far above any honest case. Checked between fetches, each
/// of which is itself bounded by the per-request agent timeout.
const IMPORT_LOAD_DEADLINE: std::time::Duration = std::time::Duration::from_secs(120);

/// Ceiling on the number of programs fetched while resolving one import graph.
/// On-chain closures are tens of programs; this is far above any of them but,
/// with each source bounded by `MAX_PROGRAM_SIZE`, caps total memory. Like the
/// deadline it is a DoS budget the protocol itself does not define (it bounds
/// only a program's *direct* imports and source size, not transitive closure
/// size), made generous so it never rejects an honest closure — the explicit
/// trade-off for not reintroducing a depth/length cap that would.
const MAX_IMPORT_PROGRAMS: usize = 256;

/// Resource budget for a single `add_program_from_node` load, bounding the two
/// ways a hostile node can make an honest, acyclic, individually-valid import
/// chain expensive: total time and total programs (hence memory).
struct LoadBudget {
    deadline: std::time::Instant,
    remaining_programs: usize,
}

impl LoadBudget {
    fn new() -> Self {
        Self {
            deadline: std::time::Instant::now() + IMPORT_LOAD_DEADLINE,
            remaining_programs: MAX_IMPORT_PROGRAMS,
        }
    }

    /// Accounts for one program about to be fetched, failing if either budget
    /// is spent.
    fn charge_one_program(&mut self) -> anyhow::Result<()> {
        anyhow::ensure!(
            std::time::Instant::now() < self.deadline,
            "import load exceeded its {IMPORT_LOAD_DEADLINE:?} time budget"
        );
        self.remaining_programs = self.remaining_programs.checked_sub(1).ok_or_else(|| {
            anyhow::anyhow!("import load exceeded its {MAX_IMPORT_PROGRAMS}-program budget")
        })?;
        Ok(())
    }
}

/// True for built-in programs and anything already loaded in the process.
fn program_is_present(vm: &VM<Net, ConsensusMemory<Net>>, id: &ProgramID<Net>) -> bool {
    id.to_string() == "credits.aleo" || vm.process().read().contains_program(id)
}

/// Fetches `id`'s source at its current on-chain edition. The two are read in
/// that order (`latest_edition`, then `/program/{id}/{edition}`) so they stay
/// consistent even if the program is upgraded concurrently. The node is not
/// trusted: the source may not exceed `MAX_PROGRAM_SIZE` (a larger one cannot
/// be a valid on-chain program, so rejecting it never rejects a real one) and
/// must actually declare `id`, so a node can neither flood memory with an
/// oversized body nor substitute a different program for a requested import.
fn fetch_program_at_latest_edition(
    base: &str,
    id: &ProgramID<Net>,
    budget: &mut LoadBudget,
) -> anyhow::Result<PendingProgram> {
    budget.charge_one_program()?;
    let edition = node_latest_edition(base, &id.to_string())?;
    let body = http_get(&format!("{base}/program/{id}/{edition}"))?;
    let source: String = serde_json::from_str(body.trim())?;
    anyhow::ensure!(
        source.len() <= Net::MAX_PROGRAM_SIZE,
        "node returned a {}-byte source for '{id}', over the {}-byte maximum",
        source.len(),
        Net::MAX_PROGRAM_SIZE
    );
    let program = Program::<Net>::from_str(&source)?;
    if program.id() != id {
        anyhow::bail!("node returned program '{}' for requested '{id}'", program.id());
    }
    let pending = program.imports().keys().cloned().collect();
    Ok(PendingProgram { program, edition, pending })
}

/// Adds a fetched program to the process at its edition. Edition 0
/// (first-deployed, constructor-bearing programs) goes through `add_program`,
/// which execution permits; non-upgradeable programs are edition 1, upgraded
/// programs their bumped edition. A wrong edition would yield a proof that
/// disagrees with chain state, so edition determination failures propagate.
fn add_fetched_program(
    vm: &VM<Net, ConsensusMemory<Net>>,
    program: &Program<Net>,
    edition: u16,
) -> anyhow::Result<()> {
    let process = vm.process();
    let mut process = process.write();
    // A diamond import graph may have added it along another path already.
    if !process.contains_program(program.id()) {
        if edition == 0 {
            process.add_program(program)?;
        } else {
            process.add_program_with_edition(program, edition)?;
        }
    }
    Ok(())
}

/// Fetches a non-builtin program from the node and adds it to the VM, loading
/// every imported program first (snarkVM rejects a program whose imports are
/// not already present). A no-op for built-in programs like credits.aleo or any
/// program already loaded.
///
/// The import graph is walked iteratively in post-order (imports before
/// importers), so a hostile node cannot drive call-stack depth: the protocol
/// caps a program's *direct* imports (parsing enforces `MAX_IMPORTS`) but puts
/// no limit on transitive chain length, so arbitrarily deep legal chains must
/// load. An import referring back to a program still being loaded is a cycle —
/// impossible on-chain, where a program can only import programs deployed
/// before it — and is rejected as a lying node. Because the protocol does not
/// bound closure size, the whole walk runs against a [`LoadBudget`] (total time
/// and program count) so an unbounded acyclic chain of distinct valid programs
/// cannot block the synchronous call forever or exhaust memory.
fn add_program_from_node(
    vm: &VM<Net, ConsensusMemory<Net>>,
    program_id: &str,
    url: &str,
    network: &str,
) -> anyhow::Result<()> {
    let requested = ProgramID::<Net>::from_str(program_id)?;
    if program_is_present(vm, &requested) {
        return Ok(());
    }
    let base = format!("{}/{}", url.trim_end_matches('/'), network);
    let budget = &mut LoadBudget::new();

    // `stack` holds fetched programs whose imports are still being satisfied.
    let mut stack = vec![fetch_program_at_latest_edition(&base, &requested, budget)?];
    while let Some(frame) = stack.last_mut() {
        match frame.pending.pop() {
            Some(import_id) => {
                // A stack entry is a program still waiting on its imports, so
                // an import pointing back into the stack is a cycle.
                if stack.iter().any(|frame| frame.program.id() == &import_id) {
                    let chain = stack
                        .iter()
                        .map(|frame| frame.program.id().to_string())
                        .collect::<Vec<_>>()
                        .join(" -> ");
                    anyhow::bail!("node returned an import cycle: {chain} -> {import_id}");
                }
                if !program_is_present(vm, &import_id) {
                    stack.push(fetch_program_at_latest_edition(&base, &import_id, budget)?);
                }
            }
            None => {
                let done = stack.pop().expect("the loop condition saw a frame");
                add_fetched_program(vm, &done.program, done.edition)?;
            }
        }
    }
    Ok(())
}

/// Authorizes and executes a program function, returning the serialized
/// execution. Fetches the program if it isn't built in.
fn program_execution(
    private_key: &PrivateKey<Net>,
    program_id: &str,
    function: &str,
    arguments: &str,
    url: &str,
    network: &str,
) -> anyhow::Result<String> {
    let inputs: Vec<String> = serde_json::from_str(arguments)?;
    let vm = new_vm()?;
    add_program_from_node(&vm, program_id, url, network)?;
    let query = NodeQuery::new(url, network);
    let rng = &mut rand::thread_rng();
    let authorization = vm.authorize(private_key, program_id, function, inputs, rng)?;
    let (execution, _response) = vm.execute_authorization_raw(authorization, &query, rng)?;
    Ok(serde_json::to_string(&execution)?)
}

/// Produces the (public) fee proof for a serialized execution of `program_id`.
/// The program is loaded so its per-transition cost can be computed.
fn program_fee(
    private_key: &PrivateKey<Net>,
    priority_fee: u64,
    execution: &str,
    program_id: &str,
    url: &str,
    network: &str,
) -> anyhow::Result<String> {
    let execution: Execution<Net> = serde_json::from_str(execution)?;
    let vm = new_vm()?;
    add_program_from_node(&vm, program_id, url, network)?;
    let query = NodeQuery::new(url, network);
    let rng = &mut rand::thread_rng();
    let execution_id = execution.to_execution_id()?;
    let base_fee = {
        let consensus_version = Net::CONSENSUS_VERSION(query.current_block_height()?)?;
        let process = vm.process();
        let process = process.read();
        snarkvm_synthesizer::process::execution_cost(&process, &execution, consensus_version)?.0
    };
    check_total_fee(base_fee, priority_fee)?;
    let fee_authorization =
        vm.authorize_fee_public(private_key, base_fee, priority_fee, execution_id, rng)?;
    let fee = vm.execute_fee_authorization_raw(fee_authorization, &query, rng)?;
    Ok(serde_json::to_string(&fee)?)
}

/// POSTs a transaction to the node, returning the node's response body.
fn broadcast_to_node(transaction: &str, url: &str, network: &str) -> anyhow::Result<String> {
    let base = format!("{}/{}", url.trim_end_matches('/'), network);
    Ok(http_agent()
        .post(&format!("{base}/transaction/broadcast"))
        .set("Content-Type", "application/json")
        .send_string(transaction)?
        .into_string()?)
}

/// Builds a complete credits.aleo transfer transaction (without broadcasting).
/// Returns "" on failure.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn build_transaction(
    private_key: *const c_char,
    recipient: *const c_char,
    transfer_type: *const c_char,
    amount: u64,
    fee_credits: u64,
    url: *const c_char,
    amount_record: *const c_char,
    fee_record: *const c_char,
    network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        let function = read_str(transfer_type);
        let inputs = transfer_inputs(
            function,
            read_str(recipient),
            amount,
            read_str(amount_record),
            &private_key,
        )?;
        full_transaction(
            &private_key,
            "credits.aleo",
            function,
            inputs,
            fee_credits,
            read_str(fee_record),
            read_str(url),
            read_str(network),
        )
    };
    match inner() {
        Ok(transaction) => to_cstring(transaction),
        Err(_) => to_cstring(String::new()),
    }
}

/// Builds and broadcasts a credits.aleo transfer, returning the node response.
/// Returns "" on failure.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn try_transfer(
    private_key: *const c_char,
    recipient: *const c_char,
    transfer_type: *const c_char,
    amount: u64,
    fee_credits: u64,
    url: *const c_char,
    amount_record: *const c_char,
    fee_record: *const c_char,
    network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        let function = read_str(transfer_type);
        let inputs = transfer_inputs(
            function,
            read_str(recipient),
            amount,
            read_str(amount_record),
            &private_key,
        )?;
        let transaction = full_transaction(
            &private_key,
            "credits.aleo",
            function,
            inputs,
            fee_credits,
            read_str(fee_record),
            read_str(url),
            read_str(network),
        )?;
        broadcast_to_node(&transaction, read_str(url), read_str(network))
    };
    match inner() {
        Ok(response) => to_cstring(response),
        Err(_) => to_cstring(String::new()),
    }
}

/// Executes an arbitrary program function and broadcasts the transaction.
/// `arguments` is a JSON array of Aleo value strings. Returns the node response.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn execute_program(
    private_key: *const c_char,
    program_id: *const c_char,
    function_name: *const c_char,
    arguments: *const c_char,
    fee: u64,
    url: *const c_char,
    network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        let inputs: Vec<String> = serde_json::from_str(read_str(arguments))?;
        let transaction = full_transaction(
            &private_key,
            read_str(program_id),
            read_str(function_name),
            inputs,
            fee,
            "",
            read_str(url),
            read_str(network),
        )?;
        broadcast_to_node(&transaction, read_str(url), read_str(network))
    };
    match inner() {
        Ok(response) => to_cstring(response),
        Err(_) => to_cstring(String::new()),
    }
}

/// Generates the execution proof for a previously built authorization that
/// targets a non-builtin program. Unlike `execute_proof`, the referenced
/// `program_id` (and its imports) is fetched from the node and loaded before
/// the execution. Returns the serialized execution, or "" on failure.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn execute_program_proof(
    url: *const c_char,
    authorization: *const c_char,
    network: *const c_char,
    program_id: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let authorization: Authorization<Net> = serde_json::from_str(read_str(authorization))?;
        let vm = new_vm()?;
        add_program_from_node(&vm, read_str(program_id), read_str(url), read_str(network))?;
        let query = NodeQuery::new(read_str(url), read_str(network));
        let (execution, _response) =
            vm.execute_authorization_raw(authorization, &query, &mut rand::thread_rng())?;
        Ok(serde_json::to_string(&execution)?)
    };
    match inner() {
        Ok(execution) => to_cstring(execution),
        Err(_) => to_cstring(String::new()),
    }
}

/// Like `execute_program_proof`: authorizes + executes a program function,
/// returning the serialized execution (split-proof; fee comes separately via
/// `contract_fee_execution`).
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn contract_execution(
    private_key: *const c_char,
    program_id: *const c_char,
    function_name: *const c_char,
    arguments: *const c_char,
    url: *const c_char,
    network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        program_execution(
            &private_key,
            read_str(program_id),
            read_str(function_name),
            read_str(arguments),
            read_str(url),
            read_str(network),
        )
    };
    match inner() {
        Ok(execution) => to_cstring(execution),
        Err(_) => to_cstring(String::new()),
    }
}

/// Produces the public fee proof for a contract execution. Returns "".
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn contract_fee_execution(
    private_key: *const c_char,
    fee: u64,
    execution: *const c_char,
    program_id: *const c_char,
    url: *const c_char,
    network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        program_fee(
            &private_key,
            fee,
            read_str(execution),
            read_str(program_id),
            read_str(url),
            read_str(network),
        )
    };
    match inner() {
        Ok(fee) => to_cstring(fee),
        Err(_) => to_cstring(String::new()),
    }
}

/// Builds an execution authorization for credits.aleo `join` (merging two
/// private records). Offline. Returns "" on failure.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn join_authorization(
    private_key: *const c_char,
    record_1: *const c_char,
    record_2: *const c_char,
    _url: *const c_char,
    _network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        let inputs = vec![
            plaintext_record(read_str(record_1), &private_key)?,
            plaintext_record(read_str(record_2), &private_key)?,
        ];
        let vm = new_vm()?;
        let authorization =
            vm.authorize(&private_key, "credits.aleo", "join", inputs, &mut rand::thread_rng())?;
        Ok(serde_json::to_string(&authorization)?)
    };
    match inner() {
        Ok(authorization) => to_cstring(authorization),
        Err(_) => to_cstring(String::new()),
    }
}

/// Builds, proves, and broadcasts a credits.aleo `join` of two private records.
/// Returns the node response, or "" on failure.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn try_join(
    private_key: *const c_char,
    record_1: *const c_char,
    record_2: *const c_char,
    fee_credits: u64,
    fee_record: *const c_char,
    url: *const c_char,
    network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        let inputs = vec![
            plaintext_record(read_str(record_1), &private_key)?,
            plaintext_record(read_str(record_2), &private_key)?,
        ];
        let transaction = full_transaction(
            &private_key,
            "credits.aleo",
            "join",
            inputs,
            fee_credits,
            read_str(fee_record),
            read_str(url),
            read_str(network),
        )?;
        broadcast_to_node(&transaction, read_str(url), read_str(network))
    };
    match inner() {
        Ok(response) => to_cstring(response),
        Err(_) => to_cstring(String::new()),
    }
}

/// Builds an execution authorization for a credits.aleo transfer. Offline
/// (credits.aleo is built in). Returns "" on failure.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn execution_authorization(
    private_key: *const c_char,
    recipient: *const c_char,
    transfer_type: *const c_char,
    amount: u64,
    _url: *const c_char,
    amount_record: *const c_char,
    _network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        let function = read_str(transfer_type);
        let inputs = transfer_inputs(
            function,
            read_str(recipient),
            amount,
            read_str(amount_record),
            &private_key,
        )?;
        let vm = new_vm()?;
        let authorization =
            vm.authorize(&private_key, "credits.aleo", function, inputs, &mut rand::thread_rng())?;
        Ok(serde_json::to_string(&authorization)?)
    };
    match inner() {
        Ok(authorization) => to_cstring(authorization),
        Err(_) => to_cstring(String::new()),
    }
}

/// Generates the execution proof for an authorization (the patched
/// `execute_authorization_raw`). Queries `url`/`network` for the state root.
/// Returns "" on failure.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn execute_proof(
    url: *const c_char,
    authorization: *const c_char,
    network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let authorization: Authorization<Net> = serde_json::from_str(read_str(authorization))?;
        let query = NodeQuery::new(read_str(url), read_str(network));
        let vm = new_vm()?;
        let (execution, _response) =
            vm.execute_authorization_raw(authorization, &query, &mut rand::thread_rng())?;
        Ok(serde_json::to_string(&execution)?)
    };
    match inner() {
        Ok(execution) => to_cstring(execution),
        Err(_) => to_cstring(String::new()),
    }
}

/// Broadcasts a serialized transaction to the node, returning the node's
/// response (the transaction id on success). Returns "" on transport failure.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn broadcast(
    transaction: *const c_char,
    url: *const c_char,
    _transfer_type: *const c_char,
    network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let base = format!("{}/{}", read_str(url).trim_end_matches('/'), read_str(network));
        let response = http_agent()
            .post(&format!("{base}/transaction/broadcast"))
            .set("Content-Type", "application/json")
            .send_string(read_str(transaction))?
            .into_string()?;
        Ok(response)
    };
    match inner() {
        Ok(response) => to_cstring(response),
        Err(_) => to_cstring(String::new()),
    }
}

/// Returns the base (minimum) fee in microcredits for a serialized execution,
/// or 0 on failure. u64, like every fee crossing this ABI: snarkVM fees are
/// u64 microcredits and can legitimately exceed i32.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn get_base_fee(
    url: *const c_char,
    execution: *const c_char,
    network: *const c_char,
) -> u64 {
    let inner = || -> anyhow::Result<u64> {
        let execution: Execution<Net> = serde_json::from_str(read_str(execution))?;
        base_fee_for(&execution, read_str(url), read_str(network))
    };
    inner().unwrap_or(0)
}

/// Builds the fee authorization for an execution. `fee_credits` is the priority
/// fee; the base fee is computed from the execution. An empty `fee_record` uses
/// a public fee, otherwise a private fee spending that record. Returns "".
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn execution_fee_authorization(
    private_key: *const c_char,
    _transfer_type: *const c_char,
    url: *const c_char,
    fee_credits: u64,
    fee_record: *const c_char,
    execution: *const c_char,
    network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        let execution: Execution<Net> = serde_json::from_str(read_str(execution))?;
        let execution_id = execution.to_execution_id()?;
        let base_fee = base_fee_for(&execution, read_str(url), read_str(network))?;
        let priority_fee = fee_credits;
        check_total_fee(base_fee, priority_fee)?;
        let fee_record = read_str(fee_record);
        let vm = new_vm()?;
        let rng = &mut rand::thread_rng();
        let authorization = if fee_record.trim().is_empty() {
            vm.authorize_fee_public(&private_key, base_fee, priority_fee, execution_id, rng)?
        } else {
            let record = plaintext_record_typed(fee_record, &private_key)?;
            vm.authorize_fee_private(&private_key, record, base_fee, priority_fee, execution_id, rng)?
        };
        Ok(serde_json::to_string(&authorization)?)
    };
    match inner() {
        Ok(authorization) => to_cstring(authorization),
        Err(_) => to_cstring(String::new()),
    }
}

/// Generates the fee proof for a fee authorization (the patched
/// `execute_fee_authorization_raw`). Returns "" on failure.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn execute_fee_proof(
    url: *const c_char,
    authorization: *const c_char,
    network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let authorization: Authorization<Net> = serde_json::from_str(read_str(authorization))?;
        let query = NodeQuery::new(read_str(url), read_str(network));
        let vm = new_vm()?;
        let fee = vm.execute_fee_authorization_raw(authorization, &query, &mut rand::thread_rng())?;
        Ok(serde_json::to_string(&fee)?)
    };
    match inner() {
        Ok(fee) => to_cstring(fee),
        Err(_) => to_cstring(String::new()),
    }
}

/// Builds the authorization to migrate an old (version-0) credits record to a
/// version-1 record via credits.aleo `upgrade`. The encrypted `record` is
/// decrypted with the key's view key and passed as the single input. Offline.
/// Returns "" on failure.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn upgrade_authorization(
    private_key: *const c_char,
    record: *const c_char,
    _url: *const c_char,
    _network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        let view_key = ViewKey::<Net>::try_from(&private_key)?;
        let record = Record::<Net, Ciphertext<Net>>::from_str(read_str(record))?;
        let plaintext = record.decrypt(&view_key)?;
        let vm = new_vm()?;
        let authorization = vm.authorize(
            &private_key,
            "credits.aleo",
            "upgrade",
            vec![plaintext.to_string()],
            &mut rand::thread_rng(),
        )?;
        Ok(serde_json::to_string(&authorization)?)
    };
    match inner() {
        Ok(authorization) => to_cstring(authorization),
        Err(_) => to_cstring(String::new()),
    }
}

/// Assembles a credits.aleo `upgrade` transaction from its execution alone. A
/// transaction with a single `upgrade` transition is base-fee exempt, so no fee
/// is attached (`Transaction::from_execution(execution, None)`). Returns "".
///
/// SAFETY: `execution` is a NUL-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn build_upgrade_transaction_offline(
    execution: *const c_char,
    _network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let execution: Execution<Net> = serde_json::from_str(read_str(execution))?;
        Ok(Transaction::from_execution(execution, None)?.to_string())
    };
    match inner() {
        Ok(transaction) => to_cstring(transaction),
        Err(_) => to_cstring(String::new()),
    }
}

/// Assembles a transaction from a serialized execution proof and fee proof
/// (the split-proof flow). Deterministic; returns "" on failure.
///
/// SAFETY: `execution`/`fee`/`_network` are NUL-terminated C strings
/// (snarkVM serde JSON).
#[no_mangle]
pub unsafe extern "C" fn build_transaction_offline(
    execution: *const c_char,
    fee: *const c_char,
    _network: *const c_char,
) -> *mut c_char {
    let result = (|| -> Option<String> {
        let execution: Execution<Net> = serde_json::from_str(read_str(execution)).ok()?;
        let fee: Fee<Net> = serde_json::from_str(read_str(fee)).ok()?;
        let transaction = Transaction::from_execution(execution, Some(fee)).ok()?;
        Some(transaction.to_string())
    })();
    to_cstring(result.unwrap_or_default())
}

/// Computes the record's serial number for `program_id`/`record_name`. Returns
/// "" on failure. `program_id` is e.g. "credits.aleo", `record_name` "credits".
///
/// SAFETY: all four pointers are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn serial_number_string(
    record: *const c_char,
    private_key: *const c_char,
    program_id: *const c_char,
    record_name: *const c_char,
) -> *mut c_char {
    let result = (|| -> Option<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key)).ok()?;
        let view_key = ViewKey::<Net>::try_from(&private_key).ok()?;
        let record = Record::<Net, Ciphertext<Net>>::from_str(read_str(record)).ok()?;
        let program_id = ProgramID::<Net>::from_str(read_str(program_id)).ok()?;
        let record_name = Identifier::<Net>::from_str(read_str(record_name)).ok()?;

        // Record view key via ECDH: x-coordinate of (nonce * view_key scalar).
        let record_view_key = (record.clone().into_nonce() * *view_key).to_x_coordinate();
        let plaintext = record.decrypt(&view_key).ok()?;
        let commitment =
            plaintext.to_commitment(&program_id, &record_name, &record_view_key).ok()?;
        let serial_number =
            Record::<Net, Plaintext<Net>>::serial_number(private_key, commitment).ok()?;
        Some(serial_number.to_string())
    })();
    to_cstring(result.unwrap_or_default())
}

#[cfg(test)]
mod tests {
    use super::*;

    // record[2] from packages/aleo_dart/test/_diff_records.dart, owned by OWNER_KEY.
    const TEST_RECORD: &str = "record1qyqspdn8f6lh4eum9a36l93mnxh5vcqssjsep9z4lp4vpya2efgmjdsvqyxx66trwfhkxun9v35hguerqqpqzq9yu3tvsnj4x0a7e2w9w204aya09thraeckdlsn59pve6fnnd3eqv0n7jpp5rsxn48jdjj3z55vhmp42f8hxp7vk5d2430vuvk3fzrsx0w9wqw";
    const OWNER_KEY: &str = "APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v";

    fn owner() -> PrivateKey<Net> {
        PrivateKey::<Net>::from_str(OWNER_KEY).unwrap()
    }

    fn other_key() -> PrivateKey<Net> {
        let field = Field::<Net>::new(<Net as Environment>::Field::from_bytes_le_mod_order(&[7u8; 32]));
        PrivateKey::<Net>::try_from(field).unwrap()
    }

    // A ciphertext record (record1...) is decrypted to a plaintext record before
    // it can be used as a function input.
    #[test]
    fn plaintext_record_decrypts_ciphertext() {
        let plaintext = plaintext_record(TEST_RECORD, &owner()).unwrap();
        assert!(plaintext.starts_with('{'), "expected plaintext record, got: {plaintext}");
        // Round-trips as a typed plaintext record.
        Record::<Net, Plaintext<Net>>::from_str(&plaintext).unwrap();
        // An already-plaintext input is returned unchanged (idempotent).
        assert_eq!(plaintext_record(&plaintext, &owner()).unwrap(), plaintext);
    }

    // A key that does not own the record cannot decrypt it -> error (fail closed).
    #[test]
    fn plaintext_record_rejects_wrong_owner() {
        assert!(plaintext_record(TEST_RECORD, &other_key()).is_err());
    }

    #[test]
    fn transfer_inputs_public_ordering() {
        let inputs = transfer_inputs("transfer_public", "aleo1recipient", 5, "", &owner()).unwrap();
        assert_eq!(inputs, vec!["aleo1recipient".to_string(), "5u64".to_string()]);
    }

    // Private transfers place the decrypted record first, then recipient, amount.
    #[test]
    fn transfer_inputs_private_decrypts_record() {
        let inputs =
            transfer_inputs("transfer_private", "aleo1recipient", 5, TEST_RECORD, &owner()).unwrap();
        assert_eq!(inputs.len(), 3);
        Record::<Net, Plaintext<Net>>::from_str(&inputs[0]).unwrap();
        assert_eq!(inputs[1], "aleo1recipient");
        assert_eq!(inputs[2], "5u64");
    }

    #[test]
    fn transfer_inputs_rejects_unknown_function() {
        assert!(transfer_inputs("not_a_transfer", "aleo1recipient", 1, "", &owner()).is_err());
    }

    // free_string reclaims a returned pointer and tolerates null.
    #[test]
    fn free_string_reclaims_returned_pointers() {
        unsafe {
            free_string(to_cstring("hello".to_string()));
            free_string(std::ptr::null_mut());
        }
    }

    // Malformed input must return "" (not panic/abort across the FFI boundary).
    #[test]
    fn malformed_key_returns_empty_not_abort() {
        unsafe {
            let bad = CString::new("not-a-valid-key").unwrap();
            let fns: [unsafe extern "C" fn(*const c_char) -> *mut c_char; 3] = [
                private_key_to_address,
                private_key_to_view_key,
                view_key_to_address,
            ];
            for f in fns {
                let ptr = f(bad.as_ptr());
                assert!(CStr::from_ptr(ptr).to_str().unwrap().is_empty());
                free_string(ptr);
            }
            let msg = [1u8, 2, 3];
            let ptr = sign_message(bad.as_ptr(), msg.as_ptr(), 3);
            assert!(CStr::from_ptr(ptr).to_str().unwrap().is_empty());
            free_string(ptr);
        }
    }

    // A negative message length must be rejected, not wrapped to a huge usize
    // and read out of bounds.
    #[test]
    fn negative_message_length_rejected() {
        unsafe {
            let key = CString::new(OWNER_KEY).unwrap();
            let msg = [1u8, 2, 3];
            let ptr = sign_message(key.as_ptr(), msg.as_ptr(), -1);
            assert!(CStr::from_ptr(ptr).to_str().unwrap().is_empty());
            free_string(ptr);

            let addr = CString::new("aleo1qqq").unwrap();
            let sig = CString::new("sign1qqq").unwrap();
            assert_eq!(verify(addr.as_ptr(), sig.as_ptr(), msg.as_ptr(), -1), 0);
        }
    }

    /// Serves canned `path -> body` responses on a local port, so the
    /// node-facing program loader can be exercised without a network.
    fn serve_canned(routes: std::collections::HashMap<String, String>) -> String {
        use std::io::{Read, Write};
        let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        let address = format!("http://{}", listener.local_addr().unwrap());
        std::thread::spawn(move || {
            for stream in listener.incoming() {
                let Ok(mut stream) = stream else { continue };
                let mut buffer = [0u8; 4096];
                let read = stream.read(&mut buffer).unwrap_or(0);
                let request = String::from_utf8_lossy(&buffer[..read]).into_owned();
                let path = request.split_whitespace().nth(1).unwrap_or("").to_string();
                let (status, body) = match routes.get(&path) {
                    Some(body) => ("200 OK", body.clone()),
                    None => ("404 Not Found", String::new()),
                };
                let _ = write!(
                    stream,
                    "HTTP/1.1 {status}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                    body.len()
                );
            }
        });
        address
    }

    /// Like [`serve_canned`] but computes each response from the request path,
    /// so a test can model an *unbounded* node (e.g. an endless distinct import
    /// chain) without materializing infinite routes.
    fn serve_dynamic<F>(handler: F) -> String
    where
        F: Fn(&str) -> Option<String> + Send + 'static,
    {
        use std::io::{Read, Write};
        let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        let address = format!("http://{}", listener.local_addr().unwrap());
        std::thread::spawn(move || {
            for stream in listener.incoming() {
                let Ok(mut stream) = stream else { continue };
                let mut buffer = [0u8; 4096];
                let read = stream.read(&mut buffer).unwrap_or(0);
                let request = String::from_utf8_lossy(&buffer[..read]).into_owned();
                let path = request.split_whitespace().nth(1).unwrap_or("");
                let (status, body) = match handler(path) {
                    Some(body) => ("200 OK", body),
                    None => ("404 Not Found", String::new()),
                };
                let _ = write!(
                    stream,
                    "HTTP/1.1 {status}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                    body.len()
                );
            }
        });
        address
    }

    /// Source for a minimal valid program named `id` importing `imports`.
    fn program_source(id: &str, imports: &[String]) -> String {
        let imports_block =
            imports.iter().map(|import| format!("import {import};\n")).collect::<String>();
        format!("{imports_block}\nprogram {id};\n\nfunction noop:\n    add 1u8 1u8 into r0;\n")
    }

    /// Registers the `latest_edition` and source routes for a minimal valid
    /// program named `id` importing `imports`.
    fn program_routes(
        routes: &mut std::collections::HashMap<String, String>,
        id: &str,
        imports: &[String],
    ) {
        let source = program_source(id, imports);
        routes.insert(format!("/testnet/program/{id}/latest_edition"), "1".to_string());
        routes.insert(format!("/testnet/program/{id}/1"), serde_json::to_string(&source).unwrap());
    }

    // A node claiming `a.aleo -> b.aleo -> a.aleo` must be rejected, not
    // walked forever: such a cycle is impossible on-chain (programs can only
    // import programs deployed before them), so it can only be a lying node.
    #[test]
    fn import_cycle_from_node_rejected() {
        let mut routes = std::collections::HashMap::new();
        program_routes(&mut routes, "cyclea.aleo", &["cycleb.aleo".to_string()]);
        program_routes(&mut routes, "cycleb.aleo", &["cyclea.aleo".to_string()]);
        let url = serve_canned(routes);
        let vm = new_vm().unwrap();
        let error = add_program_from_node(&vm, "cyclea.aleo", &url, "testnet").unwrap_err();
        assert!(error.to_string().contains("import cycle"), "got: {error}");
    }

    // The returned source must declare the requested ID: a node answering the
    // request for one program with another must be rejected.
    #[test]
    fn node_substituting_a_program_rejected() {
        let mut routes = std::collections::HashMap::new();
        program_routes(&mut routes, "evil.aleo", &[]);
        let evil_body = routes["/testnet/program/evil.aleo/1"].clone();
        routes.insert("/testnet/program/honest.aleo/latest_edition".to_string(), "1".to_string());
        routes.insert("/testnet/program/honest.aleo/1".to_string(), evil_body);
        let url = serve_canned(routes);
        let vm = new_vm().unwrap();
        let error = add_program_from_node(&vm, "honest.aleo", &url, "testnet").unwrap_err();
        assert!(error.to_string().contains("returned program"), "got: {error}");
    }

    // The protocol caps a program's direct imports, not transitive chain
    // depth, so a legal chain deeper than any fixed guess must still load
    // (and must not grow the call stack while doing so).
    #[test]
    fn deep_import_chain_loads() {
        const DEPTH: usize = 20;
        let mut routes = std::collections::HashMap::new();
        for i in 0..DEPTH {
            let imports = if i + 1 < DEPTH {
                vec![format!("deep{}.aleo", i + 1)]
            } else {
                Vec::new()
            };
            program_routes(&mut routes, &format!("deep{i}.aleo"), &imports);
        }
        let url = serve_canned(routes);
        let vm = new_vm().unwrap();
        add_program_from_node(&vm, "deep0.aleo", &url, "testnet").unwrap();
        let process = vm.process();
        let process = process.read();
        assert!(process.contains_program(&ProgramID::from_str("deep0.aleo").unwrap()));
        assert!(process
            .contains_program(&ProgramID::from_str(&format!("deep{}.aleo", DEPTH - 1)).unwrap()));
    }

    // An acyclic but endless chain of distinct, individually-valid programs
    // (no cycle, each within protocol limits) must still terminate, on the
    // program-count budget, rather than fetch forever or exhaust memory.
    #[test]
    fn unbounded_import_chain_hits_budget() {
        // Every `deepN.aleo` validly imports `deep{N+1}.aleo`, without end.
        let url = serve_dynamic(|path| {
            let parts: Vec<&str> = path.trim_start_matches('/').split('/').collect();
            // ["testnet", "program", "deepN.aleo", "latest_edition" | "1"]
            if parts.len() != 4 || parts[1] != "program" {
                return None;
            }
            let id = parts[2];
            if parts[3] == "latest_edition" {
                return Some("1".to_string());
            }
            let n: usize = id.strip_prefix("deep")?.strip_suffix(".aleo")?.parse().ok()?;
            let source = program_source(id, &[format!("deep{}.aleo", n + 1)]);
            Some(serde_json::to_string(&source).unwrap())
        });
        let vm = new_vm().unwrap();
        let error = add_program_from_node(&vm, "deep0.aleo", &url, "testnet").unwrap_err();
        assert!(error.to_string().contains("program budget"), "got: {error}");
    }

    // A source larger than the protocol maximum can't be a real program, so it
    // must be rejected (bounding per-fetch memory) rather than parsed.
    #[test]
    fn oversized_program_source_rejected() {
        let mut routes = std::collections::HashMap::new();
        let bloated = format!("program big.aleo;\n{}", " ".repeat(Net::MAX_PROGRAM_SIZE + 1));
        routes.insert("/testnet/program/big.aleo/latest_edition".to_string(), "1".to_string());
        routes.insert(
            "/testnet/program/big.aleo/1".to_string(),
            serde_json::to_string(&bloated).unwrap(),
        );
        let url = serve_canned(routes);
        let vm = new_vm().unwrap();
        let error = add_program_from_node(&vm, "big.aleo", &url, "testnet").unwrap_err();
        assert!(error.to_string().contains("maximum"), "got: {error}");
    }

    // A fee the network would reject must fail before proving, and the
    // base + priority sum must not wrap.
    #[test]
    fn total_fee_capped_at_network_maximum() {
        assert!(check_total_fee(Net::MAX_FEE, 0).is_ok());
        assert!(check_total_fee(Net::MAX_FEE - 1, 1).is_ok());
        let error = check_total_fee(Net::MAX_FEE, 1).unwrap_err();
        assert!(error.to_string().contains("exceeds"), "got: {error}");
        let error = check_total_fee(u64::MAX, 1).unwrap_err();
        assert!(error.to_string().contains("overflows"), "got: {error}");
    }

    // Calls a few exported functions through their C ABI and frees the result,
    // exercising the FFI surface end-to-end (not just internal helpers).
    #[test]
    fn ffi_smoke_through_c_abi() {
        assert_eq!(numbers_add(2, 3), 6); // a + b + 1
        unsafe {
            let seed = [1u8; 32];
            let pk_ptr = seed_to_private_key(seed.as_ptr());
            let pk = CStr::from_ptr(pk_ptr).to_str().unwrap().to_owned();
            assert!(pk.starts_with("APrivateKey1"), "got {pk}");

            let pk_c = CString::new(pk).unwrap();
            let addr_ptr = private_key_to_address(pk_c.as_ptr());
            let addr = CStr::from_ptr(addr_ptr).to_str().unwrap();
            assert!(addr.starts_with("aleo1"), "got {addr}");

            free_string(pk_ptr);
            free_string(addr_ptr);
        }
    }

    // latest_edition reports a program's current edition (token_registry = 1).
    #[test]
    #[ignore = "network: run with `cargo test -- --ignored`"]
    fn node_latest_edition_reads_current_edition() {
        let base = std::env::var("ALEO_NODE_URL")
            .unwrap_or_else(|_| "https://api.explorer.provable.com/v1".to_string())
            + "/testnet";
        assert_eq!(node_latest_edition(&base, "token_registry.aleo").unwrap(), 1);
    }

    // Loading a program pulls in its non-builtin imports recursively
    // (wrapped_credits.aleo imports token_registry.aleo). Hits the public node.
    #[test]
    #[ignore = "network: run with `cargo test -- --ignored`"]
    fn add_program_loads_imports_recursively() {
        let url = std::env::var("ALEO_NODE_URL")
            .unwrap_or_else(|_| "https://api.explorer.provable.com/v1".to_string());
        let vm = new_vm().unwrap();
        add_program_from_node(&vm, "wrapped_credits.aleo", &url, "testnet").unwrap();
        let process = vm.process();
        let process = process.read();
        assert!(process.contains_program(&ProgramID::from_str("wrapped_credits.aleo").unwrap()));
        assert!(
            process.contains_program(&ProgramID::from_str("token_registry.aleo").unwrap()),
            "recursive import token_registry.aleo was not loaded"
        );
    }
}
