@TestOn('vm')
library;

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:timezone/tzdata.dart' as tzdata;

void main() {
  test('Read zone1970.tab file', () async {
    final packageUri = Uri(scheme: 'package', path: 'timezone/timezone.dart');
    final packagePath = p.dirname(
      p.dirname((await Isolate.resolvePackageUri(packageUri))!.toFilePath()),
    );
    final locationDir = p.join(packagePath, 'test');
    final rawData = await File(
      p.join(locationDir, 'data/zone1970.tab'),
    ).readAsString();
    final db = tzdata.LocationDescriptionDatabase.fromString(rawData);

    expect(db.locations[0].name, equals('Europe/Andorra'));
    expect(db.locations[0].countryCodes, equals(['AD']));
    expect(db.locations[0].latitude, equals(42.5));
    expect(db.locations[0].longitude, equals(1.5166666666666666));
    expect(db.locations[0].comments, isEmpty);

    expect(db.locations[1].name, equals('Asia/Dubai'));
    expect(db.locations[1].countryCodes, equals(['AE', 'OM']));
    expect(db.locations[1].latitude, equals(25.3));
    expect(db.locations[1].longitude, equals(55.3));
    expect(db.locations[1].comments, isEmpty);

    expect(db.locations[2].name, equals('Antarctica/Syowa'));
    expect(db.locations[2].countryCodes, equals(['AQ']));
    expect(db.locations[2].latitude, equals(-69.00611111111111));
    expect(db.locations[2].longitude, equals(39.59));
    expect(db.locations[2].comments, equals('Syowa Station, E Ongul I'));
  });
}
