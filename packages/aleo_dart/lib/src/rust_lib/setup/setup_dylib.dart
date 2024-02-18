// ignore_for_file: avoid_print

import 'dart:io';

import 'package:aleo_dart/src/rust_lib/setup/cpu_architecture.dart';
import 'package:aleo_dart/src/rust_lib/setup/library_locator.dart'
    show dynamicLibraryEnvVariable, getDesktopLibName, libBuildOutDir;

Future<void> setUpDynamicLibrary({String? dynamicLibraryPath}) async {
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
  const baseUrl = 'https://github.com/pzhun/aleo_dart/releases/download';
  const version = 'v0.0.1-dev.1';
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
