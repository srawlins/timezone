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
///  final now = TZDateTime.now(detroit);
/// });
library timezone.browser;

import 'package:http/browser_client.dart' as browser;
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
/// Throws [TimeZoneInitException] when something is wrong.
///
/// ```dart
/// import 'package:timezone/browser.dart';
///
/// initializeTimeZone().then(() {
///   final detroit = getLocation('America/Detroit');
///   final detroitNow = TZDateTime.now(detroit);
/// });
/// ```
Future<void> initializeTimeZone([String path = tzDataDefaultPath]) async {
  final client = browser.BrowserClient();
  try {
    final response = await client.get(
      Uri.parse(path),
      headers: {'Accept': 'application/octet-stream'},
    );
    if (response.statusCode == 200) {
      initializeDatabase(response.bodyBytes);
    } else {
      throw TimeZoneInitException(
        'Request failed with status: ${response.statusCode}',
      );
    }
  } on TimeZoneInitException {
    rethrow;
  } on Exception catch (e) {
    throw TimeZoneInitException(e.toString());
  } finally {
    client.close();
  }
}
