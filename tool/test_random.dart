import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:args/args.dart';
import 'package:timezone/standalone.dart';

final int minEpochTime = DateTime.utc(1890).millisecondsSinceEpoch ~/ 1000;
final int maxEpochTime = DateTime.utc(2020).millisecondsSinceEpoch ~/ 1000;

Future<String> dateCmd(int time, String tz) {
  List<String> dateArgs;
  if (Platform.isMacOS) {
    dateArgs = ['-r', '$time', '+%Y-%m-%d %H:%M:%S'];
  } else if (Platform.isLinux) {
    dateArgs = ['-d', '@$time', '+%Y-%m-%d %H:%M:%S'];
  } else {
    throw UnimplementedError(
        'Tool does not support ${Platform.operatingSystem} yet.');
  }
  return Process.run('date', dateArgs, environment: {'TZ': tz}).then((r) {
    return r.stdout as String;
  });
}

/// Run random tests against `date(1)` unix command
void main(List<String> arguments) async {
  // Parse CLI arguments
  final parser = ArgParser()
    ..addOption('iterations', abbr: 'i', defaultsTo: '1000')
    ..addOption('seed', abbr: 's', defaultsTo: '0');

  final argResults = parser.parse(arguments);

  final randomRange = maxEpochTime - minEpochTime;

  final seed = int.parse(argResults['seed'] as String);
  var r = Random(seed);

  final iterations = int.parse(argResults['iterations'] as String);
  print('Seed: $seed');
  print('Iterations: $iterations');

  await initializeTimeZone();
  final zoneNames = timeZoneDatabase.locations.keys.map((k) => k).toList();
  final zoneCount = zoneNames.length;

  for (var i = 0; i < iterations; i++) {
    final time = r.nextInt(randomRange) + minEpochTime;
    final tz = zoneNames[r.nextInt(zoneCount)];

    var dateOutput = (await dateCmd(time, tz)).trim();
    final tzTime =
        TZDateTime.fromMillisecondsSinceEpoch(getLocation(tz), time * 1000);

    if (dateOutput != tzTime.toString().substring(0, 19)) {
      print('$i: $tz $time "$tzTime" != $dateOutput');
    }
  }
}
