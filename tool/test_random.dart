/// Run random tests against `date(1)` unix command

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:timezone/standalone.dart';

final int minEpochTime = DateTime.utc(1890).millisecondsSinceEpoch ~/ 1000;
final int maxEpochTime = DateTime.utc(2020).millisecondsSinceEpoch ~/ 1000;

Future<String> dateCmd(int time, String tz) {
  return Process.run('date', ['-d', '@$time', '+%Y-%m-%d %H:%M:%S'],
      environment: {'TZ': tz}).then((r) {
    return r.stdout;
  });
}

void main(List<String> arguments) {
  // Initialize logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  final log = Logger('main');

  // Parse CLI arguments
  final parser = ArgParser()
    ..addOption('iterations', abbr: 'i', defaultsTo: '1000')
    ..addOption('seed', abbr: 's', defaultsTo: '0');

  final argResults = parser.parse(arguments);

  final randomRange = maxEpochTime - minEpochTime;

  final seed = int.parse(argResults['seed']);
  var i = int.parse(argResults['iterations']);
  var r = Random(seed);

  log.info('Seed: $seed');
  log.info('Iterations: $i');

  initializeTimeZone().then((_) {
    final zoneNames = timeZoneDatabase.locations.keys.map((k) => k).toList();
    final zoneCount = zoneNames.length;

    Future.doWhile(() {
      final time = r.nextInt(randomRange) + minEpochTime;
      final tz = zoneNames[r.nextInt(zoneCount)];

      return dateCmd(time, tz).then((v) {
        final x =
            TZDateTime.fromMillisecondsSinceEpoch(getLocation(tz), time * 1000);
        v = v.trim();

        if (v != x.toString().substring(0, 19)) {
          log.severe('$tz $time $x != $v');
        }

        i--;
        return i == 0 ? false : true;
      });
    });
  });
}
