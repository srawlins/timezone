/// A tool to download and compile TimeZone database
///
/// Usage example:
///
/// ```sh
/// $ pub run tool/get -s 2014h
/// ```

import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';

import 'package:timezone/tzdata.dart' as tzfile;
import 'package:timezone/timezone.dart';
import 'package:timezone/src/tools.dart';
import 'package:timezone/src/tzdb.dart';

final outPath = p.join('lib', 'data');

const _zicDataFiles = [
  'africa',
  'antarctica',
  'asia',
  'australasia',
  'etcetera',
  'europe',
  'northamerica',
  'southamerica',
  'pacificnew',
  'backward'
];

const _repositoryUri = 'https://data.iana.org/time-zones';

/// Load [tzfile.Location] from tzfile.
Future<tzfile.Location> loadTzfileLocation(String name, String path) async {
  final rawData = await File(path).readAsBytes();
  return tzfile.Location.fromBytes(name, rawData);
}

/// Download IANA Time Zone database to [dest] directory.
Future<String> downloadTzData(String version, String dest) async {
  final outPath = p.join(dest, 'tzdata$version.tar.gz');
  final client = HttpClient();
  try {
    var uri = version == 'latest'
        ? Uri.parse('$_repositoryUri/tzdata-$version.tar.gz')
        : Uri.parse('$_repositoryUri/releases/tzdata$version.tar.gz');

    final req = await client.getUrl(uri);
    final resp = await req.close();
    final out = File(outPath);
    final sink = out.openWrite();
    try {
      await sink.addStream(resp);
    } finally {
      await sink.close();
    }
  } finally {
    await client.close();
  }
  return outPath;
}

/// Unpack IANA Time Zone database to [dest] directory.
Future unpackTzData(String archivePath, String dest) async {
  final result =
      await Process.run('tar', ['--directory=$dest', '-zxf', archivePath]);
  if (result.exitCode == 0) {
    return true;
  }
  throw Exception(result.stderr);
}

/// Compile IANA Time Zone file with zic compiler.
Future zic(String src, String dest) async {
  final result = await Process.run('zic', ['-d', dest, src]);
  if (result.exitCode == 0) {
    return true;
  }
  throw Exception(result.stderr);
}

Future main(List<String> arguments) async {
  // Initialize logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  final Logger log = Logger('main');

  // Parse CLI arguments
  final parser = ArgParser()
    ..addOption('source', abbr: 's', defaultsTo: 'latest');
  final argResults = parser.parse(arguments);

  final source = argResults['source'];

  final tzfileLocations = [];

  log.info('Creating temp directory');

  final tmpDir = await Directory.systemTemp.createTemp('tzdata-');
  log.info('Temp directory created: ${tmpDir.path}');
  try {
    log.info('Downloading timezone data');
    final archivePath = await downloadTzData(source, tmpDir.path);

    log.info('Unpacking timezone data: $archivePath');
    await unpackTzData(archivePath, tmpDir.path);

    log.info('Creating zic directory');
    final zicDirPath = p.join(tmpDir.path, 'zic');
    await Directory(zicDirPath).create();

    log.info('Compiling timezone data with zic compiler');
    for (final i in _zicDataFiles) {
      log.info('- $i');
      await zic(p.join(tmpDir.path, i), zicDirPath);
    }

    log.info('Importing tzfile Locations');
    final files = await Glob('**/*').list(root: zicDirPath).toList();
    for (final f in files) {
      if (f is File) {
        final name = p.relative(f.path, from: zicDirPath);
        log.info('- $name');
        final loc = await loadTzfileLocation(name, f.path);
        tzfileLocations.add(loc);
      }
    }
  } finally {
    log.info('Cleaning up temporary directories');
    await tmpDir.delete(recursive: true);
  }

  log.info('Converting tzfile Locations to native Locations');
  final db = LocationDatabase();
  for (final loc in tzfileLocations) {
    db.add(tzfileLocationToNativeLocation(loc));
  }
  logReport(r) {
    log.info('  + locations: ${r.originalLocationsCount} => '
        '${r.newLocationsCount}');
    log.info('  + transitions: ${r.originalTransitionsCount} => '
        '${r.newTransitionsCount}');
  }

  log.info('Building location databases:');

  log.info('- all locations');
  final allDb = filterTimeZoneData(db, locations: allLocations);
  logReport(allDb.report);

  log.info('- common locations from all locations');
  final commonDb = filterTimeZoneData(allDb.db, locations: commonLocations);
  logReport(commonDb.report);

  log.info('- [2015 - 2025 years] from common locations');
  final common_2015_2025_Db = filterTimeZoneData(commonDb.db,
      dateFrom: DateTime.utc(2015, 1, 1).millisecondsSinceEpoch,
      dateTo: DateTime.utc(2025, 1, 1).millisecondsSinceEpoch,
      locations: commonLocations);
  logReport(common_2015_2025_Db.report);

  log.info('Serializing location databases');
  final allOut = File(p.join(outPath, '${source}_all.$tzDataExtension'));
  final commonOut = File(p.join(outPath, '${source}.$tzDataExtension'));
  final common_2015_2025_Out =
      File(p.join(outPath, '${source}_2015-2025.$tzDataExtension'));
  await allOut.writeAsBytes(tzdbSerialize(allDb.db), flush: true);
  await commonOut.writeAsBytes(tzdbSerialize(commonDb.db), flush: true);
  await common_2015_2025_Out.writeAsBytes(tzdbSerialize(common_2015_2025_Db.db),
      flush: true);

  exit(0);
}
