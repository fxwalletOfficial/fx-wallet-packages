// Copyright (C) 2019-2023 Aleo Systems Inc.
// This file is part of the Aleo SDK library.

// The Aleo SDK library is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// The Aleo SDK library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with the Aleo SDK library. If not, see <https://www.gnu.org/licenses/>.

//!
//! [![Crates.io](https://img.shields.io/crates/v/aleo-wasm.svg?color=neon)](https://crates.io/crates/aleo-wasm)
//! [![Authors](https://img.shields.io/badge/authors-Aleo-orange.svg)](https://aleo.org)
//! [![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](./LICENSE.md)
//!
//! [![github]](https://github.com/AleoHQ/sdk)&ensp;[![crates-io]](https://crates.io/crates/aleo-wasm)&ensp;[![docs-rs]](https://docs.rs/aleo-wasm/latest/aleo-wasm/)
//!
//! [github]: https://img.shields.io/badge/github-8da0cb?style=for-the-badge&labelColor=555555&logo=github
//! [crates-io]: https://img.shields.io/badge/crates.io-fc8d62?style=for-the-badge&labelColor=555555&logo=rust
//! [docs-rs]: https://img.shields.io/badge/docs.rs-66c2a5?style=for-the-badge&labelColor=555555&logo=docs.rs
//!
//! # Aleo Wasm
//!
//! Aleo JavaScript and WebAssembly bindings for building zero-knowledge web applications.
//!
//! `Rust` compiles easily to `WebAssembly` but creating the glue code necessary to use compiled WebAssembly binaries
//! from other languages such as JavaScript is a challenging task. `wasm-bindgen` is a tool that simplifies this process by
//! auto-generating JavaScript bindings to Rust code that has been compiled into WebAssembly.
//!
//! This crate uses `wasm-bindgen` to create JavaScript bindings to Aleo source code so that it can be used to create zero
//! knowledge proofs directly within `web browsers` and `NodeJS`.
//!
//! Functionality exposed by this crate includes:
//! * Aleo account management objects
//! * Aleo primitives such as `Records`, `Programs`, and `Transactions` and their associated helper methods
//! * A `ProgramManager` object that contains methods for authoring, deploying, and interacting with Aleo programs
//!
//! More information on these concepts can be found at the [Aleo Developer Hub](https://developer.aleo.org/concepts).
//!
//! ## Usage
//! The [wasm-pack](https://crates.io/crates/wasm-pack) tool is used to compile the Rust code in this crate into JavaScript
//! modules which can be imported into other JavaScript projects.
//!
//! #### Install Wasm-Pack
//! ```bash
//! curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh
//! ```
//!
//! ### Build Instructions
//! The general syntax for compiling rust into WebAssembly based JavaScript modules with
//! [wasm-pack](https://crates.io/crates/wasm-pack) is as follows:
//! ```bash
//! wasm-pack build --target <target> --out-dir <out-dir> -- --features <crate-features>
//! ```
//!
//! Invoking this command will build a JavaScript module in the current directory with the default name `pkg` (which can
//! be changed as necessary using the `--out-dir` flag). This folder can then be imported directly as a JavaScript module
//! by other JavaScript modules.
//!
//! There are 3 possible JavaScript modules that [wasm-pack](https://crates.io/crates/wasm-pack) can be used to generate
//! when run within this crate:
//! 1. **NodeJS module:** Used to build NodeJS applications.
//! 2. **Single-Threaded browser module:** Used to build browser-based web applications.
//! 3. **Multi-Threaded browser module:** Used to build browser-based web applications which use web-worker based
//! multi-threading to achieve significant performance increases.
//!
//! These 3 modules and how to build them are explained in more detail below.
//!
//! ### 1. NodeJS Module
//!
//! This module has the features of the NodeJS environment built-in. It is single-threaded and unfortunately cannot yet be
//! used to generate Aleo program executions or deployments due to current Aleo protocol limitations. It can however still
//! be used to perform Aleo account, record, and program management tasks.
//!
//! #### Build Instructions
//! ```bash
//! wasm-pack build --release --target nodejs -- --features "serial" --no-default-features
//! ```
//!
//! ### 2. Single-Threaded browser module
//!
//! This module is very similar to the NodeJS module, however it is built to make use browser-based JavaScript environments
//! and can be used for program execution and deployment.
//!
//! If used for program execution or deployment, it suggested to do so on a web-worker as these operations are long-running
//! and will cause a browser window to hang if run in the main thread.
//!
//! #### Build Instructions
//! ```bash
//! wasm-pack build --release --target web
//! ```
//!
//! If you are intending to use this for program execution or deployment, it is recommended to build
//! with maximum or close to maximum memory allocation (which is 4 gigabytes for wasm).
//!
//! ```bash
//! RUSTFLAGS='-C link-arg=--max-memory=4294967296' wasm-pack build --release --target web
//! ````
//!
//! ### 3. Multi-Threaded browser module
//!
//! This module is also built for browser-based JavaScript environments, however it is built to make use of Rust-native
//! threading via web-workers (using the approach outlined in the `rayon-wasm-bindgen` crate). It is the most complex to use,
//! but it will run significantly faster when performing Aleo program executions and deployments and should be the choice for
//! performance-critical applications.
//!
//! To build with threading enabled, it is necessary to use `nightly Rust` and set certain `RUSTFLAGS` to enable the
//! necessary threading features. The `wasm-pack` build command is shown below.
//! ```bash
//! # Set rustflags to enable atomics,
//! # bulk-memory, and mutable-globals.
//! # Also, set the maximum memory to
//! # 4294967296 bytes (4GB).
//! export RUSTFLAGS='-C target-feature=+atomics,+bulk-memory,+mutable-globals -C link-arg=--max-memory=4294967296'
//!
//! # Use rustup to run the following commands
//! # with the nightly version of Rust.
//! rustup run nightly \
//!
//! # Use wasm-pack to build the project.
//! # Specify the 'parallel' feature for
//! # multi-threading and the 'browser'
//! # feature to enable program execution
//! # and include necessary unstable options
//! # using -Z
//! wasm-pack build --release --target web --out-dir pkg-parallel \
//! -- --features "parallel, browser" -Z build-std=panic_abort,std
//! ```
//!
//! ## Testing
//!
//! Run tests in NodeJS
//! ```bash
//! wasm-pack test --node
//! ```
//!
//! Run tests in a browser
//! ```bash
//! wasm-pack test --[firefox/chrome/safari]
//! ```
//!
//! ## Building Web Apps
//!
//! Further documentation and tutorials as to how to use the modules built from this crate to build web apps  will be built
//! in the future. However - in the meantime, the [aleo.tools](https://aleo.tools) website is a good
//! example of how to use these modules to build a web app. Its source code can be found in the
//!

pub mod account;
pub use account::*;

pub mod programs;
pub use programs::*;

pub mod record;
pub use record::*;

pub mod types;
pub use types::Field;

use std::ffi::CStr;
use std::ffi::CString;
use std::os::raw::c_char;
use std::slice;

#[cfg(not(test))]
mod thread_pool;

use wasm_bindgen::prelude::*;

#[cfg(not(test))]
use thread_pool::ThreadPool;

use std::str::FromStr;

use types::native::RecordPlaintextNative;

// Facilities for cross-platform logging in both web browsers and nodeJS

/// A trait providing convenient methods for accessing the amount of Aleo present in a record
pub trait Credits {
    /// Get the amount of credits in the record if the record possesses Aleo credits
    fn credits(&self) -> Result<f64, String> {
        Ok(self.microcredits()? as f64 / 1_000_000.0)
    }

    /// Get the amount of microcredits in the record if the record possesses Aleo credits
    fn microcredits(&self) -> Result<u64, String>;
}

impl Credits for RecordPlaintextNative {
    fn microcredits(&self) -> Result<u64, String> {
        match self
            .find(&[native::IdentifierNative::from_str("microcredits").map_err(|e| e.to_string())?])
            .map_err(|e| e.to_string())?
        {
            native::Entry::Private(native::PlaintextNative::Literal(native::LiteralNative::U64(amount), _)) => {
                Ok(*amount)
            }
            _ => Err("The record provided does not contain a microcredits field".to_string()),
        }
    }
}

#[cfg(not(test))]
#[doc(hidden)]
pub use thread_pool::run_rayon_thread;
use types::native;

#[cfg(not(test))]
#[wasm_bindgen(js_name = "initThreadPool")]
pub async fn init_thread_pool(url: web_sys::Url, num_threads: usize) -> Result<(), JsValue> {
    console_error_panic_hook::set_once();

    ThreadPool::builder().url(url).num_threads(num_threads).build_global().await?;

    Ok(())
}

#[no_mangle]
pub extern "C" fn numbers_add(a: u32, b: u32) -> u32 {
    let result = a + b;
    result
}

#[no_mangle]
pub extern "C" fn seedToPrivateKey(seed_raw: *const u8) -> *const c_char {
    let seed;
    unsafe {
        seed = slice::from_raw_parts(seed_raw, 32);
    };
    let private_key = PrivateKey::from_seed_unchecked(seed);
    let c_string = CString::new(private_key.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn privateKeyToAddress(private_key_raw: *const c_char) -> *const c_char {
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::from_string(private_key_str).unwrap();
    let address = private_key.to_address();
    let c_string = CString::new(address.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn privateKeyToViewKey(private_key_raw: *const c_char) -> *const c_char {
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::from_string(private_key_str).unwrap();
    let view_key = private_key.to_view_key();
    let c_string = CString::new(view_key.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn viewKeyToAddress(view_key_raw: *const c_char) -> *const c_char {
    let view_key_cstr = unsafe { CStr::from_ptr(view_key_raw) };
    let view_key_str: &str = view_key_cstr.to_str().unwrap();
    let view_key = ViewKey::from_string(view_key_str);
    let address = view_key.to_address();
    let c_string = CString::new(address.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn signMessage(private_key_raw: *const c_char, message_raw: *const u8, length: usize) -> *const c_char {
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::from_string(private_key_str).unwrap();

    let message;
    unsafe {
        message = slice::from_raw_parts(message_raw, length);
    };

    let signature = private_key.sign(message);

    let c_string = CString::new(signature.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn verify(
    address_raw: *const c_char,
    signature_raw: *const c_char,
    message_raw: *const u8,
    length: usize,
) -> bool {
    let address_cstr = unsafe { CStr::from_ptr(address_raw) };
    let address_str: &str = address_cstr.to_str().unwrap();
    let address = Address::from_string(address_str);

    let signature_cstr = unsafe { CStr::from_ptr(signature_raw) };
    let signature_str: &str = signature_cstr.to_str().unwrap();
    let signature: Signature = Signature::from_string(signature_str);

    let message;
    unsafe {
        message = slice::from_raw_parts(message_raw, length);
    };
    signature.verify(&address, message)
}

#[no_mangle]
pub extern "C" fn encryptPrivateKey(private_key_raw: *const c_char, secret_raw: *const c_char) -> *const c_char {
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::from_string(private_key_str).unwrap();

    let secret_cstr = unsafe { CStr::from_ptr(secret_raw) };
    let secret: &str = secret_cstr.to_str().unwrap();

    let result = PrivateKeyCiphertext::encrypt_private_key(&private_key, secret).unwrap();

    let c_string = CString::new(result.to_string()).unwrap();
    c_string.into_raw()
}

fn cstr_to_string(cstr_raw: *const c_char) -> String {
    let cstr = unsafe { CStr::from_ptr(cstr_raw) };
    let str = cstr.to_str().unwrap();
    String::from(str)
}

#[no_mangle]
pub extern "C" fn decryptToPrivateKey(
    private_key_ciphertext_raw: *const c_char,
    secret_raw: *const c_char,
) -> *const c_char {
    let private_key_ciphertext_cstr = unsafe { CStr::from_ptr(private_key_ciphertext_raw) };
    let private_key_ciphertext_str: &str = private_key_ciphertext_cstr.to_str().unwrap();
    let private_key_ciphertext = PrivateKeyCiphertext::from_string(private_key_ciphertext_str.to_string()).unwrap();

    let secret_cstr = unsafe { CStr::from_ptr(secret_raw) };
    let secret: &str = secret_cstr.to_str().unwrap();

    let private_key = private_key_ciphertext.decrypt_to_private_key(secret).unwrap();
    let c_string = CString::new(private_key.to_string()).unwrap();
    c_string.into_raw()
}

// transfer
#[no_mangle]
pub extern "C" fn serialNumberString(
    record_plaintext_raw: *const c_char,
    private_key_raw: *const c_char,
    program_id_raw: *const c_char,
    record_name_raw: *const c_char,
) -> *const c_char {
    let record_plaintext = RecordPlaintext::from_string(&cstr_to_string(record_plaintext_raw)).unwrap();
    let private_key = PrivateKey::from_string(&cstr_to_string(private_key_raw)).unwrap();
    let program_id_cstr = unsafe { CStr::from_ptr(program_id_raw) };
    let program_id: &str = program_id_cstr.to_str().unwrap();
    let record_name_cstr = unsafe { CStr::from_ptr(record_name_raw) };
    let record_name: &str = record_name_cstr.to_str().unwrap();

    let result = record_plaintext.serial_number_string(&private_key, program_id, record_name);
    let c_string = CString::new(result.unwrap()).unwrap();
    c_string.into_raw()
}

// transfer
#[no_mangle]
pub extern "C" fn decryptCipherText(record_plaintext_raw: *const c_char, view_key_raw: *const c_char) -> *const c_char {
    let record_ciphertext = RecordCiphertext::from_string(&cstr_to_string(record_plaintext_raw)).unwrap();
    let view_key = ViewKey::from_string(&cstr_to_string(view_key_raw));

    let result = record_ciphertext.decrypt(&view_key).unwrap();
    let c_string = CString::new(result.to_string()).unwrap();
    c_string.into_raw()
}

// transfer
#[no_mangle]
pub extern "C" fn isOwner(record_plaintext_raw: *const c_char, view_key_raw: *const c_char) -> bool {
    let record_ciphertext = RecordCiphertext::from_string(&cstr_to_string(record_plaintext_raw)).unwrap();
    let view_key = ViewKey::from_string(&cstr_to_string(view_key_raw));

    let result: bool = record_ciphertext.is_owner(&view_key);
    result
}

use crate::types::native::{CurrentAleo, ProcessNative, ProgramNative, QueryNative, TransactionNative};
use js_sys::Array;
use rand::{rngs::StdRng, SeedableRng};

#[no_mangle]
pub extern "C" fn transfer_part(
    private_key_raw: *const c_char,
    amount_credits: f64,
    transfer_type_raw: *const c_char,
    recipient_raw: *const c_char,
    fee_credits: f64,
    url_raw: *const c_char,
) -> *const c_char {
    let private_key = PrivateKey::from_string(&cstr_to_string(private_key_raw)).unwrap();
    let transfer_type_cstr = unsafe { CStr::from_ptr(transfer_type_raw) };
    let transfer_type: &str = transfer_type_cstr.to_str().unwrap();
    let recipient_cstr = unsafe { CStr::from_ptr(recipient_raw) };
    let recipient: &str = recipient_cstr.to_str().unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap().to_string();

    // let result = ProgramManager::transfer_part(
    //     &private_key,
    //     amount_credits,
    //     recipient,
    //     transfer_type,
    //     None,
    //     fee_credits,
    //     None,
    //     Some(url),
    //     None,
    //     None,
    //     None,
    //     None,
    //     None,
    // )
    // .await;
    let mut process_native = ProcessNative::load_web().unwrap();
    let process = &mut process_native;
    let program_str = ProgramNative::credits().unwrap().to_string();
    let rng = &mut StdRng::from_entropy();

    // log("Loading program");
    let program = ProgramNative::from_str(&program_str).unwrap();
    // log("Loading function");
    let program_id = program.id().to_string();
    println!("transfer_type: {}", transfer_type);
    println!("recipient: {}", recipient);

    let inputs = [recipient, "10u64"];

    let authorization = process
        .authorize::<CurrentAleo, _>(&private_key, program.id(), transfer_type, inputs.into_iter(), rng)
        .map_err(|err| err.to_string())
        .unwrap();
    println!("authorization end-----------------------------------");
    let (_, mut trace) = process.execute::<CurrentAleo, _>(authorization, rng).unwrap();

    // if let Err(error) = authorization {
    //     // let c_string = CString::new(error).unwrap();
    //     println!("Authorization failed: {}", error);
    //     // c_string.into_raw();
    // }
    println!("trace end-----------------------------------");
    // let offline_query: Option<OfflineQuery> = None;
    // if let Some(offline_query) = offline_query.as_ref() {
    //     trace.prepare(offline_query.clone()).map_err(|err| err.to_string());
    // } else {
    //     let query = QueryNative::from(url);
    //     trace.prepare(query).map_err(|err| err.to_string());
    // }
    println!("offline_query end-----------------------");

    let execution = trace.prove_execution::<CurrentAleo, _>("credits.aleo/transfer", rng).map_err(|e| e.to_string()).unwrap();
    let execution_id = execution.to_execution_id().map_err(|e| e.to_string()).unwrap();

    let c_string = CString::new(execution_id.to_string()).unwrap();
    c_string.into_raw()
}
