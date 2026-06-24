// The v1 runtime-download path is removed. Its only pinned source was the
// pre-clean-room GPL-era `pzhun/aleo_dart` release (a stale, ABI-incompatible
// library). The native library is now built from source on desktop/CI
// (`cargo build` in rust/aleo_ffi -> DyLib.getDyLibFromCargo) or bundled at build
// time on mobile by the aleo_flutter plugin (DyLib.getMobileDyLib). A downloaded
// library would also be rejected by the ffi_abi_version load guard (AleoLib).

@Deprecated('v1 does not download the native library at runtime; build from '
    'source (DyLib.getDyLibFromCargo) or use the aleo_flutter plugin.')
Future<void> setUpDynamicLibrary({
  String? dynamicLibraryPath,
  String? userUrl,
  String? userVersion,
}) async {
  throw UnsupportedError(
    'aleo_dart runtime native-library download is removed in v1 (it targeted a '
    'stale, GPL-era, ABI-incompatible artifact). Build from source via '
    'DyLib.getDyLibFromCargo(), or use the aleo_flutter plugin which bundles the '
    'library at build time.',
  );
}
