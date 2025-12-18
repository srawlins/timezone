import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final tzDataPath = args[0];
  final dartLibraryPath = args[1];
  final bytes = File(tzDataPath).readAsBytesSync();
  final generatedDartFile = generateDartFile(
    name: p.basenameWithoutExtension(tzDataPath),
    data: bytes,
  );
  File(dartLibraryPath).writeAsStringSync(generatedDartFile);
}

String bytesAsString(
  Uint8List bytes, {
  String prefix = '',
  String indent = '',
}) {
  final buffer = StringBuffer();
  buffer.write('\'');
  var column = prefix.length + 1;
  for (var index = 0; index < bytes.length; index++) {
    final byte = bytes[index];
    if (column > 74) {
      // Not space for one encoding + "';".
      buffer
        ..write('\'\n')
        ..write(indent)
        ..write('\'');
      column = indent.length + 1;
    }
    buffer
      ..write(byte < 16 ? r'\x0' : r'\x')
      ..write(byte.toRadixString(16));
    column += 4;
  }
  buffer.write('\'');
  return buffer.toString();
}

String generateDartFile({required String name, required Uint8List data}) => '''
// This is a generated file. Do not edit.
import 'dart:typed_data';

import '../src/env.dart';
import '../src/exceptions.dart';

/// Initialize Time Zone database from $name.
///
/// Throws [TimeZoneInitException] when something is wrong.
void initializeTimeZones() {
  try {
    initializeDatabase(
        Uint8List.fromList(_embeddedData.codeUnits));
  }
  // ignore: avoid_catches_without_on_clauses
  catch (e) {
    throw TimeZoneInitException(e.toString());
  }
}

const _embeddedData = ${bytesAsString(
      data,
      prefix: 'const _embeddedData = ',
      indent: '    ',
    )};
''';
