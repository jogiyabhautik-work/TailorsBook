import 'package:flutter_test/flutter_test.dart';
import 'package:tailorsbook/core/utils/version_utils.dart';

void main() {
  group('VersionUtils.parse', () {
    test('parses standard semver', () {
      expect(VersionUtils.parse('1.2.3'), [1, 2, 3]);
    });
    test('parses with trailing zeros', () {
      expect(VersionUtils.parse('1.0.0'), [1, 0, 0]);
    });
    test('parses two-segment version', () {
      expect(VersionUtils.parse('2.5'), [2, 5]);
    });
    test('handles empty string', () {
      expect(VersionUtils.parse(''), [0]);
    });
    test('handles non-numeric segments', () {
      expect(VersionUtils.parse('1.0a.3'), [1, 0, 3]);
    });
  });

  group('VersionUtils.compare', () {
    test('equal versions returns 0', () {
      expect(VersionUtils.compare('1.2.3', '1.2.3'), 0);
    });
    test('a < b returns -1', () {
      expect(VersionUtils.compare('1.2.3', '1.2.4'), -1);
    });
    test('a > b returns 1', () {
      expect(VersionUtils.compare('2.0.0', '1.9.9'), 1);
    });
    test('different segment lengths: equal', () {
      expect(VersionUtils.compare('1.0', '1.0.0'), 0);
    });
    test('different segment lengths: shorter < longer', () {
      expect(VersionUtils.compare('1.0', '1.0.1'), -1);
    });
    test('numeric-aware: 1.0.9 < 1.0.10', () {
      expect(VersionUtils.compare('1.0.9', '1.0.10'), -1);
    });
    test('major version takes precedence', () {
      expect(VersionUtils.compare('2.0.0', '1.99.99'), 1);
    });
    test('same version with non-numeric chars', () {
      expect(VersionUtils.compare('1.2.3-beta', '1.2.3'), 0);
    });
  });
}
