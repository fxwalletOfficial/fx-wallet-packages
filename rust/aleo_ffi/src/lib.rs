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
