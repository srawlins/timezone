// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

/// TimeZone initialization for browser environments.
///
/// ```dart
/// import 'package:timezone/browser.dart';
///
/// initializeTimeZone().then((_) {
///  final detroit = getLocation('America/Detroit');
///  final now = new TZDateTime.now(detroit);
/// });
library timezone.browser;

import 'dart:html';
import 'dart:typed_data';

import 'package:timezone/timezone.dart';

export 'package:timezone/timezone.dart'
    show
        getLocation,
        setLocalLocation,
        TZDateTime,
        Location,
        TimeZone,
        timeZoneDatabase;

/// Path to the Time Zone default database.
const String tzDataDefaultPath =
    'packages/timezone/data/$tzDataDefaultFilename';

/// Initialize Time Zone database.
///
/// Throws [TimeZoneInitException] when something is worng.
///
/// ```dart
/// import 'package:timezone/browser.dart';
///
/// initializeTimeZone().then(() {
///   final detroit = getLocation('America/Detroit');
///   final detroitNow = new TZDateTime.now(detroit);
/// });
/// ```
Future<void> initializeTimeZone([String path = tzDataDefaultPath]) {
  return HttpRequest.request(path,
          method: 'GET',
          responseType: 'arraybuffer',
          mimeType: 'application/octet-stream')
      .then((req) {
    final response = req.response;

    if (response is ByteBuffer) {
      initializeDatabase(response.asUint8List());
    } else {
      throw TimeZoneInitException(
          'Invalid response type: ${response.runtimeType}');
    }
  }).catchError((dynamic e) {
    throw TimeZoneInitException(e.toString());
  }, test: (e) => e is! TimeZoneInitException);
}
