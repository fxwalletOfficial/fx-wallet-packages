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

//! Tools for deploying, executing, and managing programs on the Aleo network

use super::*;

pub mod execute;

pub mod join;

pub mod helpers;
pub use helpers::*;

pub mod network;

pub mod resolver;

pub mod transfer;

/// Program management object for loading programs for building, execution, and deployment
///
/// This object is meant to be a software abstraction that can be consumed by software like
/// CLI tools, IDE plugins, Server-side stack components and other software that needs to
/// interact with the Aleo network.
#[derive(Clone)]
pub struct ProgramManager<N: Network> {
    pub(crate) programs: IndexMap<ProgramID<N>, Program<N>>,
    pub(crate) private_key: Option<PrivateKey<N>>,
    pub(crate) private_key_ciphertext: Option<Ciphertext<N>>,
    pub(crate) local_program_directory: Option<PathBuf>,
    pub(crate) api_client: Option<AleoAPIClient<N>>,
    pub(crate) vm: Option<VM<N, ConsensusMemory<N>>>,
}

impl<N: Network> ProgramManager<N> {
    /// Create a new program manager by specifying custom options for the private key (or private
    /// key ciphertext) and resolver. Use this method if you want to create a custom resolver
    /// (i.e. one that searches a local or remote database) for program and record resolution.
    pub fn new(
        private_key: Option<PrivateKey<N>>,
        private_key_ciphertext: Option<Ciphertext<N>>,
        api_client: Option<AleoAPIClient<N>>,
        local_program_directory: Option<PathBuf>,
        use_cache: bool,
    ) -> Result<Self> {
        // if private_key.is_some() && private_key_ciphertext.is_some() {
        //     bail!("Cannot have both private key and private key ciphertext");
        // } else if private_key.is_none() && private_key_ciphertext.is_none() {
        //     bail!("Must have either private key or private key ciphertext");
        // }
        let programs = IndexMap::new();
        let vm = if use_cache {
            let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
            Some(VM::<N, ConsensusMemory<N>>::from(store)?)
        } else {
            None
        };
        Ok(Self {
            programs,
            private_key,
            private_key_ciphertext,
            local_program_directory,
            api_client,
            vm,
        })
    }

    /// Manually add a program to the program manager from memory if it does not already exist
    pub fn add_program(&mut self, program: &Program<N>) -> Result<()> {
        if self.contains_program(program.id())? {
            bail!("program already exists")
        };
        self.programs
            .entry(*program.id())
            .or_insert(program.clone());
        Ok(())
    }

    /// Initialize a SnarkVM instance with a program and its imports
    pub fn initialize_vm(
        api_client: &AleoAPIClient<N>,
        program: &Program<N>,
        initialize_execution: bool,
    ) -> Result<VM<N, ConsensusMemory<N>>> {
        // Create an ephemeral SnarkVM to store the programs
        // Initialize an RNG and query object for the transaction
        let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
        let vm: VM<N, ConsensusMemory<N>> = VM::<N, ConsensusMemory<N>>::from(store)?;

        // Resolve imports
        let credits_id = ProgramID::<N>::from_str("credits.aleo")?;
        api_client
            .get_program_imports_from_source(program)?
            .iter()
            .try_for_each(|(_, import)| {
                if import.id() != &credits_id {
                    vm.process().write().add_program(import)?;
                }
                Ok::<_, Error>(())
            })?;

        // If the initialization is for an execution, add the program. Otherwise, don't add it as
        // it will be added during the deployment process
        if initialize_execution {
            // If the program doesn't have a constructor, use edition 1 to avoid edition 0 execution errors
            // in ConsensusVersion::V8 or higher
            if program.contains_constructor() {
                vm.process().write().add_program(program)?;
            } else {
                vm.process().write().add_program_with_edition(program, 1)?;
            }
        }
        Ok(vm)
    }

    /// Manually add a program to the program manager if it does not already exist or update
    /// it if it does
    pub fn update_program(&mut self, program: &Program<N>) -> Option<Program<N>> {
        self.programs.insert(*program.id(), program.clone())
    }

    /// Retrieve a program from the program manager if it exists
    pub fn get_program(&self, program_id: impl TryInto<ProgramID<N>>) -> Result<Program<N>> {
        let program_id = program_id
            .try_into()
            .map_err(|_| anyhow!("invalid program id"))?;
        self.programs
            .get(&program_id)
            .map_or(Err(anyhow!("program not found")), |program| {
                Ok(program.clone())
            })
    }

    /// Determine if a program exists in the program manager
    pub fn contains_program(&self, program_id: impl TryInto<ProgramID<N>>) -> Result<bool> {
        let program_id = program_id
            .try_into()
            .map_err(|_| anyhow!("invalid program id"))?;
        Ok(self.programs.contains_key(&program_id))
    }

    /// Get the private key from the program manager. If the key is stored as ciphertext, a
    /// password must be provided to decrypt it
    pub(super) fn get_private_key(&self, password: Option<&str>) -> Result<PrivateKey<N>> {
        if self.private_key.is_none() && self.private_key_ciphertext.is_none() {
            bail!("Private key is not configured");
        };
        if let Some(private_key) = &self.private_key {
            if self.private_key_ciphertext.is_some() {
                bail!(
                    "Private key ciphertext is also configured, cannot have both private key and private key ciphertext"
                );
            }
            return Ok(*private_key);
        };
        if let Some(ciphertext) = &self.private_key_ciphertext {
            if self.private_key.is_some() {
                bail!("Private key is already configured, cannot have both private key and private key ciphertext");
            }

            let password = password
                .ok_or_else(|| anyhow!("Private key is encrypted, password is required"))?;
            return Encryptor::<N>::decrypt_private_key_with_secret(ciphertext, password);
        };
        bail!("Private key configuration error")
    }

    pub fn vm(&self) -> &Option<VM<N, ConsensusMemory<N>>> {
        &self.vm
    }
}
