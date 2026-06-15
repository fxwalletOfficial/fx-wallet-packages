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

use std::collections::{HashMap, HashSet};
use std::ffi::{c_char, c_int, CStr, CString};
use std::slice;

use rand::rngs::OsRng;
use snarkvm_console::account::{Address, PrivateKey, Signature, ViewKey};
use snarkvm_console::network::{MainnetV0, TestnetV0};
use snarkvm_console::prelude::*;
use snarkvm_console::program::{
    Ciphertext, Identifier, InputID, Literal, Plaintext, ProgramID, Record,
};
use snarkvm_console::types::Field;
use snarkvm_console::program::StatePath;
use snarkvm_ledger_block::{Execution, Fee, Transaction};
use snarkvm_ledger_query::StaticQuery;
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

/// Borrows a C string as `&str`. A null pointer or invalid UTF-8 yields "" rather
/// than reading out of bounds / panicking, so malformed or absent input is handled
/// by the caller's normal "" / error path instead of undefined behaviour or
/// unwinding across the FFI boundary (which aborts the process). `CStr::from_ptr`
/// is UB on null, and that UB happens before — and cannot be caught by — the
/// `catch_unwind` envelope wrapper, so the null check must live here.
///
/// SAFETY: `p` is null, or a valid NUL-terminated C string for the duration of the
/// call.
unsafe fn read_str<'a>(p: *const c_char) -> &'a str {
    if p.is_null() {
        return "";
    }
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
fn new_vm<N: Network>() -> anyhow::Result<VM<N, ConsensusMemory<N>>> {
    VM::from(ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?)
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

/// True for built-in programs and anything already loaded in the process.
fn program_is_present<N: Network>(vm: &VM<N, ConsensusMemory<N>>, id: &ProgramID<N>) -> bool {
    id.to_string() == "credits.aleo" || vm.process().read().contains_program(id)
}

/// Adds a fetched program to the process at its edition. Edition 0
/// (first-deployed, constructor-bearing programs) goes through `add_program`,
/// which execution permits; non-upgradeable programs are edition 1, upgraded
/// programs their bumped edition. A wrong edition would yield a proof that
/// disagrees with chain state, so edition determination failures propagate.
///
/// `add_program_with_edition` builds and verifies the program's `Stack` —
/// real CPU work that snarkVM exposes no way to interrupt. The caller checks
/// the load deadline *before* each call, so no new add starts once the budget
/// is spent, but a call already under way runs to completion: the deadline
/// bounds when adds *start*, with an overshoot of at most one program's add.
fn add_fetched_program<N: Network>(
    vm: &VM<N, ConsensusMemory<N>>,
    program: &Program<N>,
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

// ----------------------------------------------------------------------------
// I/O-to-Dart migration (docs/network-io-to-dart.md): RPC-free proving/fee
// surface, plus small helpers that let Dart discover what to fetch. These take
// pre-fetched node data (`height`, `state_paths_json`, `public_state_root`,
// `program_sources_json`) instead of a `url`/`network` to query, so these
// exports issue no node RPC — all node I/O lives in the Dart `AleoNode`. Phase 3
// deleted the old in-Rust HTTP path (the 12 network exports). The proving/fee
// primitives KEEP their `_static` symbol names: those names never collided with
// an old export, so a stale prebuilt library (which lacks them) fails Dart's
// `lookupFunction` with a clear missing-symbol error. Renaming them to the
// now-free canonical names is deferred to the phase-4 lib redistribution, where
// it can land atomically with a rebuilt/redistributed library + an ABI-version
// guard — reusing a freed name whose ABI differs in an already-distributed lib
// would turn that clean error into a silent ABI mismatch. NOTE: this is still
// not "zero network" — snarkVM's proving lazily downloads proving keys / the SRS
// via `curl` (no timeout) on a cold parameter cache, so the crate still links
// curl/openssl; removing that is a separate task (phase 4, see the spec's
// "Proving parameters" section).
// ----------------------------------------------------------------------------

/// Assumed serialized size of one `StatePath`, used *only* as a factor to derive
/// the overall `state_paths_json` byte cap (× [`max_state_paths`]); there is no
/// per-path size check. A real serialized state path is a few KB, so this sits
/// well above any honest path — the whole-blob cap is what bounds memory before
/// serde.
const MAX_STATE_PATH_BYTES: usize = 16 * 1024;

/// Generous byte ceiling on a `public_state_root` string (a bech32 `sr1…` root
/// is ~63 chars); bounds untrusted input before parsing.
const MAX_STATE_ROOT_BYTES: usize = 256;

/// The most state paths a single execution can legitimately require: at most
/// `MAX_INPUTS` record inputs per transition across at most `MAX_TRANSITIONS`
/// transitions. The protocol bounds the required commitments to this, so it is a
/// tight, protocol-grounded entry cap on the node-supplied `state_paths_json`.
fn max_state_paths<N: Network>() -> usize {
    N::MAX_INPUTS.saturating_mul(Transaction::<N>::MAX_TRANSITIONS)
}

/// Parses node-supplied state paths, rejecting an oversized blob *before* serde
/// (byte budget) and an over-long array *after* (entry budget). An empty/blank
/// input is an empty set (a public flow with no record inputs).
fn parse_state_paths<N: Network>(state_paths_json: &str) -> anyhow::Result<Vec<StatePath<N>>> {
    let state_paths_json = state_paths_json.trim();
    if state_paths_json.is_empty() {
        return Ok(Vec::new());
    }
    let byte_budget = max_state_paths::<N>().saturating_mul(MAX_STATE_PATH_BYTES);
    anyhow::ensure!(
        state_paths_json.len() <= byte_budget,
        "state_paths_json is {} bytes, over the {byte_budget}-byte budget",
        state_paths_json.len()
    );
    let paths: Vec<StatePath<N>> = serde_json::from_str(state_paths_json)?;
    anyhow::ensure!(
        paths.len() <= max_state_paths::<N>(),
        "state_paths_json has {} entries, over the {}-entry budget",
        paths.len(),
        max_state_paths::<N>()
    );
    Ok(paths)
}

/// Builds the offline [`StaticQuery`] the proving primitives run against, from
/// pre-fetched node data. Dart only ever passes opaque strings it got from the
/// node; Rust derives and verifies the global state root here:
///
/// - **Private flow** (non-empty `state_paths_json`): every path must agree on
///   its `global_state_root`; that shared root is used and the map is keyed by
///   each path's record commitment (`transition_leaf().id()`). If
///   `public_state_root` is also supplied it must equal the derived root.
/// - **Public flow** (empty `state_paths_json`): there is no path to derive
///   from, so the caller's `public_state_root` (the `latest/stateRoot` it
///   fetched) is used directly.
fn static_query(
    height: u32,
    state_paths_json: &str,
    public_state_root: &str,
) -> anyhow::Result<StaticQuery<Net>> {
    static_query_from_paths(height, parse_state_paths(state_paths_json)?, public_state_root)
}

/// [`static_query`] over already-parsed paths, so a caller that parsed the JSON
/// once (the exact-match guard) does not pay the serde cost twice on a
/// budget-sized blob.
fn static_query_from_paths<N: Network>(
    height: u32,
    paths: Vec<StatePath<N>>,
    public_state_root: &str,
) -> anyhow::Result<StaticQuery<N>> {
    let public_state_root = public_state_root.trim();
    anyhow::ensure!(
        public_state_root.len() <= MAX_STATE_ROOT_BYTES,
        "public_state_root is {} bytes, over the {MAX_STATE_ROOT_BYTES}-byte budget",
        public_state_root.len()
    );

    if paths.is_empty() {
        anyhow::ensure!(
            !public_state_root.is_empty(),
            "public flow (no state paths) requires a public_state_root"
        );
        let state_root = <N as Network>::StateRoot::from_str(public_state_root)
            .map_err(|_| anyhow::anyhow!("invalid public_state_root"))?;
        return Ok(StaticQuery::new(height, state_root, HashMap::new()));
    }

    // Private flow: derive the snapshot root from the paths; all must agree.
    let state_root = paths[0].global_state_root();
    let mut state_paths = HashMap::with_capacity(paths.len());
    for path in paths {
        anyhow::ensure!(
            path.global_state_root() == state_root,
            "state paths disagree on the global state root"
        );
        // A global state path proves an output record's commitment is on-chain;
        // that commitment is the transition leaf's id, which is how the query
        // looks paths up during proving.
        let commitment = path.transition_leaf().id();
        anyhow::ensure!(
            state_paths.insert(commitment, path).is_none(),
            "duplicate state path for commitment {commitment}"
        );
    }
    if !public_state_root.is_empty() {
        let supplied = <N as Network>::StateRoot::from_str(public_state_root)
            .map_err(|_| anyhow::anyhow!("invalid public_state_root"))?;
        anyhow::ensure!(
            supplied == state_root,
            "public_state_root disagrees with the state paths' derived root"
        );
    }
    Ok(StaticQuery::new(height, state_root, state_paths))
}

/// [`static_query`] with the phase-2 exact-match guard: the supplied state
/// paths' commitment set must equal exactly the commitments `authorization`
/// will prove inclusion for (`global_commitment_set`) — no missing path (proving
/// would fail anyway) and, crucially, no *extra* one. Without this, an untrusted
/// node could pad the response with unrelated valid state paths; the byte/entry
/// budget bounds size but not relevance. This is the tighter, protocol-grounded
/// bound the phase-1 primitives deferred to phase 2.
fn checked_static_query<N: Network>(
    authorization: &Authorization<N>,
    height: u32,
    state_paths_json: &str,
    public_state_root: &str,
) -> anyhow::Result<StaticQuery<N>> {
    let expected: HashSet<String> = global_commitment_set(authorization).into_iter().collect();
    // Parse once, here, and hand the parsed paths to `static_query_from_paths`
    // (rather than `static_query`, which would re-parse the budget-sized blob).
    let paths: Vec<StatePath<N>> = parse_state_paths(state_paths_json)?;
    let actual: HashSet<String> =
        paths.iter().map(|path| path.transition_leaf().id().to_string()).collect();
    anyhow::ensure!(
        actual == expected,
        "state paths' commitment set ({} entries) does not match the authorization's \
         {} required commitment(s)",
        actual.len(),
        expected.len()
    );
    static_query_from_paths(height, paths, public_state_root)
}

/// Base (minimum) fee in microcredits for an execution at the given height:
/// `height` selects the consensus version instead of a node fetch (the node I/O
/// now lives in Dart). `program_sources_json` supplies the execution's root
/// program (and its imports) — snarkVM's `execution_cost` reads each transition's
/// program `Stack`, so a non-builtin execution needs them loaded first. Empty
/// for a credits.aleo execution (the program is built in).
fn base_fee_at_height(
    execution: &Execution<Net>,
    program_sources_json: &str,
    height: u32,
) -> anyhow::Result<u64> {
    let consensus_version = Net::CONSENSUS_VERSION(height)?;
    let vm = new_vm()?;
    add_programs_from_sources(&vm, program_sources_json)?;
    let process = vm.process();
    let process = process.read();
    let (base_fee, _details) =
        snarkvm_synthesizer::process::execution_cost(&process, execution, consensus_version)?;
    Ok(base_fee)
}

/// One `{id, edition, source}` entry of a caller-supplied program closure.
#[derive(serde::Deserialize)]
struct ProgramSourceEntry {
    id: String,
    edition: u16,
    source: String,
}

/// Adds programs supplied as in-memory sources (the whole import closure, in any
/// order) to the VM, imports-before-importers — the offline program loader (the
/// node fetch now lives in Dart, which supplies the closure as JSON). Applies a
/// per-program id-match and `MAX_PROGRAM_SIZE` check, the program-count and
/// total-byte budget, and a
/// wall-clock deadline. The deadline matters even with no network I/O left:
/// `Program::from_str` and `add_program_with_edition` (Stack construction) are
/// expensive, uninterruptible CPU work, so a hostile closure of up to
/// `MAX_IMPORT_PROGRAMS` large-but-valid programs could otherwise block this
/// synchronous FFI call for a long time — and the Dart-side network timeout
/// cannot interrupt work already inside the FFI. Only the *thread/in-flight*
/// machinery is dropped (no blocking I/O left to bound). A missing import or an
/// import cycle in the supplied set is rejected as the walk stalls with programs
/// left unadded.
fn add_programs_from_sources<N: Network>(
    vm: &VM<N, ConsensusMemory<N>>,
    program_sources_json: &str,
) -> anyhow::Result<()> {
    add_programs_from_sources_within(
        vm,
        program_sources_json,
        std::time::Instant::now() + IMPORT_LOAD_DEADLINE,
    )
}

/// [`add_programs_from_sources`] with an explicit `deadline`, so a caller (or
/// test) can bound the whole load. The deadline is checked before each
/// `Program::from_str` and before each program is added, so an over-budget call
/// stops starting new CPU-bound work instead of parsing/building all of them; a
/// single in-flight add still runs to completion (snarkVM exposes no way to
/// interrupt it), an overshoot of at most one program.
fn add_programs_from_sources_within<N: Network>(
    vm: &VM<N, ConsensusMemory<N>>,
    program_sources_json: &str,
    deadline: std::time::Instant,
) -> anyhow::Result<()> {
    let program_sources_json = program_sources_json.trim();
    if program_sources_json.is_empty() {
        return Ok(());
    }
    // Total-byte budget before serde: `MAX_PROGRAM_SIZE` caps a single program,
    // not the set, so an unbounded acyclic closure is bounded here in aggregate.
    let byte_budget = MAX_IMPORT_PROGRAMS.saturating_mul(N::MAX_PROGRAM_SIZE);
    anyhow::ensure!(
        program_sources_json.len() <= byte_budget,
        "program_sources_json is {} bytes, over the {byte_budget}-byte budget",
        program_sources_json.len()
    );
    let entries: Vec<ProgramSourceEntry> = serde_json::from_str(program_sources_json)?;
    anyhow::ensure!(
        entries.len() <= MAX_IMPORT_PROGRAMS,
        "program_sources_json has {} programs, over the {MAX_IMPORT_PROGRAMS}-program budget",
        entries.len()
    );

    // Parse and validate each program; the node is not trusted, so a source over
    // the protocol maximum or one not declaring its claimed id is rejected.
    // Parsing is uninterruptible CPU work, so gate every one on the deadline.
    let mut pending: HashMap<ProgramID<N>, (Program<N>, u16)> = HashMap::new();
    for entry in entries {
        anyhow::ensure!(
            std::time::Instant::now() < deadline,
            "program load exceeded its {IMPORT_LOAD_DEADLINE:?} time budget"
        );
        anyhow::ensure!(
            entry.source.len() <= N::MAX_PROGRAM_SIZE,
            "program '{}' source is {} bytes, over the {}-byte maximum",
            entry.id,
            entry.source.len(),
            N::MAX_PROGRAM_SIZE
        );
        let program = Program::<N>::from_str(&entry.source)?;
        let declared = ProgramID::<N>::from_str(&entry.id)?;
        anyhow::ensure!(
            program.id() == &declared,
            "program source declares '{}' but the entry id is '{declared}'",
            program.id()
        );
        anyhow::ensure!(
            pending.insert(declared, (program, entry.edition)).is_none(),
            "duplicate program '{declared}' in program_sources_json"
        );
    }

    // Add in dependency order: each pass adds every program whose imports are all
    // already present (built-in or added on an earlier pass). If a pass adds
    // nothing while programs remain, an import is missing from the supplied set
    // or the set has a cycle — either way the caller's closure is rejected.
    while !pending.is_empty() {
        let ready: Vec<ProgramID<N>> = pending
            .iter()
            .filter(|(_, (program, _))| {
                program.imports().keys().all(|import| program_is_present(vm, import))
            })
            .map(|(id, _)| *id)
            .collect();
        anyhow::ensure!(
            !ready.is_empty(),
            "program_sources_json has unresolved imports or an import cycle"
        );
        for id in ready {
            // `add_program_with_edition` builds the program's Stack — real CPU
            // work snarkVM cannot interrupt — so gate every add on the deadline.
            anyhow::ensure!(
                std::time::Instant::now() < deadline,
                "program load exceeded its {IMPORT_LOAD_DEADLINE:?} time budget"
            );
            let (program, edition) = pending.remove(&id).expect("a ready id is pending");
            add_fetched_program(vm, &program, edition)?;
        }
    }
    Ok(())
}

/// Given each transition's record-input and record-output commitments **in
/// execution order**, returns the global (on-chain) input commitments. Mirrors
/// snarkVM's `Inclusion::insert_transition`: an input record is *local* only if
/// an *earlier* transition output it — a later transition's output never makes
/// an earlier input local (that would drop a real on-chain commitment and miss
/// its state path). Split out so the order-sensitive logic is unit-tested.
fn global_input_commitments(transitions: &[(Vec<String>, Vec<String>)]) -> Vec<String> {
    let mut local: HashSet<String> = HashSet::new();
    let mut global = Vec::new();
    for (inputs, outputs) in transitions {
        // Judge this transition's inputs against outputs accumulated so far...
        for commitment in inputs {
            if !local.contains(commitment) {
                global.push(commitment.clone());
            }
        }
        // ...then add this transition's outputs (visible only to later ones).
        for commitment in outputs {
            local.insert(commitment.clone());
        }
    }
    global
}

/// The global input-record commitments an authorization will prove inclusion
/// for — exactly the keys `static_query`'s map must contain. Shared by the
/// [`required_commitments`] export (what Dart fetches state paths for) and the
/// proving primitives' exact-match guard (so a node can supply neither extra nor
/// missing paths). The `tcm` pairing + execution-order local filter mirror
/// `Inclusion::insert_transition`; see [`required_commitments`].
fn global_commitment_set<N: Network>(authorization: &Authorization<N>) -> Vec<String> {
    let mut inputs_by_tcm: HashMap<String, Vec<String>> = HashMap::new();
    for request in authorization.to_vec_deque() {
        let entry = inputs_by_tcm.entry(request.tcm().to_string()).or_default();
        for input_id in request.input_ids() {
            if let InputID::Record(commitment, ..) = input_id {
                entry.push(commitment.to_string());
            }
        }
    }
    let mut ordered = Vec::new();
    for (_, transition) in authorization.transitions() {
        let inputs =
            inputs_by_tcm.get(&transition.tcm().to_string()).cloned().unwrap_or_default();
        let outputs = transition
            .outputs()
            .iter()
            .filter_map(|output| output.commitment().map(|commitment| commitment.to_string()))
            .collect();
        ordered.push((inputs, outputs));
    }
    global_input_commitments(&ordered)
}

/// The input-record commitments whose state paths the caller must fetch before
/// proving this authorization. Empty for public flows (no record inputs).
/// Pure: read from the authorization itself, no VM/synthesis or network.
///
/// This mirrors exactly what proving asks the query for: `Trace::prepare`
/// collects the input-record commitments whose record is NOT an output of an
/// *earlier* transition in the same transaction (a "local" record, which is not
/// on-chain and has no state path). `vm.authorize` already populates the
/// authorization's transitions (with their record outputs). Requests are stored
/// pre-order and transitions in execution order, so they are paired by `tcm`
/// (the same key `Authorization::try_from` uses), and the local filter is
/// applied in execution order — a later transition's output cannot retroactively
/// make an earlier input local. For the single-request credits flows (transfer /
/// join / upgrade) the outputs are freshly-created records, so nothing is
/// dropped; for a composite program that spends a record minted by an earlier
/// transition, that local commitment is correctly excluded.
///
/// SAFETY: `authorization` is a NUL-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn required_commitments(authorization: *const c_char) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let authorization: Authorization<Net> = serde_json::from_str(read_str(authorization))?;
        Ok(serde_json::to_string(&global_commitment_set(&authorization))?)
    };
    match inner() {
        Ok(commitments) => to_cstring(commitments),
        Err(_) => to_cstring(String::new()),
    }
}

/// The direct imports of a program, as a JSON array of program ids, so Dart can
/// walk the closure it must fetch (Dart recurses; this stays a pure per-program
/// function). Returns "" on a malformed/oversized source.
///
/// SAFETY: `program_source` is a NUL-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn required_imports(program_source: *const c_char) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let source = read_str(program_source);
        anyhow::ensure!(
            source.len() <= Net::MAX_PROGRAM_SIZE,
            "program source is {} bytes, over the {}-byte maximum",
            source.len(),
            Net::MAX_PROGRAM_SIZE
        );
        let program = Program::<Net>::from_str(source)?;
        let imports: Vec<String> = program.imports().keys().map(|id| id.to_string()).collect();
        Ok(serde_json::to_string(&imports)?)
    };
    match inner() {
        Ok(imports) => to_cstring(imports),
        Err(_) => to_cstring(String::new()),
    }
}

/// The global state root shared by a non-empty batch of state paths — a
/// convenience for callers that want the snapshot root for logging/caching
/// (proving derives it itself). Returns "" if the paths are empty or disagree.
///
/// SAFETY: `state_paths_json` is a NUL-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn state_root_from_paths(state_paths_json: *const c_char) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let paths = parse_state_paths::<Net>(read_str(state_paths_json))?;
        let state_root =
            paths.first().ok_or_else(|| anyhow::anyhow!("no state paths"))?.global_state_root();
        for path in &paths {
            anyhow::ensure!(
                path.global_state_root() == state_root,
                "state paths disagree on the global state root"
            );
        }
        Ok(state_root.to_string())
    };
    match inner() {
        Ok(root) => to_cstring(root),
        Err(_) => to_cstring(String::new()),
    }
}

/// The consensus version active at `height`, so Dart can pin one version for a
/// whole transaction without hardcoding upgrade heights. Returns 0 on failure
/// (only height 0 with no V1 mapping, which never happens for the live network).
#[no_mangle]
pub extern "C" fn consensus_version_for(height: u32) -> u16 {
    Net::CONSENSUS_VERSION(height).map(|version| version as u16).unwrap_or(0)
}

/// Pure variant of [`get_base_fee_static`]: `height` (→ consensus version) replaces the
/// node fetch, and `program_sources_json` supplies the execution's root program
/// (+ imports) needed to compute its cost — empty for a credits.aleo execution.
/// Returns the base fee in microcredits, or 0 on failure.
///
/// SAFETY: `execution`/`program_sources_json` are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn get_base_fee_static(
    execution: *const c_char,
    program_sources_json: *const c_char,
    height: u32,
) -> u64 {
    let inner = || -> anyhow::Result<u64> {
        let execution: Execution<Net> = serde_json::from_str(read_str(execution))?;
        base_fee_at_height(&execution, read_str(program_sources_json), height)
    };
    inner().unwrap_or(0)
}

/// Pure variant of [`execution_fee_authorization_static`]: `height` replaces the node
/// fetch used to derive the base fee, and `program_sources_json` supplies the
/// execution's root program (+ imports) needed to compute that fee (empty for a
/// credits.aleo execution). `fee_credits` is the priority fee; an empty
/// `fee_record` uses a public fee, otherwise a private fee spending that record.
/// Returns "" on failure.
///
/// SAFETY: `private_key`/`execution`/`fee_record`/`program_sources_json` are
/// NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn execution_fee_authorization_static(
    private_key: *const c_char,
    execution: *const c_char,
    fee_credits: u64,
    fee_record: *const c_char,
    program_sources_json: *const c_char,
    height: u32,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        let execution: Execution<Net> = serde_json::from_str(read_str(execution))?;
        let execution_id = execution.to_execution_id()?;
        // One VM loads the execution's program(s) so its cost can be computed,
        // then authorizes the fee (credits.aleo is built in) — no second VM.
        let consensus_version = Net::CONSENSUS_VERSION(height)?;
        let vm = new_vm()?;
        add_programs_from_sources(&vm, read_str(program_sources_json))?;
        let base_fee = {
            let process = vm.process();
            let process = process.read();
            snarkvm_synthesizer::process::execution_cost(&process, &execution, consensus_version)?.0
        };
        let priority_fee = fee_credits;
        check_total_fee(base_fee, priority_fee)?;
        let fee_record = read_str(fee_record);
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

/// Pure variant of [`execute_proof_static`]: proves an authorization against a
/// [`StaticQuery`] built from pre-fetched `height` / `state_paths_json` /
/// `public_state_root` instead of querying a node. Returns the serialized
/// execution, or "" on failure.
///
/// SAFETY: `authorization`/`state_paths_json`/`public_state_root` are
/// NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn execute_proof_static(
    authorization: *const c_char,
    height: u32,
    state_paths_json: *const c_char,
    public_state_root: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let authorization: Authorization<Net> = serde_json::from_str(read_str(authorization))?;
        let query = checked_static_query(
            &authorization,
            height,
            read_str(state_paths_json),
            read_str(public_state_root),
        )?;
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

/// Pure variant of [`execute_fee_proof_static`]: proves a fee authorization against a
/// [`StaticQuery`] built from pre-fetched node data. A private fee spends its
/// own record, so its `state_paths_json` is its own snapshot (distinct from the
/// execution's); a public fee passes empty paths + a `public_state_root`.
/// Returns the serialized fee, or "" on failure.
///
/// SAFETY: `authorization`/`state_paths_json`/`public_state_root` are
/// NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn execute_fee_proof_static(
    authorization: *const c_char,
    height: u32,
    state_paths_json: *const c_char,
    public_state_root: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let authorization: Authorization<Net> = serde_json::from_str(read_str(authorization))?;
        let query = checked_static_query(
            &authorization,
            height,
            read_str(state_paths_json),
            read_str(public_state_root),
        )?;
        let vm = new_vm()?;
        let fee = vm.execute_fee_authorization_raw(authorization, &query, &mut rand::thread_rng())?;
        Ok(serde_json::to_string(&fee)?)
    };
    match inner() {
        Ok(fee) => to_cstring(fee),
        Err(_) => to_cstring(String::new()),
    }
}

/// Pure variant of [`execute_program_proof_static`]: the referenced program (and its
/// import closure) is supplied in-memory via `program_sources_json` rather than
/// fetched from a node, then the authorization is proved against a
/// [`StaticQuery`] built from pre-fetched node data. Returns the serialized
/// execution, or "" on failure.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn execute_program_proof_static(
    authorization: *const c_char,
    program_sources_json: *const c_char,
    height: u32,
    state_paths_json: *const c_char,
    public_state_root: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let authorization: Authorization<Net> = serde_json::from_str(read_str(authorization))?;
        let vm = new_vm()?;
        add_programs_from_sources(&vm, read_str(program_sources_json))?;
        let query = checked_static_query(
            &authorization,
            height,
            read_str(state_paths_json),
            read_str(public_state_root),
        )?;
        let (execution, _response) =
            vm.execute_authorization_raw(authorization, &query, &mut rand::thread_rng())?;
        Ok(serde_json::to_string(&execution)?)
    };
    match inner() {
        Ok(execution) => to_cstring(execution),
        Err(_) => to_cstring(String::new()),
    }
}

/// Builds an execution authorization for an arbitrary program function, offline.
/// The referenced program (and its imports) is supplied in-memory via
/// `program_sources_json` and loaded before authorizing — `vm.authorize` reads
/// the program's `Stack`, so a non-builtin function cannot be authorized without
/// it. `arguments` is a JSON array of Aleo value strings (record inputs already
/// decrypted to plaintext by the caller, as on the old `contract_execution`
/// path). This is the pure-FFI authorize step the phase-2 Dart orchestration
/// uses for arbitrary programs, replacing the network-bound
/// `contract_execution` / `execute_program`. Empty `program_sources_json` works
/// for a built-in program (credits.aleo). Returns "" on failure.
///
/// SAFETY: the pointer args are NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn program_authorization_static(
    private_key: *const c_char,
    program_id: *const c_char,
    function_name: *const c_char,
    arguments: *const c_char,
    program_sources_json: *const c_char,
) -> *mut c_char {
    let inner = || -> anyhow::Result<String> {
        let private_key = PrivateKey::<Net>::from_str(read_str(private_key))?;
        let inputs: Vec<String> = serde_json::from_str(read_str(arguments))?;
        let vm = new_vm()?;
        add_programs_from_sources(&vm, read_str(program_sources_json))?;
        let authorization = vm.authorize(
            &private_key,
            read_str(program_id),
            read_str(function_name),
            inputs,
            &mut rand::thread_rng(),
        )?;
        Ok(serde_json::to_string(&authorization)?)
    };
    match inner() {
        Ok(authorization) => to_cstring(authorization),
        Err(_) => to_cstring(String::new()),
    }
}

// ── Phase 4 FFI result envelope (docs/phase4-plan.md §8 Contract 1) ──────────
//
// New (PR2+) exports return a tagged, fail-closed JSON envelope instead of the
// legacy ""-on-failure convention, so the Dart side can tell success from every
// failure mode and never mistakes a non-empty error string for a proof. All such
// exports run through `ffi_envelope`, which catches any unwinding panic — e.g. a
// poisoned snarkVM parameter `lazy_static` — and reports it as the non-retryable
// `restart_required` rather than letting it unwind across the C ABI (UB/abort).
//
//   ok:    {"ok":true, …}                       // per-export fields: `data`, `missing`, …
//   error: {"ok":false,"code":…,"message":…}
struct Envelope(serde_json::Value);

impl Envelope {
    /// `{"ok":true}` with no payload.
    fn ok() -> Self {
        Self(serde_json::json!({ "ok": true }))
    }

    /// `{"ok":true,"data":<data>}`.
    fn ok_data(data: impl serde::Serialize) -> Self {
        Self(serde_json::json!({ "ok": true, "data": data }))
    }

    /// `{"ok":false,"code":<code>,"message":<message>}`.
    fn err(code: &str, message: impl Into<String>) -> Self {
        Self(serde_json::json!({ "ok": false, "code": code, "message": message.into() }))
    }

    /// Serializes to the wire JSON. Infallible: a (never-expected) serialization
    /// failure collapses to a constant fail-closed envelope rather than panicking
    /// inside the panic-handling path.
    fn to_json(&self) -> String {
        serde_json::to_string(&self.0).unwrap_or_else(|_| {
            r#"{"ok":false,"code":"restart_required","message":"envelope serialization failed"}"#
                .to_string()
        })
    }
}

/// Runs `f` under `catch_unwind` and renders its [`Envelope`] (or a
/// `restart_required` envelope on panic) to an owned C string. This is the single
/// choke point that keeps panics from crossing the C ABI; `[profile.release]
/// panic = "unwind"` (Cargo.toml) keeps it effective in release builds.
///
/// `AssertUnwindSafe` is sound here: the closures only borrow caller-provided
/// input and compute over snarkVM types. aleo_ffi holds no lock or invariant a
/// panic could leave inconsistent — the only cross-call state is snarkVM's
/// process-global parameter cache, whose poisoning is exactly what
/// `restart_required` signals to the caller.
fn ffi_envelope(f: impl FnOnce() -> Envelope) -> *mut c_char {
    let env = std::panic::catch_unwind(std::panic::AssertUnwindSafe(f))
        .unwrap_or_else(|_| Envelope::err("restart_required", "panic during FFI call"));
    to_cstring(env.to_json())
}

/// Overrides the directory proving parameters are read from / written to (e.g. a
/// mobile app sandbox; snarkVM has no env override). Set-once — see §8 Contract 2.
/// `{"ok":true}` | `{"ok":false,"code":"param_dir_locked|invalid_path|restart_required","message":…}`.
///
/// SAFETY: `path` is null or a valid NUL-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn ffi_set_parameter_dir(path: *const c_char) -> *mut c_char {
    ffi_envelope(|| {
        let path = unsafe { read_str(path) };
        match snarkvm_parameters::set_parameter_dir(std::path::Path::new(path)) {
            Ok(()) => Envelope::ok(),
            Err(snarkvm_parameters::ParamDirError::InvalidPath) => {
                Envelope::err("invalid_path", "parameter directory is empty or could not be created")
            }
            Err(snarkvm_parameters::ParamDirError::Locked) => Envelope::err(
                "param_dir_locked",
                "parameter directory is already set, or parameter loading has already begun",
            ),
        }
    })
}

/// Reports the directory proving parameters load from (the override if set, else
/// the default `~/.aleo`). `{"ok":true,"data":"<path>"}`.
#[no_mangle]
pub extern "C" fn ffi_aleo_dir() -> *mut c_char {
    ffi_envelope(|| Envelope::ok_data(snarkvm_parameters::effective_parameter_dir().to_string_lossy().into_owned()))
}

// ── Phase 4 network-aware checked proving (docs/phase4-plan.md §8) ───────────
//
// The network type is embedded at authorize time (the tx network ID), so the
// proving exports take a `network` string and dispatch to the matching snarkVM
// monomorphization. Both `MainnetV0` and `TestnetV0` compile in (the base SRS is
// shared, so it is not duplicated). These return the §8 Contract 1 envelope and
// run under `ffi_envelope`'s `catch_unwind`, so a missing/corrupt proving
// parameter (which panics deep in snarkVM) surfaces as `restart_required` rather
// than aborting. v1 is credits-only: a custom-program authorization is rejected
// with `unsupported_feature` before any proving (§8 Contract 3).

/// The networks the checked exports can target (wire value = lowercase name,
/// matching the existing `_network` arg convention).
enum NetworkKind {
    Mainnet,
    Testnet,
}

fn parse_network(network: &str) -> Option<NetworkKind> {
    match network.trim() {
        "mainnet" => Some(NetworkKind::Mainnet),
        "testnet" => Some(NetworkKind::Testnet),
        _ => None,
    }
}

/// True iff every execution request calls `credits.aleo`. v1 supports credits
/// proving only; any other program (the same check on all three checked exports,
/// §8 Contract 3) is rejected with `unsupported_feature` before proving.
fn authorization_is_credits_only<N: Network>(authorization: &Authorization<N>) -> bool {
    authorization
        .to_vec_deque()
        .iter()
        .all(|request| request.program_id().to_string() == "credits.aleo")
}

/// v1 supports consensus versions V8..=V13 (the inclusion-proof era). `height`
/// selects the version; outside the range is rejected with `unsupported_consensus`
/// rather than clamped — a future version must never be mis-proven as V13.
fn consensus_supported<N: Network>(height: u32) -> Result<(), Envelope> {
    match N::CONSENSUS_VERSION(height) {
        Ok(version) if (8..=13).contains(&(version as u16)) => Ok(()),
        Ok(version) => Err(Envelope::err(
            "unsupported_consensus",
            format!("consensus version {} at height {height} is outside the supported V8..=V13", version as u16),
        )),
        Err(_) => Err(Envelope::err("unsupported_consensus", format!("no consensus version for height {height}"))),
    }
}

/// Generous DoS ceiling on a serialized authorization, applied *before* serde
/// (which first builds a complete `serde_json::Value`), so an untrusted oversized
/// blob — a direct FFI caller can pass anything — cannot exhaust memory before
/// validation (an OOM cannot be turned into an envelope by `catch_unwind`).
/// Protocol-grounded: at most `MAX_TRANSITIONS` transitions, each bounded by the
/// network's `MAX_TRANSACTION_SIZE`, which is far above any honest per-transition
/// authorization JSON.
fn max_authorization_bytes<N: Network>() -> usize {
    Transaction::<N>::MAX_TRANSITIONS.saturating_mul(N::MAX_TRANSACTION_SIZE)
}

/// Shared parse + credits-only + consensus gate for the checked proving exports.
/// Returns the parsed authorization, or an error envelope to return as-is.
fn checked_proving_preconditions<N: Network>(authorization: &str, height: u32) -> Result<Authorization<N>, Envelope> {
    let cap = max_authorization_bytes::<N>();
    if authorization.len() > cap {
        return Err(Envelope::err(
            "invalid_input",
            format!("authorization is {} bytes, over the {cap}-byte budget", authorization.len()),
        ));
    }
    let authorization: Authorization<N> = serde_json::from_str(authorization)
        .map_err(|e| Envelope::err("invalid_input", format!("invalid authorization: {e}")))?;
    if !authorization_is_credits_only(&authorization) {
        return Err(Envelope::err("unsupported_feature", "only credits.aleo proving is supported in this version"));
    }
    consensus_supported::<N>(height)?;
    Ok(authorization)
}

fn execute_proof_checked_inner<N: Network>(
    authorization: &str,
    height: u32,
    state_paths_json: &str,
    public_state_root: &str,
) -> Envelope {
    let authorization = match checked_proving_preconditions::<N>(authorization, height) {
        Ok(a) => a,
        Err(env) => return env,
    };
    let proven = (|| -> anyhow::Result<String> {
        let query = checked_static_query(&authorization, height, state_paths_json, public_state_root)?;
        let vm = new_vm::<N>()?;
        let (execution, _response) =
            vm.execute_authorization_raw(authorization, &query, &mut rand::thread_rng())?;
        Ok(serde_json::to_string(&execution)?)
    })();
    match proven {
        Ok(data) => Envelope::ok_data(data),
        Err(e) => Envelope::err("invalid_input", format!("execution proving failed: {e}")),
    }
}

fn execute_fee_proof_checked_inner<N: Network>(
    authorization: &str,
    height: u32,
    state_paths_json: &str,
    public_state_root: &str,
) -> Envelope {
    let authorization = match checked_proving_preconditions::<N>(authorization, height) {
        Ok(a) => a,
        Err(env) => return env,
    };
    let proven = (|| -> anyhow::Result<String> {
        let query = checked_static_query(&authorization, height, state_paths_json, public_state_root)?;
        let vm = new_vm::<N>()?;
        let fee = vm.execute_fee_authorization_raw(authorization, &query, &mut rand::thread_rng())?;
        Ok(serde_json::to_string(&fee)?)
    })();
    match proven {
        Ok(data) => Envelope::ok_data(data),
        Err(e) => Envelope::err("invalid_input", format!("fee proving failed: {e}")),
    }
}

fn execute_program_proof_checked_inner<N: Network>(
    authorization: &str,
    program_sources_json: &str,
    height: u32,
    state_paths_json: &str,
    public_state_root: &str,
) -> Envelope {
    // credits.aleo is built in, so a credits-only flow supplies an empty program
    // closure — the Dart `AleoNode.programClosure` returns "[]" for credits.aleo,
    // not "". Reject only a closure that actually contains program entries (a
    // custom program, §8 Contract 3); "" and "[]" (JSON whitespace) are both empty.
    // Detect emptiness WITHOUT deserializing the array: a direct FFI caller could
    // otherwise force unbounded allocation/parsing of input that is rejected anyway
    // (a non-empty or malformed value fails the `[ ... ]`-empty check, fail-closed).
    // Trim only the four JSON whitespace bytes, not Rust's Unicode whitespace, so
    // invalid JSON like `[\u{00A0}]` is rejected rather than read as empty.
    let json_ws = |c: char| matches!(c, ' ' | '\t' | '\n' | '\r');
    let closure = program_sources_json.trim_matches(json_ws);
    let is_empty_closure = closure.is_empty()
        || closure
            .strip_prefix('[')
            .and_then(|rest| rest.strip_suffix(']'))
            .is_some_and(|inner| inner.trim_matches(json_ws).is_empty());
    if !is_empty_closure {
        return Envelope::err("unsupported_feature", "custom-program proving is not supported in this version");
    }
    let authorization = match checked_proving_preconditions::<N>(authorization, height) {
        Ok(a) => a,
        Err(env) => return env,
    };
    let proven = (|| -> anyhow::Result<String> {
        let query = checked_static_query(&authorization, height, state_paths_json, public_state_root)?;
        let vm = new_vm::<N>()?;
        let (execution, _response) =
            vm.execute_authorization_raw(authorization, &query, &mut rand::thread_rng())?;
        Ok(serde_json::to_string(&execution)?)
    })();
    match proven {
        Ok(data) => Envelope::ok_data(data),
        Err(e) => Envelope::err("invalid_input", format!("execution proving failed: {e}")),
    }
}

/// Network-aware [`execute_proof_static`]: proves an execution authorization for
/// `network` against a [`StaticQuery`] built from pre-fetched node data, returning
/// the §8 Contract 1 envelope (`{"ok":true,"data":"<execution>"}` or a tagged
/// error). Credits-only.
///
/// SAFETY: the pointer args are null or NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn execute_proof_checked(
    network: *const c_char,
    authorization: *const c_char,
    height: u32,
    state_paths_json: *const c_char,
    public_state_root: *const c_char,
) -> *mut c_char {
    ffi_envelope(|| {
        let network = unsafe { read_str(network) };
        let authorization = unsafe { read_str(authorization) };
        let state_paths_json = unsafe { read_str(state_paths_json) };
        let public_state_root = unsafe { read_str(public_state_root) };
        match parse_network(network) {
            Some(NetworkKind::Mainnet) => {
                execute_proof_checked_inner::<MainnetV0>(authorization, height, state_paths_json, public_state_root)
            }
            Some(NetworkKind::Testnet) => {
                execute_proof_checked_inner::<TestnetV0>(authorization, height, state_paths_json, public_state_root)
            }
            None => Envelope::err("unsupported_network", format!("unknown network '{network}'")),
        }
    })
}

/// Network-aware [`execute_fee_proof_static`]: proves a fee authorization (a
/// private fee spends its own record, so its state paths are its own snapshot;
/// a public fee passes empty paths + a `public_state_root`). Credits-only.
///
/// SAFETY: the pointer args are null or NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn execute_fee_proof_checked(
    network: *const c_char,
    authorization: *const c_char,
    height: u32,
    state_paths_json: *const c_char,
    public_state_root: *const c_char,
) -> *mut c_char {
    ffi_envelope(|| {
        let network = unsafe { read_str(network) };
        let authorization = unsafe { read_str(authorization) };
        let state_paths_json = unsafe { read_str(state_paths_json) };
        let public_state_root = unsafe { read_str(public_state_root) };
        match parse_network(network) {
            Some(NetworkKind::Mainnet) => {
                execute_fee_proof_checked_inner::<MainnetV0>(authorization, height, state_paths_json, public_state_root)
            }
            Some(NetworkKind::Testnet) => {
                execute_fee_proof_checked_inner::<TestnetV0>(authorization, height, state_paths_json, public_state_root)
            }
            None => Envelope::err("unsupported_network", format!("unknown network '{network}'")),
        }
    })
}

/// Network-aware [`execute_program_proof_static`]. v1 is credits-only, so a
/// non-empty `program_sources_json` (a custom program) is rejected with
/// `unsupported_feature`; the symbol is kept so the Dart program path can bind it.
///
/// SAFETY: the pointer args are null or NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn execute_program_proof_checked(
    network: *const c_char,
    authorization: *const c_char,
    program_sources_json: *const c_char,
    height: u32,
    state_paths_json: *const c_char,
    public_state_root: *const c_char,
) -> *mut c_char {
    ffi_envelope(|| {
        let network = unsafe { read_str(network) };
        let authorization = unsafe { read_str(authorization) };
        let program_sources_json = unsafe { read_str(program_sources_json) };
        let state_paths_json = unsafe { read_str(state_paths_json) };
        let public_state_root = unsafe { read_str(public_state_root) };
        match parse_network(network) {
            Some(NetworkKind::Mainnet) => execute_program_proof_checked_inner::<MainnetV0>(
                authorization,
                program_sources_json,
                height,
                state_paths_json,
                public_state_root,
            ),
            Some(NetworkKind::Testnet) => execute_program_proof_checked_inner::<TestnetV0>(
                authorization,
                program_sources_json,
                height,
                state_paths_json,
                public_state_root,
            ),
            None => Envelope::err("unsupported_network", format!("unknown network '{network}'")),
        }
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    // The non-test code never names `QueryTrait` (it hands `StaticQuery` to
    // snarkVM, which calls the trait internally); only these tests assert on the
    // query directly, so the import lives here rather than at module scope.
    use snarkvm_ledger_query::QueryTrait;

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

    /// Source for a minimal valid program named `id` importing `imports`.
    fn program_source(id: &str, imports: &[String]) -> String {
        let imports_block =
            imports.iter().map(|import| format!("import {import};\n")).collect::<String>();
        format!("{imports_block}\nprogram {id};\n\nfunction noop:\n    add 1u8 1u8 into r0;\n")
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

    // ---- Phase 1 (I/O-to-Dart) pure primitives + helpers --------------------

    /// Calls a `*const c_char -> *mut c_char` export with `arg` and returns the
    /// owned result, freeing the returned buffer.
    fn call_str(f: unsafe extern "C" fn(*const c_char) -> *mut c_char, arg: &str) -> String {
        unsafe {
            let c = CString::new(arg).unwrap();
            let ptr = f(c.as_ptr());
            let out = CStr::from_ptr(ptr).to_str().unwrap().to_owned();
            free_string(ptr);
            out
        }
    }

    fn recipient_address() -> String {
        Address::<Net>::try_from(&other_key()).unwrap().to_string()
    }

    // A public transfer spends no records, so it needs no state paths: "[]".
    #[test]
    fn required_commitments_public_transfer_is_empty() {
        let vm = new_vm::<Net>().unwrap();
        let authorization = vm
            .authorize(
                &owner(),
                "credits.aleo",
                "transfer_public",
                vec![recipient_address(), "5u64".to_string()],
                &mut rand::thread_rng(),
            )
            .unwrap();
        let out = call_str(required_commitments, &serde_json::to_string(&authorization).unwrap());
        assert_eq!(out, "[]");
    }

    // A private transfer spends one record, so required_commitments returns that
    // record's commitment (a field), which Dart fetches a state path for.
    #[test]
    fn required_commitments_private_transfer_has_one() {
        let owner = owner();
        let record = plaintext_record(TEST_RECORD, &owner).unwrap();
        let vm = new_vm::<Net>().unwrap();
        let authorization = vm
            .authorize(
                &owner,
                "credits.aleo",
                "transfer_private",
                vec![record, recipient_address(), "5u64".to_string()],
                &mut rand::thread_rng(),
            )
            .unwrap();
        let out = call_str(required_commitments, &serde_json::to_string(&authorization).unwrap());
        let commitments: Vec<String> = serde_json::from_str(&out).unwrap();
        assert_eq!(commitments.len(), 1, "got {out}");
        // Each entry is a field element.
        Field::<Net>::from_str(&commitments[0]).unwrap();
    }

    // Malformed authorization JSON returns "" (no panic across the FFI boundary).
    #[test]
    fn required_commitments_malformed_returns_empty() {
        assert_eq!(call_str(required_commitments, "not json"), "");
    }

    // required_imports lists a program's direct imports.
    #[test]
    fn required_imports_lists_direct_imports() {
        let source = program_source("importer.aleo", &["dep1.aleo".to_string(), "dep2.aleo".to_string()]);
        let out = call_str(required_imports, &source);
        let mut imports: Vec<String> = serde_json::from_str(&out).unwrap();
        imports.sort();
        assert_eq!(imports, vec!["dep1.aleo".to_string(), "dep2.aleo".to_string()]);
    }

    // A program with no imports yields an empty array.
    #[test]
    fn required_imports_none_is_empty() {
        let source = program_source("leaf.aleo", &[]);
        assert_eq!(call_str(required_imports, &source), "[]");
    }

    // consensus_version_for maps heights to versions at the documented boundaries.
    #[test]
    fn consensus_version_for_known_heights() {
        assert_eq!(consensus_version_for(0), 1); // V1 at genesis
        assert_eq!(consensus_version_for(2_800_000), 2); // exact V2 boundary
        assert_eq!(consensus_version_for(2_800_000 - 1), 1); // just below V2
        assert_eq!(consensus_version_for(9_430_000), 8); // V8 (inclusion upgrade)
        assert!(consensus_version_for(u32::MAX) >= 13, "latest version at far future height");
    }

    // No paths (empty or "[]") -> "" (there is no shared root to report).
    #[test]
    fn state_root_from_paths_empty_is_empty() {
        assert_eq!(call_str(state_root_from_paths, ""), "");
        assert_eq!(call_str(state_root_from_paths, "[]"), "");
    }

    // The public flow builds the query from the supplied root and height; with no
    // root it fails (a real, non-zero root is mandatory even with no inclusions).
    #[test]
    fn static_query_public_flow_uses_supplied_root() {
        let root = "sr1dz06ur5spdgzkguh4pr42mvft6u3nwsg5drh9rdja9v8jpcz3czsls9geg";
        let query = static_query(123, "", root).unwrap();
        assert_eq!(query.current_block_height().unwrap(), 123);
        assert_eq!(query.current_state_root().unwrap().to_string(), root);
        assert!(static_query(123, "", "").is_err(), "public flow needs a root");
    }

    // The private-flow StaticQuery path is exercised with real (sampled)
    // StatePaths, so it is covered offline ahead of the phase-2 testnet parity
    // run (full SNARK proving still needs a live node + proving keys).
    use snarkvm_console::network::prelude::TestRng;
    use snarkvm_console::program::state_path::test_helpers::sample_global_state_path;

    // The load-bearing assumption execute_proof_static relies on: a *global*
    // StatePath's transition-leaf id IS the record commitment, so static_query
    // can key the query map by it and proving finds each path by commitment.
    #[test]
    fn static_query_private_flow_derives_root_and_keys_by_commitment() {
        let mut rng = TestRng::default();
        let commitment = Field::<Net>::new(Uniform::rand(&mut rng));
        let path = sample_global_state_path::<Net>(Some(commitment), &mut rng).unwrap();
        // The identity the keying depends on.
        assert_eq!(path.transition_leaf().id(), commitment);
        let root = path.global_state_root();
        let json = serde_json::to_string(&vec![path]).unwrap();

        let query = static_query(99, &json, "").unwrap();
        assert_eq!(query.current_block_height().unwrap(), 99);
        // Root is derived from the path, not fetched separately.
        assert_eq!(query.current_state_root().unwrap().to_string(), root.to_string());
        // Proving looks the path up by commitment exactly like this.
        assert!(query.get_state_path_for_commitment(&commitment).is_ok());
        // An unknown commitment is not found -> proving fails closed.
        let unknown = Field::<Net>::new(Uniform::rand(&mut rng));
        assert!(query.get_state_path_for_commitment(&unknown).is_err());
    }

    // Paths from different blocks (different global state roots) are rejected,
    // not silently proved against a mixed root.
    #[test]
    fn static_query_private_flow_rejects_disagreeing_roots() {
        let mut rng = TestRng::default();
        let p1 = sample_global_state_path::<Net>(None, &mut rng).unwrap();
        let p2 = sample_global_state_path::<Net>(None, &mut rng).unwrap();
        let json = serde_json::to_string(&vec![p1, p2]).unwrap();
        let error = static_query(1, &json, "").map(|_| ()).unwrap_err();
        assert!(error.to_string().contains("disagree on the global state root"), "got: {error}");
    }

    // A supplied public_state_root that disagrees with the paths' derived root
    // is rejected (the snapshot must be internally consistent).
    #[test]
    fn static_query_private_flow_rejects_mismatched_public_root() {
        let mut rng = TestRng::default();
        let path = sample_global_state_path::<Net>(None, &mut rng).unwrap();
        let json = serde_json::to_string(&vec![path]).unwrap();
        let wrong = "sr1dz06ur5spdgzkguh4pr42mvft6u3nwsg5drh9rdja9v8jpcz3czsls9geg";
        let error = static_query(1, &json, wrong).map(|_| ()).unwrap_err();
        assert!(error.to_string().contains("disagrees"), "got: {error}");
    }

    // A repeated commitment would silently drop a path from the map, so it is
    // rejected outright rather than proving with a missing inclusion.
    #[test]
    fn static_query_private_flow_rejects_duplicate_commitment() {
        let mut rng = TestRng::default();
        let path = sample_global_state_path::<Net>(None, &mut rng).unwrap();
        let json = serde_json::to_string(&vec![path.clone(), path]).unwrap();
        let error = static_query(1, &json, "").map(|_| ()).unwrap_err();
        assert!(error.to_string().contains("duplicate state path"), "got: {error}");
    }

    // An offline credits.aleo authorization for one of the test account's
    // private records — the spent record's commitment is the single member of
    // its `global_commitment_set`, which the exact-match guard pins.
    fn private_transfer_authorization() -> Authorization<Net> {
        let owner = owner();
        let recipient = Address::<Net>::try_from(&other_key()).unwrap().to_string();
        let inputs =
            transfer_inputs("transfer_private", &recipient, 1, TEST_RECORD, &owner).unwrap();
        let vm = new_vm::<Net>().unwrap();
        vm.authorize(&owner, "credits.aleo", "transfer_private", inputs, &mut TestRng::default())
            .unwrap()
    }

    // The phase-2 exact-match: the supplied state paths' commitment set must be
    // exactly the authorization's required commitments — a matching single path
    // is accepted.
    #[test]
    fn checked_static_query_accepts_exact_match() {
        let mut rng = TestRng::default();
        let auth = private_transfer_authorization();
        let commitments = global_commitment_set(&auth);
        assert_eq!(commitments.len(), 1, "transfer_private spends exactly one record");
        let commitment = Field::<Net>::from_str(&commitments[0]).unwrap();
        let path = sample_global_state_path::<Net>(Some(commitment), &mut rng).unwrap();
        let json = serde_json::to_string(&vec![path]).unwrap();
        assert!(checked_static_query(&auth, 100, &json, "").is_ok());
    }

    // An *extra* unrelated path (which the size budget alone would let through)
    // is rejected: a node cannot pad the snapshot with irrelevant inclusions.
    #[test]
    fn checked_static_query_rejects_extra_path() {
        let mut rng = TestRng::default();
        let auth = private_transfer_authorization();
        let commitment = Field::<Net>::from_str(&global_commitment_set(&auth)[0]).unwrap();
        let wanted = sample_global_state_path::<Net>(Some(commitment), &mut rng).unwrap();
        let extra = sample_global_state_path::<Net>(None, &mut rng).unwrap();
        let json = serde_json::to_string(&vec![wanted, extra]).unwrap();
        let error = checked_static_query(&auth, 100, &json, "").map(|_| ()).unwrap_err();
        assert!(error.to_string().contains("does not match"), "got: {error}");
    }

    // A missing path (here, none at all) is likewise rejected up front, rather
    // than relying on proving to fail later.
    #[test]
    fn checked_static_query_rejects_missing_path() {
        let auth = private_transfer_authorization();
        assert_eq!(global_commitment_set(&auth).len(), 1);
        let error = checked_static_query(&auth, 100, "[]", "").map(|_| ()).unwrap_err();
        assert!(error.to_string().contains("does not match"), "got: {error}");
    }

    // A public transfer has no record inputs, so its required set is empty: the
    // matching call passes empty paths + a root, and any path is an extra.
    #[test]
    fn checked_static_query_public_flow_is_empty_set() {
        let mut rng = TestRng::default();
        let owner = owner();
        let recipient = Address::<Net>::try_from(&other_key()).unwrap().to_string();
        let inputs = transfer_inputs("transfer_public", &recipient, 1, "", &owner).unwrap();
        let vm = new_vm::<Net>().unwrap();
        let auth = vm
            .authorize(&owner, "credits.aleo", "transfer_public", inputs, &mut TestRng::default())
            .unwrap();
        assert!(global_commitment_set(&auth).is_empty());
        let root = "sr1dz06ur5spdgzkguh4pr42mvft6u3nwsg5drh9rdja9v8jpcz3czsls9geg";
        assert!(checked_static_query(&auth, 1, "", root).is_ok());
        // Any path supplied for a public flow is an unexpected extra.
        let path = sample_global_state_path::<Net>(None, &mut rng).unwrap();
        let json = serde_json::to_string(&vec![path]).unwrap();
        let error = checked_static_query(&auth, 1, &json, "").map(|_| ()).unwrap_err();
        assert!(error.to_string().contains("does not match"), "got: {error}");
    }

    // The state-paths byte budget rejects an oversized blob before parsing.
    #[test]
    fn state_paths_byte_budget_rejects_oversized() {
        let over = max_state_paths::<Net>() * MAX_STATE_PATH_BYTES + 1;
        let blob = "[".to_string() + &"a".repeat(over);
        let error = parse_state_paths::<Net>(&blob).unwrap_err();
        assert!(error.to_string().contains("byte budget"), "got: {error}");
    }

    // The state-paths entry cap rejects more paths than any execution can
    // require, even when each path is small enough to clear the byte budget.
    #[test]
    fn state_paths_entry_cap_rejects_too_many() {
        let mut rng = TestRng::default();
        let one =
            serde_json::to_string(&sample_global_state_path::<Net>(None, &mut rng).unwrap()).unwrap();
        let json = format!("[{}]", vec![one; max_state_paths::<Net>() + 1].join(","));
        let error = parse_state_paths::<Net>(&json).unwrap_err();
        assert!(error.to_string().contains("entry budget"), "got: {error}");
    }

    // The program-sources total-byte cap rejects an oversized blob before serde.
    #[test]
    fn program_sources_byte_cap_rejects_oversized() {
        let over = MAX_IMPORT_PROGRAMS * Net::MAX_PROGRAM_SIZE + 1;
        let blob = "[".to_string() + &"x".repeat(over);
        let vm = new_vm::<Net>().unwrap();
        let error = add_programs_from_sources(&vm, &blob).unwrap_err();
        assert!(error.to_string().contains("byte budget"), "got: {error}");
    }

    // The program-sources count cap rejects too many programs (before any
    // Program::from_str), bounding an unbounded import closure.
    #[test]
    fn program_sources_count_cap_rejects_too_many() {
        let entries: Vec<serde_json::Value> = (0..=MAX_IMPORT_PROGRAMS)
            .map(|i| serde_json::json!({ "id": format!("p{i}.aleo"), "edition": 1, "source": "x" }))
            .collect();
        let json = serde_json::to_string(&entries).unwrap();
        let vm = new_vm::<Net>().unwrap();
        let error = add_programs_from_sources(&vm, &json).unwrap_err();
        assert!(error.to_string().contains("program budget"), "got: {error}");
    }

    /// Builds a `[{id, edition, source}]` program-sources JSON for `programs`.
    fn sources_json(programs: &[(&str, &[String])]) -> String {
        let entries: Vec<serde_json::Value> = programs
            .iter()
            .map(|(id, imports)| {
                serde_json::json!({ "id": id, "edition": 1, "source": program_source(id, imports) })
            })
            .collect();
        serde_json::to_string(&entries).unwrap()
    }

    // Programs supplied out of order are added imports-before-importers.
    #[test]
    fn add_programs_from_sources_orders_imports() {
        let json = sources_json(&[
            ("imp0.aleo", &["dep0.aleo".to_string()]),
            ("dep0.aleo", &[]),
        ]);
        let vm = new_vm::<Net>().unwrap();
        add_programs_from_sources(&vm, &json).unwrap();
        let process = vm.process();
        let process = process.read();
        assert!(process.contains_program(&ProgramID::from_str("imp0.aleo").unwrap()));
        assert!(process.contains_program(&ProgramID::from_str("dep0.aleo").unwrap()));
    }

    // A closure missing a transitively-imported program is rejected (the walk
    // stalls), rather than adding a program whose imports are absent.
    #[test]
    fn add_programs_from_sources_rejects_missing_import() {
        let json = sources_json(&[("imp1.aleo", &["missing.aleo".to_string()])]);
        let vm = new_vm::<Net>().unwrap();
        let error = add_programs_from_sources(&vm, &json).unwrap_err();
        assert!(error.to_string().contains("unresolved imports"), "got: {error}");
    }

    // A source that doesn't declare its claimed id is rejected (a lying caller,
    // mirroring the node-substitution guard on the old path).
    #[test]
    fn add_programs_from_sources_rejects_id_mismatch() {
        let evil = program_source("evil.aleo", &[]);
        let json = serde_json::to_string(&serde_json::json!([
            { "id": "honest.aleo", "edition": 1, "source": evil }
        ]))
        .unwrap();
        let vm = new_vm::<Net>().unwrap();
        let error = add_programs_from_sources(&vm, &json).unwrap_err();
        assert!(error.to_string().contains("declares"), "got: {error}");
    }

    // A single program source over MAX_PROGRAM_SIZE is rejected before it is even
    // parsed (the per-entry size guard). The offline analogue of the old
    // node-fetched `oversized_program_source_rejected`: the total-byte budget is
    // generous (256 × MAX_PROGRAM_SIZE), so this trips the per-program bound, not
    // the aggregate one, and `MAX_PROGRAM_SIZE` is a real protocol constant so it
    // never rejects an honest program.
    #[test]
    fn add_programs_from_sources_rejects_oversized_source() {
        let bloated = format!("program big.aleo;\n{}", " ".repeat(Net::MAX_PROGRAM_SIZE));
        assert!(bloated.len() > Net::MAX_PROGRAM_SIZE);
        let json = serde_json::to_string(&serde_json::json!([
            { "id": "big.aleo", "edition": 1, "source": bloated }
        ]))
        .unwrap();
        let vm = new_vm::<Net>().unwrap();
        let error = add_programs_from_sources(&vm, &json).unwrap_err();
        assert!(error.to_string().contains("maximum"), "got: {error}");
    }

    // A cycle in the supplied closure (a imports b, b imports a) is rejected: with
    // neither program built in or added yet, neither is ever "ready", so the walk
    // stalls with programs left unadded. The offline analogue of the old
    // `import_cycle_from_node_rejected` — and a guard that a still-pending program
    // is not mistaken for an already-present one.
    #[test]
    fn add_programs_from_sources_rejects_cycle() {
        let json = sources_json(&[
            ("cyclea.aleo", &["cycleb.aleo".to_string()]),
            ("cycleb.aleo", &["cyclea.aleo".to_string()]),
        ]);
        let vm = new_vm::<Net>().unwrap();
        let error = add_programs_from_sources(&vm, &json).unwrap_err();
        assert!(
            error.to_string().contains("unresolved imports or an import cycle"),
            "got: {error}"
        );
        assert!(!vm.process().read().contains_program(&ProgramID::from_str("cyclea.aleo").unwrap()));
    }

    // An empty source set is a no-op (public flows supply no programs).
    #[test]
    fn add_programs_from_sources_empty_is_noop() {
        let vm = new_vm::<Net>().unwrap();
        add_programs_from_sources(&vm, "").unwrap();
        add_programs_from_sources(&vm, "[]").unwrap();
    }

    // Parse + Stack build is uninterruptible CPU work even with no network, so an
    // expired deadline stops the load before building anything — the Dart-side
    // timeout can't reach work already inside the FFI, so the bound must be here.
    #[test]
    fn add_programs_from_sources_bounded_by_deadline() {
        let json = sources_json(&[("solo.aleo", &[])]);
        let vm = new_vm::<Net>().unwrap();
        let expired = std::time::Instant::now() - std::time::Duration::from_secs(1);
        let error = add_programs_from_sources_within(&vm, &json, expired).unwrap_err();
        assert!(error.to_string().contains("time budget"), "got: {error}");
        assert!(!vm.process().read().contains_program(&ProgramID::from_str("solo.aleo").unwrap()));
    }

    // The local filter is order-sensitive, mirroring Inclusion::insert_transition.
    #[test]
    fn global_input_commitments_is_order_sensitive() {
        // An earlier transition's output makes a later input local -> dropped.
        let earlier_output_then_spend = vec![
            (vec![], vec!["c_local".to_string()]),     // T0 outputs c_local
            (vec!["c_local".to_string()], vec![]),     // T1 spends it (earlier output)
        ];
        assert!(global_input_commitments(&earlier_output_then_spend).is_empty());

        // A LATER transition's output must NOT make an earlier input local: the
        // input is a real on-chain commitment and still needs its state path.
        // (This is the case the old all-outputs-minus-all-inputs logic got wrong.)
        let spend_then_later_output = vec![
            (vec!["c_chain".to_string()], vec![]),     // T0 spends c_chain (on-chain)
            (vec![], vec!["c_chain".to_string()]),     // T1 outputs the same commitment
        ];
        assert_eq!(
            global_input_commitments(&spend_then_later_output),
            vec!["c_chain".to_string()]
        );

        // A plain global input with unrelated outputs stays global.
        let global_with_fresh_outputs =
            vec![(vec!["c_in".to_string()], vec!["c_out".to_string()])];
        assert_eq!(global_input_commitments(&global_with_fresh_outputs), vec!["c_in".to_string()]);
    }

    // On a real authorization, required_commitments returns the global inputs and
    // never a record the transaction itself creates (a transition output) — so a
    // composite program's local record can never be sent to the node as a path
    // request. (transfer_private's outputs are fresh, so nothing is dropped here;
    // the drop path is covered by the unit test above.)
    #[test]
    fn required_commitments_excludes_transition_outputs() {
        let owner = owner();
        let record = plaintext_record(TEST_RECORD, &owner).unwrap();
        let vm = new_vm::<Net>().unwrap();
        let auth = vm
            .authorize(
                &owner,
                "credits.aleo",
                "transfer_private",
                vec![record, recipient_address(), "5u64".to_string()],
                &mut rand::thread_rng(),
            )
            .unwrap();
        // The transaction's own output-record commitments (the local set).
        let mut outputs = HashSet::new();
        for (_, transition) in auth.transitions() {
            for output in transition.outputs() {
                if let Some(commitment) = output.commitment() {
                    outputs.insert(commitment.to_string());
                }
            }
        }
        assert!(!outputs.is_empty(), "transfer_private creates output records");

        let out = call_str(required_commitments, &serde_json::to_string(&auth).unwrap());
        let required: Vec<String> = serde_json::from_str(&out).unwrap();
        assert_eq!(required.len(), 1, "the one spent record; got {out}");
        for commitment in &required {
            assert!(!outputs.contains(commitment), "leaked a local output: {commitment}");
        }
    }

    // The static fee API takes program_sources_json (so non-builtin executions
    // can be costed). Malformed input returns 0 / "" without panicking across the
    // FFI boundary — and exercises the new 3-arg / 6-arg ABIs.
    #[test]
    fn get_base_fee_static_malformed_returns_zero() {
        unsafe {
            let execution = CString::new("not json").unwrap();
            let sources = CString::new("").unwrap();
            assert_eq!(get_base_fee_static(execution.as_ptr(), sources.as_ptr(), 9_430_000), 0);
        }
    }

    #[test]
    fn execution_fee_authorization_static_malformed_returns_empty() {
        unsafe {
            let pk = CString::new(OWNER_KEY).unwrap();
            let execution = CString::new("not json").unwrap();
            let fee_record = CString::new("").unwrap();
            let sources = CString::new("").unwrap();
            let ptr = execution_fee_authorization_static(
                pk.as_ptr(),
                execution.as_ptr(),
                1000,
                fee_record.as_ptr(),
                sources.as_ptr(),
                9_430_000,
            );
            let out = CStr::from_ptr(ptr).to_str().unwrap().to_owned();
            free_string(ptr);
            assert_eq!(out, "");
        }
    }

    /// Calls the 5-arg program_authorization_static and returns the owned result.
    fn call_program_authorization_static(
        private_key: &str,
        program_id: &str,
        function: &str,
        arguments: &str,
        sources: &str,
    ) -> String {
        unsafe {
            let pk = CString::new(private_key).unwrap();
            let program = CString::new(program_id).unwrap();
            let function = CString::new(function).unwrap();
            let arguments = CString::new(arguments).unwrap();
            let sources = CString::new(sources).unwrap();
            let ptr = program_authorization_static(
                pk.as_ptr(),
                program.as_ptr(),
                function.as_ptr(),
                arguments.as_ptr(),
                sources.as_ptr(),
            );
            let out = CStr::from_ptr(ptr).to_str().unwrap().to_owned();
            free_string(ptr);
            out
        }
    }

    // A built-in program (credits.aleo) authorizes with no program sources.
    #[test]
    fn program_authorization_static_builtin_no_sources() {
        let args = serde_json::to_string(&vec![recipient_address(), "5u64".to_string()]).unwrap();
        let out =
            call_program_authorization_static(OWNER_KEY, "credits.aleo", "transfer_public", &args, "");
        let auth: Authorization<Net> = serde_json::from_str(&out).unwrap();
        assert_eq!(auth.to_vec_deque().len(), 1);
    }

    // The path credits-only authorize exports can't reach: load a non-builtin
    // program from sources, then authorize its function offline.
    #[test]
    fn program_authorization_static_loads_then_authorizes() {
        let sources = sources_json(&[("auth0.aleo", &[])]);
        let out = call_program_authorization_static(OWNER_KEY, "auth0.aleo", "noop", "[]", &sources);
        let auth: Authorization<Net> = serde_json::from_str(&out).unwrap();
        assert!(!auth.to_vec_deque().is_empty(), "authorized a non-builtin function");
    }

    // Malformed input returns "" rather than panicking across the FFI boundary.
    #[test]
    fn program_authorization_static_malformed_returns_empty() {
        // Bad arguments JSON.
        assert_eq!(
            call_program_authorization_static(OWNER_KEY, "credits.aleo", "transfer_public", "nope", ""),
            ""
        );
        // Unknown program with no sources to load it.
        assert_eq!(call_program_authorization_static(OWNER_KEY, "ghost.aleo", "go", "[]", ""), "");
    }

    // End-to-end proof through execute_proof_static for a PUBLIC transfer: no
    // record inputs, so no state paths — proving only needs a height and a real
    // (non-zero) state root. This exercises static_query's public branch +
    // execute_authorization_raw for real and checks the proof carries the
    // supplied root. Heavy (downloads proving keys + proves), hence #[ignore].
    // The private-flow end-to-end stays for the phase-2 testnet parity run (it
    // needs a real on-chain state path).
    #[test]
    #[ignore = "proving: downloads keys + proves, run with `cargo test --release -- --ignored`"]
    fn execute_proof_static_public_transfer_end_to_end() {
        let owner = owner();
        let vm = new_vm::<Net>().unwrap();
        let auth = vm
            .authorize(
                &owner,
                "credits.aleo",
                "transfer_public",
                vec![recipient_address(), "1u64".to_string()],
                &mut rand::thread_rng(),
            )
            .unwrap();
        let auth_json = serde_json::to_string(&auth).unwrap();
        // Any valid, non-zero state root works for a public flow (no inclusion
        // assignments to check it against; consensus checks it on-chain later).
        let root = "sr1dz06ur5spdgzkguh4pr42mvft6u3nwsg5drh9rdja9v8jpcz3czsls9geg";
        let out = unsafe {
            let auth_c = CString::new(auth_json).unwrap();
            let paths_c = CString::new("").unwrap();
            let root_c = CString::new(root).unwrap();
            let ptr = execute_proof_static(auth_c.as_ptr(), 9_430_000, paths_c.as_ptr(), root_c.as_ptr());
            let out = CStr::from_ptr(ptr).to_str().unwrap().to_owned();
            free_string(ptr);
            out
        };
        assert!(!out.is_empty(), "expected a serialized execution, got the error sentinel");
        let execution: Execution<Net> = serde_json::from_str(&out).unwrap();
        // The proof carries the root static_query was given.
        assert_eq!(execution.global_state_root().to_string(), root);
    }

    // ── Network-aware checked proving exports (§8): the offline reject paths ────
    // (The happy path is real SNARK proving — covered by the #[ignore] end-to-end
    // test above for the equivalent `_static` export.)

    fn call_envelope(ptr: *mut c_char) -> serde_json::Value {
        let s = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_owned();
        unsafe { free_string(ptr) };
        serde_json::from_str(&s).unwrap_or_else(|_| panic!("non-JSON envelope: {s:?}"))
    }

    fn execute_proof_checked_call(network: &str, authorization: &str, height: u32) -> serde_json::Value {
        let n = CString::new(network).unwrap();
        let a = CString::new(authorization).unwrap();
        let empty = CString::new("").unwrap();
        call_envelope(unsafe {
            execute_proof_checked(n.as_ptr(), a.as_ptr(), height, empty.as_ptr(), empty.as_ptr())
        })
    }

    #[test]
    fn execute_proof_checked_rejects_unknown_network() {
        let auth = serde_json::to_string(&private_transfer_authorization()).unwrap();
        let env = execute_proof_checked_call("bogusnet", &auth, 17_000_000);
        assert_eq!(env["ok"], false);
        assert_eq!(env["code"], "unsupported_network");
    }

    #[test]
    fn execute_proof_checked_rejects_invalid_authorization() {
        let env = execute_proof_checked_call("mainnet", "not json", 17_000_000);
        assert_eq!(env["ok"], false);
        assert_eq!(env["code"], "invalid_input");
    }

    #[test]
    fn execute_proof_checked_rejects_unsupported_consensus() {
        // A valid credits authorization, but height 0 selects consensus V1 (< V8),
        // which v1 does not support — rejected before any proving.
        let auth = serde_json::to_string(&private_transfer_authorization()).unwrap();
        let env = execute_proof_checked_call("mainnet", &auth, 0);
        assert_eq!(env["ok"], false);
        assert_eq!(env["code"], "unsupported_consensus");
    }

    #[test]
    fn execute_program_proof_checked_rejects_custom_sources() {
        // v1 is credits-only: a non-empty program closure is a custom program.
        let auth = serde_json::to_string(&private_transfer_authorization()).unwrap();
        let n = CString::new("mainnet").unwrap();
        let a = CString::new(auth).unwrap();
        let sources =
            CString::new(r#"[{"id":"foo.aleo","edition":0,"source":"program foo.aleo;"}]"#).unwrap();
        let empty = CString::new("").unwrap();
        let env = call_envelope(unsafe {
            execute_program_proof_checked(
                n.as_ptr(),
                a.as_ptr(),
                sources.as_ptr(),
                17_000_000,
                empty.as_ptr(),
                empty.as_ptr(),
            )
        });
        assert_eq!(env["ok"], false);
        assert_eq!(env["code"], "unsupported_feature");
    }

    #[test]
    fn execute_program_proof_checked_accepts_empty_array_closure() {
        // "[]" is an empty closure (what AleoNode.programClosure returns for
        // credits.aleo), not a custom program — it must pass the closure gate. The
        // call then fails on the empty private-flow state paths (invalid_input),
        // which proves it got *past* the unsupported_feature check.
        let auth = serde_json::to_string(&private_transfer_authorization()).unwrap();
        let n = CString::new("mainnet").unwrap();
        let a = CString::new(auth).unwrap();
        let sources = CString::new("[]").unwrap();
        let empty = CString::new("").unwrap();
        let env = call_envelope(unsafe {
            execute_program_proof_checked(
                n.as_ptr(),
                a.as_ptr(),
                sources.as_ptr(),
                17_000_000,
                empty.as_ptr(),
                empty.as_ptr(),
            )
        });
        assert_ne!(env["code"], "unsupported_feature", "empty array closure must not be rejected: {env}");
        assert_eq!(env["code"], "invalid_input", "{env}");
    }

    #[test]
    fn execute_program_proof_checked_rejects_non_array_closure() {
        // A non-array (or malformed) closure is rejected without deserializing it.
        let auth = serde_json::to_string(&private_transfer_authorization()).unwrap();
        let n = CString::new("mainnet").unwrap();
        let a = CString::new(auth).unwrap();
        let empty = CString::new("").unwrap();
        // "[\u{00A0}]" is invalid JSON (NBSP is not JSON whitespace) — must be
        // rejected, not read as empty by Rust's Unicode-aware trim.
        for bad in ["{}", "[ ", "not json", "[\u{00A0}]"] {
            let sources = CString::new(bad).unwrap();
            let env = call_envelope(unsafe {
                execute_program_proof_checked(
                    n.as_ptr(),
                    a.as_ptr(),
                    sources.as_ptr(),
                    17_000_000,
                    empty.as_ptr(),
                    empty.as_ptr(),
                )
            });
            assert_eq!(env["code"], "unsupported_feature", "input {bad:?} → {env}");
        }
    }

    #[test]
    fn execute_proof_checked_rejects_oversized_authorization() {
        // An authorization past the byte budget is rejected BEFORE serde, so an
        // untrusted blob can't OOM the deserializer. The string is > the cap
        // (MAX_TRANSITIONS * MAX_TRANSACTION_SIZE) but still small enough to test.
        let cap = max_authorization_bytes::<Net>();
        let huge = "x".repeat(cap + 1);
        let env = execute_proof_checked_call("mainnet", &huge, 17_000_000);
        assert_eq!(env["ok"], false);
        assert_eq!(env["code"], "invalid_input");
        assert!(env["message"].as_str().unwrap().contains("budget"), "{env}");
    }

    #[test]
    fn execute_proof_checked_handles_null_pointers() {
        // The new exports document null as allowed; `read_str` maps null to "" so
        // `CStr::from_ptr` is never called on null (which would be UB, uncatchable
        // by the envelope wrapper). A null network reads as "" → unsupported_network.
        let env = call_envelope(unsafe {
            execute_proof_checked(
                std::ptr::null(),
                std::ptr::null(),
                17_000_000,
                std::ptr::null(),
                std::ptr::null(),
            )
        });
        assert_eq!(env["ok"], false);
        assert_eq!(env["code"], "unsupported_network");
    }
}

#[cfg(test)]
mod param_dir_tests {
    //! Tests for the parameter-directory FFI (§8 Contract 1 envelope + Contract 2
    //! set-once). The directory lives in a process-global `OnceLock`, so the
    //! mutating scenarios must each run in their own subprocess — the harness
    //! re-execs this test binary with `ALEO_FFI_PARAM_DIR_SCENARIO` set.
    use super::*;
    use std::ffi::CString;

    fn parse(ptr: *mut c_char) -> serde_json::Value {
        let s = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_owned();
        unsafe { free_string(ptr) };
        serde_json::from_str(&s).unwrap_or_else(|_| panic!("non-JSON envelope: {s:?}"))
    }

    fn set_dir(path: &str) -> serde_json::Value {
        let c = CString::new(path).unwrap();
        parse(unsafe { ffi_set_parameter_dir(c.as_ptr()) })
    }

    fn aleo_dir() -> serde_json::Value {
        parse(ffi_aleo_dir())
    }

    // ── In-process: pure / non-mutating (safe to share the parent's OnceLock) ──

    #[test]
    fn envelope_shapes() {
        // Assert parsed fields, not the raw string: key ordering depends on whether
        // serde_json's `preserve_order` is unified on across the build.
        let json = |e: Envelope| serde_json::from_str::<serde_json::Value>(&e.to_json()).unwrap();

        let ok = json(Envelope::ok());
        assert_eq!(ok["ok"], true);

        let okd = json(Envelope::ok_data("x"));
        assert_eq!(okd["ok"], true);
        assert_eq!(okd["data"], "x");

        let err = json(Envelope::err("invalid_path", "nope"));
        assert_eq!(err["ok"], false);
        assert_eq!(err["code"], "invalid_path");
        assert_eq!(err["message"], "nope");
    }

    #[test]
    fn set_parameter_dir_empty_is_invalid_path() {
        // An empty path is rejected before the OnceLock is touched, so this is
        // safe to run in the shared parent process.
        let r = set_dir("");
        assert_eq!(r["ok"], false);
        assert_eq!(r["code"], "invalid_path");
    }

    #[test]
    fn aleo_dir_reports_a_nonempty_path() {
        let r = aleo_dir();
        assert_eq!(r["ok"], true);
        assert!(!r["data"].as_str().unwrap().is_empty());
    }

    // ── Subprocess: the set-once state machine (mutates the global OnceLock) ────

    /// Re-exec this test binary so the scenario runs with a fresh, unset OnceLock.
    fn run_scenario(scenario: &str) -> std::process::Output {
        let exe = std::env::current_exe().expect("current_exe");
        std::process::Command::new(exe)
            .args(["--exact", "--nocapture", "param_dir_tests::scenario_runner"])
            .env("ALEO_FFI_PARAM_DIR_SCENARIO", scenario)
            .output()
            .expect("spawn subprocess")
    }

    /// Dispatches a mutating scenario when re-execed; a no-op (passing) test under
    /// a normal `cargo test`, where the env var is unset.
    #[test]
    fn scenario_runner() {
        let Ok(scenario) = std::env::var("ALEO_FFI_PARAM_DIR_SCENARIO") else { return };
        match scenario.as_str() {
            "first_then_idempotent_then_locked" => {
                let base = std::env::temp_dir();
                let a = base.join(format!("aleo_ffi_pd_a_{}", std::process::id()));
                let b = base.join(format!("aleo_ffi_pd_b_{}", std::process::id()));
                std::fs::create_dir_all(&a).unwrap();
                std::fs::create_dir_all(&b).unwrap();

                // First set wins.
                let r = set_dir(a.to_str().unwrap());
                assert_eq!(r["ok"], true, "first set: {r}");

                // aleo_dir now reports the override, canonicalized.
                let d = aleo_dir();
                assert_eq!(d["data"].as_str().unwrap(), a.canonicalize().unwrap().to_str().unwrap());

                // Same path again -> idempotent ok.
                let r = set_dir(a.to_str().unwrap());
                assert_eq!(r["ok"], true, "idempotent: {r}");

                // A different path -> locked.
                let r = set_dir(b.to_str().unwrap());
                assert_eq!(r["ok"], false, "different path should be rejected: {r}");
                assert_eq!(r["code"], "param_dir_locked", "{r}");

                let _ = std::fs::remove_dir_all(&a);
                let _ = std::fs::remove_dir_all(&b);
            }
            "load_started_then_set_locked" => {
                // Simulate the load macro beginning a read (which atomically freezes
                // the directory at the default), then a later set to a *different*
                // dir must be rejected — the TOCTOU the single lock closes.
                let frozen = snarkvm_parameters::parameter_dir_for_load().unwrap();
                let other = std::env::temp_dir().join(format!("aleo_ffi_pd_post_load_{}", std::process::id()));
                std::fs::create_dir_all(&other).unwrap();

                let r = set_dir(other.to_str().unwrap());
                assert_eq!(r["ok"], false, "set after load-started must be rejected: {r}");
                assert_eq!(r["code"], "param_dir_locked", "{r}");

                // The effective dir is still the frozen (default) one, not the rejected path.
                let d = aleo_dir();
                assert_eq!(d["data"].as_str().unwrap(), frozen.to_str().unwrap());

                let _ = std::fs::remove_dir_all(&other);
            }
            other => panic!("unknown scenario {other}"),
        }
    }

    #[test]
    fn set_parameter_dir_first_then_idempotent_then_locked() {
        let out = run_scenario("first_then_idempotent_then_locked");
        assert!(
            out.status.success(),
            "subprocess failed.\nstdout:\n{}\nstderr:\n{}",
            String::from_utf8_lossy(&out.stdout),
            String::from_utf8_lossy(&out.stderr),
        );
    }

    #[test]
    fn set_parameter_dir_rejected_after_load_started() {
        let out = run_scenario("load_started_then_set_locked");
        assert!(
            out.status.success(),
            "subprocess failed.\nstdout:\n{}\nstderr:\n{}",
            String::from_utf8_lossy(&out.stdout),
            String::from_utf8_lossy(&out.stderr),
        );
    }
}
