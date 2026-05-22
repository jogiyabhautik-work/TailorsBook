import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:tailorsbook/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads english json and returns keys', () async {
    final loc = await AppLocalizations.load(const Locale('en'));
    expect(loc.appName, isNotEmpty);
    expect(loc.invoice, 'Invoice');
  });

  test('loads hindi and falls back to english for missing key', () async {
    final locHi = await AppLocalizations.load(const Locale('hi'));
    // assuming 'app_name' exists in en.json; if missing in hi, fallback should return en
    final name = locHi.appName;
    expect(name, isNotEmpty);
  });

  test('translate with params replaces values', () async {
    final loc = await AppLocalizations.load(const Locale('en'));
    final text = loc.translate('invoice_shared_error', {'error': '404'});
    expect(text.contains('404'), isTrue);
  });
}
