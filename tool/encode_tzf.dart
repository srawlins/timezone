/// A tool to create the .tzf databases from a zoneinfo directory.
///
/// Usage example:
///
/// ```sh
/// pub run tool/encode_tzf --zoneinfo path/to/zoneinfo
/// ```

import 'dart:io';
import 'package:args/args.dart';
import 'package:file/file.dart' as pkg_file;
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'package:timezone/src/tools.dart';
import 'package:timezone/src/tzdb.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/tzdata.dart' as tzfile;

Future<void> main(List<String> arguments) async {
  // Initialize logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  final log = Logger('main');

  // Parse CLI arguments
  final parser = ArgParser()
    ..addOption('output-all', defaultsTo: 'lib/data/latest_all.tzf')
    ..addOption('output-common', defaultsTo: 'lib/data/latest.tzf')
    ..addOption('output-10y', defaultsTo: 'lib/data/latest_10y.tzf')
    ..addOption('zoneinfo');
  final args = parser.parse(arguments);

  final zoneinfoPath = args['zoneinfo'];
  if (zoneinfoPath == null) {
    print('Usage:\n${parser.usage}');
    exit(1);
  }

  final db = LocationDatabase();

  log.info('Importing zoneinfo files');
  final files = await Glob('**').list(root: zoneinfoPath).toList();
  for (final f in files) {
    if (f is pkg_file.File) {
      final name = p.relative(f.path, from: zoneinfoPath);
      log.info('- $name');
      db.add(tzfileLocationToNativeLocation(
          tzfile.Location.fromBytes(name, await f.readAsBytes())));
    }
  }

  void logReport(FilterReport r) {
    log.info('  + locations: ${r.originalLocationsCount} => '
        '${r.newLocationsCount}');
    log.info('  + transitions: ${r.originalTransitionsCount} => '
        '${r.newTransitionsCount}');
  }

  log.info('Building location databases:');

  log.info('- all locations');
  final allDb = filterTimeZoneData(db);
  logReport(allDb.report);

  log.info('- common locations from all locations');
  final commonDb = filterTimeZoneData(allDb.db, locations: commonLocations);
  logReport(commonDb.report);

  log.info('- [+- 5 years] from common locations');
  final common_10y_Db = filterTimeZoneData(commonDb.db,
      dateFrom: DateTime(DateTime.now().year - 5, 1, 1).millisecondsSinceEpoch,
      dateTo: DateTime(DateTime.now().year + 5, 1, 1).millisecondsSinceEpoch,
      locations: commonLocations);
  logReport(common_10y_Db.report);

  log.info('Serializing location databases');
  Future<void> write(String file, LocationDatabase db) =>
      File(file).writeAsBytes(tzdbSerialize(db), flush: true);
  await write(args['output-all'], allDb.db);
  await write(args['output-common'], commonDb.db);
  await write(args['output-10y'], common_10y_Db.db);
}
