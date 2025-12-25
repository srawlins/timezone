import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones();
  final locations = tz.timeZoneDatabase.locations;
  print(locations.length); // => 429
  print(locations.keys.first); // => "Africa/Abidjan"
  print(locations.keys.last); // => "US/Pacific"

  final detroit = tz.getLocation('America/Detroit');
  final now = tz.TZDateTime.now(detroit);
  print(DateTime.now()); // => 2025-12-18 10:34:02.590478 in GMT+1
  print(now); // => 2025-12-18 04:32:07.515720-0500
  final timeInUtc = DateTime.utc(1995, 1, 1);
  final timeZone = detroit.timeZone(timeInUtc.millisecondsSinceEpoch);
  print(timeZone); // => [EST offset=-18000000 dst=false]
}
