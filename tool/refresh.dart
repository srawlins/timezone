import 'dart:io';
import 'package:args/args.dart';

import 'encode_dart.dart' as encode_dart;
import 'encode_tzf.dart' as encode_tzf;

const String _defaultSourceUrl =
    "https://data.iana.org/time-zones/tzdata-latest.tar.gz";

const String _defaultFilePrefix = "latest";

Future<void> main(List<String> args) async {
  try {
    await _checkCommand('curl');
    await _checkCommand('tar');
    await _checkCommand('make');
    await _checkCommand('zic');
  } on Exception catch (e) {
    print(e);
    return;
  }

  final parser = ArgParser()
    ..addOption('output',
        abbr: 'o', help: 'Output directory)', defaultsTo: 'lib/data')
    ..addOption('source',
        abbr: 's',
        help: 'Source URL for timezone data',
        defaultsTo: _defaultSourceUrl)
    ..addOption('file-prefix',
        abbr: 'p',
        help:
            // ignore: lines_longer_than_80_chars
            'Prefix for the generated files. E.g.: "latest", "2025", etc.\nRequired when passing a custom source',
        defaultsTo: _defaultFilePrefix)
    ..addFlag('help', abbr: 'h', help: 'Show help information');

  final argResults = parser.parse(args);

  if (argResults['help'] == true) {
    print(
        "\nWELCOME TO TIMEZONE DATA GENERATOR\n\nThis utility is used to generate/regenerate timezone files (*.tzf/*.dart) from IANA timezone data archives. See https://data.iana.org/time-zones.\n\nIMPORTANT NOTE: This utility only works on Linux and Unix-like systems due its dependence on ZIC utility. So If you are using Windows, please run this in a WSL environment.\n\nOptions:\n");
    print('Timezone Data Generator Tool');
    print(parser.usage);
    return;
  }

  final sourceURL = argResults['source'] as String;
  final filePrefix = argResults['file-prefix'] as String;

  if (sourceURL != _defaultSourceUrl && filePrefix == _defaultFilePrefix) {
    print(
        // ignore: lines_longer_than_80_chars
        "Error: When using a custom source URL, you must also provide a custom --file-prefix to avoid overwriting default files.");
    return;
  }

  final outputPath = argResults['output'] as String;
  final outputDir = Directory(outputPath);

  await outputDir.create(recursive: true);
  print('Writing output to: ${outputDir.absolute.path}');

  final tmpDir = await _makeTempDirectory();

  try {
    await _downloadAndExtractTarGz(Uri.parse(sourceURL), tmpDir);
    await runMake(tmpDir);
    await runZic(tmpDir);

    await runEncodeTzf(filePrefix, '${tmpDir.path}/zoneinfo', outputDir.path);
    await runEmbedScopes(filePrefix, outputDir.path);
    await formatDartFiles(outputDir.path);
  } finally {
    print('Cleaning up temp files...');
    await tmpDir.delete(recursive: true);
  }

  print('Done!');
}

Future<Directory> _makeTempDirectory() async {
  final tempDir =
      Directory('__tmp__${DateTime.now().microsecondsSinceEpoch}__tz__');
  var exists = await tempDir.exists();
  if (exists) {
    return _makeTempDirectory();
  }
  return tempDir;
}

Future<void> _downloadAndExtractTarGz(Uri url, Directory outputDir) async {
  await outputDir.create(recursive: true);

  final curl = await Process.start('curl', ['-sL', url.toString()]);
  final tar = await Process.start('tar', ['-zx', '-C', outputDir.path]);

  // Pipe curl stdout to tar stdin
  await curl.stdout.pipe(tar.stdin);

  curl.stderr.transform(SystemEncoding().decoder).listen(stderr.write);
  tar.stderr.transform(SystemEncoding().decoder).listen(stderr.write);

  final curlExit = await curl.exitCode;
  final tarExit = await tar.exitCode;

  if (curlExit != 0 || tarExit != 0) {
    throw Exception(
        'Failed to download and extract. Exit codes: curl=$curlExit, tar=$tarExit');
  }

  print('Extracted tzdata to ${outputDir.path}');
}

Future<void> formatDartFiles(String outputPath) async {
  print('Formatting Dart files in $outputPath...');
  final result = await Process.run('dart', ['format', outputPath]);

  if (result.exitCode != 0) {
    print('Formatting failed:\n${result.stderr}');
    throw Exception('dart format failed');
  }

  print('Formatting complete');
}

Future<void> runEmbedScopes(String filePrefix, String outputPath) async {
  final scopes = [filePrefix, '${filePrefix}_all', '${filePrefix}_10y'];

  for (final scope in scopes) {
    final tzfPath = '$outputPath/$scope.tzf';
    final dartPath = '$outputPath/$scope.dart';

    print('Creating embedding: $scope...');
    await encode_dart.encodeDart(tzfPath, dartPath);
    print('Created: $dartPath');
  }
}

Future<void> runEncodeTzf(
    String filePrefix, String zoneInfoPath, String outputPath) async {
  print('Running encode_tzf.dart...');
  await encode_tzf.encodeTzf(
    zoneInfoPath: zoneInfoPath,
    outputCommon: '$outputPath/$filePrefix.tzf',
    outputAll: '$outputPath/${filePrefix}_all.tzf',
    output10y: '$outputPath/${filePrefix}_10y.tzf',
  );
}

Future<void> runZic(Directory dir) async {
  print('Running zic...');
  final zoneInfoDir = Directory('${dir.path}/zoneinfo');
  await zoneInfoDir.create();

  final result = await Process.run(
    'zic',
    ['-d', zoneInfoDir.absolute.path, '-b', 'fat', 'rearguard.zi'],
    workingDirectory: dir.path,
  );

  if (result.exitCode != 0) {
    print('zic failed:\n${result.stderr}');
    throw Exception('zic failed');
  }

  print('zic compilation complete');
}

Future<void> runMake(Directory dir) async {
  print('Running make rearguard.zi...');
  final result = await Process.run(
    'make',
    ['rearguard.zi'],
    workingDirectory: dir.path,
  );

  if (result.exitCode != 0) {
    print('make failed:\n${result.stderr}');
    throw Exception('make failed');
  }

  print('make rearguard.zi succeeded');
}

Future<void> _checkCommand(String cmd) async {
  final result = await Process.run('which', [cmd]);
  if (result.exitCode != 0) {
    throw Exception('Required command `$cmd` not found. Please install it.');
  }
}
