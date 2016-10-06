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
import 'package:path/path.dart' as path;
import 'package:glob/glob.dart';

import 'package:timezone/tzdata.dart' as tzfile;
import 'package:timezone/timezone.dart';
import 'package:timezone/src/tools.dart';
import 'package:timezone/src/tzdb.dart';

final outPath = path.join('lib', 'data');

const _zicDataFiles = const [
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

/// Load [tzfile.Location] from tzfile.
Future<tzfile.Location> loadTzfileLocation(String name, String p) async {
  final rawData = await new File(p).readAsBytes();
  return new tzfile.Location.fromBytes(name, rawData);
}

/// Download IANA Time Zone database to [dest] directory.
Future<String> downloadTzData(String version, String dest) async {
  final outPath = path.join(dest, 'tzdata$version.tar.gz');
  final client = new HttpClient();
  try {
    var uri;
    if (version == 'latest')
      uri = Uri.parse('https://www.iana.org/time-zones/repository/tzdata-$version.tar.gz');
    else
      uri = Uri.parse('https://www.iana.org/time-zones/repository/releases/tzdata$version.tar.gz');

    final req = await client.getUrl(uri);
    final resp = await req.close();
    final out = new File(outPath);
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
  final result = await Process.run('tar', ['--directory=$dest', '-zxf', archivePath]);
  if (result.exitCode == 0) {
    return true;
  }
  throw new Exception(result.stderr);
}

/// Compile IANA Time Zone file with zic compiler.
Future zic(String src, String dest) async {
  final result = await Process.run('zic', ['-d', dest, src]);
  if (result.exitCode == 0) {
    return true;
  }
  throw new Exception(result.stderr);
}

Future main(List<String> arguments) async {
  // Initialize logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  final Logger log = new Logger('main');

  // Parse CLI arguments
  final parser = new ArgParser()..addOption('source', abbr: 's', defaultsTo: 'latest');
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
    final zicDirPath = path.join(tmpDir.path, 'zic');
    await new Directory(zicDirPath).create();

    log.info('Compiling timezone data with zic compiler');
    for (final i in _zicDataFiles) {
      log.info('- $i');
      await zic(path.join(tmpDir.path, i), zicDirPath);
    }

    log.info('Importing tzfile Locations');
    final files = await new Glob('**/*').list(root: zicDirPath).toList();
    for (final f in files) {
      if (f is File) {
        final name = path.relative(f.path, from: zicDirPath);
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
  final db = new LocationDatabase();
  for (final loc in tzfileLocations) {
    db.add(tzfileLocationToNativeLocation(loc));
  }
  logReport(r) {
    log.info('  + locations: ${r.originalLocationsCount} => ${r.newLocationsCount}');
    log.info('  + transitions: ${r.originalTransitionsCount} => ${r.newTransitionsCount}');
  }

  log.info('Building location databases:');

  log.info('- all locations');
  final allDb = filterTimeZoneData(db, locations: allLocations);
  logReport(allDb.report);

  log.info('- common locations from all locations');
  final commonDb = filterTimeZoneData(allDb.db, locations: commonLocations);
  logReport(commonDb.report);

  log.info('- [2010 - 2020 years] from common locations');
  final common_2010_2020_Db = filterTimeZoneData(commonDb.db,
      dateFrom: new DateTime.utc(2010, 1, 1).millisecondsSinceEpoch,
      dateTo: new DateTime.utc(2020, 1, 1).millisecondsSinceEpoch,
      locations: commonLocations);
  logReport(common_2010_2020_Db.report);

  log.info('Serializing location databases');
  final allOut = new File(path.join(outPath, '${source}_all.$tzDataExtension'));
  final commonOut = new File(path.join(outPath, '${source}.$tzDataExtension'));
  final common_2010_2020_Out = new File(path.join(outPath, '${source}_2010-2020.$tzDataExtension'));
  await allOut.writeAsBytes(tzdbSerialize(allDb.db), flush: true);
  await commonOut.writeAsBytes(tzdbSerialize(commonDb.db), flush: true);
  await common_2010_2020_Out.writeAsBytes(tzdbSerialize(common_2010_2020_Db.db), flush: true);

  exit(0);
}
