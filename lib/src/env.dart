// Copyright (c) 2015, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

library timezone.src.env;

import 'location.dart';
import 'location_database.dart';
import 'tzdb.dart';

/// Latest version of the Time Zone database.
const String tzDataLatestVersion = '2015b';

/// Time Zone database file extension.
const String tzDataExtension = 'tzf';

/// File name of the Time Zone default database.
const String tzDataDefaultFilename = '$tzDataLatestVersion.$tzDataExtension';

LocationDatabase _database;
Location _UTC;
Location _local;

/// Global TimeZone database
LocationDatabase get timeZoneDatabase => _database;

/// UTC Location
Location get UTC => _UTC;

/// Local Location
///
/// By default it is instantiated with UTC [Location]
Location get local => _local;

/// Find [Location] by its name.
///
/// ```dart
/// final detroit = getLocation('America/Detroit');
/// ```
Location getLocation(String locationName) {
  return _database.get(locationName);
}

/// Set local [Location]
///
/// ```dart
/// final detroit = getLocation('America/Detroit')
/// setLocalLocation(detroit);
/// ```
void setLocalLocation(Location location) {
  _local = location;
}

/// Initialize Time zone database.
void initializeDatabase(List<int> rawData) {
  if (_database == null) {
    _database = new LocationDatabase();
  }

  for (final Location l in tzdbDeserialize(rawData)) {
    _database.add(l);
  }

  if (_UTC == null) {
    _UTC = new Location('UTC', [minTime], [0], [TimeZone.UTC]);
  }

  if (_local == null) {
    _local = _UTC;
  }
}
