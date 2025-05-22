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
    /// Executes a transfer to the specified recipient_address with the specified amount and fee.
    /// Specify 0 for no fee.
    #[allow(clippy::too_many_arguments)]
    pub fn join(
        &self,
        amount_record_1: Record<N, Plaintext<N>>,
        amount_record_2: Record<N, Plaintext<N>>,
        fee_record: Option<Record<N, Plaintext<N>>>,
        fee: u64,
    ) -> Result<String> {
        // Ensure records provided have enough credits to cover the transfer amount and fee
        if let Some(fee_record) = fee_record.as_ref() {
            ensure!(
                fee_record.microcredits()? >= fee,
                "Fee must be greater than the fee specified in the record"
            );
        }

        // Specify the network state query
        let query = Query::from(self.api_client.as_ref().unwrap().base_url());

        // Retrieve the private key.
        let private_key = self.get_private_key(None)?;

        // Generate the execution transaction
        let execution = {
            let rng = &mut rand::thread_rng();

            // Initialize a VM
            let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
            let vm = VM::from(store)?;

            // Create a new transaction.
            vm.execute(
                &private_key,
                ("credits.aleo", "join"),
                vec![
                    Value::Record(amount_record_1),
                    Value::Record(amount_record_2),
                ]
                .iter(),
                fee_record,
                fee,
                Some(query),
                rng,
            )?
        };

        self.broadcast_transaction(execution)
    }
}
