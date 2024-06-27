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
    /// Create an offline execution of a program to share with a third party.
    ///
    /// DISCLAIMER: Offline executions will not interact with the Aleo network and cannot use all
    /// of the features of the Leo programming language or Aleo instructions. Any code written
    /// inside finalize blocks will not be executed, mappings cannot be initialized, updated or read,
    /// and a chain of records cannot be created.
    ///
    /// Offline executions however can be used to verify that program outputs follow from program
    /// inputs and that the program was executed correctly. If this is the aim and no chain
    /// interaction is desired, this function can be used.
    #[allow(clippy::too_many_arguments)]
    pub fn execute_program_offline<A: Aleo<Network = N>>(
        &self,
        private_key: &PrivateKey<N>,
        program: &Program<N>,
        function: impl TryInto<Identifier<N>>,
        imports: &[Program<N>],
        inputs: impl ExactSizeIterator<Item = impl TryInto<Value<N>>>,
        include_outputs: bool,
        url: &str,
    ) -> Result<OfflineExecution<N>> {
        // Initialize an RNG and query object for the transaction
        let rng = &mut rand::thread_rng();
        let query = Query::<N, BlockMemory<N>>::from(url);

        // Check that the function exists in the program
        let function_name = function
            .try_into()
            .map_err(|_| anyhow!("Invalid function name"))?;
        let program_id = program.id();
        println!("Checking function {function_name:?} exists in {program_id:?}");
        ensure!(
            program.contains_function(&function_name),
            "Program {program_id:?} does not contain function {function_name:?}, aborting execution"
        );

        // Create an ephemeral SnarkVM to store the programs
        let store = ConsensusStore::<N, ConsensusMemory<N>>::open(None)?;
        let vm = VM::<N, ConsensusMemory<N>>::from(store)?;
        let credits_id = ProgramID::<N>::from_str("credits.aleo")?;
        imports.iter().try_for_each(|program| {
            if &credits_id != program.id() {
                vm.process().write().add_program(program)?
            }
            Ok::<(), Error>(())
        })?;
        let _ = vm.process().write().add_program(program);

        // Compute the authorization.
        let authorization = vm.authorize(private_key, program_id, function_name, inputs, rng)?;

        // Compute the trace
        let locator = Locator::new(*program_id, function_name);
        let (response, mut trace) = vm.process().write().execute::<A, _>(authorization, rng)?;
        trace.prepare(query)?;
        let execution =
            trace.prove_execution::<A, _>(&locator.to_string(), &mut rand::thread_rng())?;

        // Get the public outputs
        let mut public_outputs = vec![];
        response
            .outputs()
            .iter()
            .zip(response.output_ids().iter())
            .for_each(|(output, output_id)| {
                if let OutputID::Public(_) = output_id {
                    public_outputs.push(output.clone());
                }
            });

        // If all outputs are requested, include them
        let response = if include_outputs {
            Some(response)
        } else {
            None
        };

        // Return the execution
        Ok(OfflineExecution::new(
            execution,
            response,
            trace,
            Some(public_outputs),
        ))
    }

    /// Execute a program function on the Aleo Network.
    ///
    /// To run this function successfully, the program must already be deployed on the Aleo Network
    pub fn execute_program(
        &mut self,
        program_id: impl TryInto<ProgramID<N>>,
        function: impl TryInto<Identifier<N>>,
        inputs: impl ExactSizeIterator<Item = impl TryInto<Value<N>>>,
        priority_fee: u64,
        fee_record: Option<Record<N, Plaintext<N>>>,
        password: Option<&str>,
        private_key: Option<&PrivateKey<N>>,
    ) -> Result<String> {
        // Ensure a network client is set, otherwise online execution is not possible
        ensure!(
            self.api_client.is_some(),
            "❌ Network client not set. A network client must be set before execution in order to send an execution transaction to the Aleo network"
        );

        // Check program and function have valid names
        let program_id = program_id
            .try_into()
            .map_err(|_| anyhow!("Invalid program ID"))?;
        let function_id = function
            .try_into()
            .map_err(|_| anyhow!("Invalid function name"))?;
        let function_name = function_id.to_string();
        let api_client = self.api_client()?;

        // Get the program from chain, error if it doesn't exist
        let program = self
            .get_program(program_id)
            .or_else(|_| api_client.get_program(program_id))?;

        // Create the execution transaction
        let private_key = private_key.map_or_else(
            || self.get_private_key(password),
            |private_key| Ok(*private_key),
        )?;
        let node_url = self.api_client.as_ref().unwrap().base_url().to_string();
        let transaction = Self::create_execute_transaction(
            &private_key,
            priority_fee,
            inputs,
            fee_record,
            &program,
            function_id,
            node_url,
            self.api_client()?,
            &self.vm,
        )?;

        // Broadcast the execution transaction to the network
        println!("Attempting to broadcast execution transaction for {program_id:?}");
        let execution = self.broadcast_transaction(transaction);

        // Tell the user about the result of the execution before returning it
        if execution.is_ok() {
            println!("✅ Execution of function {function_name:?} from program {program_id:?}' broadcast successfully");
        } else {
            println!("❌ Execution of function {function_name:?} from program {program_id:?} failed to broadcast");
        }

        execution
    }

    /// Create an execute transaction without initializing a program manager instance
    #[allow(clippy::too_many_arguments)]
    pub fn create_execute_transaction(
        private_key: &PrivateKey<N>,
        priority_fee: u64,
        inputs: impl ExactSizeIterator<Item = impl TryInto<Value<N>>>,
        fee_record: Option<Record<N, Plaintext<N>>>,
        program: &Program<N>,
        function: impl TryInto<Identifier<N>>,
        node_url: String,
        api_client: &AleoAPIClient<N>,
        vm: &Option<VM<N, ConsensusMemory<N>>>,
    ) -> Result<Transaction<N>> {
        // Initialize an RNG and query object for the transaction
        let rng = &mut rand::thread_rng();
        let query = Query::from(node_url);

        // Check that the function exists in the program
        let function_name = function
            .try_into()
            .map_err(|_| anyhow!("Invalid function name"))?;
        let program_id = program.id();
        println!("Checking function {function_name:?} exists in {program_id:?}");
        ensure!(
            program.contains_function(&function_name),
            "Program {program_id:?} does not contain function {function_name:?}, aborting execution"
        );

        // Initialize the VM
        if let Some(vm) = vm {
            let credits_id = ProgramID::<N>::from_str("credits.aleo")?;
            api_client
                .get_program_imports_from_source(program)?
                .iter()
                .try_for_each(|(_, import)| {
                    if import.id() != &credits_id
                        && !vm.process().read().contains_program(import.id())
                    {
                        vm.process().write().add_program(import)?
                    }
                    Ok::<_, Error>(())
                })?;

            // If the initialization is for an execution, add the program. Otherwise, don't add it as
            // it will be added during the deployment process
            if !vm.process().read().contains_program(program.id()) {
                vm.process().write().add_program(program)?;
            }
            vm.execute(
                private_key,
                (program_id, function_name),
                inputs,
                fee_record,
                priority_fee,
                Some(query),
                rng,
            )
        } else {
            let vm = Self::initialize_vm(api_client, program, true)?;
            vm.execute(
                private_key,
                (program_id, function_name),
                inputs,
                fee_record,
                priority_fee,
                Some(query),
                rng,
            )
        }
    }

    /// Estimate the cost of executing a program with the given inputs in microcredits. The response
    /// will be in the form of (total_cost, (storage_cost, finalize_cost))
    ///
    /// Disclaimer: Fee estimation is experimental and may not represent a correct estimate on any current or future network
    pub fn estimate_execution_fee<A: Aleo<Network = N>>(
        &self,
        program: &Program<N>,
        function: impl TryInto<Identifier<N>>,
        inputs: impl ExactSizeIterator<Item = impl TryInto<Value<N>>>,
    ) -> Result<(u64, (u64, u64))> {
        let url = self.api_client.as_ref().map_or_else(
            || bail!("A network client must be configured to estimate a program execution fee"),
            |api_client| Ok(api_client.base_url()),
        )?;

        // Check that the function exists in the program
        let function_name = function
            .try_into()
            .map_err(|_| anyhow!("Invalid function name"))?;
        let program_id = program.id();
        println!("Checking function {function_name:?} exists in {program_id:?}");
        ensure!(
            program.contains_function(&function_name),
            "Program {program_id:?} does not contain function {function_name:?}, aborting execution"
        );

        // Create an ephemeral SnarkVM to store the programs
        // Initialize an RNG and query object for the transaction
        let rng = &mut rand::thread_rng();
        let query = Query::<N, BlockMemory<N>>::from(url);
        let vm = Self::initialize_vm(self.api_client()?, program, true)?;

        // Create an ephemeral private key for the sample execution
        let private_key = PrivateKey::<N>::new(rng)?;

        // Compute the authorization.
        let authorization = vm.authorize(&private_key, program_id, function_name, inputs, rng)?;

        let locator = Locator::new(*program_id, function_name);
        let (_, mut trace) = vm.process().write().execute::<A, _>(authorization, rng)?;
        trace.prepare(query)?;
        let execution =
            trace.prove_execution::<A, _>(&locator.to_string(), &mut rand::thread_rng())?;
        execution_cost(&vm.process().read(), &execution)
    }
}
