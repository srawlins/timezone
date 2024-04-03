@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

Future<void> main() async {
  initializeTimeZones();
  final detroit = getLocation('America/Detroit');
  final la = getLocation('America/Los_Angeles');
  final newYork = getLocation('America/New_York');

  group('Constructors', () {
    test('Default', () {
      final t = TZDateTime(la, 2010, 1, 2, 3, 4, 5, 6, 7);
      expect(t.toString(), equals('2010-01-02 03:04:05.006007-0800'));
    });

    test('Default, only year argument', () {
      final t = TZDateTime(la, 2010);
      expect(t.toString(), equals('2010-01-01 00:00:00.000-0800'));
    });

    test('from DateTime', () {
      final utcTime = DateTime.utc(2010, 1, 2, 3, 4, 5, 6, 7);
      final t = TZDateTime.from(utcTime, newYork);
      expect(t.toString(), equals('2010-01-01 22:04:05.006007-0500'));
    });

    test('from local DateTime', () {
      final localTime = DateTime(2010, 1, 2, 3, 4, 5, 6);
      final newYorkTime = TZDateTime.from(localTime, newYork);
      // New York time should be 5 hours behind UTC.
      expect(newYorkTime.hour,
          equals(localTime.toUtc().subtract(Duration(hours: 5)).hour));
    });

    test('from TZDateTime', () {
      final laTime = TZDateTime(la, 2010, 1, 2, 3, 4, 5, 6, 7);
      final t = TZDateTime.from(laTime, newYork);
      expect(t.toString(), equals('2010-01-02 06:04:05.006007-0500'));
    });

    test('fromMilliseconds', () {
      final t = TZDateTime.fromMillisecondsSinceEpoch(newYork, 1262430245006);
      expect(t.toString(), equals('2010-01-02 06:04:05.006-0500'));
    });

    test('fromMicroseconds', () {
      final t =
          TZDateTime.fromMicrosecondsSinceEpoch(newYork, 1262430245006007);
      expect(t.toString(), equals('2010-01-02 06:04:05.006007-0500'));
    });

    test('utc', () {
      final t = TZDateTime.utc(2010, 1, 2, 3, 4, 5, 6, 7);
      expect(t.toString(), equals('2010-01-02 03:04:05.006007Z'));
    });
  });

  group('Offsets', () {
    group('UTC to America/Detroit', () {
      group('Simple translations', () {
        final u1 = DateTime.utc(1975, 1, 1, 5);
        final x1 = TZDateTime.from(u1, detroit);

        test('$u1 => 1975-01-01 00:00:00.000-0500', () {
          expect(x1.toString(), equals('1975-01-01 00:00:00.000-0500'));
        });

        final u2 = u1.subtract(const Duration(milliseconds: 1));
        final x2 = TZDateTime.from(u2, detroit);

        test('$u2 => 1974-12-31 23:59:59.999-0500', () {
          expect(x2.toString(), equals('1974-12-31 23:59:59.999-0500'));
        });

        final u3 = u1.add(const Duration(milliseconds: 1));
        final x3 = TZDateTime.from(u3, detroit);

        test('$u3 => 1975-01-01 00:00:00.001-0500', () {
          expect(x3.toString(), equals('1975-01-01 00:00:00.001-0500'));
        });
      });

      group('EWT/EPT boundaries', () {
        final u1 = DateTime.utc(1945, 09, 30, 6);
        final x1 = TZDateTime.from(u1, detroit);

        test('$u1 => 1945-09-30 01:00:00.000-0500', () {
          expect(x1.toString(), '1945-09-30 01:00:00.000-0500');
        });

        final u2 = u1.subtract(const Duration(milliseconds: 1));
        final x2 = TZDateTime.from(u2, detroit);

        test('$u2 => 1945-09-30 01:59:59.999-0400', () {
          expect(x2.toString(), equals('1945-09-30 01:59:59.999-0400'));
        });

        final u3 = u1.add(const Duration(milliseconds: 1));
        final x3 = TZDateTime.from(u3, detroit);

        test('$u3 => 1945-09-30 01:00:00.001-0500', () {
          expect(x3.toString(), equals('1945-09-30 01:00:00.001-0500'));
        });
      });
    });

    group('America/Detroit to UTC', () {
      group('EWT/EPT boundaries', () {
        final x1 = TZDateTime(detroit, 1945, 9, 30, 1);
        final u1 = DateTime.fromMillisecondsSinceEpoch(
            x1.millisecondsSinceEpoch,
            isUtc: true);

        test('$x1 => 1945-09-30 05:00:00.000Z', () {
          expect(u1.toString(), '1945-09-30 05:00:00.000Z');
        });

        final x2 = x1.subtract(const Duration(milliseconds: 1));
        final u2 = DateTime.fromMillisecondsSinceEpoch(
            x2.millisecondsSinceEpoch,
            isUtc: true);

        test('$x2 => 1945-09-30 04:59:59.999Z', () {
          expect(u2.toString(), equals('1945-09-30 04:59:59.999Z'));
        });

        final x3 = x1.add(const Duration(milliseconds: 1));
        final u3 = DateTime.fromMillisecondsSinceEpoch(
            x3.millisecondsSinceEpoch,
            isUtc: true);

        test('$x3 => 1945-09-30 05:00:00.001Z', () {
          expect(u3.toString(), equals('1945-09-30 05:00:00.001Z'));
        });

        final x4 = x1.add(const Duration(hours: 1));
        final u4 = DateTime.fromMillisecondsSinceEpoch(
            x4.millisecondsSinceEpoch,
            isUtc: true);

        test('$x4 => 1945-09-30 06:00:00.000Z', () {
          expect(u4.toString(), equals('1945-09-30 06:00:00.000Z'));
        });

        final x5 = x2.add(const Duration(hours: 1));
        final u5 = DateTime.fromMillisecondsSinceEpoch(
            x5.millisecondsSinceEpoch,
            isUtc: true);

        test('$x5 => 1945-09-30 05:59:59.999Z', () {
          expect(u5.toString(), equals('1945-09-30 05:59:59.999Z'));
        });
      });
    });

    group('America/Detroit DST (negative offset)', () {
      // https://www.timeanddate.com/time/change/usa/detroit?year=2023
      group('EST/EDT transition', () {
        test('2 months before transition', () {
          final datetime = TZDateTime(detroit, 2023, 1, 12, 4);
          expect(datetime.toString(), '2023-01-12 04:00:00.000-0500');
        });

        test('1 hour before transition', () {
          final datetime = TZDateTime(detroit, 2023, 3, 12, 1);
          expect(datetime.toString(), '2023-03-12 01:00:00.000-0500');
        });

        test('lower transition', () {
          final datetime = TZDateTime(detroit, 2023, 3, 12, 2);
          expect(datetime.toString(), '2023-03-12 03:00:00.000-0400');
        });

        test('upper transition', () {
          final datetime = TZDateTime(detroit, 2023, 3, 12, 3);
          expect(datetime.toString(), '2023-03-12 03:00:00.000-0400');
        });

        test('1 hour after transition', () {
          final datetime = TZDateTime(detroit, 2023, 3, 12, 4);
          expect(datetime.toString(), '2023-03-12 04:00:00.000-0400');
        });

        test('2 months after transition', () {
          final datetime = TZDateTime(detroit, 2023, 5, 12, 4);
          expect(datetime.toString(), '2023-05-12 04:00:00.000-0400');
        });
      });

      group('EDT/EST transition', () {
        test('2 months before transition', () {
          final datetime = TZDateTime(detroit, 2023, 9, 5, 1);
          expect(datetime.toString(), '2023-09-05 01:00:00.000-0400');
        });

        test('1 hour before transition', () {
          final datetime = TZDateTime(detroit, 2023, 11, 5);
          expect(datetime.toString(), '2023-11-05 00:00:00.000-0400');
        });

        test('lower transition', () {
          final datetime = TZDateTime(detroit, 2023, 11, 5, 1);
          expect(datetime.toString(), '2023-11-05 01:00:00.000-0400');
        });

        test('upper transition', () {
          final datetime = TZDateTime(detroit, 2023, 11, 5, 2);
          expect(datetime.toString(), '2023-11-05 02:00:00.000-0500');
        });

        test('1 hour after transition', () {
          final datetime = TZDateTime(detroit, 2023, 11, 5, 3);
          expect(datetime.toString(), '2023-11-05 03:00:00.000-0500');
        });

        test('2 months after transition', () {
          final datetime = TZDateTime(detroit, 2024, 1, 5, 2);
          expect(datetime.toString(), '2024-01-05 02:00:00.000-0500');
        });
      });
    });

    group('Europe/Berlin DST (positive offset)', () {
      // https://www.timeanddate.com/time/change/germany/berlin?year=2023
      final berlin = getLocation('Europe/Berlin');

      group('EST/EDT transition', () {
        test('2 months before transition', () {
          final datetime = TZDateTime(berlin, 2023, 1, 26, 2);
          expect(datetime.toString(), '2023-01-26 02:00:00.000+0100');
        });

        test('1 hour before transition', () {
          final datetime = TZDateTime(berlin, 2023, 3, 26, 1);
          expect(datetime.toString(), '2023-03-26 01:00:00.000+0100');
        });

        test('lower transition', () {
          final datetime = TZDateTime(berlin, 2023, 3, 26, 2);
          expect(datetime.toString(), '2023-03-26 03:00:00.000+0200');
        });

        test('upper transition', () {
          final datetime = TZDateTime(berlin, 2023, 3, 26, 3);
          expect(datetime.toString(), '2023-03-26 03:00:00.000+0200');
        });

        test('1 hour after transition', () {
          final datetime = TZDateTime(berlin, 2023, 3, 26, 4);
          expect(datetime.toString(), '2023-03-26 04:00:00.000+0200');
        });

        test('2 months after transition', () {
          final datetime = TZDateTime(berlin, 2023, 5, 26, 3);
          expect(datetime.toString(), '2023-05-26 03:00:00.000+0200');
        });
      });

      group('EDT/EST transition', () {
        test('2 months before transition', () {
          final datetime = TZDateTime(berlin, 2023, 8, 29, 2);
          expect(datetime.toString(), '2023-08-29 02:00:00.000+0200');
        });

        test('1 hour before transition', () {
          final datetime = TZDateTime(berlin, 2023, 10, 29, 1);
          expect(datetime.toString(), '2023-10-29 01:00:00.000+0200');
        });

        test('lower transition', () {
          final datetime = TZDateTime(berlin, 2023, 10, 29, 2);
          expect(datetime.toString(), '2023-10-29 02:00:00.000+0100');
        });

        test('upper transition', () {
          final datetime = TZDateTime(berlin, 2023, 10, 29, 3);
          expect(datetime.toString(), '2023-10-29 03:00:00.000+0100');
        });

        test('1 hour after transition', () {
          final datetime = TZDateTime(berlin, 2023, 10, 29, 4);
          expect(datetime.toString(), '2023-10-29 04:00:00.000+0100');
        });

        test('2 months after transition', () {
          final datetime = TZDateTime(berlin, 2024, 1, 29, 3);
          expect(datetime.toString(), '2024-01-29 03:00:00.000+0100');
        });
      });
    });
  });

  group('Timezones', () {
    test(
        'getLocation throws $LocationNotFoundException for unrecognized '
        'timezone', () {
      expect(() => getLocation('non-existent-location'),
          throwsA(TypeMatcher<LocationNotFoundException>()));
    });
  });
}
