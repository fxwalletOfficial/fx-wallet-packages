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
// The "choose a directory" and "begin loading" transitions share ONE mutex, so
// they cannot interleave: a load that begins from the default directory and a
// concurrent `set_parameter_dir` are serialized, and whichever runs first wins —
// the loser is rejected. Without that, a setter could observe "load not started",
// a loader could then freeze + read the default directory, and the setter could
// still succeed, leaving later parameters loading from a different directory than
// the ones already cached.
//
// See `rust/vendor/README.md` and `rust/vendor/parameters-param-dir.patch`.

use std::path::{Path, PathBuf};
use std::sync::Mutex;

struct State {
    /// The chosen override directory, if any. `None` means no override has been
    /// set (the default `aleo_dir()` is used).
    dir: Option<PathBuf>,
    /// Set once the first parameter read has begun; the directory is then frozen
    /// (parameters are statically cached against the directory they first loaded
    /// from, so changing it mid-process would silently mismatch the cache).
    load_started: bool,
}

static STATE: Mutex<State> = Mutex::new(State { dir: None, load_started: false });

/// Error from [`set_parameter_dir`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ParamDirError {
    /// The path was empty, or could not be created / canonicalized.
    InvalidPath,
    /// A different directory is already in effect, or a parameter load has
    /// already begun from the default directory.
    Locked,
}

/// The default directory parameters load from when no override is set.
fn default_dir() -> PathBuf {
    #[cfg(feature = "filesystem")]
    {
        aleo_std::aleo_dir()
    }
    #[cfg(not(feature = "filesystem"))]
    {
        PathBuf::from(".aleo")
    }
}

/// Locks the shared state, recovering (rather than propagating) a poisoned lock —
/// the critical sections are trivial and cannot leave inconsistent state.
fn lock() -> std::sync::MutexGuard<'static, State> {
    STATE.lock().unwrap_or_else(|poisoned| poisoned.into_inner())
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
///
/// Holds the same lock as [`parameter_dir_for_load`], so a set and the start of a
/// load cannot interleave.
pub fn set_parameter_dir(path: &Path) -> Result<(), ParamDirError> {
    if path.as_os_str().is_empty() {
        return Err(ParamDirError::InvalidPath);
    }
    // Create then canonicalize: `canonicalize` requires the path to exist, but the
    // app-sandbox param dir may not have been created yet on a cold start. Do this
    // before taking the lock (filesystem I/O should not be held under the mutex).
    std::fs::create_dir_all(path).map_err(|_| ParamDirError::InvalidPath)?;
    let canon = path.canonicalize().map_err(|_| ParamDirError::InvalidPath)?;

    let mut state = lock();
    match &state.dir {
        Some(current) if *current == canon => Ok(()), // idempotent
        Some(_) => Err(ParamDirError::Locked),
        // A load already started from the default dir — too late to redirect.
        None if state.load_started => Err(ParamDirError::Locked),
        None => {
            state.dir = Some(canon);
            Ok(())
        }
    }
}

/// Freezes the parameter directory and returns it, atomically. Called by the load
/// macro immediately before the first parameter read, so a later
/// [`set_parameter_dir`] to a different path is rejected rather than silently
/// mismatching the static cache.
pub fn parameter_dir_for_load() -> PathBuf {
    let mut state = lock();
    state.load_started = true;
    state.dir.clone().unwrap_or_else(default_dir)
}

/// The directory parameters load from (the override if set, else the default
/// `~/.aleo`), for reporting. Unlike [`parameter_dir_for_load`] this does **not**
/// freeze the directory, so querying it (e.g. via `ffi_aleo_dir`) is side-effect
/// free.
pub fn effective_parameter_dir() -> PathBuf {
    let state = lock();
    state.dir.clone().unwrap_or_else(default_dir)
}
