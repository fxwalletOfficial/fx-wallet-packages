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

use crate::errors::ParameterError;
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

/// The default directory, **created and canonicalized** — matching the explicit
/// override path ([`set_parameter_dir`]) so the frozen directory is a stable
/// physical path. `aleo_std::aleo_dir()` is `$HOME/.aleo`, which may be a symlink;
/// resolving it once means a later re-point cannot move where parameters load
/// from.
///
/// **Fail closed:** if the directory cannot be created or canonicalized (e.g. a
/// dangling `~/.aleo` symlink that could later become loadable and then be
/// re-pointed between reads), this is a hard error — surfaced as a parameter-load
/// failure (→ `restart_required` at the FFI boundary) — rather than freezing an
/// uncanonicalized raw path.
fn resolve_default_dir() -> Result<PathBuf, ParameterError> {
    let dir = default_dir();
    std::fs::create_dir_all(&dir)
        .map_err(|e| ParameterError::Message(format!("failed to create parameter dir {dir:?}: {e}")))?;
    dir.canonicalize()
        .map_err(|e| ParameterError::Message(format!("failed to canonicalize parameter dir {dir:?}: {e}")))
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
///
/// On the first load with no override, the default is **resolved once and stored**
/// in `state.dir` — `aleo_std::aleo_dir()` re-reads `HOME` on every call, so
/// without persisting it a later environment change could move where subsequent
/// parameters load from, breaking the immutable-directory contract. Returns an
/// error (fail closed) if the default cannot be created/canonicalized.
pub fn parameter_dir_for_load() -> Result<PathBuf, ParameterError> {
    let mut state = lock();
    state.load_started = true;
    if state.dir.is_none() {
        state.dir = Some(resolve_default_dir()?);
    }
    Ok(state.dir.clone().expect("dir is Some after resolving the default above"))
}

/// The directory parameters load from (the override if set, else the default
/// `~/.aleo`), for reporting. Unlike [`parameter_dir_for_load`] this does **not**
/// freeze the directory, so querying it (e.g. via `ffi_aleo_dir`) is side-effect
/// free.
pub fn effective_parameter_dir() -> PathBuf {
    let state = lock();
    state.dir.clone().unwrap_or_else(default_dir)
}
