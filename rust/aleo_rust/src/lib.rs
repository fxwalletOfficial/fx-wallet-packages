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
// use snarkvm_synthesizer::Authorization;
#[cfg(test)]
#[cfg(feature = "full")]
pub use test_utils::*;

pub mod snarkvm_types {
    //! Re-export of crucial types from the snarkVM crate
    #[cfg(feature = "full")]
    pub use snarkvm::{file::Manifest, package::Package};
    pub use snarkvm_circuit_network::{Aleo, AleoV0};
    #[cfg(feature = "mainnet")]
    pub use snarkvm_console::network::MainnetV0 as CurrentNetwork;
    // #[cfg(feature = "testnet")]
    // pub use snarkvm_console::network::TestnetV0 as CurrentNetwork;
    pub use aleo_std_storage::StorageMode;
    pub use snarkvm_algorithms::snark::varuna::VarunaVersion;
    pub use snarkvm_console::{
        account::{Address, PrivateKey, Signature, ViewKey},
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
    pub use snarkvm_synthesizer::prelude::{cost_in_microcredits_v2, execution_cost_v2};
    pub use snarkvm_synthesizer::Authorization;
    pub use snarkvm_synthesizer::{
        snark::{Proof, ProvingKey, VerifyingKey},
        Process, Program, Trace, VM,
    };
    pub use snarkvm_synthesizer_process::InclusionVersion;
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

use snarkvm::circuit::prelude::PrimeField;
use snarkvm_console::prelude::Environment;
use snarkvm_console::prelude::FromBytes;
use snarkvm_console::prelude::ToBits;

#[no_mangle]
pub extern "C" fn numbers_add(a: u32, b: u32) -> u32 {
    let result = a + b + 1;
    result
}

#[no_mangle]
pub extern "C" fn seed_to_private_key(seed_raw: *const u8) -> *const c_char {
    let seed;
    unsafe {
        seed = slice::from_raw_parts(seed_raw, 32);
    };

    let field_mid = <CurrentNetwork as Environment>::Field::from_bytes_le_mod_order(seed);
    let field = FromBytes::read_le(&*field_mid.to_bytes_le().unwrap()).unwrap();

    let private_key = PrivateKey::<CurrentNetwork>::try_from(field).unwrap();
    let c_string = CString::new(private_key.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn private_key_to_address(private_key_raw: *const c_char) -> *const c_char {
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::<CurrentNetwork>::from_str(private_key_str).unwrap();
    let view_key = ViewKey::try_from(&private_key).unwrap();
    let address = view_key.to_address();
    let c_string = CString::new(address.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn private_key_to_view_key(private_key_raw: *const c_char) -> *const c_char {
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::<CurrentNetwork>::from_str(private_key_str).unwrap();
    let view_key = ViewKey::try_from(&private_key).unwrap();
    let c_string = CString::new(view_key.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn view_key_to_address(view_key_raw: *const c_char) -> *const c_char {
    let view_key_cstr = unsafe { CStr::from_ptr(view_key_raw) };
    let view_key_str: &str = view_key_cstr.to_str().unwrap();
    let view_key = ViewKey::<CurrentNetwork>::from_str(view_key_str).unwrap();
    let address = view_key.to_address();
    let c_string = CString::new(address.to_string()).unwrap();
    c_string.into_raw()
}

use rand::{rngs::StdRng, SeedableRng};

#[no_mangle]
pub extern "C" fn sign_message(
    private_key_raw: *const c_char,
    message_raw: *const u8,
    length: usize,
) -> *const c_char {
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::<CurrentNetwork>::from_str(private_key_str).unwrap();

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
    let address = Address::<CurrentNetwork>::from_str(address_str).unwrap();

    let signature_cstr = unsafe { CStr::from_ptr(signature_raw) };
    let signature_str: &str = signature_cstr.to_str().unwrap();
    let signature = Signature::<CurrentNetwork>::from_str(signature_str).unwrap();

    let message;
    unsafe {
        message = slice::from_raw_parts(message_raw, length);
    };
    signature.verify_bytes(&address, &message)
}

#[no_mangle]
pub extern "C" fn encrypt_private_key(
    private_key_raw: *const c_char,
    secret_raw: *const c_char,
) -> *const c_char {
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::<CurrentNetwork>::from_str(private_key_str).unwrap();

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
pub extern "C" fn decrypt_to_private_key(
    private_key_ciphertext_raw: *const c_char,
    secret_raw: *const c_char,
) -> *const c_char {
    let private_key_ciphertext_cstr = unsafe { CStr::from_ptr(private_key_ciphertext_raw) };
    let private_key_ciphertext_str: &str = private_key_ciphertext_cstr.to_str().unwrap();

    let private_key_ciphertext =
        Ciphertext::<CurrentNetwork>::from_str(private_key_ciphertext_str).unwrap();

    let secret_cstr = unsafe { CStr::from_ptr(secret_raw) };
    let secret: &str = secret_cstr.to_str().unwrap();

    let private_key =
        Encryptor::decrypt_private_key_with_secret(&private_key_ciphertext, secret).unwrap();

    let c_string = CString::new(private_key.to_string()).unwrap();
    c_string.into_raw()
}

// transfer
#[no_mangle]
pub extern "C" fn decrypt_cipher_text(
    record_ciphertext_raw: *const c_char,
    view_key_raw: *const c_char,
) -> *const c_char {
    let record_ciphertext = Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(
        &cstr_to_string(record_ciphertext_raw),
    )
    .unwrap();
    let view_key = ViewKey::<CurrentNetwork>::from_str(&cstr_to_string(view_key_raw)).unwrap();
    let result = record_ciphertext.decrypt(&view_key).unwrap();
    let c_string = CString::new(result.to_string()).unwrap();
    c_string.into_raw()
}

// transfer
#[no_mangle]
pub extern "C" fn is_owner(
    record_plaintext_raw: *const c_char,
    view_key_raw: *const c_char,
) -> bool {
    let record_ciphertext = Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(
        &cstr_to_string(record_plaintext_raw),
    )
    .unwrap();
    let view_key = ViewKey::<CurrentNetwork>::from_str(&cstr_to_string(view_key_raw)).unwrap();
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
    network_raw: *const c_char,
) -> *const c_char {
    let transfer_type_cstr = unsafe { CStr::from_ptr(transfer_type_raw) };
    let transfer_type: &str = transfer_type_cstr.to_str().unwrap();
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();

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
    let sender = PrivateKey::<CurrentNetwork>::from_str(private_key).unwrap();
    let recipient_cstr = unsafe { CStr::from_ptr(recipient_raw) };
    let recipient_str: &str = recipient_cstr.to_str().unwrap();
    let recipient = Address::<CurrentNetwork>::from_str(recipient_str).unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    println!(
        "Attempting to transfer in {network} of type : {visibility:?} of {amount} to {recipient:?}"
    );
    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);
    let view_key = ViewKey::try_from(&sender).unwrap();
    let program_manager = ProgramManager::<CurrentNetwork>::new(
        Some(sender),
        None,
        Some(api_client.clone()),
        None,
        false,
    )
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

                let amount_record_ciphertext =
                    Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(
                        &cstr_to_string(amount_record_raw),
                    )
                    .unwrap();
                let amount_record = amount_record_ciphertext.decrypt(&view_key).unwrap();

                let fee_record_ciphertext =
                    Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(
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
    network_raw: *const c_char,
) -> *const c_char {
    let transfer_type_cstr = unsafe { CStr::from_ptr(transfer_type_raw) };
    let transfer_type: &str = transfer_type_cstr.to_str().unwrap();
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();
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
    let sender = PrivateKey::<CurrentNetwork>::from_str(private_key).unwrap();
    let recipient_cstr = unsafe { CStr::from_ptr(recipient_raw) };
    let recipient_str: &str = recipient_cstr.to_str().unwrap();
    let recipient = Address::<CurrentNetwork>::from_str(recipient_str).unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    println!(
        "Attempting to transfer in {network} of type : {visibility:?} of {amount} to {recipient:?}"
    );
    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);
    let view_key = ViewKey::try_from(&sender).unwrap();
    let program_manager = ProgramManager::<CurrentNetwork>::new(
        Some(sender),
        None,
        Some(api_client.clone()),
        None,
        false,
    )
    .unwrap();
    // let record_finder = RecordFinder::new(api_client);
    let mut authorization = "error".to_string();
    for i in 0..10 {
        let amount_record = match &visibility {
            TransferType::Public => None,
            TransferType::PublicToPrivate => None,
            _ => {
                let amount_record_ciphertext =
                    Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(
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
    network_raw: *const c_char,
) -> *const c_char {
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();
    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);
    let program_manager =
        ProgramManager::<CurrentNetwork>::new(None, None, Some(api_client.clone()), None, false)
            .unwrap();
    let authorization_cstr = unsafe { CStr::from_ptr(authorization_raw) };
    let authorization_str: &str = authorization_cstr.to_str().unwrap();
    let authorization =
        Authorization::<CurrentNetwork>::from_str(&authorization_str.to_string()).unwrap();
    let execution = program_manager.execute_proof(authorization);
    let result = match execution {
        Ok(value) => value,
        Err(err) => format!("Error: {}!", err.to_string()),
    };
    let c_string = CString::new(result.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn execute_program_proof(
    url_raw: *const c_char,
    authorization_raw: *const c_char,
    network_raw: *const c_char,
    program_id_raw: *const c_char,
) -> *const c_char {
    let program_id_cstr = unsafe { CStr::from_ptr(program_id_raw) };
    let program_id: &str = program_id_cstr.to_str().unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();
    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);
    let program_manager =
        ProgramManager::<CurrentNetwork>::new(None, None, Some(api_client.clone()), None, false)
            .unwrap();
    let authorization_cstr = unsafe { CStr::from_ptr(authorization_raw) };
    let authorization_str: &str = authorization_cstr.to_str().unwrap();
    let authorization =
        Authorization::<CurrentNetwork>::from_str(&authorization_str.to_string()).unwrap();
    let execution =
        program_manager.execute_program_proof(authorization, program_id.to_string(), &api_client);
    let result = match execution {
        Ok(value) => value,
        Err(err) => format!("Error: {}!", err.to_string()),
    };
    let c_string = CString::new(result.to_string()).unwrap();
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
    network_raw: *const c_char,
) -> *const c_char {
    let transfer_type_cstr = unsafe { CStr::from_ptr(transfer_type_raw) };
    let transfer_type: &str = transfer_type_cstr.to_str().unwrap();
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();
    let visibility = match transfer_type {
        "transfer_public" => TransferType::Public,
        "transfer_public_to_private" => TransferType::PublicToPrivate,
        "transfer_private" => TransferType::Private,
        "transfer_private_to_public" => TransferType::PrivateToPublic,
        _ => TransferType::Public,
    };

    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key: &str = private_key_cstr.to_str().unwrap();
    let sender = PrivateKey::<CurrentNetwork>::from_str(private_key).unwrap();

    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();

    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);
    let view_key = ViewKey::try_from(&sender).unwrap();
    let program_manager = ProgramManager::<CurrentNetwork>::new(
        Some(sender),
        None,
        Some(api_client.clone()),
        None,
        false,
    )
    .unwrap();
    let execution_cstr = unsafe { CStr::from_ptr(execution_raw) };
    let execution_str: &str = execution_cstr.to_str().unwrap();
    let execution = Execution::<CurrentNetwork>::from_str(&execution_str.to_string()).unwrap();

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
                        Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(
                            &fee_record_string,
                        )
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
    network_raw: *const c_char,
) -> *const c_char {
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();
    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);
    let program_manager =
        ProgramManager::<CurrentNetwork>::new(None, None, Some(api_client.clone()), None, false)
            .unwrap();
    let authorization_cstr = unsafe { CStr::from_ptr(authorization_raw) };
    let authorization_str: &str = authorization_cstr.to_str().unwrap();
    let authorization =
        Authorization::<CurrentNetwork>::from_str(&authorization_str.to_string()).unwrap();
    let execution = program_manager.execute_fee_proof(authorization);
    let result = match execution {
        Ok(value) => value,
        Err(err) => format!("Error: {}!", err.to_string()),
    };
    let c_string = CString::new(result.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn build_transaction_offline(
    execution_raw: *const c_char,
    fee_raw: *const c_char,
) -> *const c_char {
    let execution_cstr = unsafe { CStr::from_ptr(execution_raw) };
    let execution_str: &str = execution_cstr.to_str().unwrap();
    let execution = Execution::<CurrentNetwork>::from_str(&execution_str.to_string()).unwrap();

    let fee_cstr = unsafe { CStr::from_ptr(fee_raw) };
    let fee_str: &str = fee_cstr.to_str().unwrap();
    let fee = Some(Fee::<CurrentNetwork>::from_str(&fee_str.to_string()).unwrap());
    let transaction = Transaction::from_execution(execution, fee).unwrap();

    let c_string = CString::new(transaction.to_string()).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn build_upgrade_transaction_offline(execution_raw: *const c_char) -> *const c_char {
    let execution_cstr = unsafe { CStr::from_ptr(execution_raw) };
    let execution_str: &str = execution_cstr.to_str().unwrap();
    let execution = Execution::<CurrentNetwork>::from_str(&execution_str.to_string()).unwrap();

    let transaction = Transaction::from_execution(execution, None).unwrap();

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
    network_raw: *const c_char,
) -> *const c_char {
    let transfer_type_cstr = unsafe { CStr::from_ptr(transfer_type_raw) };
    let transfer_type: &str = transfer_type_cstr.to_str().unwrap();
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();
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
    let sender = PrivateKey::<CurrentNetwork>::from_str(private_key).unwrap();
    let recipient_cstr = unsafe { CStr::from_ptr(recipient_raw) };
    let recipient_str: &str = recipient_cstr.to_str().unwrap();
    let recipient = Address::<CurrentNetwork>::from_str(recipient_str).unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    println!(
        "Attempting to transfer in {network} of type : {visibility:?} of {amount} to {recipient:?}"
    );
    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);
    let view_key = ViewKey::try_from(&sender).unwrap();
    let program_manager = ProgramManager::<CurrentNetwork>::new(
        Some(sender),
        None,
        Some(api_client.clone()),
        None,
        false,
    )
    .unwrap();
    // let record_finder = RecordFinder::new(api_client);
    let mut tx_hash = "error".to_string();
    for i in 0..10 {
        let (amount_record, fee_record) = match &visibility {
            TransferType::Public => (None, None),
            TransferType::PublicToPrivate => (None, None),
            _ => {
                let amount_record_ciphertext =
                    Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(
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
                        Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(
                            &fee_record_string,
                        )
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
    network_raw: *const c_char,
) -> *const c_char {
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();
    let execution_cstr = unsafe { CStr::from_ptr(execution_raw) };
    let execution = execution_cstr.to_str().unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    let transfer_type_cstr = unsafe { CStr::from_ptr(transfer_type_raw) };
    let transfer_type: &str = transfer_type_cstr.to_str().unwrap();

    let broadcast_result = ProgramManager::<CurrentNetwork>::broadcast(
        execution.to_string(),
        url.to_string(),
        transfer_type.to_string(),
        network.to_string(),
    );

    let result = match broadcast_result {
        Ok(value) => value,
        Err(err) => format!("Error: {}!", err.to_string()),
    };
    let c_string = CString::new(result).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn serial_number_string(
    record_ciphertext_raw: *const c_char,
    private_key_raw: *const c_char,
    program_id_raw: *const c_char,
    record_name_raw: *const c_char,
) -> *const c_char {
    let record_ciphertext = Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(
        &cstr_to_string(record_ciphertext_raw),
    )
    .unwrap();
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key_str: &str = private_key_cstr.to_str().unwrap();
    let private_key = PrivateKey::<CurrentNetwork>::from_str(private_key_str).unwrap();
    let view_key = ViewKey::try_from(&private_key).unwrap();
    let record_plaintext = record_ciphertext.decrypt(&view_key).unwrap();
    let program_id_cstr = unsafe { CStr::from_ptr(program_id_raw) };
    let program_id: &str = program_id_cstr.to_str().unwrap();
    let record_name_cstr = unsafe { CStr::from_ptr(record_name_raw) };
    let record_name: &str = record_name_cstr.to_str().unwrap();
    let parsed_program_id = ProgramID::<CurrentNetwork>::from_str(program_id).unwrap();
    let record_identifier = Identifier::<CurrentNetwork>::from_str(record_name).unwrap();
    let record_view_key = (*view_key * record_plaintext.nonce()).to_x_coordinate();
    let commitment = record_plaintext
        .to_commitment(&parsed_program_id, &record_identifier, &record_view_key)
        .unwrap();
    let serial_number =
        Record::<CurrentNetwork, Plaintext<CurrentNetwork>>::serial_number(private_key, commitment)
            .unwrap();

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
    network_raw: *const c_char,
) -> *const c_char {
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key: &str = private_key_cstr.to_str().unwrap();
    let sender = PrivateKey::<CurrentNetwork>::from_str(private_key).unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);
    let view_key = ViewKey::try_from(&sender).unwrap();
    let program_manager = ProgramManager::<CurrentNetwork>::new(
        Some(sender),
        None,
        Some(api_client.clone()),
        None,
        false,
    )
    .unwrap();

    let record1_ciphertext = Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(
        &cstr_to_string(record_1_raw),
    )
    .unwrap();
    let record1 = record1_ciphertext.decrypt(&view_key).unwrap();
    let record2_ciphertext = Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(
        &cstr_to_string(record_2_raw),
    )
    .unwrap();
    let record2 = record2_ciphertext.decrypt(&view_key).unwrap();

    let fee_record_string: String = cstr_to_string(fee_record_raw);
    let fee_record;

    if fee_record_string.is_empty() {
        fee_record = None;
    } else {
        let fee_record_ciphertext =
            Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(&fee_record_string)
                .unwrap();
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

#[no_mangle]
pub extern "C" fn join_authorization(
    private_key_raw: *const c_char,
    record_1_raw: *const c_char,
    record_2_raw: *const c_char,
    url_raw: *const c_char,
    network_raw: *const c_char,
) -> *const c_char {
    // let visibility = TransferType::Private;
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key: &str = private_key_cstr.to_str().unwrap();
    let sender = PrivateKey::<CurrentNetwork>::from_str(private_key).unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    let view_key = ViewKey::try_from(&sender).unwrap();

    let record1_ciphertext = Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(
        &cstr_to_string(record_1_raw),
    )
    .unwrap();
    let record1 = record1_ciphertext.decrypt(&view_key).unwrap();
    let record2_ciphertext = Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(
        &cstr_to_string(record_2_raw),
    )
    .unwrap();
    let record2 = record2_ciphertext.decrypt(&view_key).unwrap();

    println!("Attempting to transfer in {network} of type : join");
    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);
    let program_manager = ProgramManager::<CurrentNetwork>::new(
        Some(sender),
        None,
        Some(api_client.clone()),
        None,
        false,
    )
    .unwrap();
    // let record_finder = RecordFinder::new(api_client);
    let mut authorization = "error".to_string();
    for i in 0..10 {
        let result = program_manager.join_authorization(record1.clone(), record2.clone(), None);
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
pub extern "C" fn upgrade_authorization(
    private_key_raw: *const c_char,
    record_raw: *const c_char,
    url_raw: *const c_char,
    network_raw: *const c_char,
) -> *const c_char {
    // let visibility = TransferType::Private;
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key: &str = private_key_cstr.to_str().unwrap();
    let sender = PrivateKey::<CurrentNetwork>::from_str(private_key).unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    let view_key = ViewKey::try_from(&sender).unwrap();

    let record_ciphertext =
        Record::<CurrentNetwork, Ciphertext<CurrentNetwork>>::from_str(&cstr_to_string(record_raw))
            .unwrap();
    let record = record_ciphertext.decrypt(&view_key).unwrap();

    println!("Attempting to upgrade in {network} of type : upgrade");
    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);
    let program_manager = ProgramManager::<CurrentNetwork>::new(
        Some(sender),
        None,
        Some(api_client.clone()),
        None,
        false,
    )
    .unwrap();
    // let record_finder = RecordFinder::new(api_client);
    let mut authorization = "error".to_string();
    for i in 0..10 {
        let result = program_manager.upgrade_authorization(record.clone(), None);
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
pub extern "C" fn get_base_fee(
    url_raw: *const c_char,
    execution_raw: *const c_char,
    network_raw: *const c_char,
) -> u64 {
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();

    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);
    let execution_cstr = unsafe { CStr::from_ptr(execution_raw) };
    let execution_str: &str = execution_cstr.to_str().unwrap();
    let execution = Execution::<CurrentNetwork>::from_str(&execution_str.to_string()).unwrap();
    let program_manager =
        ProgramManager::<CurrentNetwork>::new(None, None, Some(api_client.clone()), None, false)
            .unwrap();
    let base_fee = program_manager.get_base_fee(execution).unwrap();
    base_fee
}

#[no_mangle]
pub extern "C" fn execute_program(
    private_key_raw: *const c_char,
    program_id_raw: *const c_char,
    function_name_raw: *const c_char,
    arguments_raw: *const c_char,
    fee: u64,
    url_raw: *const c_char,
    network_raw: *const c_char,
) -> *const c_char {
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();
    let program_id_cstr = unsafe { CStr::from_ptr(program_id_raw) };
    let program_id: &str = program_id_cstr.to_str().unwrap();
    let function_name_cstr = unsafe { CStr::from_ptr(function_name_raw) };
    let function_name: &str = function_name_cstr.to_str().unwrap();
    let arguments_cstr = unsafe { CStr::from_ptr(arguments_raw) };
    let arguments: &str = arguments_cstr.to_str().unwrap();
    let inputs: Vec<&str> = arguments.split(",").collect();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();

    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key: &str = private_key_cstr.to_str().unwrap();
    let sender = PrivateKey::<CurrentNetwork>::from_str(private_key).unwrap();

    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);

    let mut program_manager = ProgramManager::<CurrentNetwork>::new(
        Some(sender),
        None,
        Some(api_client.clone()),
        None,
        false,
    )
    .unwrap();
    let result = program_manager
        .execute_program(
            program_id,
            function_name,
            inputs.into_iter(),
            fee,
            None,
            None,
            None,
        )
        .unwrap();

    let c_string = CString::new(result).unwrap();
    c_string.into_raw()
}

#[no_mangle]
pub extern "C" fn contract_execution(
    private_key_raw: *const c_char,
    program_id_raw: *const c_char,
    function_name_raw: *const c_char,
    arguments_raw: *const c_char,
    url_raw: *const c_char,
    network_raw: *const c_char,
) -> *const c_char {
    // let visibility = TransferType::Private;
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key: &str = private_key_cstr.to_str().unwrap();
    let sender = PrivateKey::<CurrentNetwork>::from_str(private_key).unwrap();
    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();

    let program_id_cstr = unsafe { CStr::from_ptr(program_id_raw) };
    let program_id: &str = program_id_cstr.to_str().unwrap();
    let function_name_cstr = unsafe { CStr::from_ptr(function_name_raw) };
    let function_name: &str = function_name_cstr.to_str().unwrap();

    let arguments_cstr = unsafe { CStr::from_ptr(arguments_raw) };
    let arguments: &str = arguments_cstr.to_str().unwrap();
    let inputs: Vec<&str> = arguments.split(",").collect();

    println!("Attempting to transfer in {network} of type : {program_id}::{function_name}");
    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);

    // let record_finder = RecordFinder::new(api_client);
    let mut authorization = "error".to_string();

    let program_manager = ProgramManager::<CurrentNetwork>::new(
        Some(sender),
        None,
        Some(api_client.clone()),
        None,
        false,
    )
    .unwrap();

    for i in 0..10 {
        let result = program_manager.contract_execution(
            program_id.to_string(),
            function_name.to_string(),
            inputs.clone(),
            None,
            &api_client,
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
pub extern "C" fn contract_fee_execution(
    private_key_raw: *const c_char,
    fee: u64,
    execution_raw: *const c_char,
    program_id_raw: *const c_char,
    url_raw: *const c_char,
    network_raw: *const c_char,
) -> *const c_char {
    let network_cstr = unsafe { CStr::from_ptr(network_raw) };
    let network: &str = network_cstr.to_str().unwrap();
    let program_id_cstr = unsafe { CStr::from_ptr(program_id_raw) };
    let program_id: &str = program_id_cstr.to_str().unwrap();
    let private_key_cstr = unsafe { CStr::from_ptr(private_key_raw) };
    let private_key: &str = private_key_cstr.to_str().unwrap();
    let sender = PrivateKey::<CurrentNetwork>::from_str(private_key).unwrap();

    let url_cstr = unsafe { CStr::from_ptr(url_raw) };
    let url = url_cstr.to_str().unwrap();

    let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(url, network);
    let program_manager = ProgramManager::<CurrentNetwork>::new(
        Some(sender),
        None,
        Some(api_client.clone()),
        None,
        false,
    )
    .unwrap();
    let execution_cstr = unsafe { CStr::from_ptr(execution_raw) };
    let execution_str: &str = execution_cstr.to_str().unwrap();
    let execution = Execution::<CurrentNetwork>::from_str(&execution_str.to_string()).unwrap();

    let mut authorization = "error".to_string();
    for i in 0..10 {
        let result = program_manager.contract_fee_execution(
            fee,
            None,
            execution.clone(),
            program_id.to_string(),
            &api_client,
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

/// FFI函数：根据地址字符串和token_id字符串创建TokenOwner并计算哈希
#[no_mangle]
pub extern "C" fn get_token_owner_hash(
    address_raw: *const c_char,
    token_id_raw: *const c_char,
) -> *const c_char {
    let result = std::panic::catch_unwind(|| {
        // 解析地址
        let address_cstr = unsafe { CStr::from_ptr(address_raw) };
        let address_str = address_cstr.to_str().unwrap();
        let address = Address::<CurrentNetwork>::from_str(address_str).unwrap();

        // 解析token_id
        let token_id_cstr = unsafe { CStr::from_ptr(token_id_raw) };
        let token_id_str = token_id_cstr.to_str().unwrap();
        let token_id = Field::<CurrentNetwork>::from_str(token_id_str).unwrap();

        let token_owner_plaintext = Plaintext::<CurrentNetwork>::Struct(
            indexmap::IndexMap::from_iter(vec![
                (
                    Identifier::from_str("account").unwrap(),
                    Plaintext::<CurrentNetwork>::from(Literal::Address(address)),
                ),
                (
                    Identifier::from_str("token_id").unwrap(),
                    Plaintext::<CurrentNetwork>::from(Literal::Field(token_id)),
                ),
            ]),
            OnceCell::new(),
        );

        // 使用BHP256哈希函数 - 这是正确的Leo兼容实现
        let hash_result = CurrentNetwork::hash_bhp256(&token_owner_plaintext.to_bits_le()).unwrap();

        Ok::<String, &str>(hash_result.to_string())
    });

    match result {
        Ok(Ok(hash_string)) => {
            let c_string =
                CString::new(hash_string).unwrap_or_else(|_| CString::new("error").unwrap());
            c_string.into_raw()
        }
        _ => {
            let c_string = CString::new("error").unwrap();
            c_string.into_raw()
        }
    }
}

/// 辅助函数：使用网络哈希函数哈希任意数据到Field
#[no_mangle]
pub extern "C" fn psd2_hash_to_field(data_raw: *const c_char) -> *const c_char {
    let result = std::panic::catch_unwind(|| {
        let data_cstr = unsafe { CStr::from_ptr(data_raw) };
        let data_str = data_cstr.to_str().map_err(|_| "Invalid UTF-8")?;

        // 将输入字符串转换为Field
        let input_field = Field::<CurrentNetwork>::new_domain_separator(data_str);

        // 使用PSD2哈希
        let hash_result =
            CurrentNetwork::hash_psd2(&[input_field]).map_err(|_| "Failed to hash data")?;

        Ok::<String, &str>(hash_result.to_string())
    });

    match result {
        Ok(Ok(hash_string)) => {
            let c_string =
                CString::new(hash_string).unwrap_or_else(|_| CString::new("error").unwrap());
            c_string.into_raw()
        }
        _ => {
            let c_string = CString::new("error").unwrap();
            c_string.into_raw()
        }
    }
}
