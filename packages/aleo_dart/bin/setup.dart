import 'package:aleo_dart/src/rust_lib/setup/setup_dylib.dart';

/// DEPRECATED in v1: the native library is built from source (desktop/CI) or
/// bundled at build time (mobile), not downloaded. Kept so the
/// `dart run aleo_dart:setup` entry point still resolves; it delegates to the
/// deprecated downloader (which targets a stale GPL-era artifact).
void main() async {
  // ignore: deprecated_member_use_from_same_package
  await setUpDynamicLibrary();
}
