@TestOn('vm')
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';

main() async {
  await initializeTimeZone();
  final detroit = getLocation('America/Detroit');
  final la = getLocation('America/Los_Angeles');
  final newYork = getLocation('America/New_York');

  group('Constructors', () {
    test('Default', () {
      final t = new TZDateTime(la, 2010, 1, 2, 3, 4, 5, 6);
      expect(t.toString(), equals('2010-01-02 03:04:05.006-0800'));
    });

    test('from DateTime', () {
      final utcTime = new DateTime.utc(2010, 1, 2, 3, 4, 5, 6);
      final t = new TZDateTime.from(utcTime, newYork);
      expect(t.toString(), equals('2010-01-01 22:04:05.006-0500'));
    });

    test('from local DateTime', () {
      final localTime = DateTime(2010, 1, 2, 3, 4, 5, 6);
      final newYorkTime = TZDateTime.from(localTime, newYork);
      // New York time should be 5 hours behind UTC.
      expect(newYorkTime.hour,
          equals(localTime.toUtc().subtract(Duration(hours: 5)).hour));
    });

    test('from TZDateTime', () {
      final laTime = new TZDateTime(la, 2010, 1, 2, 3, 4, 5, 6);
      final t = new TZDateTime.from(laTime, newYork);
      expect(t.toString(), equals('2010-01-02 06:04:05.006-0500'));
    });

    test('fromMilliseconds', () {
      final t =
          new TZDateTime.fromMillisecondsSinceEpoch(newYork, 1262430245006);
      expect(t.toString(), equals('2010-01-02 06:04:05.006-0500'));
    });

    test('fromMicroseconds', () {
      final t =
          new TZDateTime.fromMicrosecondsSinceEpoch(newYork, 1262430245006007);
      expect(t.toString(), equals('2010-01-02 06:04:05.006007-0500'));
    });

    test('utc', () {
      final t = new TZDateTime.utc(2010, 1, 2, 3, 4, 5, 6);
      expect(t.toString(), equals('2010-01-02 03:04:05.006Z'));
    });
  });

  group('Offsets', () {
    group('UTC to America/Detroit', () {
      group('Simple translations', () {
        final u1 = new DateTime.utc(1975, 1, 1, 5);
        final x1 = new TZDateTime.from(u1, detroit);

        test('$u1 => 1975-01-01 00:00:00.000-0500', () {
          expect(x1.toString(), equals('1975-01-01 00:00:00.000-0500'));
        });

        final u2 = u1.subtract(const Duration(milliseconds: 1));
        final x2 = new TZDateTime.from(u2, detroit);

        test('$u2 => 1974-12-31 23:59:59.999-0500', () {
          expect(x2.toString(), equals('1974-12-31 23:59:59.999-0500'));
        });

        final u3 = u1.add(const Duration(milliseconds: 1));
        final x3 = new TZDateTime.from(u3, detroit);

        test('$u3 => 1975-01-01 00:00:00.001-0500', () {
          expect(x3.toString(), equals('1975-01-01 00:00:00.001-0500'));
        });
      });

      group('EWT/EPT boundaries', () {
        final u1 = new DateTime.utc(1945, 09, 30, 6);
        final x1 = new TZDateTime.from(u1, detroit);

        test('$u1 => 1945-09-30 01:00:00.000-0500', () {
          expect(x1.toString(), '1945-09-30 01:00:00.000-0500');
        });

        final u2 = u1.subtract(const Duration(milliseconds: 1));
        final x2 = new TZDateTime.from(u2, detroit);

        test('$u2 => 1945-09-30 01:59:59.999-0400', () {
          expect(x2.toString(), equals('1945-09-30 01:59:59.999-0400'));
        });

        final u3 = u1.add(const Duration(milliseconds: 1));
        final x3 = new TZDateTime.from(u3, detroit);

        test('$u3 => 1945-09-30 01:00:00.001-0500', () {
          expect(x3.toString(), equals('1945-09-30 01:00:00.001-0500'));
        });
      });
    });

    group('America/Detroit to UTC', () {
      group('EWT/EPT boundaries', () {
        final x1 = new TZDateTime(detroit, 1945, 9, 30, 1);
        final u1 = new DateTime.fromMillisecondsSinceEpoch(
            x1.millisecondsSinceEpoch,
            isUtc: true);

        test('$x1 => 1945-09-30 05:00:00.000Z', () {
          expect(u1.toString(), '1945-09-30 05:00:00.000Z');
        });

        final x2 = x1.subtract(const Duration(milliseconds: 1));
        final u2 = new DateTime.fromMillisecondsSinceEpoch(
            x2.millisecondsSinceEpoch,
            isUtc: true);

        test('$x2 => 1945-09-30 04:59:59.999Z', () {
          expect(u2.toString(), equals('1945-09-30 04:59:59.999Z'));
        });

        final x3 = x1.add(const Duration(milliseconds: 1));
        final u3 = new DateTime.fromMillisecondsSinceEpoch(
            x3.millisecondsSinceEpoch,
            isUtc: true);

        test('$x3 => 1945-09-30 05:00:00.001Z', () {
          expect(u3.toString(), equals('1945-09-30 05:00:00.001Z'));
        });

        final x4 = x1.add(const Duration(hours: 1));
        final u4 = new DateTime.fromMillisecondsSinceEpoch(
            x4.millisecondsSinceEpoch,
            isUtc: true);

        test('$x4 => 1945-09-30 06:00:00.000Z', () {
          expect(u4.toString(), equals('1945-09-30 06:00:00.000Z'));
        });

        final x5 = x2.add(const Duration(hours: 1));
        final u5 = new DateTime.fromMillisecondsSinceEpoch(
            x5.millisecondsSinceEpoch,
            isUtc: true);

        test('$x5 => 1945-09-30 05:59:59.999Z', () {
          expect(u5.toString(), equals('1945-09-30 05:59:59.999Z'));
        });
      });
    });
  });
}
