import 'package:flutter/material.dart';
import 'package:mobile_shared/core/localization/locale_provider.dart';

class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeProvider,
      builder: (context, _) {
        final currentLocale = localeProvider.locale.languageCode;

        return PopupMenuButton<String>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onSelected: (value) {
            localeProvider.setLocale(Locale(value));
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'vi',
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.asset(
                      'assets/vi_flag.png',
                      width: 24,
                      height: 16,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Tiếng Việt'),
                  const Spacer(),
                  IgnorePointer(
                    // ignore: deprecated_member_use
                    child: Radio<String>(
                      value: 'vi',
                      // ignore: deprecated_member_use
                      groupValue: currentLocale,
                      // ignore: deprecated_member_use
                      onChanged: (value) {},
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'en',
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.asset(
                      'assets/uk_flag.png',
                      width: 24,
                      height: 16,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('English'),
                  const Spacer(),
                  IgnorePointer(
                    // ignore: deprecated_member_use
                    child: Radio<String>(
                      value: 'en',
                      // ignore: deprecated_member_use
                      groupValue: currentLocale,
                      // ignore: deprecated_member_use
                      onChanged: (value) {},
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, size: 20),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
