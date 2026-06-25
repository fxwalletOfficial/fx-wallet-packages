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

#[macro_export]
macro_rules! checksum {
    ($bytes: expr) => {{
        use sha2::Digest;
        hex::encode(&sha2::Sha256::digest($bytes))
    }};
}

#[macro_export]
macro_rules! checksum_error {
    ($expected: expr, $candidate: expr) => {
        Err($crate::errors::ParameterError::ChecksumMismatch($expected, $candidate))
    };
}

#[macro_export]
macro_rules! remove_file {
    ($filepath:expr) => {
        // Safely remove the corrupt file, if it exists.
        #[cfg(not(feature = "wasm"))]
        if std::path::PathBuf::from(&$filepath).exists() {
            match std::fs::remove_file(&$filepath) {
                Ok(()) => println!("Removed {:?}. Please retry the command.", $filepath),
                Err(err) => eprintln!("Failed to remove {:?}: {err}", $filepath),
            }
        }
    };
}

macro_rules! impl_store_and_remote_fetch {
    () => {
        // fx-wallet no-remote-fetch patch (workstream A, NOT upstream): the native
        // `store_bytes` + curl `remote_fetch` were removed so the build links no
        // curl/openssl-sys. The native load macro fails closed when a parameter is
        // absent (the Dart layer provisions it first). Only the wasm `remote_fetch`
        // remains (wasm is unused by this project but kept for crate coherence).
        #[cfg(feature = "wasm")]
        fn remote_fetch(url: &str) -> Result<Vec<u8>, $crate::errors::ParameterError> {
            // Use the browser's XmlHttpRequest object to download the parameter file synchronously.
            //
            // This method blocks the event loop while the parameters are downloaded, and should be
            // executed in a web worker to prevent the main browser window from freezing.
            let xhr = web_sys::XmlHttpRequest::new().map_err(|_| {
                $crate::errors::ParameterError::Wasm("Download failed - XMLHttpRequest object not found".to_string())
            })?;

            // XmlHttpRequest if specified as synchronous cannot use the responseType property. It
            // cannot thus download bytes directly and enforces a text encoding. To get back the
            // original binary, a charset that does not corrupt the original bytes must be used.
            xhr.override_mime_type("octet/binary; charset=ISO-8859-5").unwrap();

            // Initialize and send the request.
            xhr.open_with_async("GET", url, false).map_err(|_| {
                $crate::errors::ParameterError::Wasm(
                    "Download failed - This browser does not support synchronous requests".to_string(),
                )
            })?;
            xhr.send()
                .map_err(|_| $crate::errors::ParameterError::Wasm("Download failed - XMLHttpRequest failed".to_string()))?;

            // Wait for the response in a blocking fashion.
            if xhr.response().is_ok() && xhr.status().unwrap() == 200 {
                // Get the text from the response.
                let rust_text = xhr
                    .response_text()
                    .map_err(|_| $crate::errors::ParameterError::Wasm("XMLHttpRequest failed".to_string()))?
                    .ok_or($crate::errors::ParameterError::Wasm(
                        "The request was successful but no parameters were received".to_string(),
                    ))?;

                // Re-encode the text back into bytes using the chosen encoding.
                use encoding::Encoding;
                encoding::all::ISO_8859_5
                    .encode(&rust_text, encoding::EncoderTrap::Strict)
                    .map_err(|_| $crate::errors::ParameterError::Wasm("Parameter decoding failed".to_string()))
            } else {
                Err($crate::errors::ParameterError::Wasm("Download failed - XMLHttpRequest failed".to_string()))
            }
        }
    };
}

macro_rules! impl_load_bytes_logic_local {
    ($filepath: expr, $buffer: expr, $expected_size: expr, $expected_checksum: expr) => {
        // Ensure the size matches.
        if $expected_size != $buffer.len() {
            remove_file!($filepath);
            return Err($crate::errors::ParameterError::SizeMismatch($expected_size, $buffer.len()));
        }

        // Ensure the checksum matches.
        let candidate_checksum = checksum!($buffer);
        if $expected_checksum != candidate_checksum {
            return checksum_error!($expected_checksum, candidate_checksum);
        }

        return Ok($buffer.to_vec());
    };
}

macro_rules! impl_load_bytes_logic_remote {
    ($remote_urls: expr, $local_dir: expr, $filename: expr, $metadata: expr, $expected_checksum: expr, $expected_size: expr) => {
        cfg_if::cfg_if! {
            if #[cfg(all(feature = "filesystem", not(feature="wasm")))] {
                // fx-wallet param-dir patch (NOT upstream): atomically freeze the
                // parameter directory on first read and read it, from the
                // (overridable) effective dir instead of the hard-wired
                // `aleo_std::aleo_dir()`. One lock guards "freeze + read" and
                // `set_parameter_dir`, so they cannot interleave. Fail closed if the
                // default dir can't be created/canonicalized (no raw-path freeze).
                let mut file_path = $crate::parameter_dir_for_load()?;
                file_path.push($local_dir);
                file_path.push($filename);

                let buffer = if file_path.exists() {
                    // Attempts to load the parameter file locally with an absolute path.
                    std::fs::read(&file_path)?
                } else {
                    // fx-wallet no-remote-fetch patch (workstream A, NOT upstream):
                    // the in-Rust curl downloader is removed so the native build links
                    // no HTTP/TLS stack (curl + openssl-sys). Missing parameters are
                    // provisioned by the Dart layer into the (overridable) param dir
                    // BEFORE proving; a file that is still absent here fails closed.
                    // The size + checksum guards below remain the trust boundary for
                    // files that ARE present, so a Dart-provisioned param that is
                    // corrupt/wrong-size is still rejected by this crate.
                    return Err($crate::errors::ParameterError::RemoteFetchDisabled);
                };

                // Ensure the size matches.
                if $expected_size != buffer.len() {
                    remove_file!(file_path);
                    return Err($crate::errors::ParameterError::SizeMismatch($expected_size, buffer.len()));
                }

                // Ensure the checksum matches.
                let candidate_checksum = checksum!(buffer.as_slice());
                if $expected_checksum != candidate_checksum {
                    return checksum_error!($expected_checksum, candidate_checksum)
                }
                return Ok(buffer);
            } else {
                cfg_if::cfg_if! {
                    if #[cfg(feature = "wasm")] {
                        // Try each URL in order, falling back to the next if one fails.
                        let remote_urls: &[&str] = &$remote_urls;
                        let mut buffer = vec![];
                        let mut last_error: Option<$crate::errors::ParameterError> = None;

                        for base_url in remote_urls.iter() {
                            let url = format!("{}/{}", base_url, $filename);

                            match Self::remote_fetch(&url) {
                                Ok(fetched_buffer) => {
                                    // Ensure the checksum matches.
                                    let candidate_checksum = checksum!(&fetched_buffer);
                                    if $expected_checksum == candidate_checksum {
                                        buffer = fetched_buffer;
                                        last_error = None;
                                        break;
                                    } else {
                                        last_error = Some($crate::errors::ParameterError::ChecksumMismatch(
                                            $expected_checksum.to_string(),
                                            candidate_checksum,
                                        ));
                                    }
                                }
                                Err(e) => {
                                    last_error = Some(e);
                                }
                            }
                        }

                        // If all URLs failed, return the last error.
                        if let Some(e) = last_error {
                            return Err(e);
                        }

                        // Ensure the size matches.
                        if $expected_size != buffer.len() {
                            return Err($crate::errors::ParameterError::SizeMismatch($expected_size, buffer.len()));
                        }

                        return Ok(buffer)
                    } else {
                        return Err($crate::errors::ParameterError::FilesystemDisabled);
                    }
                }
            }
        }
    }
}

#[macro_export]
macro_rules! impl_local {
    ($name: ident, $local_dir: expr, $fname: tt, "usrs") => {
        #[derive(Clone, Debug, PartialEq, Eq)]
        pub struct $name;

        impl $name {
            pub const METADATA: &'static str = include_str!(concat!($local_dir, $fname, ".metadata"));

            pub fn load_bytes() -> Result<Vec<u8>, $crate::errors::ParameterError> {
                let metadata: serde_json::Value = serde_json::from_str(Self::METADATA).expect("Metadata was not well-formatted");
                let expected_checksum: String = metadata["checksum"].as_str().expect("Failed to parse checksum").to_string();
                let expected_size: usize = metadata["size"].to_string().parse().expect("Failed to retrieve the file size");

                let _filepath = concat!($local_dir, $fname, ".", "usrs");
                let buffer = include_bytes!(concat!($local_dir, $fname, ".", "usrs"));

                impl_load_bytes_logic_local!(_filepath, buffer, expected_size, expected_checksum);
            }
        }

        paste::item! {
            #[cfg(test)]
            #[test]
            fn [< test_ $fname _usrs >]() {
                // Print error messages if loading fails. This can be simplified once assert_matches! is stable.
                if let Err(err) = $name::load_bytes() {
                    panic!("Failed to load bytes: {err}");
                }
            }
        }
    };
    ($name: ident, $local_dir: expr, $fname: tt, $ftype: tt, $credits_version: tt) => {
        #[derive(Clone, Debug, PartialEq, Eq)]
        pub struct $name;

        impl $name {
            pub const METADATA: &'static str = include_str!(concat!($local_dir, $credits_version, "/", $fname, ".metadata"));

            pub fn load_bytes() -> Result<Vec<u8>, $crate::errors::ParameterError> {
                let metadata: serde_json::Value = serde_json::from_str(Self::METADATA).expect("Metadata was not well-formatted");
                let expected_checksum: String =
                    metadata[concat!($ftype, "_checksum")].as_str().expect("Failed to parse checksum").to_string();
                let expected_size: usize =
                    metadata[concat!($ftype, "_size")].to_string().parse().expect("Failed to retrieve the file size");

                let _filepath = concat!($local_dir, $credits_version, "/", $fname, ".", $ftype);
                let buffer = include_bytes!(concat!($local_dir, $credits_version, "/", $fname, ".", $ftype));

                impl_load_bytes_logic_local!(_filepath, buffer, expected_size, expected_checksum);
            }
        }

        paste::item! {
            #[cfg(test)]
            #[test]
            fn [< test_ $credits_version _ $fname _ $ftype >]() {
                if let Err(err) = $name::load_bytes() {
                    panic!("Failed to load bytes: {err}");
                }
            }
        }
    };
}

#[macro_export]
macro_rules! impl_remote {
    ($name: ident, $remote_url: expr, $local_dir: expr, $fname: tt, "usrs") => {
        pub struct $name;

        impl $name {
            pub const METADATA: &'static str = include_str!(concat!($local_dir, $fname, ".metadata"));

            impl_store_and_remote_fetch!();

            pub fn load_bytes() -> Result<Vec<u8>, $crate::errors::ParameterError> {
                let metadata: serde_json::Value = serde_json::from_str(Self::METADATA).expect("Metadata was not well-formatted");
                let expected_checksum: String = metadata["checksum"].as_str().expect("Failed to parse checksum").to_string();
                let expected_size: usize = metadata["size"].to_string().parse().expect("Failed to retrieve the file size");

                // Construct the versioned filename.
                let filename = match expected_checksum.get(0..7) {
                    Some(sum) => format!("{}.{}.{}", $fname, "usrs", sum),
                    _ => format!("{}.{}", $fname, "usrs"),
                };

                impl_load_bytes_logic_remote!($remote_url, $local_dir, &filename, metadata, expected_checksum, expected_size);
            }
        }
        paste::item! {
            #[cfg(test)]
            #[test]
            fn [< test_ $fname _usrs >]() {
                assert!($name::load_bytes().is_ok());
            }
        }
    };
    ($name: ident, $remote_url: expr, $local_dir: expr, $fname: tt, $ftype: tt, $credits_version: tt) => {
        pub struct $name;

        impl $name {
            pub const METADATA: &'static str = include_str!(concat!($local_dir, $credits_version, "/", $fname, ".metadata"));

            impl_store_and_remote_fetch!();

            pub fn load_bytes() -> Result<Vec<u8>, $crate::errors::ParameterError> {
                let metadata: serde_json::Value = serde_json::from_str(Self::METADATA).expect("Metadata was not well-formatted");
                let expected_checksum: String =
                    metadata[concat!($ftype, "_checksum")].as_str().expect("Failed to parse checksum").to_string();
                let expected_size: usize =
                    metadata[concat!($ftype, "_size")].to_string().parse().expect("Failed to retrieve the file size");

                // Construct the versioned filename.
                let filename = match expected_checksum.get(0..7) {
                    Some(sum) => format!("{}.{}.{}", $fname, $ftype, sum),
                    _ => format!("{}.{}", $fname, $ftype),
                };

                impl_load_bytes_logic_remote!($remote_url, $local_dir, &filename, metadata, expected_checksum, expected_size);
            }

            #[cfg(feature = "wasm")]
            /// Verify external bytes.
            pub fn verify_bytes(buffer: &[u8]) -> Result<(), $crate::errors::ParameterError> {
                let metadata: serde_json::Value = serde_json::from_str(Self::METADATA).expect("Metadata was not well-formatted");
                let expected_checksum: String =
                    metadata[concat!($ftype, "_checksum")].as_str().expect("Failed to parse checksum").to_string();
                let expected_size: usize =
                    metadata[concat!($ftype, "_size")].to_string().parse().expect("Failed to retrieve the file size");

                // Ensure the size matches.
                if buffer.len() != expected_size {
                    return Err($crate::errors::ParameterError::SizeMismatch(expected_size, buffer.len()));
                }

                // Ensure the checksum matches.
                let candidate_checksum = checksum!(buffer);
                if expected_checksum != candidate_checksum {
                    return checksum_error!(expected_checksum, candidate_checksum);
                }
                Ok(())
            }
        }

        paste::item! {
            #[cfg(test)]
            #[test]
            fn [< test_ $credits_version _ $fname _ $ftype >]() {
                if let Err(err) = $name::load_bytes() {
                    panic!("Failed to load bytes: {err}");
                }
            }
        }
    };
}
