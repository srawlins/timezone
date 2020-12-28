/// Print Location details

// @dart=2.9

import 'dart:io';

import 'package:args/args.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';

void main(List<String> arguments) {
  // Parse CLI arguments
  final parser = ArgParser()
    ..addOption('source', abbr: 'd', defaultsTo: tzDataDefaultPath)
    ..addOption('location', abbr: 'l');

  final argResults = parser.parse(arguments);

  final String source = argResults['source'];
  final String /*?*/ location = argResults['location'];

  if (source.isEmpty || location == null || location.isEmpty) {
    print(parser.usage);
    exit(64);
  }

  initializeTimeZone(source).then((_) {
    final l = getLocation(location /*!*/);

    for (var i = 0; i < l.transitionAt.length; i++) {
      final t = l.transitionAt[i];
      final z = l.zones[l.transitionZone[i]];

      final dt = DateTime.fromMillisecondsSinceEpoch(t, isUtc: true);
      print('${dt.toIso8601String()} $z');
    }

    exit(0);
  });
}
