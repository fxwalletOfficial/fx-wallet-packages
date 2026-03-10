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
    /// 创建 Query 对象，使用 API 客户端的完整 base_url（保留版本路径如 /v2）
    ///
    /// 部分 API（如 api.explorer.provable.com）要求请求路径包含版本（如 /v2），
    /// 否则会返回非 JSON 导致解析失败。因此 Query 使用与 AleoAPIClient 一致的完整 URL。
    fn create_query(&self) -> Result<Query<N, BlockMemory<N>>> {
        let base_url = self
            .api_client
            .as_ref()
            .ok_or_else(|| anyhow!("API client not available"))?
            .base_url();

        // 保留完整 URL（含 /v2 等版本路径），确保 block/height/latest 等请求带版本
        let query_url = base_url.trim_end_matches('/');
        let uri = query_url
            .parse::<http::Uri>()
            .map_err(|e| anyhow!("Invalid URL format: {} (URL: {})", e, query_url))?;

        Ok(Query::<N, BlockMemory<N>>::from(uri))
    }
    /// Executes a transfer to the specified recipient_address with the specified amount and fee.
    /// Specify 0 for no fee.
    #[allow(clippy::too_many_arguments)]
    pub fn transfer(
        &self,
        amount: u64,
        fee: u64,
        recipient_address: Address<N>,
        transfer_type: TransferType,
        password: Option<&str>,
        amount_record: Option<Record<N, Plaintext<N>>>,
        fee_record: Option<Record<N, Plaintext<N>>>,
    ) -> Result<String> {
        // Ensure records provided have enough credits to cover the transfer amount and fee
        if let Some(amount_record) = amount_record.as_ref() {
            ensure!(
                amount_record.microcredits()? >= amount,
                "Credits in amount record must greater than transfer amount specified"
            );
        }
        if let Some(fee_record) = fee_record.as_ref() {
            ensure!(
                fee_record.microcredits()? >= fee,
                "Credits in fee record must greater than fee specified"
            );
        }

        // Specify the network state query
        // Query 使用完整 base_url（含版本路径），与 API 客户端一致
        let query = self.create_query()?;

        // Retrieve the private key.
        let private_key = self.get_private_key(password)?;

        // Generate the execution transaction
        let execution = {
            let rng = &mut rand::thread_rng();

            // Initialize a VM
            let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
            let vm = VM::from(store)?;

            // Prepare the inputs for a transfer.
            let (transfer_function, inputs) = match transfer_type {
                TransferType::Public => {
                    let inputs = vec![
                        Value::from_str(&recipient_address.to_string())?,
                        Value::from_str(&format!("{}u64", amount))?,
                    ];
                    ("transfer_public", inputs)
                }
                TransferType::Private => {
                    if amount_record.is_none() {
                        bail!("Amount record must be specified for private transfers");
                    } else {
                        let inputs = vec![
                            Value::Record(amount_record.unwrap()),
                            Value::from_str(&recipient_address.to_string())?,
                            Value::from_str(&format!("{}u64", amount))?,
                        ];
                        ("transfer_private", inputs)
                    }
                }
                TransferType::PublicToPrivate => {
                    let inputs = vec![
                        Value::from_str(&recipient_address.to_string())?,
                        Value::from_str(&format!("{}u64", amount))?,
                    ];
                    ("transfer_public_to_private", inputs)
                }
                TransferType::PrivateToPublic => {
                    if amount_record.is_none() {
                        bail!("Amount record must be specified for private transfers");
                    } else {
                        let inputs = vec![
                            Value::Record(amount_record.unwrap()),
                            Value::from_str(&recipient_address.to_string())?,
                            Value::from_str(&format!("{}u64", amount))?,
                        ];
                        ("transfer_private_to_public", inputs)
                    }
                }
            };

            // Create a new transaction.
            vm.execute(
                &private_key,
                ("credits.aleo", transfer_function),
                inputs.iter(),
                fee_record,
                fee,
                Some(&query),
                rng,
            )?
        };
        let result = execution.to_string();
        println!("{}", result);
        self.broadcast_transaction(execution)
    }

    #[allow(clippy::too_many_arguments)]
    pub fn build_transaction(
        &self,
        amount: u64,
        fee: u64,
        recipient_address: Address<N>,
        transfer_type: TransferType,
        password: Option<&str>,
        amount_record: Option<Record<N, Plaintext<N>>>,
        fee_record: Option<Record<N, Plaintext<N>>>,
    ) -> Result<String> {
        // Ensure records provided have enough credits to cover the transfer amount and fee
        if let Some(amount_record) = amount_record.as_ref() {
            ensure!(
                amount_record.microcredits()? >= amount,
                "Credits in amount record must greater than transfer amount specified"
            );
        }
        if let Some(fee_record) = fee_record.as_ref() {
            ensure!(
                fee_record.microcredits()? >= fee,
                "Credits in fee record must greater than fee specified"
            );
        }

        // Specify the network state query
        // Query 使用完整 base_url（含版本路径），与 API 客户端一致
        let query = self.create_query()?;

        // Retrieve the private key.
        let private_key = self.get_private_key(password)?;

        // Generate the execution transaction
        let execution = {
            let rng = &mut rand::thread_rng();

            // Initialize a VM
            let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
            let vm = VM::from(store)?;

            // Prepare the inputs for a transfer.
            let (transfer_function, inputs) = match transfer_type {
                TransferType::Public => {
                    let inputs = vec![
                        Value::from_str(&recipient_address.to_string())?,
                        Value::from_str(&format!("{}u64", amount))?,
                    ];
                    ("transfer_public", inputs)
                }
                TransferType::Private => {
                    if amount_record.is_none() {
                        bail!("Amount record must be specified for private transfers");
                    } else {
                        let inputs = vec![
                            Value::Record(amount_record.unwrap()),
                            Value::from_str(&recipient_address.to_string())?,
                            Value::from_str(&format!("{}u64", amount))?,
                        ];
                        ("transfer_private", inputs)
                    }
                }
                TransferType::PublicToPrivate => {
                    let inputs = vec![
                        Value::from_str(&recipient_address.to_string())?,
                        Value::from_str(&format!("{}u64", amount))?,
                    ];
                    ("transfer_public_to_private", inputs)
                }
                TransferType::PrivateToPublic => {
                    if amount_record.is_none() {
                        bail!("Amount record must be specified for private transfers");
                    } else {
                        let inputs = vec![
                            Value::Record(amount_record.unwrap()),
                            Value::from_str(&recipient_address.to_string())?,
                            Value::from_str(&format!("{}u64", amount))?,
                        ];
                        ("transfer_private_to_public", inputs)
                    }
                }
            };

            // Create a new transaction.
            vm.execute(
                &private_key,
                ("credits.aleo", transfer_function),
                inputs.iter(),
                fee_record,
                fee,
                Some(&query),
                rng,
            )?
        };
        // Return the execute transaction.
        Ok(execution.to_string())
    }

    pub fn broadcast(
        execution_raw: String,
        url: String,
        transaction_type: String,
        network: String,
    ) -> Result<String> {
        let execution = Transaction::<CurrentNetwork>::from_str(&execution_raw).unwrap();
        let api_client = AleoAPIClient::<CurrentNetwork>::aleo_net(&url, &network);
        let result = api_client.transaction_broadcast(execution);
        if result.is_ok() {
            println!(
                "✅ {} Transaction successfully posted to {}",
                transaction_type,
                api_client.base_url()
            );
        } else {
            println!(
                "❌ {} Transaction failed to post to {}",
                transaction_type,
                api_client.base_url()
            );
        }
        result
    }

    #[allow(clippy::too_many_arguments)]
    pub fn execution_authorization(
        &self,
        amount: u64,
        recipient_address: Address<N>,
        transfer_type: TransferType,
        password: Option<&str>,
        amount_record: Option<Record<N, Plaintext<N>>>,
    ) -> Result<String> {
        // Ensure records provided have enough credits to cover the transfer amount and fee
        if let Some(amount_record) = amount_record.as_ref() {
            ensure!(
                amount_record.microcredits()? >= amount,
                "Credits in amount record must greater than transfer amount specified"
            );
        }
        // Retrieve the private key.
        let private_key = self.get_private_key(password)?;

        // Generate the execution transaction
        let authorization = {
            let rng = &mut rand::thread_rng();

            // Initialize a VM
            let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
            let vm = VM::from(store)?;

            // Prepare the inputs for a transfer.
            let (transfer_function, inputs) = match transfer_type {
                TransferType::Public => {
                    let inputs = vec![
                        Value::from_str(&recipient_address.to_string())?,
                        Value::from_str(&format!("{}u64", amount))?,
                    ];
                    ("transfer_public", inputs)
                }
                TransferType::Private => {
                    if amount_record.is_none() {
                        bail!("Amount record must be specified for private transfers");
                    } else {
                        let inputs = vec![
                            Value::Record(amount_record.unwrap()),
                            Value::from_str(&recipient_address.to_string())?,
                            Value::from_str(&format!("{}u64", amount))?,
                        ];
                        ("transfer_private", inputs)
                    }
                }
                TransferType::PublicToPrivate => {
                    let inputs = vec![
                        Value::from_str(&recipient_address.to_string())?,
                        Value::from_str(&format!("{}u64", amount))?,
                    ];
                    ("transfer_public_to_private", inputs)
                }
                TransferType::PrivateToPublic => {
                    if amount_record.is_none() {
                        bail!("Amount record must be specified for private transfers");
                    } else {
                        let inputs = vec![
                            Value::Record(amount_record.unwrap()),
                            Value::from_str(&recipient_address.to_string())?,
                            Value::from_str(&format!("{}u64", amount))?,
                        ];
                        ("transfer_private_to_public", inputs)
                    }
                }
            };
            // Compute the authorization.
            vm.authorize(&private_key, "credits.aleo", transfer_function, inputs, rng)?
        };
        Ok(authorization.to_string())
    }

    #[allow(clippy::too_many_arguments)]
    pub fn get_base_fee(&self, execution: Execution<N>) -> Result<u64> {
        // Initialize a VM
        let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
        let vm = VM::from(store)?;
        // Compute the fee.

        // Compute the minimum execution cost.
        let (minimum_execution_cost, (_, _)) = execution_cost(&vm.process().read(), &execution, ConsensusVersion::V10)?;
        // Compute the execution ID.
        Ok(minimum_execution_cost)
    }

    #[allow(clippy::too_many_arguments)]
    pub fn execution_fee_authorization(
        &self,
        fee: u64,
        password: Option<&str>,
        fee_record: Option<Record<N, Plaintext<N>>>,
        execution: Execution<N>,
    ) -> Result<String> {
        // Ensure records provided have enough credits to cover the transfer amount and fee
        if let Some(fee_record) = fee_record.as_ref() {
            ensure!(
                fee_record.microcredits()? >= fee,
                "Credits in fee record must greater than fee specified"
            );
        }
        // Retrieve the private key.
        let private_key = self.get_private_key(password)?;

        // Generate the execution transaction
        let rng = &mut rand::thread_rng();

        // Initialize a VM
        let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
        let vm = VM::from(store)?;
        // Compute the fee.

        // Compute the minimum execution cost.
        let (minimum_execution_cost, (_, _)) = execution_cost(&vm.process().read(), &execution, ConsensusVersion::V10)?;
        // Compute the execution ID.
        let execution_id = execution.to_execution_id()?;
        // Authorize the fee.
        let fee_authorization = match fee_record {
            Some(record) => vm.authorize_fee_private(
                &private_key,
                record,
                minimum_execution_cost,
                fee,
                execution_id,
                rng,
            )?,
            None => vm.authorize_fee_public(
                &private_key,
                minimum_execution_cost,
                fee,
                execution_id,
                rng,
            )?,
        };
        Ok(fee_authorization.to_string())
    }

    pub fn execute_proof(&self, authorization: Authorization<N>) -> Result<String> {
        // Query 使用完整 base_url（含版本路径），与 API 客户端一致
        let query = self.create_query()?;

        // Initialize a VM
        let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
        let vm = VM::from(store)?;
        let rng = &mut rand::thread_rng();

        // Compute the execution.
        let (execution, _response) = vm.execute_authorization_raw(authorization, &query, rng)?;
        Ok(format!("{:?}", execution))
    }

    pub fn execute_program_proof(
        &self,
        authorization: Authorization<N>,
        program_id: String,
        api_client: &AleoAPIClient<N>,
    ) -> Result<String> {
        let program_id = ProgramID::<N>::from_str(&program_id)?;

        // AleoAPIClient 可以处理带版本路径的 URL（如 /v2），用于获取程序数据
        let program = self
            .get_program(program_id)
            .or_else(|_| api_client.get_program(program_id))?;

        // Query 使用完整 base_url（含版本路径），与 API 客户端一致
        let query = self.create_query()?;

        // Initialize a VM
        let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
        let vm = VM::from(store)?;

        let credits_id = ProgramID::<N>::from_str("credits.aleo")?;
        api_client
            .get_program_imports_from_source(&program)?
            .iter()
            .try_for_each(|(_, import)| {
                if import.id() != &credits_id && !vm.process().read().contains_program(import.id())
                {
                    vm.process().write().add_program(import)?;
                }
                Ok::<_, Error>(())
            })?;

        // If the initialization is for an execution, add the program. Otherwise, don't add it as
        // it will be added during the deployment process
        if !vm.process().read().contains_program(program.id()) {
            // If the program doesn't have a constructor, use edition 1 to avoid edition 0 execution errors
            // in ConsensusVersion::V8 or higher
            if program.contains_constructor() {
                vm.process().write().add_program(&program)?;
            } else {
                vm.process().write().add_program_with_edition(&program, 1)?;
            }
        }
        let rng = &mut rand::thread_rng();

        // Compute the execution.
        let (execution, _response) = vm.execute_authorization_raw(authorization, &query, rng)?;
        Ok(format!("{:?}", execution))
    }

    pub fn execute_fee_proof(&self, authorization: Authorization<N>) -> Result<String> {
        // Query 使用完整 base_url（含版本路径），与 API 客户端一致
        let query = self.create_query()?;

        // Initialize a VM
        let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
        let vm = VM::from(store)?;
        let rng = &mut rand::thread_rng();

        // Compute the execution.
        let execution = vm.execute_fee_authorization_raw(authorization, &query, rng)?;
        Ok(execution.to_string())
    }

    #[allow(clippy::too_many_arguments)]
    pub fn join_authorization(
        &self,
        record_1: Record<N, Plaintext<N>>,
        record_2: Record<N, Plaintext<N>>,
        password: Option<&str>,
    ) -> Result<String> {
        // Retrieve the private key.
        let private_key = self.get_private_key(password)?;

        // Generate the execution transaction
        let authorization = {
            let rng = &mut rand::thread_rng();

            // Initialize a VM
            let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
            let vm = VM::from(store)?;
            let inputs = vec![Value::Record(record_1), Value::Record(record_2)];

            // Compute the authorization.
            vm.authorize(&private_key, "credits.aleo", "join", inputs, rng)?
        };
        Ok(authorization.to_string())
    }

    #[allow(clippy::too_many_arguments)]
    pub fn upgrade_authorization(
        &self,
        record: Record<N, Plaintext<N>>,
        password: Option<&str>,
    ) -> Result<String> {
        // Retrieve the private key.
        let private_key = self.get_private_key(password)?;

        // Generate the execution transaction
        let authorization = {
            let rng = &mut rand::thread_rng();

            // Initialize a VM
            let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
            let vm = VM::from(store)?;
            let inputs = vec![Value::Record(record)];

            // Compute the authorization.
            vm.authorize(&private_key, "credits.aleo", "upgrade", inputs, rng)?
        };
        Ok(authorization.to_string())
    }

    #[allow(clippy::too_many_arguments)]
    pub fn contract_execution(
        &self,
        program_id: String,
        function_name: String,
        arguments: Vec<&str>,
        password: Option<&str>,
        api_client: &AleoAPIClient<N>,
    ) -> Result<String> {
        let private_key = self.get_private_key(password)?;
        let program_id = ProgramID::<N>::from_str(&program_id)?;
        // Generate the execution transaction
        let authorization = {
            let rng = &mut rand::thread_rng();

            // Initialize a VM
            let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
            let vm = VM::from(store)?;
            let inputs = arguments;

            // Add the program to the VM
            let program = self
                .get_program(program_id)
                .or_else(|_| api_client.get_program(program_id))?;

            let credits_id = ProgramID::<N>::from_str("credits.aleo")?;
            api_client
                .get_program_imports_from_source(&program)?
                .iter()
                .try_for_each(|(_, import)| {
                    if import.id() != &credits_id
                        && !vm.process().read().contains_program(import.id())
                    {
                        vm.process().write().add_program(import)?;
                    }
                    Ok::<_, Error>(())
                })?;

            // If the initialization is for an execution, add the program. Otherwise, don't add it as
            // it will be added during the deployment process
            if !vm.process().read().contains_program(program.id()) {
                // If the program doesn't have a constructor, use edition 1 to avoid edition 0 execution errors
                // in ConsensusVersion::V8 or higher
                if program.contains_constructor() {
                    vm.process().write().add_program(&program)?;
                } else {
                    vm.process().write().add_program_with_edition(&program, 1)?;
                }
            }
            // Compute the authorization.
            vm.authorize(&private_key, program_id, function_name, inputs, rng)?
        };
        Ok(authorization.to_string())
    }

    #[allow(clippy::too_many_arguments)]
    pub fn contract_fee_execution(
        &self,
        fee: u64,
        password: Option<&str>,
        execution: Execution<N>,
        program_id: String,
        api_client: &AleoAPIClient<N>,
    ) -> Result<String> {
        // Retrieve the private key.
        let private_key = self.get_private_key(password)?;
        let program_id = ProgramID::<N>::from_str(&program_id)?;
        // Generate the execution transaction
        let rng = &mut rand::thread_rng();

        // Initialize a VM
        let store = ConsensusStore::<N, ConsensusMemory<N>>::open(StorageMode::Production)?;
        let vm = VM::from(store)?;
        // Compute the fee.

        // Add the program to the VM
        let program = self
            .get_program(program_id)
            .or_else(|_| api_client.get_program(program_id))?;

        let credits_id = ProgramID::<N>::from_str("credits.aleo")?;
        api_client
            .get_program_imports_from_source(&program)?
            .iter()
            .try_for_each(|(_, import)| {
                if import.id() != &credits_id && !vm.process().read().contains_program(import.id())
                {
                    vm.process().write().add_program(import)?;
                }
                Ok::<_, Error>(())
            })?;

        // If the initialization is for an execution, add the program. Otherwise, don't add it as
        // it will be added during the deployment process
        if !vm.process().read().contains_program(program.id()) {
            // If the program doesn't have a constructor, use edition 1 to avoid edition 0 execution errors
            // in ConsensusVersion::V8 or higher
            if program.contains_constructor() {
                vm.process().write().add_program(&program)?;
            } else {
                vm.process().write().add_program_with_edition(&program, 1)?;
            }
        }
        // Compute the minimum execution cost.
        let (minimum_execution_cost, (_, _)) = execution_cost(&vm.process().read(), &execution, ConsensusVersion::V10)?;
        // Compute the execution ID.
        let execution_id = execution.to_execution_id()?;
        // Authorize the fee.
        let fee_authorization =
            vm.authorize_fee_public(&private_key, minimum_execution_cost, fee, execution_id, rng)?;
        Ok(fee_authorization.to_string())
    }
}

#[cfg(test)]
mod tests {}
