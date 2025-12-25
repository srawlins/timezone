// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'dart:collection';
import 'dart:typed_data';

/// Time Zone information file magic header "TZif"
const int _ziMagic = 1415211366;

/// tzfile header structure
class _Header {
  /// Header size
  static int size = 6 * 4;

  /// The number of UTC/local indicators stored in the file.
  final int tzh_ttisgmtcnt;

  /// The number of standard/wall indicators stored in the file.
  final int tzh_ttisstdcnt;

  /// The number of leap seconds for which data is stored in the file.
  final int tzh_leapcnt;

  /// The number of "transition times" for which data is stored in the file.
  final int tzh_timecnt;

  /// The  number  of  "local  time types" for which data is stored in the file
  /// (must not be zero).
  final int tzh_typecnt;

  /// The number of characters of "timezone abbreviation strings" stored in the
  /// file.
  final int tzh_charcnt;

  _Header(
    this.tzh_ttisgmtcnt,
    this.tzh_ttisstdcnt,
    this.tzh_leapcnt,
    this.tzh_timecnt,
    this.tzh_typecnt,
    this.tzh_charcnt,
  );

  int dataLength(int longSize) {
    final leapBytes = tzh_leapcnt * (longSize + 4);
    final timeBytes = tzh_timecnt * (longSize + 1);
    final typeBytes = tzh_typecnt * 6;

    return tzh_ttisgmtcnt +
        tzh_ttisstdcnt +
        leapBytes +
        timeBytes +
        typeBytes +
        tzh_charcnt;
  }

  factory _Header.fromBytes(List<int> rawData) {
    final data = rawData is Uint8List ? rawData : Uint8List.fromList(rawData);
    final bdata = ByteData.sublistView(data);

    final tzh_ttisgmtcnt = bdata.getInt32(0);
    final tzh_ttisstdcnt = bdata.getInt32(4);
    final tzh_leapcnt = bdata.getInt32(8);
    final tzh_timecnt = bdata.getInt32(12);
    final tzh_typecnt = bdata.getInt32(16);
    final tzh_charcnt = bdata.getInt32(20);

    return _Header(
      tzh_ttisgmtcnt,
      tzh_ttisstdcnt,
      tzh_leapcnt,
      tzh_timecnt,
      tzh_typecnt,
      tzh_charcnt,
    );
  }
}

/// Read NULL-terminated string
String _readByteString(Uint8List data, int offset) {
  var i = offset;
  for (; i < data.length; i++) {
    final byte = data[i];
    if (byte >= 1 && byte < 0x80) continue;
    if (byte == 0) break;
    throw FormatException('Not ASCII', data, i);
  }
  return String.fromCharCodes(data, offset, i);
}

/// This exception is thrown when Zone Info data is invalid.
class InvalidZoneInfoDataException implements Exception {
  final String msg;

  InvalidZoneInfoDataException(this.msg);

  @override
  String toString() => msg;
}

/// TimeZone data
class TimeZone {
  /// Offset in seconds east of UTC.
  final int offset;

  /// DST time.
  final bool isDst;

  /// Index to abbreviation.
  final int abbreviationIndex;

  const TimeZone(
    this.offset, {
    required this.isDst,
    required this.abbreviationIndex,
  });
}

/// Location data
class Location {
  /// [Location] name
  final String name;

  /// Time in seconds when the transitioning is occured.
  final List<int> transitionAt;

  /// Transition zone index.
  final List<int> transitionZone;

  /// List of abbreviations.
  final List<String> abbreviations;

  /// List of [TimeZone]s.
  final List<TimeZone> zones;

  /// Time in seconds when the leap seconds should be applied.
  final List<int> leapAt;

  /// Amount of leap seconds that should be applied.
  final List<int> leapDiff;

  /// Whether transition times associated with local time types are specified as
  /// standard time or wall time.
  final List<int> isStd;

  /// Whether transition times associated with local time types are specified as
  /// UTC or local time.
  final List<int> isUtc;

  Location(
    this.name,
    this.transitionAt,
    this.transitionZone,
    this.abbreviations,
    this.zones,
    this.leapAt,
    this.leapDiff,
    this.isStd,
    this.isUtc,
  );

  /// Deserialize [Location] from bytes
  factory Location.fromBytes(String name, List<int> rawData) {
    final data = rawData is Uint8List ? rawData : Uint8List.fromList(rawData);

    final bdata = ByteData.sublistView(data);

    final magic1 = bdata.getUint32(0);
    if (magic1 != _ziMagic) {
      throw InvalidZoneInfoDataException('Invalid magic header "$magic1"');
    }
    final version1 = bdata.getUint8(4);

    var offset = 20;

    switch (version1) {
      case 0:
        final header = _Header.fromBytes(
          Uint8List.sublistView(bdata, offset, _Header.size),
        );

        // calculating data offsets
        final dataOffset = offset + _Header.size;
        final transitionAtOffset = dataOffset;
        final transitionZoneOffset =
            transitionAtOffset + header.tzh_timecnt * 5;
        final abbreviationsOffset =
            transitionZoneOffset + header.tzh_typecnt * 6;
        final leapOffset = abbreviationsOffset + header.tzh_charcnt;
        final stdOrWctOffset = leapOffset + header.tzh_leapcnt * 8;
        final utcOrGmtOffset = stdOrWctOffset + header.tzh_ttisstdcnt;

        // read transitions
        final transitionAt = <int>[];
        final transitionZone = <int>[];

        offset = transitionAtOffset;

        for (var i = 0; i < header.tzh_timecnt; i++) {
          transitionAt.add(bdata.getInt32(offset));
          offset += 4;
        }

        for (var i = 0; i < header.tzh_timecnt; i++) {
          transitionZone.add(bdata.getUint8(offset));
          offset += 1;
        }

        // function to read from abbreviation buffer
        final abbreviationsData = Uint8List.sublistView(
          data,
          abbreviationsOffset,
          abbreviationsOffset + header.tzh_charcnt,
        );
        final abbreviations = <String>[];
        final abbreviationsCache = HashMap<int, int>();
        int readAbbreviation(int offset) {
          var result = abbreviationsCache[offset];
          if (result == null) {
            result = abbreviations.length;
            abbreviationsCache[offset] = result;
            abbreviations.add(_readByteString(abbreviationsData, offset));
          }
          return result;
        }

        // read zones
        final zones = <TimeZone>[];
        offset = transitionZoneOffset;

        for (var i = 0; i < header.tzh_typecnt; i++) {
          final tt_gmtoff = bdata.getInt32(offset);
          final tt_isdst = bdata.getInt8(offset + 4);
          final tt_abbrind = bdata.getUint8(offset + 5);
          offset += 6;

          zones.add(
            TimeZone(
              tt_gmtoff,
              isDst: tt_isdst == 1,
              abbreviationIndex: readAbbreviation(tt_abbrind),
            ),
          );
        }

        // read leap seconds
        final leapAt = <int>[];
        final leapDiff = <int>[];

        offset = leapOffset;
        for (var i = 0; i < header.tzh_leapcnt; i++) {
          leapAt.add(bdata.getInt32(offset));
          leapDiff.add(bdata.getInt32(offset + 4));
          offset += 5;
        }

        // read std flags
        final isStd = <int>[];

        offset = stdOrWctOffset;
        for (var i = 0; i < header.tzh_ttisstdcnt; i++) {
          isStd.add(bdata.getUint8(offset));
          offset += 1;
        }

        // read utc flags
        final isUtc = <int>[];

        offset = utcOrGmtOffset;
        for (var i = 0; i < header.tzh_ttisgmtcnt; i++) {
          isUtc.add(bdata.getUint8(offset));
          offset += 1;
        }

        return Location(
          name,
          transitionAt,
          transitionZone,
          abbreviations,
          zones,
          leapAt,
          leapDiff,
          isStd,
          isUtc,
        );

      case 50:
      case 51:
        // skip old version header/data
        final header1 = _Header.fromBytes(
          Uint8List.sublistView(bdata, offset, offset + _Header.size),
        );
        offset += _Header.size + header1.dataLength(4);

        final magic2 = bdata.getUint32(offset);
        if (magic2 != _ziMagic) {
          throw InvalidZoneInfoDataException(
            'Invalid second magic header "$magic2"',
          );
        }

        final version2 = bdata.getUint8(offset + 4);
        if (version2 != version1) {
          throw InvalidZoneInfoDataException(
            'Second version "$version2" doesn\'t match first version '
            '"$version1"',
          );
        }

        offset += 20;

        final header2 = _Header.fromBytes(
          Uint8List.sublistView(bdata, offset, offset + _Header.size),
        );

        // calculating data offsets
        final dataOffset = offset + _Header.size;
        final transitionAtOffset = dataOffset;
        final transitionZoneOffset =
            transitionAtOffset + header2.tzh_timecnt * 9;
        final abbreviationsOffset =
            transitionZoneOffset + header2.tzh_typecnt * 6;
        final leapOffset = abbreviationsOffset + header2.tzh_charcnt;
        final stdOrWctOffset = leapOffset + header2.tzh_leapcnt * 12;
        final utcOrGmtOffset = stdOrWctOffset + header2.tzh_ttisstdcnt;

        // read transitions
        final transitionAt = <int>[];
        final transitionZone = <int>[];

        offset = transitionAtOffset;

        for (var i = 0; i < header2.tzh_timecnt; i++) {
          transitionAt.add(bdata.getInt64(offset));
          offset += 8;
        }

        for (var i = 0; i < header2.tzh_timecnt; i++) {
          transitionZone.add(bdata.getUint8(offset));
          offset += 1;
        }

        // function to read from abbreviation buffer
        final abbreviationsData = Uint8List.sublistView(
          data,
          abbreviationsOffset,
          abbreviationsOffset + header2.tzh_charcnt,
        );
        final abbreviations = <String>[];
        final abbreviationsCache = HashMap<int, int>();
        int readAbbreviation(int offset) {
          var result = abbreviationsCache[offset];
          if (result == null) {
            result = abbreviations.length;
            abbreviationsCache[offset] = result;
            abbreviations.add(_readByteString(abbreviationsData, offset));
          }
          return result;
        }

        // read transition info
        final zones = <TimeZone>[];
        offset = transitionZoneOffset;

        for (var i = 0; i < header2.tzh_typecnt; i++) {
          final tt_gmtoff = bdata.getInt32(offset);
          final tt_isdst = bdata.getInt8(offset + 4);
          final tt_abbrind = bdata.getUint8(offset + 5);
          offset += 6;

          zones.add(
            TimeZone(
              tt_gmtoff,
              isDst: tt_isdst == 1,
              abbreviationIndex: readAbbreviation(tt_abbrind),
            ),
          );
        }

        // read leap seconds
        final leapAt = <int>[];
        final leapDiff = <int>[];

        offset = leapOffset;
        for (var i = 0; i < header2.tzh_leapcnt; i++) {
          leapAt.add(bdata.getInt64(offset));
          leapDiff.add(bdata.getInt32(offset + 8));
          offset += 9;
        }

        // read std flags
        final isStd = <int>[];

        offset = stdOrWctOffset;
        for (var i = 0; i < header2.tzh_ttisstdcnt; i++) {
          isStd.add(bdata.getUint8(offset));
          offset += 1;
        }

        // read utc flags
        final isUtc = <int>[];

        offset = utcOrGmtOffset;
        for (var i = 0; i < header2.tzh_ttisgmtcnt; i++) {
          isUtc.add(bdata.getUint8(offset));
          offset += 1;
        }

        return Location(
          name,
          transitionAt,
          transitionZone,
          abbreviations,
          zones,
          leapAt,
          leapDiff,
          isStd,
          isUtc,
        );

      default:
        throw InvalidZoneInfoDataException('Unknown version: $version1');
    }
  }
}
