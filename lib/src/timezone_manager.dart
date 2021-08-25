library timezone.src.timezone_manager;

import 'timezone_manager_import.dart'
    if (dart.library.io) 'timezone_manager_standard.dart'
    if (dart.library.js) 'timezone_manager_web.dart';

enum DatabaseVariant { latest, latest_10y, latestAll }

abstract class TimezoneManager {
  static TimezoneManager? _instance;

  static TimezoneManager get instance {
    _instance ??= getTimezoneManager();
    return _instance!;
  }

  Future<void> initializeTimezoneConfiguration(
    DatabaseVariant databaseVariant,
  );
}
