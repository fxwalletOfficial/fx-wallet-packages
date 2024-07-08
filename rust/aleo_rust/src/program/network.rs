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

use super::*;

impl<N: Network> ProgramManager<N> {
    /// Broadcast a transaction to the network
    pub fn broadcast_transaction(&self, transaction: Transaction<N>) -> Result<String> {
        let transaction_type = if let Transaction::Deploy(..) = &transaction { "Deployment" } else { "Execute" };
        let api_client = self.api_client()?;
        let result = api_client.transaction_broadcast(transaction);
        if result.is_ok() {
            println!("✅ {} Transaction successfully posted to {}", transaction_type, api_client.base_url());
        } else {
            println!("❌ {} Transaction failed to post to {}", transaction_type, api_client.base_url());
        }
        result
    }

    /// Get a reference to the configured API client
    pub fn api_client(&self) -> Result<&AleoAPIClient<N>> {
        self.api_client.as_ref().ok_or_else(|| anyhow!("No API client found"))
    }

    /// Check the on-chain version of a program to determine if it is deployed, and if so,
    /// if it is the same as the local version
    pub fn on_chain_program_state(&self, program: &Program<N>) -> Result<OnChainProgramState> {
        let program_id = program.id();
        Ok(self
            .api_client()?
            .get_program(program_id)
            .map(
                |chain_program| {
                    if chain_program.eq(program) { OnChainProgramState::Same } else { OnChainProgramState::Different }
                },
            )
            .unwrap_or(OnChainProgramState::NotDeployed))
    }

    /// Check the value of an on-chain mapping
    pub fn get_mapping_value(
        &self,
        program_id: impl TryInto<ProgramID<N>>,
        mapping_name: impl TryInto<Identifier<N>>,
        key: impl TryInto<Plaintext<N>>,
    ) -> Result<Value<N>> {
        let api_client = self.api_client()?;
        let mapping_value = api_client.get_mapping_value(program_id, mapping_name, key)?;
        Ok(mapping_value)
    }

    /// Check the mappings available in a program
    pub fn get_mappings(&self, program_id: impl TryInto<ProgramID<N>>) -> Result<Vec<Identifier<N>>> {
        let api_client = self.api_client()?;
        let mappings = api_client.get_program_mappings(program_id)?;
        Ok(mappings)
    }
}