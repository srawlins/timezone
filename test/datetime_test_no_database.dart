@TestOn('vm')
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';

void main() {
  group('Without initializing timezone database', () {
    test('Can still construct TZDateTime.utc', () {
      TZDateTime.utc(2019);
    });
  });
}
