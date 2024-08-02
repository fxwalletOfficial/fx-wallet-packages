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
    #[cfg(feature = "testnet")]
    pub use snarkvm_console::network::TestnetV0 as CurrentNetwork;
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
    pub use snarkvm_synthesizer::prelude::{cost_in_microcredits, execution_cost};
    pub use snarkvm_synthesizer::Authorization;
    pub use snarkvm_synthesizer::{
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

use snarkvm::circuit::prelude::PrimeField;
use snarkvm_console::prelude::Environment;
use snarkvm_console::prelude::FromBytes;

