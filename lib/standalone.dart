// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

/// TimeZone initialization for standalone environments.
///
/// ```dart
/// import 'package:timezone/standalone.dart';
///
/// initializeTimeZone().then((_) {
///  final detroit = getLocation('America/Detroit');
///  final now = new TZDateTime.now(detroit);
/// });
/// ```
library timezone.standalone;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as path;
import 'package:timezone/timezone.dart';

export 'package:timezone/timezone.dart'
    show getLocation, setLocalLocation, TZDateTime, Location, TimeZone, timeZoneDatabase;

final String tzDataDefaultPath = path.join('data', tzDataDefaultFilename);

// Load file
Future<List<int>> _loadAsBytes(String p) async {
  final script = Platform.script;
  final scheme = Platform.script.scheme;

  if (scheme.startsWith('http')) {
    // TODO: This path is not tested. How would one get to this situation?
    return new HttpClient()
        .getUrl(new Uri(scheme: script.scheme, host: script.host, port: script.port, path: p))
        .then((req) {
      return req.close();
    }).then((response) {
      // join byte buffers
      return response.fold(new BytesBuilder(), (b, d) => b..add(d)).then((builder) {
        return builder.takeBytes();
      });
    });
  } else {
    var uri = await Isolate.resolvePackageUri(new Uri(scheme: 'package', path: 'timezone/$p'));
    return new File(path.fromUri(uri)).readAsBytes();
  }
}

/// Initialize Time Zone database.
///
/// Throws [TimeZoneInitException] when something is worng.
///
/// ```dart
/// import 'package:timezone/standalone.dart';
///
/// initializeTimeZone().then(() {
///   final detroit = getLocation('America/Detroit');
///   final detroitNow = new TZDateTime.now(detroit);
/// });
/// ```
Future initializeTimeZone([String p]) {
  if (p == null) {
    p = tzDataDefaultPath;
  }
  return _loadAsBytes(p).then((rawData) {
    initializeDatabase(rawData);
  }).catchError((e) {
    throw new TimeZoneInitException(e.toString());
  });
}
