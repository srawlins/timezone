import 'dart:io';

import 'encode_dart.dart' as encodeDart;
import 'encode_tzf.dart' as encodeTzf;

const String _sourceUrl =
    "https://data.iana.org/time-zones/tzdata-latest.tar.gz";

Future<void> main() async {
  final tmpDir = await _makeTempDirectory();

  await _downloadAndExtractTarGz(Uri.parse(_sourceUrl), tmpDir);

  await runMake(tmpDir);
  await runZic(tmpDir);

  await Directory('lib/data').create(recursive: true);

  await runEncodeTzf('${tmpDir.path}/zoneinfo');
  await runEmbedScopes();
  await formatDartFiles();

  print('Cleaning up...');
  await tmpDir.delete(recursive: true);
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

Future<void> formatDartFiles() async {
  print('Formatting Dart files...');
  final result = await Process.run('dart', ['format', 'lib/data']);

  if (result.exitCode != 0) {
    print('Formatting failed:\n${result.stderr}');
    throw Exception('dart format failed');
  }

  print('Formatting complete');
}

Future<void> runEmbedScopes() async {
  const scopes = ['latest', 'latest_all', 'latest_10y'];

  for (final scope in scopes) {
    print('Creating embedding: $scope...');
    await encodeDart.encodeDart('lib/data/$scope.tzf', 'lib/data/$scope.dart');
    print('Created embedding: $scope');
  }
}

Future<void> runEncodeTzf(String zoneInfoPath) async {
  print('Running encode_tzf.dart...');
  await encodeTzf.encodeTzf(zoneInfoPath: zoneInfoPath);
  print('encode_tzf.dart completed');
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
