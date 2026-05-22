import 'package:flutter/material.dart';

/// Feature flag: language support is postponed for next update.
/// Do NOT enable until translations are completed and tested across all screens.
/// TODO: Remove this flag and restore full language switching in a future update
///       when all translations are production-ready.
const bool kLanguageSupportEnabled = false;

class LanguageProvider extends ChangeNotifier {
  /// Always returns English until language support is re-enabled.
  Locale get locale => const Locale('en');

  LanguageProvider() {
    // Language support is postponed. Provider exists for widget tree compatibility.
    // No initialization needed — always uses English.
  }

  /// No-op until language support is re-enabled in a future update.
  /// TODO: Restore when kLanguageSupportEnabled is set to true.
  Future<void> setLanguage(String languageCode) async {
    // Language switching is disabled. All UI stays English-only.
    debugPrint('LanguageProvider: setLanguage("$languageCode") called but language support is disabled.');
  }
}
