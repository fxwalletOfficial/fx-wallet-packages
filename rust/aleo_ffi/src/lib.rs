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
use snarkvm_console::program::{Ciphertext, Identifier, Plaintext, ProgramID, Record};
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

#[cfg(test)]
mod encryptor_probe {
    //! Black-box scheme search for the private-key Encryptor: tries candidate
    //! key-derivation constructions (snarkVM public API only) against a known
    //! (ciphertext, secret, private-key) vector. No GPL source consulted.
    use super::*;
    use snarkvm_console::network::TestnetV0;
    use snarkvm_console::program::Plaintext as Pt;

    const VECTOR_CT: &str = "ciphertext1qvqg7rgvam3xdcu55pwu6sl8rxwefxaj5gwthk0yzln6jv5fastzup0qn0qftqlqq7jcckyx03fzv9kke0z9puwd7cl7jzyhxfy2f2juplz39dkqs6p24urhxymhv364qm3z8mvyklv5gr52n4fxr2z59jgqytyddj8";
    const SECRET: &str = "mypassword";
    const EXPECTED: &str = "APrivateKey1zkpAYS46Dq4rnt9wdohyWMwdmjmTeMJKPZdp5AhvjXZDsVG";

    fn probe<N: Network>(net: &str) {
        let ct = match snarkvm_console::program::Ciphertext::<N>::from_str(VECTOR_CT) {
            Ok(ct) => ct,
            Err(e) => {
                println!("[{net}] ciphertext parse FAILED: {e}");
                return;
            }
        };
        let base = Field::<N>::new_domain_separator(SECRET);
        let candidates: Vec<(&str, Field<N>)> = vec![
            ("domain_sep(secret)", base),
            ("psd2[secret]", N::hash_psd2(&[base]).unwrap()),
            ("psd2[enc_domain, secret]", N::hash_psd2(&[N::encryption_domain(), base]).unwrap()),
            ("psd4[secret]", N::hash_psd4(&[base]).unwrap()),
            ("psd8[secret]", N::hash_psd8(&[base]).unwrap()),
            ("bhp256(secret bits)", N::hash_bhp256(&SECRET.as_bytes().to_bits_le()).unwrap()),
        ];
        for (name, key) in candidates {
            match ct.decrypt_symmetric(key) {
                Ok(pt) => {
                    let shown = pt.to_string();
                    let mut derived = String::from("(not a field literal)");
                    if let Pt::Literal(snarkvm_console::program::Literal::Field(f), _) = &pt {
                        if let Ok(pk) = PrivateKey::<N>::try_from(*f) {
                            derived = pk.to_string();
                        }
                    }
                    let hit = if derived == EXPECTED { "  <<< MATCH" } else { "" };
                    println!("[{net}] {name}: decrypt OK, pt={shown}, pk={derived}{hit}");
                }
                Err(_) => println!("[{net}] {name}: decrypt failed"),
            }
        }
    }

    #[test]
    fn search_encryptor_scheme() {
        probe::<MainnetV0>("mainnet");
        probe::<TestnetV0>("testnet");
    }

    fn inner_layer<N: Network>(net: &str) {
        let ct = snarkvm_console::program::Ciphertext::<N>::from_str(VECTOR_CT).unwrap();
        let pt = ct.decrypt_symmetric(Field::new_domain_separator(SECRET)).unwrap();
        let (mut key, mut nonce) = (None, None);
        if let Pt::Struct(members, _) = &pt {
            for (id, member) in members {
                if let Pt::Literal(snarkvm_console::program::Literal::Field(f), _) = member {
                    match id.to_string().as_str() {
                        "key" => key = Some(*f),
                        "nonce" => nonce = Some(*f),
                        _ => {}
                    }
                }
            }
        }
        let (key, nonce) = (key.unwrap(), nonce.unwrap());
        let expected_seed = PrivateKey::<N>::from_str(EXPECTED).unwrap().seed();
        let target = key - expected_seed; // the blinding term H(secret, nonce)
        let secret_field = Field::<N>::new_domain_separator(SECRET);
        let candidates: Vec<(&str, Field<N>)> = vec![
            ("psd2[secret, nonce]", N::hash_psd2(&[secret_field, nonce]).unwrap()),
            ("psd2[nonce, secret]", N::hash_psd2(&[nonce, secret_field]).unwrap()),
            ("psd4[secret, nonce]", N::hash_psd4(&[secret_field, nonce]).unwrap()),
            ("psd4[nonce, secret]", N::hash_psd4(&[nonce, secret_field]).unwrap()),
            ("psd8[secret, nonce]", N::hash_psd8(&[secret_field, nonce]).unwrap()),
            ("psd2[enc_domain, secret, nonce]", N::hash_psd2(&[N::encryption_domain(), secret_field, nonce]).unwrap()),
        ];
        for (name, h) in candidates {
            let mark = if h == target { "  <<< MATCH (key - H == seed)" } else { "" };
            println!("[{net}] {name}{mark}");
        }

        // Hypothesis 2: inner layer is itself encrypt_symmetric(pvk), i.e.
        // key = seed + hash_many_psd8([enc_domain, pvk], 1)[0].
        let pvks: Vec<(&str, Field<N>)> = vec![
            ("pvk=psd2[secret, nonce]", N::hash_psd2(&[secret_field, nonce]).unwrap()),
            ("pvk=psd2[nonce, secret]", N::hash_psd2(&[nonce, secret_field]).unwrap()),
            ("pvk=psd4[secret, nonce]", N::hash_psd4(&[secret_field, nonce]).unwrap()),
            ("pvk=psd8[secret, nonce]", N::hash_psd8(&[secret_field, nonce]).unwrap()),
            ("pvk=secret+nonce", secret_field + nonce),
            ("pvk=secret*nonce", secret_field * nonce),
        ];
        for (name, pvk) in pvks {
            let r = N::hash_many_psd8(&[N::encryption_domain(), pvk], 1)[0];
            let mark = if r == target { "  <<< MATCH (inner encrypt_symmetric)" } else { "" };
            println!("[{net}] {name}{mark}");
        }

        // Hypothesis 3: hash_many without the encryption domain, or nested psd2.
        let more: Vec<(&str, Field<N>)> = vec![
            ("many8[psd2[s,n]]", N::hash_many_psd8(&[N::hash_psd2(&[secret_field, nonce]).unwrap()], 1)[0]),
            ("many8[psd2[n,s]]", N::hash_many_psd8(&[N::hash_psd2(&[nonce, secret_field]).unwrap()], 1)[0]),
            ("many8[s,n]", N::hash_many_psd8(&[secret_field, nonce], 1)[0]),
            ("many8[n,s]", N::hash_many_psd8(&[nonce, secret_field], 1)[0]),
            ("psd2[psd2[s],n]", N::hash_psd2(&[N::hash_psd2(&[secret_field]).unwrap(), nonce]).unwrap()),
            ("psd2[s, psd2[n]]", N::hash_psd2(&[secret_field, N::hash_psd2(&[nonce]).unwrap()]).unwrap()),
        ];
        for (name, r) in more {
            let mark = if r == target { "  <<< MATCH" } else { "" };
            println!("[{net}] {name}{mark}");
        }
    }

    #[test]
    fn search_inner_layer() {
        inner_layer::<MainnetV0>("mainnet");
        inner_layer::<TestnetV0>("testnet");
    }
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
