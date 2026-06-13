// Copyright (c) 2026 fx wallet
// Licensed under the Apache License, Version 2.0.
//
// fx-wallet param-dir patch — NOT part of upstream snarkvm-parameters.
//
// Gives the FFI layer process-global control over WHERE proving parameters are
// read from / written to, so the Dart layer can point reads at the mobile app
// sandbox (snarkVM has no `ALEO_HOME`/env override; `aleo_std::aleo_dir()` is
// hard-wired to `~/.aleo`). The directory is owned HERE (not in `aleo_ffi`)
// because the actual reads happen inside this crate's load macro, so this is the
// only layer that can enforce the set-once / load-started rules.
//
// See `rust/vendor/README.md` and `rust/vendor/parameters-param-dir.patch`.

use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::OnceLock;

/// Process-global override for the parameter directory. Set at most once, and
/// only before any parameter is read; afterwards it is immutable (params are
/// statically cached against the directory they were first loaded from, so
/// changing it mid-process would silently mismatch the cache).
static PARAM_DIR: OnceLock<PathBuf> = OnceLock::new();

/// Set true the first time a parameter file is actually read (by the load macro,
/// via [`effective_parameter_dir`]). Once set, the directory is frozen.
static LOAD_STARTED: AtomicBool = AtomicBool::new(false);

/// Error from [`set_parameter_dir`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ParamDirError {
    /// The path was empty, or could not be created / canonicalized.
    InvalidPath,
    /// A different directory is already in effect, or a parameter load has
    /// already begun from the default directory.
    Locked,
}

/// Overrides the directory that proving parameters are read from / written to.
///
/// Set-once contract:
/// - an empty path → [`ParamDirError::InvalidPath`];
/// - the directory is created (so a cold app-sandbox dir works) and then
///   canonicalized — resolving symlinks — for the idempotent comparison;
/// - the first successful set wins; setting the **same** canonical path again is
///   a no-op `Ok`;
/// - a **different** path after the first set, or after any parameter load has
///   begun from the default directory, → [`ParamDirError::Locked`].
pub fn set_parameter_dir(path: &Path) -> Result<(), ParamDirError> {
    if path.as_os_str().is_empty() {
        return Err(ParamDirError::InvalidPath);
    }
    // Create then canonicalize: `canonicalize` requires the path to exist, but the
    // app-sandbox param dir may not have been created yet on a cold start.
    std::fs::create_dir_all(path).map_err(|_| ParamDirError::InvalidPath)?;
    let canon = path.canonicalize().map_err(|_| ParamDirError::InvalidPath)?;

    match PARAM_DIR.get() {
        Some(current) if *current == canon => Ok(()), // idempotent
        Some(_) => Err(ParamDirError::Locked),
        // A load already started from the default dir — too late to redirect.
        None if LOAD_STARTED.load(Ordering::Acquire) => Err(ParamDirError::Locked),
        None => match PARAM_DIR.set(canon.clone()) {
            Ok(()) => Ok(()),
            // Lost a race to a concurrent setter: succeed only if it set the same path.
            Err(_) => {
                if PARAM_DIR.get() == Some(&canon) {
                    Ok(())
                } else {
                    Err(ParamDirError::Locked)
                }
            }
        },
    }
}

/// The directory parameters are read from: the override if one was set, else the
/// upstream default `aleo_std::aleo_dir()` (`~/.aleo`).
pub fn effective_parameter_dir() -> PathBuf {
    if let Some(dir) = PARAM_DIR.get() {
        return dir.clone();
    }
    #[cfg(feature = "filesystem")]
    {
        aleo_std::aleo_dir()
    }
    #[cfg(not(feature = "filesystem"))]
    {
        PathBuf::from(".aleo")
    }
}

/// Freezes the parameter directory. Called by the load macro immediately before
/// the first parameter read, so a later [`set_parameter_dir`] to a different
/// path is rejected rather than silently mismatching the static cache.
pub fn mark_parameter_load_started() {
    LOAD_STARTED.store(true, Ordering::Release);
}
