import 'dart:io';

import 'package:args/args.dart';
import 'package:timezone/standalone.dart';

/// Print Location details
void main(List<String> arguments) {
  // Parse CLI arguments
  final parser = ArgParser()
    ..addOption('source', abbr: 'd', defaultsTo: tzDataDefaultPath)
    ..addOption('location', abbr: 'l');

  final argResults = parser.parse(arguments);

  final source = argResults['source'] as String?;
  final location = argResults['location'] as String?;

  if (source == null ||
      source.isEmpty ||
      location == null ||
      location.isEmpty) {
    print(parser.usage);
    exit(64);
  }

  initializeTimeZone(source).then((_) {
    final l = getLocation(location);

    for (var i = 0; i < l.transitionAt.length; i++) {
      final t = l.transitionAt[i];
      final z = l.zones[l.transitionZone[i]];

      final dt = DateTime.fromMillisecondsSinceEpoch(t, isUtc: true);
      print('${dt.toIso8601String()} $z');
    }

    exit(0);
  });
}
