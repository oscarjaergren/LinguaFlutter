import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/shared.dart';
import '../../../language/domain/language_provider.dart';

/// Widget for selecting the active language in the app bar
class LanguageSelectorWidget extends StatelessWidget {
  const LanguageSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final activeLanguage = languageProvider.activeLanguage;
        final languageDetails = languageProvider.getLanguageDetails(activeLanguage)!;

        return PopupMenuButton<String>(
          onSelected: (String languageCode) {
            languageProvider.setActiveLanguage(languageCode);
            context.read<CardProvider>().onLanguageChanged();
          },
          itemBuilder: (BuildContext context) {
            return languageProvider.availableLanguages.entries.map((entry) {
              final code = entry.key;
              final details = entry.value;
              return PopupMenuItem<String>(
                value: code,
                child: Row(
                  children: [
                    Text(
                      details['flag'],
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(details['name']),
                    if (code == activeLanguage) ...[
                      const Spacer(),
                      Icon(
                        Icons.check,
                        color: languageProvider.getLanguageColor(code),
                        size: 16,
                      ),
                    ],
                  ],
                ),
              );
            }).toList();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                languageDetails['flag'],
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                languageDetails['name'],
                style: TextStyle(
                  color: languageProvider.getLanguageColor(activeLanguage),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: languageProvider.getLanguageColor(activeLanguage),
              ),
            ],
          ),
        );
      },
    );
  }
}
