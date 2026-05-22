import 'package:flutter/material.dart';
import '../../widgets/common/provider_wrappers.dart';
import '../../core/utils/design_system.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selectedCode;

  final _flagEmojis = {
    'en': '🇬🇧',
    'hi': '🇮🇳',
    'gu': '🇮🇳',
    'mr': '🇮🇳',
    'bn': '🇮🇳',
    'ta': '🇮🇳',
    'te': '🇮🇳',
    'ur': '🇵🇰',
  };

  @override
  void initState() {
    super.initState();
    _selectedCode = 'en';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = LanguageProviderWrapper.of(context);
    _selectedCode = provider.locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = Theme.of(context).colorScheme.primary;
    final brandBlack = const Color(0xFF1C1C1C);
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final provider = LanguageProviderWrapper.of(context);
    final selectLangLabel = l10n?.selectLanguage ?? 'Select Language';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              color: DesignSystem.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: brandBlack),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: brandOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.language_rounded,
                          color: brandOrange, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectLangLabel,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: brandBlack,
                          ),
                        ),
                        Text(
                          'Choose your preferred language',
                          style: TextStyle(
                            fontSize: 12,
                            color: DesignSystem.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Language Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
              itemCount: AppLocalizations.supportedLocales.length,
              itemBuilder: (context, index) {
                final locale = AppLocalizations.supportedLocales[index];
                final code = locale.languageCode;
                final name = AppLocalizations.languageNames[code] ?? code;
                final flag = _flagEmojis[code] ?? '🌍';
                final isSelected = _selectedCode == code;

                return GestureDetector(
                  onTap: () async {
                    setState(() => _selectedCode = code);
                    await provider.setLanguage(code);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Text(flag, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Text(
                                '$name selected!',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: DesignSystem.white,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: brandOrange,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: isSelected ? brandOrange : DesignSystem.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? brandOrange.withValues(alpha: 0.3)
                              : DesignSystem.charcoal.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: isSelected
                            ? brandOrange
                            : const Color(0xFFF0F0F0),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(flag, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? DesignSystem.white : brandBlack,
                          ),
                        ),
                        if (code == 'en')
                          Text(
                            'English',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? DesignSystem.white.withValues(alpha: 0.7)
                                  : DesignSystem.muted,
                            ),
                          ),
                        if (isSelected)
                          const SizedBox(height: 4),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: DesignSystem.white, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
