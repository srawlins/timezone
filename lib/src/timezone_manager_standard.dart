library timezone.src.timezone_manager_standard;

import 'package:timezone/data/latest.dart' as latest;
import 'package:timezone/data/latest_10y.dart' as latest_10y;
import 'package:timezone/data/latest_all.dart' as latest_all;

import 'timezone_manager.dart';

TimezoneManager getTimezoneManager() => TimezoneMobile();

class TimezoneMobile extends TimezoneManager {
  @override
  Future<void> initializeTimezoneConfiguration(
    DatabaseVariant databaseVariant,
  ) {
    // Only works with Future.microtask(). Fails with Future.value()
    return Future.microtask(
      () => databaseVariant == DatabaseVariant.latest
          ? latest.initializeTimeZones()
          : databaseVariant == DatabaseVariant.latest_10y
              ? latest_10y.initializeTimeZones()
              : latest_all.initializeTimeZones(),
    );
  }
}
