import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../shared/theme/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const List<_LanguageItem> _languages = [
    _LanguageItem(code: 'uz', label: "O'zbek", flag: '🇺🇿', native: "O'zbek tili"),
    _LanguageItem(code: 'ru', label: 'Русский', flag: '🇷🇺', native: 'Русский язык'),
    _LanguageItem(code: 'en', label: 'English', flag: '🇬🇧', native: 'English'),
  ];

  /// Snackbar matni yangi til strings instansidan olinadi —
  /// shunda xabar tanlangan tilda chiqadi.
  String _getSuccessMessage(String code) {
    final s = AppStrings.forCode(code);
    switch (code) {
      case 'uz':
        return s.settingsLangSavedUz;
      case 'ru':
        return s.settingsLangSavedRu;
      case 'en':
        return s.settingsLangSavedEn;
      default:
        return s.settingsLangSavedUz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final selectedLang = localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.settingsTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.language_rounded,
              title: s.settingsLangTitle,
              subtitle: s.settingsLangSubtitle,
            ),
            const SizedBox(height: 12),
            _buildLanguageCards(context, selectedLang),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageCards(BuildContext context, String selectedLang) {
    return Column(
      children: _languages.map((lang) {
        final isSelected = selectedLang == lang.code;
        return GestureDetector(
          onTap: () async {
            // Avval LocaleProvider orqali locale o'zgartiramiz
            await context.read<LocaleProvider>().setLocale(lang.code);

            if (context.mounted) {
              // Snackbar matni yangi tilda chiqadi
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(_getSuccessMessage(lang.code)),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.stroke,
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.pageBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      lang.flag,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lang.native,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.stroke,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LanguageItem {
  final String code;
  final String label;
  final String flag;
  final String native;

  const _LanguageItem({
    required this.code,
    required this.label,
    required this.flag,
    required this.native,
  });
}
