import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final tzDataPath = args[0];
  final dartLibraryPath = args[1];
  final bytes = File(tzDataPath).readAsBytesSync();
  final generatedDartFile = generateDartFile(
    name: p.basenameWithoutExtension(tzDataPath),
    data: bytesAsString(bytes),
  );
  File(dartLibraryPath).writeAsStringSync(generatedDartFile);
}

String bytesAsString(Uint8List bytes) {
  assert(bytes.length.isEven);
  return bytes.buffer
      .asUint16List()
      .map((u) => '\\u${u.toRadixString(16).padLeft(4, '0')}')
      .join();
}

String generateDartFile({required String name, required String data}) =>
    '''// This is a generated file. Do not edit.
import 'dart:typed_data';

import 'package:timezone/src/env.dart';
import 'package:timezone/src/exceptions.dart';

/// Initialize Time Zone database from $name.
///
/// Throws [TimeZoneInitException] when something is wrong.
void initializeTimeZones() {
  try {
    initializeDatabase(
        Uint16List.fromList(_embeddedData.codeUnits).buffer.asUint8List());
  }
  // ignore: avoid_catches_without_on_clauses
  catch (e) {
    throw TimeZoneInitException(e.toString());
  }
}

const _embeddedData =
    '$data';
''';
