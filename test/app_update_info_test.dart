import 'package:flutter_test/flutter_test.dart';
import 'package:tailorsbook/models/app_update_info.dart';

void main() {
  group('AppUpdateInfo.fromMap', () {
    test('parses all fields correctly', () {
      final info = AppUpdateInfo.fromMap({
        'latest_version': '1.2.0',
        'minimum_supported_version': '1.0.0',
        'update_required': true,
        'flexible_allowed': false,
        'update_title': 'Test Update',
        'update_description': 'Test description',
        'apk_url': 'https://example.com/app.apk',
        'apk_size_bytes': 12345678,
      });
      expect(info.latestVersion, '1.2.0');
      expect(info.minimumSupportedVersion, '1.0.0');
      expect(info.updateRequired, true);
      expect(info.flexibleAllowed, false);
      expect(info.title, 'Test Update');
      expect(info.description, 'Test description');
      expect(info.apkUrl, 'https://example.com/app.apk');
      expect(info.sizeBytes, 12345678);
      expect(info.fetchedAt, isNotNull);
    });

    test('missing optional fields use defaults', () {
      final info = AppUpdateInfo.fromMap({'latest_version': '1.2.0'});
      expect(info.latestVersion, '1.2.0');
      expect(info.minimumSupportedVersion, '0.0.0');
      expect(info.updateRequired, false);
      expect(info.flexibleAllowed, true);
      expect(info.title, 'Update Available');
      expect(info.description, '');
      expect(info.apkUrl, null);
      expect(info.sizeBytes, null);
    });

    test('handles empty map', () {
      final info = AppUpdateInfo.fromMap({});
      expect(info.latestVersion, '0.0.0');
      expect(info.fetchedAt, isNotNull);
    });

    test('handles apk_size_bytes as int', () {
      final info = AppUpdateInfo.fromMap({'apk_size_bytes': 5000000, 'latest_version': '1.0.0'});
      expect(info.sizeBytes, 5000000);
    });
  });
}
