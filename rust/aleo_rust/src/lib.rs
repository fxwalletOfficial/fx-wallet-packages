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

//! [![github]](https://github.com/AleoHQ/sdk)&ensp;[![crates-io]](https://crates.io/crates/aleo-rust)&ensp;[![docs-rs]](https://docs.rs/aleo-rust/latest/aleo_rust/)
//!
//! [github]: https://img.shields.io/badge/github-8da0cb?style=for-the-badge&labelColor=555555&logo=github
//! [crates-io]: https://img.shields.io/badge/crates.io-fc8d62?style=for-the-badge&labelColor=555555&logo=rust
//! [docs-rs]: https://img.shields.io/badge/docs.rs-66c2a5?style=for-the-badge&labelColor=555555&logo=docs.rs
//!
//! <br/>
//! The Aleo Rust SDK provides a set of tools for deploying and executing programs as well as
//! tools for communicating with the Aleo Network.
//!
//! # Aleo Network Interaction
//!
//! Users of the SDK can interact with the Aleo network via the [AleoAPIClient] struct.
//!
//! The Aleo Network has nodes within the network which provide a REST API for interacting with
//! the network. The AleoAPIClient struct provides a 1:1 mapping of those REST API endpoints as well
//! as several convenience methods for interacting with the network.
//!
//! Some key usages of the Aleo API client are:
//! * Finding records to spend in value transfers, program executions and program deployments
//! * Locating programs deployed on the network
//! * Sending transactions to the network
//! * Inspecting chain data such as block content, transaction content, etc.
//!
//! ### Example Usage
//! ```no_run
//!   use aleo_rust::AleoAPIClient;
//!   use snarkvm_console::{
//!       account::PrivateKey,
//!       network::Testnet3,
//!   };
//!   use rand::thread_rng;
//!
//!   // Create a client that interacts with the testnet3 program
//!   let api_client = AleoAPIClient::<Testnet3>::testnet3();
//!
//!   // FIND A PROGRAM ON THE ALEO NETWORK
//!   let hello = api_client.get_program("hello.aleo").unwrap();
//!   println!("Hello program: {hello:?}");
//!
//!   // FIND RECORDS THAT BELONG TO A PRIVATE KEY
//!   let mut rng = thread_rng();
//!   // Create a private key (in practice, this would be an existing user's private key)
//!   let private_key = PrivateKey::new(&mut rng).unwrap();
//!   // Get the latest block height
//!   let end_height = api_client.latest_height().unwrap();
//!   // Look back 1000 blocks
//!   let start_height = end_height - 1000u32;
//!   // Find records with these gate amounts (requires an account with a balance)
//!   let amounts_to_find = vec![100u64, 200u64];
//!   let records = api_client.get_unspent_records(&private_key, (start_height..end_height), None, Some(&amounts_to_find)).unwrap();
//!
//!   ```
//! # Program Execution and Deployment
//!
//! The Aleo [ProgramManager] provides a set of tools for deploying and executing programs locally
//! and on the Aleo Network.
//!
//! The [RecordFinder] struct is used in conjunction with the ProgramManager to find records to
//! spend in value transfers and program execution/deployments fees.
//!
//! The program deployment and execution flow are shown in the example below.
//!
//! ### Example Usage
//! ```no_run
//!   use aleo_rust::{
//!     AleoAPIClient, Encryptor, ProgramManager, RecordFinder,
//!     snarkvm_types::{Address, PrivateKey, Testnet3, Program},
//!     TransferType
//!   };
//!   use rand::thread_rng;
//!   use std::str::FromStr;
//!
//!   // Create the necessary components to create the program manager
//!   let mut rng = thread_rng();
//!   // Create an api client to query the network state
//!   let api_client = AleoAPIClient::<Testnet3>::testnet3();
//!   // Create a private key (in practice, this would be a user's private key)
//!   let private_key = PrivateKey::<Testnet3>::new(&mut rng).unwrap();
//!   // Encrypt the private key with a password
//!   let private_key_ciphertext = Encryptor::<Testnet3>::encrypt_private_key_with_secret(&private_key, "password").unwrap();
//!
//!   // Create the program manager
//!   // (Note: An optional local directory can be provided to manage local program data)
//!   let mut program_manager = ProgramManager::<Testnet3>::new(None, Some(private_key_ciphertext), Some(api_client), None, false).unwrap();
//!
//!   // ------------------
//!   // EXECUTE PROGRAM STEPS
//!   // ------------------
//!
//!   let record_finder = RecordFinder::<Testnet3>::new(AleoAPIClient::testnet3());
//!   // Set the fee for the deployment transaction (in units of microcredits)
//!   let fee_microcredits = 300000;
//!   // Find a record to fund the deployment fee (requires an account with a balance)
//!   let fee_record = record_finder.find_one_record(&private_key, fee_microcredits, None).unwrap();
//!
//!   // Execute the function `hello` of the hello.aleo program with the arguments 5u32 and 3u32.
//!   // Specify 0 for the fee and provide a password to decrypt the private key stored in the program manager
//!   program_manager.execute_program("hello.aleo", "hello", ["5u32", "3u32"].into_iter(), 0, Some(fee_record), Some("password"), None).unwrap();
//!
//!   // ------------------
//!   // DEPLOY PROGRAM STEPS
//!   // ------------------
//!
//!   // Note - Deployment requires a mandatory deployment fee, so an account with an existing
//!   // balance is required to deploy a program
//!
//!   // Create a program name (note: change this to something unique)
//!   let program_name = "yourownprogram.aleo";
//!   // Create a test program
//!   let test_program = format!("program {};\n\nfunction hello:\n    input r0 as u32.public;\n    input r1 as u32.private;\n    add r0 r1 into r2;\n    output r2 as u32.private;\n", program_name);
//!   // Create a program object from the program string
//!   let program = Program::from_str(&test_program).unwrap();
//!   // Add the program to the program manager (this can also be done by providing a path to
//!   // the program on disk when the program manager is created)
//!   program_manager.add_program(&program).unwrap();
//!   // Create a record finder to find records to fund the deployment fee
//!   let record_finder = RecordFinder::<Testnet3>::new(AleoAPIClient::testnet3());
//!   // Set the fee for the deployment transaction (in units of microcredits)
//!   let fee_microcredits = 300000;
//!   // Find a record to fund the deployment fee (requires an account with a balance)
//!   let fee_record = record_finder.find_one_record(&private_key, fee_microcredits, None).unwrap();
//!   // Deploy the program to the network
//!   program_manager.deploy_program(program_name, fee_microcredits, Some(fee_record), Some("password")).unwrap();
//!
//!   // Wait several minutes.. then check the program exists on the network
//!   let api_client = AleoAPIClient::<Testnet3>::testnet3();
//!   let program_on_chain = api_client.get_program(program_name).unwrap();
//!   let program_on_chain_name = program_on_chain.id().to_string();
//!   assert_eq!(&program_on_chain_name, program_name);
//!
//!   // ------------------
//!   // TRANSFER STEPS
//!   // ------------------
//!
//!   // Create a recipient (in practice, the recipient would send their address to the sender)
//!   let recipient_key = PrivateKey::<Testnet3>::new(&mut rng).unwrap();
//!   let recipient_address = Address::try_from(recipient_key).unwrap();
//!   // Create amount and fee (both in units of microcredits)
//!   let amount = 30000;
//!   let fee = 100;
//!   // Find records to fund the transfer
//!   let (amount_record, fee_record) = record_finder.find_amount_and_fee_records(amount, fee, &private_key).unwrap();
//!   // Create a transfer
//!   program_manager.transfer(amount, fee, recipient_address, TransferType::Private, Some("password"), Some(amount_record), Some(fee_record)).unwrap();
//!
//!   ```
//! This API is currently under active development and is expected to change in the future in order
//! to provide a more streamlined experience for program execution and deployment.
//!

pub mod account;
#[doc(inline)]
pub use account::Encryptor;

#[cfg(feature = "full")]
pub mod api;
#[cfg(feature = "full")]
#[doc(inline)]
pub use api::AleoAPIClient;

#[cfg(feature = "full")]
pub mod program;
#[cfg(feature = "full")]
#[doc(inline)]
pub use program::{OnChainProgramState, ProgramManager, RecordFinder, TransferType};

#[cfg(test)]
#[cfg(feature = "full")]
pub mod test_utils;
use snarkvm_ledger_block::Fee;
use snarkvm_synthesizer::Authorization;
#[cfg(test)]
#[cfg(feature = "full")]
pub use test_utils::*;

pub mod snarkvm_types {
    //! Re-export of crucial types from the snarkVM crate
    #[cfg(feature = "full")]
    pub use snarkvm::{file::Manifest, package::Package};
    pub use snarkvm_circuit_network::{Aleo, AleoV0};
    pub use snarkvm_console::{
        account::{Address, PrivateKey, Signature, ViewKey},
        network::Testnet3,
        prelude::{ToBytes, Uniform},
        program::{
            Ciphertext, Entry, EntryType, Identifier, Literal, Locator, Network, OutputID,
            Plaintext, PlaintextType, ProgramID, ProgramOwner, Record, Response, Value, ValueType,
        },
        types::Field,
    };
    pub use snarkvm_ledger_block::{Block, Deployment, Execution, Transaction};
    pub use snarkvm_ledger_query::Query;
    pub use snarkvm_ledger_store::{
        helpers::memory::{BlockMemory, ConsensusMemory},
        BlockStore, ConsensusStore,
    };
    pub use snarkvm_synthesizer::{
        cost_in_microcredits, deployment_cost, execution_cost,
        snark::{Proof, ProvingKey, VerifyingKey},
        Process, Program, Trace, VM,
    };
}

pub use snarkvm_types::*;

use anyhow::{anyhow, bail, ensure, Error, Result};
use indexmap::IndexMap;
use once_cell::sync::OnceCell;
#[cfg(feature = "full")]
use std::{convert::TryInto, fs::File, io::Read, ops::Range, path::PathBuf};
use std::{iter::FromIterator, marker::PhantomData, str::FromStr};

/// A trait providing convenient methods for accessing the amount of Aleo present in a record
pub trait Credits {
    /// Get the amount of credits in the record if the record possesses Aleo credits
    fn credits(&self) -> Result<f64> {
        Ok(self.microcredits()? as f64 / 1_000_000.0)
    }

    /// Get the amount of microcredits in the record if the record possesses Aleo credits
    fn microcredits(&self) -> Result<u64>;
}

impl<N: Network> Credits for Record<N, Plaintext<N>> {
    fn microcredits(&self) -> Result<u64> {
        let amount = match self.find(&[Identifier::from_str("microcredits")?])? {
            Entry::Private(Plaintext::Literal(Literal::<N>::U64(amount), _)) => amount,
            _ => bail!("The record provided does not contain a microcredits field"),
        };
        Ok(*amount)
    }
}

use std::ffi::CStr;
use std::ffi::CString;
use std::os::raw::c_char;
use std::slice;

#[no_mangle]
pub extern "C" fn numbers_add(a: u32, b: u32) -> u32 {
    let result = a + b;
    result
}
use snarkvm::circuit::prelude::PrimeField;
use snarkvm_console::prelude::Environment;
use snarkvm_console::prelude::FromBytes;

#[no_mangle]
pub extern "C" fn seedToPrivateKey(seed_raw: *const u8) -> *const c_char {
    let seed;
    unsafe {
        seed = slice::from_raw_parts(seed_raw, 32);
    };

    let field_mid = <Testnet3 as Environment>::Field::from_bytes_le_mod_order(seed);
    let field = FromBytes::read_le(&*field_mid.to_bytes_le().unwrap()).unwrap();

    let private_key = PrivateKey::<Testnet3>::try_from(field).unwrap();
    let c_string = CString::new(private_key.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn privateKeyToAddress(private_key_raw: *const c_char) -> *const c_char {
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::<Testnet3>::from_str(private_key_str).unwrap();
    let view_key = ViewKey::try_from(&private_key).unwrap();
    let address = view_key.to_address();
    let c_string = CString::new(address.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn privateKeyToViewKey(private_key_raw: *const c_char) -> *const c_char {
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::<Testnet3>::from_str(private_key_str).unwrap();
    let view_key = ViewKey::try_from(&private_key).unwrap();
    let c_string = CString::new(view_key.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn viewKeyToAddress(view_key_raw: *const c_char) -> *const c_char {
    let view_key_cstr = unsafe { CStr::from_ptr(view_key_raw) };
    let view_key_str: &str = view_key_cstr.to_str().unwrap();
    let view_key = ViewKey::<Testnet3>::from_str(view_key_str).unwrap();
    let address = view_key.to_address();
    let c_string = CString::new(address.to_string()).unwrap();
    c_string.into_raw()
}

use rand::{rngs::StdRng, SeedableRng};

#[no_mangle]
pub extern "C" fn signMessage(
    private_key_raw: *const c_char,
    message_raw: *const u8,
    length: usize,
) -> *const c_char {
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::<Testnet3>::from_str(private_key_str).unwrap();

    let message;
    unsafe {
        message = slice::from_raw_parts(message_raw, length);
    };
    let rng = &mut StdRng::from_entropy();
    let signature = private_key.sign_bytes(message, rng).unwrap();

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
    let address = Address::<Testnet3>::from_str(address_str).unwrap();

    let signature_cstr = unsafe { CStr::from_ptr(signature_raw) };
    let signature_str: &str = signature_cstr.to_str().unwrap();
    let signature = Signature::<Testnet3>::from_str(signature_str).unwrap();

    let message;
    unsafe {
        message = slice::from_raw_parts(message_raw, length);
    };
    signature.verify_bytes(&address, &message)
}

#[no_mangle]
pub extern "C" fn encryptPrivateKey(
    private_key_raw: *const c_char,
    secret_raw: *const c_char,
) -> *const c_char {
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::<Testnet3>::from_str(private_key_str).unwrap();

    let secret_cstr = unsafe { CStr::from_ptr(secret_raw) };
    let secret: &str = secret_cstr.to_str().unwrap();

    let result = Encryptor::encrypt_private_key_with_secret(&private_key, secret).unwrap();

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

    let private_key_ciphertext =
        Ciphertext::<Testnet3>::from_str(private_key_ciphertext_str).unwrap();

    let secret_cstr = unsafe { CStr::from_ptr(secret_raw) };
    let secret: &str = secret_cstr.to_str().unwrap();

    let private_key =
        Encryptor::decrypt_private_key_with_secret(&private_key_ciphertext, secret).unwrap();

    let c_string = CString::new(private_key.to_string()).unwrap();
    c_string.into_raw()
}

// transfer
#[no_mangle]
pub extern "C" fn decryptCipherText(
    record_ciphertext_raw: *const c_char,
    view_key_raw: *const c_char,
) -> *const c_char {
    let record_ciphertext =
        Record::<Testnet3, Ciphertext<Testnet3>>::from_str(&cstr_to_string(record_ciphertext_raw))
            .unwrap();
    let view_key = ViewKey::<Testnet3>::from_str(&cstr_to_string(view_key_raw)).unwrap();
    let result = record_ciphertext.decrypt(&view_key).unwrap();
    let c_string = CString::new(result.to_string()).unwrap();
    c_string.into_raw()
}

// transfer
#[no_mangle]
pub extern "C" fn isOwner(
    record_plaintext_raw: *const c_char,
    view_key_raw: *const c_char,
) -> bool {
    let record_ciphertext =
        Record::<Testnet3, Ciphertext<Testnet3>>::from_str(&cstr_to_string(record_plaintext_raw))
            .unwrap();
    let view_key = ViewKey::<Testnet3>::from_str(&cstr_to_string(view_key_raw)).unwrap();
    let result: bool = record_ciphertext.is_owner(&view_key);
    result
}

// use std::thread;

#[no_mangle]
pub extern "C" fn try_transfer(
    private_key_raw: *const c_char,
    recipient_raw: *const c_char,
    transfer_type_raw: *const c_char,
    amount: u64,
    fee: u64,
    url_raw: *const c_char,
    amount_record_raw: *const c_char,
    fee_record_raw: *const c_char,
) -> *const c_char {
    let transfer_type_cstr = unsafe { CStr::from_ptr(transfer_type_raw) };
    let transfer_type: &str = transfer_type_cstr.to_str().unwrap();

    let visibility = match transfer_type {
        "transfer_public" => TransferType::Public,
        "transfer_public_to_private" => TransferType::PublicToPrivate,
        "transfer_private" => TransferType::Private,
        "transfer_private_to_public" => TransferType::PrivateToPublic,
        _ => TransferType::Public,
    };
    // let visibility = TransferType::Private;
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key: &str = private_key_cstr.to_str().unwrap();
    let sender = PrivateKey::<Testnet3>::from_str(private_key).unwrap();
    let recipient_cstr = unsafe { CStr::from_ptr(recipient_raw) };
    let recipient_str: &str = recipient_cstr.to_str().unwrap();
    let recipient = Address::<Testnet3>::from_str(recipient_str).unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    println!("Attempting to transfer of type: {visibility:?} of {amount} to {recipient:?}");
    let api_client = AleoAPIClient::<Testnet3>::aleo_net(url);
    let view_key = ViewKey::try_from(&sender).unwrap();
    let program_manager =
        ProgramManager::<Testnet3>::new(Some(sender), None, Some(api_client.clone()), None, false)
            .unwrap();
    // let record_finder = RecordFinder::new(api_client);
    let mut tx_hash = "error".to_string();
    for i in 0..10 {
        let (amount_record, fee_record) = match &visibility {
            TransferType::Public => (None, None),
            TransferType::PublicToPrivate => (None, None),
            _ => {
                // let record = record_finder.find_amount_and_fee_records(amount, fee, &sender);
                // if record.is_err() {
                //     println!("Record not found: {} - retrying", record.unwrap_err());
                //     thread::sleep(std::time::Duration::from_secs(3));
                //     continue;
                // }
                // let (amount_record, fee_record) = record.unwrap();

                let amount_record_ciphertext = Record::<Testnet3, Ciphertext<Testnet3>>::from_str(
                    &cstr_to_string(amount_record_raw),
                )
                .unwrap();
                let amount_record = amount_record_ciphertext.decrypt(&view_key).unwrap();

                let fee_record_ciphertext = Record::<Testnet3, Ciphertext<Testnet3>>::from_str(
                    &cstr_to_string(fee_record_raw),
                )
                .unwrap();
                let fee_record = fee_record_ciphertext.decrypt(&view_key).unwrap();

                (Some(amount_record), Some(fee_record))
            }
        };
        let result = program_manager.transfer(
            amount,
            fee,
            recipient,
            visibility,
            None,
            amount_record,
            fee_record,
        );
        if result.is_err() {
            println!("Transfer error: {} - retrying", result.unwrap_err());
            if i == 9 {
                panic!("Transfer failed after 10 attempts");
            }
        } else {
            tx_hash = result.unwrap();
            break;
        }
    }
    let c_string = CString::new(tx_hash).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn execution_authorization(
    private_key_raw: *const c_char,
    recipient_raw: *const c_char,
    transfer_type_raw: *const c_char,
    amount: u64,
    url_raw: *const c_char,
    amount_record_raw: *const c_char,
) -> *const c_char {
    let transfer_type_cstr = unsafe { CStr::from_ptr(transfer_type_raw) };
    let transfer_type: &str = transfer_type_cstr.to_str().unwrap();

    let visibility = match transfer_type {
        "transfer_public" => TransferType::Public,
        "transfer_public_to_private" => TransferType::PublicToPrivate,
        "transfer_private" => TransferType::Private,
        "transfer_private_to_public" => TransferType::PrivateToPublic,
        _ => TransferType::Public,
    };
    // let visibility = TransferType::Private;
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key: &str = private_key_cstr.to_str().unwrap();
    let sender = PrivateKey::<Testnet3>::from_str(private_key).unwrap();
    let recipient_cstr = unsafe { CStr::from_ptr(recipient_raw) };
    let recipient_str: &str = recipient_cstr.to_str().unwrap();
    let recipient = Address::<Testnet3>::from_str(recipient_str).unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    println!("Attempting to transfer of type: {visibility:?} of {amount} to {recipient:?}");
    let api_client = AleoAPIClient::<Testnet3>::aleo_net(url);
    let view_key = ViewKey::try_from(&sender).unwrap();
    let program_manager =
        ProgramManager::<Testnet3>::new(Some(sender), None, Some(api_client.clone()), None, false)
            .unwrap();
    // let record_finder = RecordFinder::new(api_client);
    let mut authorization = "error".to_string();
    for i in 0..10 {
        let amount_record = match &visibility {
            TransferType::Public => None,
            TransferType::PublicToPrivate => None,
            _ => {
                let amount_record_ciphertext = Record::<Testnet3, Ciphertext<Testnet3>>::from_str(
                    &cstr_to_string(amount_record_raw),
                )
                .unwrap();
                let amount_record = amount_record_ciphertext.decrypt(&view_key).unwrap();

                Some(amount_record)
            }
        };
        let result = program_manager.execution_authorization(
            amount,
            recipient,
            visibility,
            None,
            amount_record,
        );
        if result.is_err() {
            println!("Transfer error: {} - retrying", result.unwrap_err());
            if i == 9 {
                panic!("Transfer failed after 10 attempts");
            }
        } else {
            authorization = result.unwrap();
            break;
        }
    }
    let c_string = CString::new(authorization).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn execute_proof(
    url_raw: *const c_char,
    authorization_raw: *const c_char,
) -> *const c_char {
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    let api_client = AleoAPIClient::<Testnet3>::aleo_net(url);
    let program_manager =
        ProgramManager::<Testnet3>::new(None, None, Some(api_client.clone()), None, false).unwrap();
    let authorization_cstr = unsafe { CStr::from_ptr(authorization_raw) };
    let authorization_str: &str = authorization_cstr.to_str().unwrap();
    let authorization =
        Authorization::<Testnet3>::from_str(&authorization_str.to_string()).unwrap();
    let execution = program_manager.execute_proof(authorization).unwrap();
    let c_string = CString::new(execution.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn execution_fee_authorization(
    private_key_raw: *const c_char,
    transfer_type_raw: *const c_char,
    url_raw: *const c_char,
    fee: u64,
    fee_record_raw: *const c_char,
    execution_raw: *const c_char,
) -> *const c_char {
    let transfer_type_cstr = unsafe { CStr::from_ptr(transfer_type_raw) };
    let transfer_type: &str = transfer_type_cstr.to_str().unwrap();

    let visibility = match transfer_type {
        "transfer_public" => TransferType::Public,
        "transfer_public_to_private" => TransferType::PublicToPrivate,
        "transfer_private" => TransferType::Private,
        "transfer_private_to_public" => TransferType::PrivateToPublic,
        _ => TransferType::Public,
    };

    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key: &str = private_key_cstr.to_str().unwrap();
    let sender = PrivateKey::<Testnet3>::from_str(private_key).unwrap();

    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();

    let api_client = AleoAPIClient::<Testnet3>::aleo_net(url);
    let view_key = ViewKey::try_from(&sender).unwrap();
    let program_manager =
        ProgramManager::<Testnet3>::new(Some(sender), None, Some(api_client.clone()), None, false)
            .unwrap();
    let execution_cstr = unsafe { CStr::from_ptr(execution_raw) };
    let execution_str: &str = execution_cstr.to_str().unwrap();
    let execution = Execution::<Testnet3>::from_str(&execution_str.to_string()).unwrap();

    let mut authorization = "error".to_string();
    for i in 0..10 {
        let fee_record = match &visibility {
            TransferType::Public => None,
            TransferType::PublicToPrivate => None,
            _ => {
                let fee_record_string: String = cstr_to_string(fee_record_raw);
                let fee_record;

                if fee_record_string.is_empty() {
                    fee_record = None;
                } else {
                    let fee_record_ciphertext =
                        Record::<Testnet3, Ciphertext<Testnet3>>::from_str(&fee_record_string)
                            .unwrap();
                    fee_record = Some(fee_record_ciphertext.decrypt(&view_key).unwrap());
                }

                fee_record
            }
        };
        let result =
            program_manager.execution_fee_authorization(fee, None, fee_record, execution.clone());
        if result.is_err() {
            println!("Transfer error: {} - retrying", result.unwrap_err());
            if i == 9 {
                panic!("Transfer failed after 10 attempts");
            }
        } else {
            authorization = result.unwrap();
            break;
        }
    }
    let c_string = CString::new(authorization).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn execute_fee_proof(
    url_raw: *const c_char,
    authorization_raw: *const c_char,
) -> *const c_char {
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    let api_client = AleoAPIClient::<Testnet3>::aleo_net(url);
    let program_manager =
        ProgramManager::<Testnet3>::new(None, None, Some(api_client.clone()), None, false).unwrap();
    let authorization_cstr = unsafe { CStr::from_ptr(authorization_raw) };
    let authorization_str: &str = authorization_cstr.to_str().unwrap();
    let authorization =
        Authorization::<Testnet3>::from_str(&authorization_str.to_string()).unwrap();
    let execution = program_manager.execute_fee_proof(authorization).unwrap();
    let c_string = CString::new(execution.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn build_transaction_offline(
    execution_raw: *const c_char,
    fee_raw: *const c_char,
) -> *const c_char {
    let execution_cstr = unsafe { CStr::from_ptr(execution_raw) };
    let execution_str: &str = execution_cstr.to_str().unwrap();
    let execution = Execution::<Testnet3>::from_str(&execution_str.to_string()).unwrap();

    let fee_cstr = unsafe { CStr::from_ptr(fee_raw) };
    let fee_str: &str = fee_cstr.to_str().unwrap();
    let fee = Some(Fee::<Testnet3>::from_str(&fee_str.to_string()).unwrap());
    let transaction = Transaction::from_execution(execution, fee).unwrap();

    let c_string = CString::new(transaction.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn build_transaction(
    private_key_raw: *const c_char,
    recipient_raw: *const c_char,
    transfer_type_raw: *const c_char,
    amount: u64,
    fee: u64,
    url_raw: *const c_char,
    amount_record_raw: *const c_char,
    fee_record_raw: *const c_char,
) -> *const c_char {
    let transfer_type_cstr = unsafe { CStr::from_ptr(transfer_type_raw) };
    let transfer_type: &str = transfer_type_cstr.to_str().unwrap();

    let visibility = match transfer_type {
        "transfer_public" => TransferType::Public,
        "transfer_public_to_private" => TransferType::PublicToPrivate,
        "transfer_private" => TransferType::Private,
        "transfer_private_to_public" => TransferType::PrivateToPublic,
        _ => TransferType::Public,
    };
    // let visibility = TransferType::Private;
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key: &str = private_key_cstr.to_str().unwrap();
    let sender = PrivateKey::<Testnet3>::from_str(private_key).unwrap();
    let recipient_cstr = unsafe { CStr::from_ptr(recipient_raw) };
    let recipient_str: &str = recipient_cstr.to_str().unwrap();
    let recipient = Address::<Testnet3>::from_str(recipient_str).unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    println!("Attempting to transfer of type: {visibility:?} of {amount} to {recipient:?}");
    let api_client = AleoAPIClient::<Testnet3>::aleo_net(url);
    let view_key = ViewKey::try_from(&sender).unwrap();
    let program_manager =
        ProgramManager::<Testnet3>::new(Some(sender), None, Some(api_client.clone()), None, false)
            .unwrap();
    // let record_finder = RecordFinder::new(api_client);
    let mut tx_hash = "error".to_string();
    for i in 0..10 {
        let (amount_record, fee_record) = match &visibility {
            TransferType::Public => (None, None),
            TransferType::PublicToPrivate => (None, None),
            _ => {
                let amount_record_ciphertext = Record::<Testnet3, Ciphertext<Testnet3>>::from_str(
                    &cstr_to_string(amount_record_raw),
                )
                .unwrap();
                let amount_record = amount_record_ciphertext.decrypt(&view_key).unwrap();

                let fee_record_string: String = cstr_to_string(fee_record_raw);
                let fee_record;

                if fee_record_string.is_empty() {
                    fee_record = None;
                } else {
                    let fee_record_ciphertext =
                        Record::<Testnet3, Ciphertext<Testnet3>>::from_str(&fee_record_string)
                            .unwrap();
                    fee_record = Some(fee_record_ciphertext.decrypt(&view_key).unwrap());
                }

                (Some(amount_record), fee_record)
            }
        };
        let result = program_manager.build_transaction(
            amount,
            fee,
            recipient,
            visibility,
            None,
            amount_record,
            fee_record,
        );
        if result.is_err() {
            println!("Transfer error: {} - retrying", result.unwrap_err());
            if i == 9 {
                panic!("Transfer failed after 10 attempts");
            }
        } else {
            tx_hash = result.unwrap();
            break;
        }
    }
    let c_string = CString::new(tx_hash).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn broadcast(
    execution_raw: *const c_char,
    url_raw: *const c_char,
    transfer_type_raw: *const c_char,
) -> *const c_char {
    let execution_cstr = unsafe { CStr::from_ptr(execution_raw) };
    let execution = execution_cstr.to_str().unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    let transfer_type_cstr = unsafe { CStr::from_ptr(transfer_type_raw) };
    let transfer_type: &str = transfer_type_cstr.to_str().unwrap();

    let result = ProgramManager::<Testnet3>::broadcast(
        execution.to_string(),
        url.to_string(),
        transfer_type.to_string(),
    )
    .unwrap();
    let c_string = CString::new(result).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn serialNumberString(
    record_ciphertext_raw: *const c_char,
    private_key_raw: *const c_char,
    program_id_raw: *const c_char,
    record_name_raw: *const c_char,
) -> *const c_char {
    let record_ciphertext =
        Record::<Testnet3, Ciphertext<Testnet3>>::from_str(&cstr_to_string(record_ciphertext_raw))
            .unwrap();
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::<Testnet3>::from_str(private_key_str).unwrap();
    let view_key = ViewKey::try_from(&private_key).unwrap();
    let record_plaintext = record_ciphertext.decrypt(&view_key).unwrap();
    let program_id_cstr = unsafe { CStr::from_ptr(program_id_raw) };
    let program_id: &str = program_id_cstr.to_str().unwrap();
    let record_name_cstr = unsafe { CStr::from_ptr(record_name_raw) };
    let record_name: &str = record_name_cstr.to_str().unwrap();
    let parsed_program_id = ProgramID::<Testnet3>::from_str(program_id).unwrap();
    let record_identifier = Identifier::<Testnet3>::from_str(record_name).unwrap();
    let commitment = record_plaintext
        .to_commitment(&parsed_program_id, &record_identifier)
        .unwrap();
    let serial_number =
        Record::<Testnet3, Plaintext<Testnet3>>::serial_number(private_key, commitment).unwrap();

    let c_string = CString::new(serial_number.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn try_join(
    private_key_raw: *const c_char,
    record_1_raw: *const c_char,
    record_2_raw: *const c_char,
    fee: u64,
    fee_record_raw: *const c_char,
    url_raw: *const c_char,
) -> *const c_char {
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key: &str = private_key_cstr.to_str().unwrap();
    let sender = PrivateKey::<Testnet3>::from_str(private_key).unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    let api_client = AleoAPIClient::<Testnet3>::aleo_net(url);
    let view_key = ViewKey::try_from(&sender).unwrap();
    let program_manager =
        ProgramManager::<Testnet3>::new(Some(sender), None, Some(api_client.clone()), None, false)
            .unwrap();

    let record1_ciphertext =
        Record::<Testnet3, Ciphertext<Testnet3>>::from_str(&cstr_to_string(record_1_raw)).unwrap();
    let record1 = record1_ciphertext.decrypt(&view_key).unwrap();
    let record2_ciphertext =
        Record::<Testnet3, Ciphertext<Testnet3>>::from_str(&cstr_to_string(record_2_raw)).unwrap();
    let record2 = record2_ciphertext.decrypt(&view_key).unwrap();

    let fee_record_string: String = cstr_to_string(fee_record_raw);
    let fee_record;

    if fee_record_string.is_empty() {
        fee_record = None;
    } else {
        let fee_record_ciphertext =
            Record::<Testnet3, Ciphertext<Testnet3>>::from_str(&fee_record_string).unwrap();
        fee_record = Some(fee_record_ciphertext.decrypt(&view_key).unwrap());
    }

    // let record_finder = RecordFinder::new(api_client);
    let mut tx_hash = "error".to_string();

    for i in 0..10 {
        let result =
            program_manager.join(record1.clone(), record2.clone(), fee_record.clone(), fee);
        if result.is_err() {
            println!("Transfer error: {} - retrying", result.unwrap_err());
            if i == 9 {
                panic!("Transfer failed after 10 attempts");
            }
        } else {
            tx_hash = result.unwrap();
            break;
        }
    }
    let c_string = CString::new(tx_hash).unwrap();
    c_string.into_raw()
}
