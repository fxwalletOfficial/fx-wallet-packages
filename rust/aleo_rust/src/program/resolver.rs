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
    /// Find a program by first looking on disk, and if not found, on the aleo network
    pub fn find_program(&self, program_id: &ProgramID<N>) -> Result<Program<N>> {
        self.find_program_on_disk(program_id).or_else(|_| self.find_program_on_chain(program_id))
    }

    /// Load a program from a local program directory
    pub fn find_program_on_disk(&self, program_id: &ProgramID<N>) -> Result<Program<N>> {
        let local_program_directory =
            self.local_program_directory.as_ref().ok_or_else(|| anyhow!("Local program directory not set"))?;
        let imports_directory = local_program_directory.join("imports");
        // Ensure the directory path exists.
        ensure!(local_program_directory.exists(), "The program directory does not exist");

        ensure!(!Program::is_reserved_keyword(program_id.name()), "Program name is invalid (reserved): {program_id}");

        ensure!(
            Manifest::<N>::exists_at(local_program_directory),
            "Please ensure that the manifest file exists in the Aleo program directory (missing '{}' at '{}')",
            Manifest::<N>::file_name(),
            local_program_directory.display()
        );

        // Open the manifest file.
        let manifest = Manifest::<N>::open(local_program_directory)?;

        // Ensure the program ID matches the manifest program ID, or that the program is a local import
        if manifest.program_id() == program_id {
            // Load the package.
            let package = Package::open(local_program_directory)?;
            // Load the main program.
            Ok(package.program().clone())
        } else {
            let import_file = imports_directory.join(program_id.to_string());
            ensure!(
                import_file.exists(),
                "No program named {program_id:?} found at {:?}",
                local_program_directory.display()
            );
            println!("Attempting to load program {program_id:?} at {:?}", import_file.display());
            let mut program_file = File::open(import_file)?;
            let mut program_string = String::new();
            program_file.read_to_string(&mut program_string).map_err(|err| anyhow::anyhow!(err.to_string()))?;
            let program = Program::from_str(&program_string)?;
            println!("Loaded program {program_id:?} successfully!");
            Ok(program)
        }
    }

    /// Load a program from the network
    pub fn find_program_on_chain(&self, program_id: &ProgramID<N>) -> Result<Program<N>> {
        self.api_client()?.get_program(program_id)
    }

    /// Find a program's imports by first searching on disk, and if not found, on the aleo network
    pub fn find_program_imports(&self, program: &Program<N>) -> Result<Vec<Program<N>>> {
        let mut imports = vec![];
        for program_id in program.imports().keys() {
            if let Ok(program) = self.find_program(program_id) {
                imports.push(program);
            } else {
                bail!("Could not find program import: {:?}", program_id);
            }
        }
        Ok(imports)
    }
}

