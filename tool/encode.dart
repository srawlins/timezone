import 'dart:convert' show base64Encode;
import 'dart:io';

import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final tzDataPath = args[0];
  final dartLibraryPath = args[1];
  final bytes = File(tzDataPath).readAsBytesSync();
  final encodedString = base64Encode(bytes);
  final buffer = StringBuffer();
  buffer.write('''
// This is a generated file. Do not edit.
//
// This file contains a base64-encoded timezone database, generated from
// $tzDataPath by ${p.basename(Platform.script.path)} on ${DateTime.now()}.
import "package:timezone/src/env.dart" show initializeTimeZonesFromBase64;
''');
  buffer.writeln('const _encodedTzData = "$encodedString";');
  buffer.writeln('void initializeTimeZones() =>\n'
      '    initializeTimeZonesFromBase64(_encodedTzData);');
  File(dartLibraryPath).writeAsStringSync(buffer.toString());
}
