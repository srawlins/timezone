@TestOn('vm')
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';

Future<void> main() async {
  const timeStep = 15 * 60 * 1000; // 15 minutes
  final startTime =
      (DateTime.now().millisecondsSinceEpoch ~/ timeStep) * timeStep;
  await initializeTimeZone();

  test('Europe/London', () {
    final location = getLocation('Europe/London');
    for (var i = startTime; i >= 0; i -= timeStep) {
      var time1 = DateTime.fromMillisecondsSinceEpoch(i);

      var tzTime1 = TZDateTime(location, time1.year, time1.month, time1.day,
          time1.hour, time1.minute);

      DateTime localTime2 = tzTime1.toLocal();

      var tzTime2 = TZDateTime.from(localTime2, location);

      expect(tzTime1.toString(), equals(tzTime2.toString()));
    }
  });

  test('America/Detroit', () {
    final location = getLocation('America/Detroit');
    for (var i = startTime; i >= 0; i -= timeStep) {
      var time1 = DateTime.fromMillisecondsSinceEpoch(i);

      var tzTime1 = TZDateTime(location, time1.year, time1.month, time1.day,
          time1.hour, time1.minute);

      DateTime localTime2 = tzTime1.toLocal();

      var tzTime2 = TZDateTime.from(localTime2, location);

      expect(tzTime1.toString(), equals(tzTime2.toString()));
    }
  });

  test('America/Los_Angeles', () {
    final location = getLocation('America/Los_Angeles');
    for (var i = startTime; i >= 0; i -= timeStep) {
      var time1 = DateTime.fromMillisecondsSinceEpoch(i);

      var tzTime1 = TZDateTime(location, time1.year, time1.month, time1.day,
          time1.hour, time1.minute);

      DateTime localTime2 = tzTime1.toLocal();

      var tzTime2 = TZDateTime.from(localTime2, location);

      expect(tzTime1.toString(), equals(tzTime2.toString()));
    }
  });

  test('America/New_York', () {
    final location = getLocation('America/New_York');
    for (var i = startTime; i >= 0; i -= timeStep) {
      var time1 = DateTime.fromMillisecondsSinceEpoch(i);

      var tzTime1 = TZDateTime(location, time1.year, time1.month, time1.day,
          time1.hour, time1.minute);

      DateTime localTime2 = tzTime1.toLocal();

      var tzTime2 = TZDateTime.from(localTime2, location);

      expect(tzTime1.toString(), equals(tzTime2.toString()));
    }
  });
}
