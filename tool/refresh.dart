import 'dart:io';
import 'package:args/args.dart';

import 'encode_dart.dart' as encode_dart;
import 'encode_tzf.dart' as encode_tzf;

const String _sourceUrl =
    "https://data.iana.org/time-zones/tzdata-latest.tar.gz";

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('output',
        abbr: 'o',
        help: 'Output directory (default: lib/data)',
        defaultsTo: 'lib/data');

  final argResults = parser.parse(args);
  final outputPath = argResults['output'] as String;
  final outputDir = Directory(outputPath);

  await outputDir.create(recursive: true);
  print('Writing output to: ${outputDir.absolute.path}');

  final tmpDir = await _makeTempDirectory();

  try {
    await _downloadAndExtractTarGz(Uri.parse(_sourceUrl), tmpDir);
    await runMake(tmpDir);
    await runZic(tmpDir);

    await runEncodeTzf('${tmpDir.path}/zoneinfo', outputDir.path);
    await runEmbedScopes(outputDir.path);
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

Future<void> runEmbedScopes(String outputPath) async {
  const scopes = ['latest', 'latest_all', 'latest_10y'];

  for (final scope in scopes) {
    final tzfPath = '$outputPath/$scope.tzf';
    final dartPath = '$outputPath/$scope.dart';

    print('Creating embedding: $scope...');
    await encode_dart.encodeDart(tzfPath, dartPath);
    print('Created: $dartPath');
  }
}

Future<void> runEncodeTzf(String zoneInfoPath, String outputPath) async {
  print('Running encode_tzf.dart...');
  await encode_tzf.encodeTzf(
    zoneInfoPath: zoneInfoPath,
    outputCommon: '$outputPath/latest.tzf',
    outputAll: '$outputPath/latest_all.tzf',
    output10y: '$outputPath/latest_10y.tzf',
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
