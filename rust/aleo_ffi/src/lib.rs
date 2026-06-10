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
use snarkvm_console::program::{Ciphertext, Record};
use snarkvm_console::types::Field;

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
