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

/// SAFETY: `p` must be a valid NUL-terminated C string for the duration of the call.
unsafe fn read_str<'a>(p: *const c_char) -> &'a str {
    CStr::from_ptr(p).to_str().expect("invalid UTF-8 in FFI input")
}

/// Transfers ownership of a heap C string to the caller (matches the existing
/// FFI contract; the caller is responsible for the buffer).
fn to_cstring(s: String) -> *mut c_char {
    CString::new(s).expect("unexpected NUL in FFI output").into_raw()
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

/// SAFETY: `pk` must be a valid NUL-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn private_key_to_address(pk: *const c_char) -> *mut c_char {
    let private_key = PrivateKey::<Net>::from_str(read_str(pk)).expect("parse private key");
    let address = Address::<Net>::try_from(&private_key).expect("private key -> address");
    to_cstring(address.to_string())
}

/// SAFETY: `pk` must be a valid NUL-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn private_key_to_view_key(pk: *const c_char) -> *mut c_char {
    let private_key = PrivateKey::<Net>::from_str(read_str(pk)).expect("parse private key");
    let view_key = ViewKey::<Net>::try_from(&private_key).expect("private key -> view key");
    to_cstring(view_key.to_string())
}

/// SAFETY: `vk` must be a valid NUL-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn view_key_to_address(vk: *const c_char) -> *mut c_char {
    let view_key = ViewKey::<Net>::from_str(read_str(vk)).expect("parse view key");
    to_cstring(view_key.to_address().to_string())
}

/// SAFETY: `pk` is a NUL-terminated C string; `msg` points to `len` readable bytes.
#[no_mangle]
pub unsafe extern "C" fn sign_message(pk: *const c_char, msg: *const u8, len: c_int) -> *mut c_char {
    let private_key = PrivateKey::<Net>::from_str(read_str(pk)).expect("parse private key");
    let message = slice::from_raw_parts(msg, len as usize);
    let signature = private_key.sign_bytes(message, &mut OsRng).expect("sign");
    to_cstring(signature.to_string())
}

/// Returns 1 if the signature is valid, 0 otherwise.
///
/// SAFETY: `addr`/`sig` are NUL-terminated C strings; `msg` points to `len` readable bytes.
#[no_mangle]
pub unsafe extern "C" fn verify(
    addr: *const c_char,
    sig: *const c_char,
    msg: *const u8,
    len: c_int,
) -> c_int {
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

/// Shared HTTP agent with bounded timeouts. `ureq`'s defaults only bound the
/// connect phase, so a node that accepts the connection and then stalls would
/// hang the (synchronous) FFI call forever and the retry loop would never run.
/// The read/write timeouts cap each attempt so a stalled peer surfaces as an
/// error and is retried.
fn http_agent() -> &'static ureq::Agent {
    static AGENT: std::sync::OnceLock<ureq::Agent> = std::sync::OnceLock::new();
    AGENT.get_or_init(|| {
        ureq::AgentBuilder::new()
            .timeout_connect(std::time::Duration::from_secs(10))
            .timeout_read(std::time::Duration::from_secs(30))
            .timeout_write(std::time::Duration::from_secs(30))
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
        commitments.iter().map(|commitment| self.get_state_path_for_commitment(commitment)).collect()
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
    amount: i64,
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

/// Fetches a non-builtin program from the node and adds it to the VM, loading
/// every imported program first (snarkVM rejects a program whose imports are
/// not already present). A no-op for built-in programs like credits.aleo or any
/// program already loaded.
///
/// The current edition is read first, then the source is fetched *at that
/// edition* (`/program/{id}/{edition}`) so the two are consistent even if the
/// program is upgraded concurrently. Edition 0 (first-deployed, constructor-
/// bearing programs) is added via `add_program`, which execution permits;
/// non-upgradeable programs are edition 1, upgraded programs their bumped
/// edition. A wrong edition would yield a proof that disagrees with chain state,
/// so any failure to determine it (e.g. a node without the route) propagates.
fn add_program_from_node(
    vm: &VM<Net, ConsensusMemory<Net>>,
    program_id: &str,
    url: &str,
    network: &str,
) -> anyhow::Result<()> {
    // Skip built-ins and anything already loaded (without holding the lock
    // across the recursion below).
    {
        let process = vm.process();
        let process = process.read();
        if program_id == "credits.aleo"
            || process.contains_program(&ProgramID::from_str(program_id)?)
        {
            return Ok(());
        }
    }

    let base = format!("{}/{}", url.trim_end_matches('/'), network);
    let edition = node_latest_edition(&base, program_id)?;
    let body = http_get(&format!("{base}/program/{program_id}/{edition}"))?;
    let source: String = serde_json::from_str(body.trim())?;
    let program = Program::<Net>::from_str(&source)?;

    // Load imports (which may themselves import others) before this program.
    for import_id in program.imports().keys() {
        add_program_from_node(vm, &import_id.to_string(), url, network)?;
    }

    let process = vm.process();
    let mut process = process.write();
    // A diamond import graph may have added it during the recursion above.
    if !process.contains_program(program.id()) {
        if edition == 0 {
            process.add_program(&program)?;
        } else {
            process.add_program_with_edition(&program, edition)?;
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
    amount: c_int,
    fee_credits: c_int,
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
            amount as i64,
            read_str(amount_record),
            &private_key,
        )?;
        full_transaction(
            &private_key,
            "credits.aleo",
            function,
            inputs,
            fee_credits as u64,
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
    amount: c_int,
    fee_credits: c_int,
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
            amount as i64,
            read_str(amount_record),
            &private_key,
        )?;
        let transaction = full_transaction(
            &private_key,
            "credits.aleo",
            function,
            inputs,
            fee_credits as u64,
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
    fee: c_int,
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
            fee as u64,
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
    fee: c_int,
    execution: *const c_char,
    program_id: *const c_char,
    url: *const c_char,
    network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        program_fee(
            &private_key,
            fee as u64,
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
    fee_credits: c_int,
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
            fee_credits as u64,
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
    amount: c_int,
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
            amount as i64,
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
        let response = ureq::post(&format!("{base}/transaction/broadcast"))
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

/// Returns the base (minimum) fee in microcredits for a serialized execution.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn get_base_fee(
    url: *const c_char,
    execution: *const c_char,
    network: *const c_char,
) -> c_int {
    let inner = || -> anyhow::Result<u64> {
        let execution: Execution<Net> = serde_json::from_str(read_str(execution))?;
        base_fee_for(&execution, read_str(url), read_str(network))
    };
    inner().map(|fee| fee as c_int).unwrap_or(0)
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
    fee_credits: c_int,
    fee_record: *const c_char,
    execution: *const c_char,
    network: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        let execution: Execution<Net> = serde_json::from_str(read_str(execution))?;
        let execution_id = execution.to_execution_id()?;
        let base_fee = base_fee_for(&execution, read_str(url), read_str(network))?;
        let priority_fee = fee_credits as u64;
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
/// SAFETY: `execution`/`fee` are NUL-terminated C strings (snarkVM serde JSON).
#[no_mangle]
pub unsafe extern "C" fn build_transaction_offline(
    execution: *const c_char,
    fee: *const c_char,
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
