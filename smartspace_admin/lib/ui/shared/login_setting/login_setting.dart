// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:mobile_shared/core/localization/locale_provider.dart';
import 'package:mobile_shared/core/theme/theme_provider.dart';

class LoginSetting extends StatelessWidget {
  const LoginSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.settings, color: colorScheme.onSurface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.settings,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        l10n.language,
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Language switcher
                    ListenableBuilder(
                      listenable: localeProvider,
                      builder: (context, _) {
                        final currentLocale =
                            localeProvider.locale.languageCode;
                        return Column(
                          children: [
                            // Vietnamese
                            RadioListTile<String>(
                              title: Row(
                                children: [
                                  Image.asset(
                                    'assets/vi_flag.png',
                                    width: 24,
                                    height: 16,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(l10n.vietnamese)),
                                ],
                              ),
                              value: 'vi',
                              groupValue: currentLocale,
                              onChanged: (value) {
                                if (value != null) {
                                  localeProvider.setLocale(Locale(value));
                                }
                              },
                              controlAffinity: ListTileControlAffinity.trailing,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            // English
                            RadioListTile<String>(
                              title: Row(
                                children: [
                                  Image.asset(
                                    'assets/uk_flag.png',
                                    width: 24,
                                    height: 16,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(l10n.english)),
                                ],
                              ),
                              value: 'en',
                              groupValue: currentLocale,
                              onChanged: (value) {
                                if (value != null) {
                                  localeProvider.setLocale(Locale(value));
                                }
                              },
                              controlAffinity: ListTileControlAffinity.trailing,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Divider(height: 1),
                    ),

                    // Theme switcher
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        l10n.theme,
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: themeProvider,
                      builder: (context, _) {
                        final currentTheme = themeProvider.themeMode;
                        return Column(
                          children: [
                            // Light
                            RadioListTile<ThemeMode>(
                              title: Row(
                                children: [
                                  Image.asset(
                                    'assets/day_icon.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(l10n.themeLight)),
                                ],
                              ),
                              value: ThemeMode.light,
                              groupValue: currentTheme,
                              onChanged: (value) {
                                if (value != null) {
                                  themeProvider.setThemeMode(value);
                                }
                              },
                              controlAffinity: ListTileControlAffinity.trailing,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            // Dark
                            RadioListTile<ThemeMode>(
                              title: Row(
                                children: [
                                  Image.asset(
                                    'assets/night_icon.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(l10n.themeDark)),
                                ],
                              ),
                              value: ThemeMode.dark,
                              groupValue: currentTheme,
                              onChanged: (value) {
                                if (value != null) {
                                  themeProvider.setThemeMode(value);
                                }
                              },
                              controlAffinity: ListTileControlAffinity.trailing,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            // System
                            RadioListTile<ThemeMode>(
                              title: Row(
                                children: [
                                  Image.asset(
                                    'assets/device_icon.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(l10n.themeSystem)),
                                ],
                              ),
                              value: ThemeMode.system,
                              groupValue: currentTheme,
                              onChanged: (value) {
                                if (value != null) {
                                  themeProvider.setThemeMode(value);
                                }
                              },
                              controlAffinity: ListTileControlAffinity.trailing,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
