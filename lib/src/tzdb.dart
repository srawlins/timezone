// Copyright (c) 2015, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

/// TimeZone db file.
library timezone.src.tzdb;

import 'dart:collection';
import 'dart:convert' show ascii;
import 'dart:typed_data';
import 'location.dart';
import 'location_database.dart';

/// Serialize TimeZone Database
List<int> tzdbSerialize(LocationDatabase db) {
  final locationsInBytes = <List<int>>[];
  var bufferLength = 0;

  for (final l in db.locations.values.toList()
    ..sort((l, r) => l.name.compareTo(r.name))) {
    List<int> b = _serializeLocation(l);
    locationsInBytes.add(b);
    bufferLength += 8 + b.length;
    bufferLength = _align(bufferLength, 8);
  }

  final r = Uint8List(bufferLength);
  final rb = r.buffer.asByteData();

  var offset = 0;
  for (final b in locationsInBytes) {
    var length = _align(b.length, 8);
    rb.setUint32(offset, length);
    r.setAll(offset + 8, b);
    offset += 8 + length;
  }

  return r;
}

/// Deserialize TimeZone Database
Iterable<Location> tzdbDeserialize(List<int> rawData) sync* {
  final data = rawData is Uint8List ? rawData : Uint8List.fromList(rawData);
  final bdata = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);

  var offset = 0;
  while (offset < data.length) {
    final length = bdata.getUint32(offset);
    // u32 _pad;
    assert((length % 8) == 0);
    offset += 8;

    yield _deserializeLocation(
        data.buffer.asUint8List(data.offsetInBytes + offset, length));
    offset += length;
  }
}

Uint8List _serializeLocation(Location location) {
  var offset = 0;

  final abbrs = <String>[];
  final abbrsIndex = HashMap<String, int>();
  final zoneAbbrOffsets = <int>[];

  var _abbrsLength = 0;
  // number of bytes of all abbrevs
  for (final z in location.zones) {
    final ai = abbrsIndex.putIfAbsent(z.abbr, () {
      final ret = abbrs.length;
      _abbrsLength += z.abbr.length + 1; // abbr + '\0'
      abbrs.add(z.abbr);
      return ret;
    });

    zoneAbbrOffsets.add(ai);
  }

  final List<int> encName = ascii.encode(location.name);

  final nameOffset = 32;
  final nameLength = encName.length;
  final abbrsOffset = nameOffset + nameLength;
  final abbrsLength = _abbrsLength;
  final zonesOffset = _align(abbrsOffset + abbrsLength, 4);
  final zonesLength = location.zones.length;
  final transitionsOffset = _align(zonesOffset + zonesLength * 8, 8);
  final transitionsLength = location.transitionAt.length;

  final bufferLength = _align(transitionsOffset + transitionsLength * 9, 8);

  final result = Uint8List(bufferLength);
  final buffer = ByteData.view(result.buffer);

  // write header
  buffer.setUint32(0, nameOffset);
  buffer.setUint32(4, nameLength);
  buffer.setUint32(8, abbrsOffset);
  buffer.setUint32(12, abbrsLength);
  buffer.setUint32(16, zonesOffset);
  buffer.setUint32(20, zonesLength);
  buffer.setUint32(24, transitionsOffset);
  buffer.setUint32(28, transitionsLength);

  // write name
  offset = nameOffset;
  for (final c in encName) {
    buffer.setUint8(offset++, c);
  }

  // write abbrevs
  offset = abbrsOffset;
  for (final a in abbrs) {
    for (final c in a.codeUnits) {
      buffer.setUint8(offset++, c);
    }
    buffer.setUint8(offset++, 0);
  }

  // write zones
  offset = zonesOffset;
  for (var i = 0; i < location.zones.length; i++) {
    final zone = location.zones[i];
    buffer.setInt32(offset, zone.offset ~/ 1000); // convert to sec
    buffer.setUint8(offset + 4, zone.isDst ? 1 : 0);
    buffer.setUint8(offset + 5, zoneAbbrOffsets[i]);
    offset += 8;
  }

  // write transitions
  offset = transitionsOffset;
  for (final tAt in location.transitionAt) {
    final t = (tAt / 1000).floorToDouble();
    buffer.setFloat64(offset, t.toDouble()); // convert to sec
    offset += 8;
  }

  for (final tZone in location.transitionZone) {
    buffer.setUint8(offset, tZone);
    offset += 1;
  }

  return result;
}

Location _deserializeLocation(Uint8List data) {
  final bdata = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);
  var offset = 0;

  // Header
  //
  //     struct {
  //       u32 nameOffset;
  //       u32 nameLength;
  //       u32 abbrsOffset;
  //       u32 abbrsLength;
  //       u32 zonesOffset;
  //       u32 zonesLength;
  //       u32 transitionsOffset;
  //       u32 transitionsLength;
  //     } header;
  final nameOffset = bdata.getUint32(0);
  final nameLength = bdata.getUint32(4);
  final abbrsOffset = bdata.getUint32(8);
  final abbrsLength = bdata.getUint32(12);
  final zonesOffset = bdata.getUint32(16);
  final zonesLength = bdata.getUint32(20);
  final transitionsOffset = bdata.getUint32(24);
  final transitionsLength = bdata.getUint32(28);

  final name = ascii.decode(
      data.buffer.asUint8List(data.offsetInBytes + nameOffset, nameLength));
  final abbrs = <String>[];
  final zones = <TimeZone>[];
  final transitionAt = <int>[];
  final transitionZone = <int>[];

  // Abbreviations
  //
  // \0 separated strings
  offset = abbrsOffset;
  final abbrsEnd = abbrsOffset + abbrsLength;
  for (var i = abbrsOffset; i < abbrsEnd; i++) {
    if (data[i] == 0) {
      final abbr = ascii.decode(
          data.buffer.asUint8List(data.offsetInBytes + offset, i - offset));
      abbrs.add(abbr);
      offset = i + 1;
    }
  }

  // TimeZones
  //
  //     struct {
  //       i32 offset; // in seconds
  //       u8 isDst;
  //       u8 abbrIndex;
  //       u8 _pad[2];
  //     } zones[zonesLength]; // at zoneOffset
  offset = zonesOffset;
  assert((offset % 4) == 0);
  for (var i = 0; i < zonesLength; i++) {
    final zoneOffset = bdata.getInt32(offset) * 1000; // convert to ms
    final zoneIsDst = bdata.getUint8(offset + 4);
    final zoneAbbrIndex = bdata.getUint8(offset + 5);
    offset += 8;
    zones.add(TimeZone(zoneOffset, zoneIsDst == 1, abbrs[zoneAbbrIndex]));
  }

  // Transitions
  //
  //     f64 transitionAt[transitionsLength]; // in seconds
  //     u8 transitionZone[transitionLength]; // at (transitionsOffset + (transitionsLength * 8))
  offset = transitionsOffset;
  assert((offset % 8) == 0);
  for (var i = 0; i < transitionsLength; i++) {
    transitionAt.add(bdata.getFloat64(offset).toInt() * 1000); // convert to ms
    offset += 8;
  }

  for (var i = 0; i < transitionsLength; i++) {
    transitionZone.add(bdata.getUint8(offset));
    offset += 1;
  }

  return Location(name, transitionAt, transitionZone, zones);
}

int _align(int offset, int boundary) {
  final i = offset % boundary;
  return i == 0 ? offset : offset + (boundary - i);
}
