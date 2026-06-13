// Copyright (c) 2019-2025 Provable Inc.
// This file is part of the snarkVM library.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#![allow(clippy::module_inception)]
#![forbid(unsafe_code)]

#[cfg(feature = "wasm")]
#[macro_use]
extern crate alloc;

#[macro_use]
extern crate lazy_static;
#[macro_use]
extern crate thiserror;

#[macro_use]
pub mod macros;

pub mod errors;
pub use errors::*;

// fx-wallet param-dir patch (NOT upstream): process-global override of the
// directory parameters load from, used by the load macro below. See
// `rust/vendor/parameters-param-dir.patch`.
mod parameter_dir;
pub use parameter_dir::{
    effective_parameter_dir, mark_parameter_load_started, set_parameter_dir, ParamDirError,
};

pub mod canary;

pub mod mainnet;

pub mod testnet;

pub mod prelude {
    pub use crate::errors::*;
}
