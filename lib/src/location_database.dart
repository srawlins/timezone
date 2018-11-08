// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

/// Locations database
library timezone.src.location_database;

import 'location.dart';
import 'exceptions.dart';

/// LocationDatabase provides interface to find [Location]s by their name.
///
///     List<int> data = load(); // load database
///
///     LocationDatabase db = new LocationDatabase.fromBytes(data);
///     Location loc = db.get('US/Eastern');
///
class LocationDatabase {
  /// Mapping between [Location] name and [Location].
  final Map<String, Location> _locations = Map<String, Location>();

  Map<String, Location> get locations => _locations;

  /// Add [Location] to the database.
  void add(Location location) {
    _locations[location.name] = location;
  }

  /// Find [Location] by its name.
  Location get(String name) {
    final loc = _locations[name];
    if (loc == null) {
      throw LocationNotFoundException(
          'Location with the name "$name" doesn\'t exist');
    }
    return loc;
  }
}
