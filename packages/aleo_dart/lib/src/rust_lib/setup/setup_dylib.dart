// ignore_for_file: avoid_print

import 'dart:io';

import 'package:aleo_dart/src/rust_lib/setup/cpu_architecture.dart';
import 'package:aleo_dart/src/rust_lib/setup/library_locator.dart'
    show dynamicLibraryEnvVariable, getDesktopLibName, libBuildOutDir;

// DEPRECATED runtime-download source. This points at the pre-clean-room GPL-era
// `pzhun/aleo_dart` release (a stale, ABI-incompatible library) and is NOT used in
// v1: the native library is now obtained build-from-source on desktop/CI
// (`cargo build` in rust/aleo_ffi, see DyLib.getDyLibFromCargo) and build-time
// bundled on mobile (rust/build_android.sh, rust/build_ios.sh — see
// DyLib.getMobileDyLib). A runtime-download path with an in-package integrity
// anchor may return later; until then a downloaded library would be rejected by
// the ffi_abi_version load-time guard (AleoLib) anyway.
final BASE_URL = 'https://github.com/pzhun/aleo_dart/releases/download';
final VERSION = 'v0.0.1-dev.1';

@Deprecated('v1 does not download the native library at runtime; build from '
    'source (DyLib.getDyLibFromCargo) or bundle at build time '
    '(DyLib.getMobileDyLib). The pinned source is a stale GPL-era artifact.')
Future<void> setUpDynamicLibrary(
    {String? dynamicLibraryPath, String? userUrl, String? userVersion}) async {
  /// Get the CPU architecture.
  final cpuArchitecture = await CpuArchitecture.currentCpuArchitecture();
  final cpuArchitectureEnum = cpuArchitecture.value;
  if (cpuArchitectureEnum == CpuArchitectureEnum.i386) {
    throw Exception(
      'Unsupported CPU architecture: ${cpuArchitecture.rawValue}',
    );
  }

  /// Get the package root.
  final root = libBuildOutDir();

  Future<File> writeToFile(String filePath, Stream<List<int>> stream) async {
    final file = File(root.resolve(filePath).toFilePath());
    await file.create(recursive: true);
    final sink = file.openWrite(mode: FileMode.writeOnly);
    await sink.addStream(stream);
    await sink.flush();
    await sink.close();
    return file;
  }

// https://github.com/pzhun/aleo_dart/releases/download/v0.0.1-dev.1/libaleo_rust_so.zip
  final baseUrl = userUrl ?? BASE_URL;
  final version = userVersion ?? VERSION;
  String archiveName;
  if (Platform.isLinux) {
    archiveName = 'libaleo_rust_so.tar.gz';
  } else if (Platform.isMacOS) {
    archiveName = 'libaleo_rust_dyLib.tar.gz';
  } else if (Platform.isWindows) {
    archiveName = 'libaleo_rust_dll.tar.gz';
  } else {
    throw Exception('Could not support platform:$Platform');
  }

  final archiveUrl = '$baseUrl/$version/$archiveName';
  final libName = getDesktopLibName();

  /// Download archive.
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(archiveUrl));
  final response = await request.close();
  if (response.statusCode != 200) {
    throw Exception(
      'Could not download archive "$archiveUrl":'
      ' ${response.statusCode} ${response.reasonPhrase}',
    );
  }
  final archiveFile = await writeToFile('temp/$archiveName', response);
  print('Downloaded archive $archiveUrl to ${archiveFile.path}');

  final tempFilePath =
      root.resolve('temp').toFilePath(windows: Platform.isWindows);

  /// Extract archive.
  final info = await Process.run(
    'tar',
    ['xzf', archiveFile.path, '-C', tempFilePath],
  );
  if (info.exitCode != 0) {
    throw Exception(
      'Could not extract archive "${archiveFile.path}": ${info.stderr}',
    );
  }

  /// Copy library.
  final inputFilePath = 'temp/$libName';
  final inputFile = File(root.resolve(inputFilePath).toFilePath());
  if (!inputFile.existsSync()) {
    throw Exception(
      'Could not find library "${inputFile.path}"'
      ' in archive "${archiveFile.path}" from ($archiveUrl)',
    );
  }

  final outputPath = dynamicLibraryPath ??
      Platform.environment[dynamicLibraryEnvVariable] ??
      root.resolve(libName).toFilePath();
  final outputFile = await inputFile.rename(outputPath);
  print('Extracted library $inputFilePath to ${outputFile.path}');

  /// Delete temp.
  await Directory(root.resolve('temp').toFilePath()).delete(recursive: true);
}
