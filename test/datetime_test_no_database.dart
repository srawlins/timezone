@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:timezone/timezone.dart';

void main() {
  group('Without initializing timezone database', () {
    test('Can still construct TZDateTime.utc', () {
      TZDateTime.utc(2019);
    });

    test('getLocation throws $LocationNotFoundException with message about the '
        'database not being initialized', () {
      expect(
        () => getLocation('America/New_York'),
        throwsA(
          const TypeMatcher<LocationNotFoundException>().having(
            (e) => e.msg,
            'msg',
            contains('database'),
          ),
        ),
      );
    });
  });
}
