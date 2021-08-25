library timezone.src.timezone_manager_web;

import 'package:flutter/foundation.dart';
import 'package:timezone/browser.dart' as timezone;

import 'timezone_manager.dart';

TimezoneManager getTimezoneManager() => TimezoneWeb();

class TimezoneWeb extends TimezoneManager {
  @override
  Future<void> initializeTimezoneConfiguration(
    DatabaseVariant databaseVariant,
  ) {
    return kReleaseMode
        ? releaseModeInitialization(databaseVariant)
        : debugModeInitialization(databaseVariant);
  }

  Future<void> releaseModeInitialization(DatabaseVariant databaseVariant) {
    return timezone.initializeTimeZone(
      databaseVariant == DatabaseVariant.latest
          ? 'assets/packages/timezone/data/latest.tzf'
          : databaseVariant == DatabaseVariant.latest_10y
              ? 'assets/packages/timezone/data/latest_10y.tzf'
              : 'assets/packages/timezone/data/latest_all.tzf',
    );
  }

  /// This method exists because Flutter's debug mode needs
  /// a different configuration.
  Future<void> debugModeInitialization(DatabaseVariant databaseVariant) {
    return timezone.initializeTimeZone(
      databaseVariant == DatabaseVariant.latest
          ? 'packages/timezone/data/latest.tzf'
          : databaseVariant == DatabaseVariant.latest_10y
              ? 'packages/timezone/data/latest_10y.tzf'
              : 'packages/timezone/data/latest_all.tzf',
    );
  }
}
